import 'dart:async';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/gen/bindings/ProxyCoreService.pb.dart';
import 'package:proxy_core/models/proxy_core_config.dart';
import 'package:proxy_core/models/proxy_core_exception.dart';
import 'package:proxy_core/platforms/proxy_core_interface.dart';

/// iOS-specific implementation of the ProxyCore interface using method channels.
class ProxyCoreIosVpnImpl implements ProxyCoreInterface {
  late final String appName;
  late final String appTunnelBundle;

  // Channels for communicating with native iOS code
  static const MethodChannel _channel = MethodChannel('proxy_core/vpn');
  static const EventChannel _eventChannel =
      EventChannel('proxy_core/vpn_events');

  Future<void> Function(bool isRunning)? _onCoreStateChanged;
  StreamSubscription? _vpnStatusSubscription;

  /// Wraps native calls and Dart logic in a try-catch to ensure consistent error handling
  T _safeExecute<T>(String operation, T Function() action) {
    try {
      return action();
    } on PlatformException catch (e, stackTrace) {
      throw ProxyCoreException('Failed to $operation: ${e.message}',
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw ProxyCoreException(e, stackTrace: stackTrace);
    }
  }

  /// Utility wrapper to invoke native methods with consistent error handling
  Future<T?> _invokeMethod<T>(String method,
      [dynamic args, String? opName]) async {
    return _safeExecute(
        opName ?? method, () => _channel.invokeMethod<T>(method, args));
  }

  @override
  Future<void> initialize(
      {Future<void> Function(bool)? onCoreStateChanged}) async {
    _onCoreStateChanged ??= onCoreStateChanged;
    if (_vpnStatusSubscription == null && _onCoreStateChanged != null) {
      _listenToVpnStatusChanges(); // Native -> Dart event listener
    }

    final status = await getTunnelStatus();
    _onCoreStateChanged?.call(status);
  }

  /// Set up listener from iOS VPN status changes via event channel
  void _listenToVpnStatusChanges() {
    _vpnStatusSubscription = _eventChannel.receiveBroadcastStream().listen(
          (status) => _onCoreStateChanged?.call(status),
          onError: (e) => throw ProxyCoreException('VPN status error: $e'),
        );
  }

  void setIosTunnelInfo(String name, String bundle) {
    _safeExecute('set tunnel info', () {
      appName = name;
      appTunnelBundle = bundle;
    });
  }

  /// Prepares the VPN tunnel configuration by passing necessary app info
  Future<void> _prepareVPN() async {
    await _invokeMethod(
        'prepare',
        {
          'appName': appName,
          'appTunnelBundle': appTunnelBundle,
        },
        'prepare VPN');
  }

  @override
  Future<bool> get isRunning async {
    final result =
        await _invokeMethod<bool>('isCoreRunning', null, 'check core status');
    return result ?? false;
  }

  @override
  Future<String> get version async {
    return await _invokeMethod<String>('getVersion', null, 'get version') ??
        'unknown';
  }

  @override
  Future<void> start(ProxyCoreConfig config) async {
    if (await getTunnelStatus()) {
      // Tunnel is Connected
      return await simpleStart(config);
    }
    await _prepareVPN();
    await _invokeMethod(
        'startVPN',
        {
          'coreName': config.core.name,
          'config': config.config,
          'cacheDir': config.dir,
          'appName': appName,
          'appTunnelBundle': appTunnelBundle,
        },
        'start VPN tunnel');
  }

  @override
  Future<void> stop() async {
    await _invokeMethod('stopVPN', null, 'stop VPN');
  }

  @override
  Future<List<PingResult>> measurePing(List<String> urls) async {
    final pingString = await _invokeMethod<String>(
      'measurePing',
      {'urls': urls.join(',')},
      'measure ping',
    );

    try {
      final parts = pingString?.split(',') ?? [];
      final results = <PingResult>[];

      for (int i = 0; i < parts.length && i < urls.length; i++) {
        final delay = parts[i].isNotEmpty ? Int64.parseInt(parts[i]) : null;
        results.add(PingResult(url: urls[i], delay: delay));
      }

      return results;
    } catch (e) {
      if (e is FormatException) {
        throw ProxyCoreException('Ping result failed');
      }
      throw ProxyCoreException('Ping result failed: $e');
    }
  }

  @override
  Future<LogResponse> fetchLogs() async {
    final logs = await _invokeMethod<String>('fetchLogs', null, 'fetch logs');
    return LogResponse(logs: logs ?? '');
  }

  @override
  Future<Empty> clearLogs() async {
    await _invokeMethod('clearLogs', null, 'clear logs');
    return Empty();
  }

  /// Check VPN status by asking native code if the tunnel is active
  Future<bool> getTunnelStatus() async {
    final status = await _invokeMethod<String>('getTunnelStatus');
    return status == "connected";
  }

  @override
  void ensureInitialized() {
    // iOS native channel setup is always ready; nothing to do.
  }

  void dispose() {
    _vpnStatusSubscription?.cancel();
    _vpnStatusSubscription = null;
  }

  @override
  Future<void> simpleStart(ProxyCoreConfig config) async {
    // Stop any existing core first
    await _simpleStop();

    if (!await getTunnelStatus()) {
      // Tunnel is Not Connected
      await _prepareVPN();
      await _invokeMethod(
          'simpleStartVpn',
          {
            'appName': appName,
            'appTunnelBundle': appTunnelBundle,
          },
          'start VPN tunnel');
    }

    // If already connected, do nothing
    await _invokeMethod(
        'simpleStart',
        {
          'coreName': config.core.name,
          'config': config.config,
          'cacheDir': config.dir,
        },
        'Sipmle Start Core');
  }

  Future<void> _simpleStop() async {
    await _invokeMethod('simpleStop', null, 'Simple Stop Core');
  }
}
