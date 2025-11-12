import NetworkExtension
import Tun2SocksKit
import os.log
import ProxyCoreKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ProxyCoreTunnel", category: "TunnelProvider")

    // Configuration defaults
    private struct TunnelDefaults {
        static let port: Int32 = 2080
        static let address = "127.0.0.1"
        static let mtu = 1500
        static let tunnelAddress = "127.0.0.1"
        static let tunnelIpv4 = "198.18.0.1"
        static let tunnelIpv4Mask = "255.255.255.0"
        static let tunnelIpv6 = "fc00::1"
        static let tunnelIpv6PrefixLength = 64
        static let dnsServers = ["1.1.1.1", "8.8.8.8"]
        static let taskStackSize = 20480
        static let tcpBufferSize = 4096
        static let connectTimeout = 5000
        static let readWriteTimeout = 60000
        static let logLevel = "error"
    }

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let config = getTunnelConfiguration(options: options)

        let networkSettings = createNetworkSettings(
            mtu: config.mtu,
            ipv4Address: TunnelDefaults.tunnelIpv4,
            ipv6Address: TunnelDefaults.tunnelIpv6
        )

        logger.info("Applying Tunnel Network Settings...")

        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("Failed to set network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            self.logger.info("Network settings applied successfully")

            let grpcStarted = self.startGRPCServer()
            if grpcStarted {
                self.startProxyCore(
                    coreName: config.coreName,
                    cacheDir: config.cacheDir,
                    config: config.xrayConfig
                )
            }

            let tunnelConfig = self.createSocks5TunnelConfig(
                mtu: config.mtu,
                port: config.port,
                address: config.address
            )

            self.startSocks5Tunnel(config: tunnelConfig)
            self.logger.info("Tunnel Started ✅")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping VPN tunnel...")
        Tun2SocksKit.Socks5Tunnel.quit()
        logger.info("Tunnel stopped successfully")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let json = try? JSONSerialization.jsonObject(with: messageData, options: []),
              let dict = json as? [String: String],
              let command = dict["command"] else {
            logger.error("❌ Invalid JSON or missing command.")
            completionHandler?(nil)
            return
        }

        logger.debug("Received command: \(command)")

        switch command {
        case "IS_CORE_RUNNING":
            let isCoreRunning = IosIsCoreRunningIOS()
            let response = String(isCoreRunning)
            completionHandler?(response.data(using: .utf8))

        case "measurePing":
            let urls = dict["urls"]
            let pingResult = IosMeasurePingIOS(urls)
            completionHandler?(pingResult.data(using: .utf8))

        case "FETCH_LOGS":
            let fetchedLogs = IosFetchLogsIOS()
            completionHandler?(fetchedLogs.data(using: .utf8))

        case "CLEAR_LOGS":
            IosClearLogsIOS()
            completionHandler?(nil)

        case "GET_VERSION":
            let version = IosGetVersionIOS()
            completionHandler?(version.data(using: .utf8))

        default:
            logger.warning("Unknown command received: \(command)")
            completionHandler?(nil)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        logger.info("Tunnel going to sleep...")
        completionHandler()
    }

    override func wake() {
        logger.info("Tunnel waking up...")
    }

    private struct TunnelConfiguration {
        let port: Int32
        let address: String
        let mtu: Int
        let config: String?
        let cacheDir: String?
        let coreName: String?
    }

    private func getTunnelConfiguration(options: [String: NSObject]?) -> TunnelConfiguration {
        var port: Int32 = TunnelDefaults.port
        var address: String = TunnelDefaults.address
        var mtu: Int = TunnelDefaults.mtu
        if let providerConfig = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
           let configData = providerConfig["config"] as? Data,
           let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {

            if let configPort = config["port"] as? Int {
                port = Int32(configPort)
            }

            if let configAddress = config["address"] as? String {
                address = configAddress
            }

            if let configMtu = config["mtu"] as? Int {
                mtu = configMtu
            }
        }

        if let optPort = (options?["port"] as? NSNumber)?.int32Value {
            port = optPort
        }

        if let optAddress = options?["address"] as? String {
            address = optAddress
        }

        if let optMtu = (options?["mtu"] as? NSNumber)?.intValue {
            mtu = optMtu
        }

        let coreName = options?["coreName"] as? String
        let config = options?["config"] as? String
        let cacheDir = options?["cacheDir"] as? String

        return TunnelConfiguration(
            port: port,
            address: address,
            mtu: mtu,
            config: config,
            cacheDir: cacheDir,

            coreName: coreName
        )
    }

    private func createNetworkSettings(mtu: Int, ipv4Address: String, ipv6Address: String) -> NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: TunnelDefaults.tunnelAddress)
        networkSettings.mtu = NSNumber(value: mtu)

        let ipv4Settings = NEIPv4Settings(addresses: [ipv4Address], subnetMasks: [TunnelDefaults.tunnelIpv4Mask])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings

        let ipv6Settings = NEIPv6Settings(addresses: [ipv6Address], networkPrefixLengths: [NSNumber(value: TunnelDefaults.tunnelIpv6PrefixLength)])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        networkSettings.ipv6Settings = ipv6Settings

        networkSettings.dnsSettings = NEDNSSettings(servers: TunnelDefaults.dnsServers)

        return networkSettings
    }

    private func createSocks5TunnelConfig(mtu: Int, port: Int32, address: String) -> String {
        return """
        tunnel:
            mtu: \(mtu)
            ipv4: \(TunnelDefaults.tunnelIpv4)
            ipv6: '\(TunnelDefaults.tunnelIpv6)'

        socks5:
            port: \(port)
            address: \(address)
            udp: 'udp'
            pipeline: true

        misc:
            task-stack-size: \(TunnelDefaults.taskStackSize)
            tcp-buffer-size: \(TunnelDefaults.tcpBufferSize)
            connect-timeout: \(TunnelDefaults.connectTimeout)
            read-write-timeout: \(TunnelDefaults.readWriteTimeout)
            log-file: stderr
            log-level: \(TunnelDefaults.logLevel)
        """
    }

    private func startGRPCServer() -> Bool {
        let grpcStarted = IosStartGRPCIOS()
        if grpcStarted {
            logger.info("GRPC Server started successfully")
            return true
        } else {
            logger.error("Failed to start GRPC Server")
            return false
        }
    }


    private func startProxyCore(coreName: String?, cacheDir: String?, config: String?) {
        guard let coreName = coreName, let config = config, let cacheDir = cacheDir else {
            logger.error("Missing core name, config, or cache directory.")
            return
        }

        let result = IosStartCoreIOS(coreName, cacheDir, config, 128, true, 2080)

        if result == "true" {
            logger.info("Core \(coreName) started successfully")
        } else {
            logger.error("Failed to start core \(coreName): \(result)")
        }
    }

    private func startSocks5Tunnel(config: String) {
        Socks5Tunnel.run(withConfig: .string(content: config)) { result in
            self.logger.info("Tunnel exit code: \(result)")
        }
    }
}