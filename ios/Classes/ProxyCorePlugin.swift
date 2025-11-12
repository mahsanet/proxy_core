import Flutter
import UIKit

public class ProxyCorePlugin: NSObject, FlutterPlugin {
    private let implementation: ProxyCorePluginIosImpl

    override init() {
        self.implementation = ProxyCorePluginIosImpl()
        super.init()
    }
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "proxy_core/vpn", binaryMessenger: registrar.messenger())
        let instance = ProxyCorePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Register event channel for VPN tunnel status updates
        let eventChannel = FlutterEventChannel(name: "proxy_core/vpn_events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance.implementation)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        implementation.handleMethodCall(call, result: result)
    }
}
