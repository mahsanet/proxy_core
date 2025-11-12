import Foundation
import NetworkExtension
import Combine
import os.log


// Protocol for better testability
protocol VpnServiceProtocol {
    func prepareVPN(
        appName: String, appTunnelBundle: String,
        completion: @escaping (Result<Void, Error>) -> Void)
    func startVPN(
        startMode: String,
        coreName: String?,
        config: String?,
        cacheDir: String?,
        port: Int32,
        appName: String,
        appTunnelBundle: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func stopVPN(completion: @escaping (Result<Void, Error>) -> Void)
    func sendTunnelMessage(_ messageDict: [String: String], completion: ((String?) -> Void)?)
    var vpnManager: NETunnelProviderManager? { get set }

}

// Protocol for VPN status updates
protocol VpnStatusDelegate: AnyObject {
    func vpnStatusDidChange(_ status: NEVPNStatus)
}

enum VpnServiceError: Error, LocalizedError {
    case managerNotInitialized
    case invalidSession
    case messageEncodingFailed
    case alreadyStopped

    var errorDescription: String? {
        switch self {
        case .managerNotInitialized:
            return "VPN Manager not initialized"
        case .invalidSession:
            return "Invalid VPN connection session"
        case .messageEncodingFailed:
            return "Failed to encode tunnel message"
        case .alreadyStopped:
            return "VPN is already stopped"
        }
    }
}

class VpnService: VpnServiceProtocol {
    private var _vpnManager: NETunnelProviderManager?
    
    // Updated to include setter for protocol conformance
    var vpnManager: NETunnelProviderManager? {
        get { return _vpnManager }
        set { _vpnManager = newValue }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var vpnStatusCancellable: AnyCancellable?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ProxyCore", category: "VpnService")

    // Add a property to track the last logged status
    private var lastLoggedStatus: NEVPNStatus?
    
    // Add delegate for status updates
    weak var statusDelegate: VpnStatusDelegate?

    static let shared = VpnService()

    private init() {
        // Register for app lifecycle notifications
        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(appWillEnterForeground),
        //     name: UIApplication.willEnterForegroundNotification,
        //     object: nil
        // )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillEnterForeground() {
        // Reload VPN manager and restore observation when app comes to foreground
        loadManager { [weak self] success in
            guard let self = self, success, let manager = self._vpnManager else { return }
            
            // Ensure we're observing status changes
            self.observeVPNStatus(manager)
            
            // Get current status
            let status = manager.connection.status
            self.updateVPNStatus(status)
            
            // Double-check with tunnel if possible
            if let session = manager.connection as? NETunnelProviderSession {
                self.sendTunnelMessage(["command": "IS_CORE_RUNNING"]) { response in
                    if response?.lowercased() == "true" {
                        // Core is actually running
                        DispatchQueue.main.async {
                            // Force status to connected if core is running
                            if status != .connected {
                                self.logger.info("Core is running but status is not connected, forcing connected status")
                                self.statusDelegate?.vpnStatusDidChange(.connected)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadManager(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let managers = try await NETunnelProviderManager.loadAllFromPreferences()
                if let manager = managers.first {
                    self._vpnManager = manager
                    self.logger.info("Loaded existing VPN manager")
                    completion(true)
                } else {
                    self.logger.warning("No existing VPN manager found")
                    completion(false)
                }
            } catch {
                self.logger.error("Failed to load managers: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func prepareVPN(
        appName: String, appTunnelBundle: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                let managers = try await NETunnelProviderManager.loadAllFromPreferences()

                if managers.isEmpty {
                    self._vpnManager = NETunnelProviderManager()
                    do {
                        try configureVPNManager(
                            self._vpnManager!, appName: appName, appTunnelBundle: appTunnelBundle)
                        try await self._vpnManager?.saveToPreferences()
                    } catch {
                        completion(.failure(error))
                        return
                    }
                } else {
                    self._vpnManager = managers.first
                }

                guard let manager = self._vpnManager else {
                    completion(.failure(VpnServiceError.managerNotInitialized))
                    return
                }

                try await manager.loadFromPreferences()
                self.observeVPNStatus(manager)
                completion(.success(()))
            } catch {
                self.logger.error("Failed to prepare VPN: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private func enableVPNManager(_ manager: NETunnelProviderManager) async throws {
        do {
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func startVPN(
        startMode: String,
        coreName: String?,
        config: String?,
        cacheDir: String?,
        port: Int32,
        appName: String,
        appTunnelBundle: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                guard let manager = _vpnManager else {
                    throw VpnServiceError.managerNotInitialized
                }
                try configureVPNManager(
                    manager, appName: appName, appTunnelBundle: appTunnelBundle)
                try await enableVPNManager(manager)

                // Check if VPN is already connected and stop it first
                try await stopVpnTunnel(manager)
                

                let options: [String: NSObject] = [
                    "startMode": startMode as NSString,
                    "coreName": (coreName ?? "") as NSString,
                    "port": NSNumber(value: port),
                    "address": "127.0.0.1" as NSString,
                    "mtu": NSNumber(value: 1500),
                    "config": (config ?? "") as NSString,
                    "cacheDir": (cacheDir ?? "") as NSString,
                ]

                try manager.connection.startVPNTunnel(options: options)
                self.logger.info("VPN tunnel initiation successful")
                completion(.success(()))
            } catch {
                self.logger.error("VPN Start Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }


    func stopVPN(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                guard let manager = _vpnManager else {
                    throw VpnServiceError.managerNotInitialized
                }

                try await manager.loadFromPreferences()

                try await stopVpnTunnel(manager)
                completion(.success(()))
            } catch {
                self.logger.error("Failed to stop VPN: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func sendTunnelMessage(_ messageDict: [String: String], completion: ((String?) -> Void)? = nil)
    {
        Task {
            do {
                guard let manager = _vpnManager else {
                    self.logger.error("VPN Manager is not initialized")
                    completion?(nil)
                    return
                }

                try await manager.loadFromPreferences()

                guard let session = manager.connection as? NETunnelProviderSession else {
                    self.logger.error("Invalid VPN connection")
                    completion?(nil)
                    return
                }

                guard
                    let data = try? JSONSerialization.data(withJSONObject: messageDict, options: [])
                else {
                    self.logger.error("Failed to encode message")
                    completion?(nil)
                    return
                }

                try session.sendProviderMessage(data) { responseData in
                    if let responseData = responseData,
                        let responseString = String(data: responseData, encoding: .utf8)
                    {
                        completion?(responseString)
                    } else {
                        self.logger.warning("No response or invalid response from tunnel")
                        completion?(nil)
                    }
                }
            } catch {
                self.logger.error("Error sending tunnel message: \(error.localizedDescription)")
                completion?(nil)
            }
        }
    }

    private func configureVPNManager(
        _ manager: NETunnelProviderManager, appName: String, appTunnelBundle: String
    ) throws {
        manager.localizedDescription = appName

        let protocolConfig = NETunnelProviderProtocol()
        protocolConfig.providerBundleIdentifier = appTunnelBundle
        protocolConfig.serverAddress = appName

        let configData: [String: Any] = [
            "address": "127.0.0.1",
            "port": 2080,
            "mtu": 1500,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: configData) else {
            throw VpnServiceError.messageEncodingFailed
        }

        protocolConfig.providerConfiguration = ["config": data]
        protocolConfig.excludeLocalNetworks = true

        manager.protocolConfiguration = protocolConfig
        manager.isEnabled = true
        manager.isOnDemandEnabled = false
        manager.onDemandRules = []
    }

    private func observeVPNStatus(_ manager: NETunnelProviderManager) {
        // Cancel any existing subscription
        vpnStatusCancellable?.cancel()
        
        vpnStatusCancellable = NotificationCenter.default.publisher(for: .NEVPNStatusDidChange, object: manager.connection)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let status = manager.connection.status
                self.updateVPNStatus(status)
            }
    }

    private func stopVpnTunnel(_ manager: NETunnelProviderManager) async throws {
        switch manager.connection.status {
                case .connected, .connecting, .reasserting:
                    manager.connection.stopVPNTunnel()
                    self.logger.info("Stopping existing connection before reconnecting")
                default:
                    // VPN is already stopped so just complete the task
                    self.logger.info("VPN is already stopped. Current status: \(String(manager.connection.status.rawValue))")
                }
    }

    private func updateVPNStatus(_ status: NEVPNStatus) {
        // Only log if the status has changed from the previous one
        if lastLoggedStatus != status {
            switch status {
            case .connected:
                logger.info("VPN Connected")
            case .connecting:
                logger.info("VPN Connecting...")
            case .disconnecting:
                logger.info("VPN Disconnecting...")
            case .disconnected:
                logger.info("VPN Disconnected")
            case .reasserting:
                logger.info("VPN Reasserting...")
            case .invalid:
                logger.error("VPN Status Invalid")
            @unknown default:
                logger.warning("VPN Unknown Status: \(String(status.rawValue))")
            }
            
            // Update the last logged status
            lastLoggedStatus = status
            
            // Notify delegate with the actual status
            statusDelegate?.vpnStatusDidChange(status)
        }
    }
}
