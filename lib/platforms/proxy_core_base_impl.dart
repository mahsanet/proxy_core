import 'dart:async';
import 'dart:io';

import 'package:proxy_core/constants/grpc_channel_config.dart';
import 'package:proxy_core/ffi/ffi.dart';
import 'package:proxy_core/gen/bindings/ProxyCoreService.pbgrpc.dart';
import 'package:proxy_core/method_channel/vpn_mode_channel.dart';
import 'package:proxy_core/models/proxy_core_config.dart';
import 'package:proxy_core/models/proxy_core_exception.dart';
import 'package:proxy_core/platforms/proxy_core_interface.dart';
import 'package:proxy_core/utils/persistent_notification_service.dart';

class ProxyCoreBaseImpl
    with VpnModeChannelMixin, ProxyCoreBindingsMixin
    implements ProxyCoreInterface {
  late final ProxyCoreClient _grpcClient;
  bool _isGrpcServerInitialized = false;
  final _notifService = PersistentNotificationService.instance;

  late final Future<void> Function(bool isRunning)? _onCoreStateChanged;

  bool _isInitialized = false;

  Timer? _vpnStatusTimer;

  bool get _shouldUseNotifications => !(Platform.isWindows || Platform.isIOS);

  @override
  Future<void> initialize({
    Future<void> Function(bool isRunning)? onCoreStateChanged,
  }) async {
    if (_isInitialized) return;
    _onCoreStateChanged = onCoreStateChanged;
    _initializeGrpcServer();
    if (_shouldUseNotifications) {
      await _notifService.initialize();
    }
    _isInitialized = true;
    _onCoreStateChanged?.call(await isRunning);
  }

  void _initializeGrpcServer() {
    try {
      final result = nativeLib.GRPCSERVER();
      if (result < 1) {
        throw ProxyCoreException.message(
          'GRPC server is not available/GRPC start failed.',
        );
      }
      _grpcClient = ProxyCoreClient(grpcChannelConfig);
      _isGrpcServerInitialized = true;
    } catch (e, stackTrace) {
      throw ProxyCoreException(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<bool> get isRunning => _executeGrpcOperation(() async {
        var val = (await _grpcClient.isCoreRunning(Empty())).message;
        return val;
      });

  @override
  Future<String> get version => _executeGrpcOperation(() async {
        return (await _grpcClient.getVersion(Empty())).message;
      });

  @override
  Future<void> start(ProxyCoreConfig config) async {
    if (_shouldUseNotifications && !await _notifService.requestPermissions()) {
      throw ProxyCoreException.message('Required permissions not granted');
    }

    await _start(config);

    if (_shouldUseNotifications) {
      await _notifService.showActiveNotification(
        config.vpnMode ? "VPN" : "Proxy",
      );
    }
  }

  @override
  Future<void> simpleStart(ProxyCoreConfig config) async {
    await stopAnyRunningVPN();
    return _start(config);
  }

  Future<void> _start(ProxyCoreConfig config) async {
    await _executeGrpcOperation(() async {
      await stop();

      final finalConfig = await prepareConfigForVpnIfNeeded(config);

      await _grpcClient.startCore(finalConfig.toGrpcModel());
      await _onCoreStateChanged?.call(await isRunning);

      // Start VPN status polling if in VPN mode
      if (finalConfig.vpnMode) _startVpnStatusPolling();
    });
  }

  @override
  Future<void> stop() async {
    await _executeGrpcOperation(() async {
      await stopVPN();
      await _grpcClient.stopCore(Empty());
      await _onCoreStateChanged?.call(await isRunning);

      if (_shouldUseNotifications) {
        await _notifService.cancelProxyNotification();
      }
      _stopVpnStatusPolling();
    });
  }

  @override
  Future<List<PingResult>> measurePing(List<String> urls) =>
      _executeGrpcOperation(() async {
        return (await _grpcClient.measurePing(MeasurePingRequest(url: urls)))
            .results;
      });

  @override
  Future<LogResponse> fetchLogs() => _executeGrpcOperation(() async {
        return await _grpcClient.fetchLogs(Empty());
      });

  @override
  Future<Empty> clearLogs() => _executeGrpcOperation(() async {
        return await _grpcClient.clearLogs(Empty());
      });

  @override
  void ensureInitialized() {
    if (!_isGrpcServerInitialized) {
      throw ProxyCoreException.message(
        'GRPC server not initialized. Call initialize() first.',
      );
    }
  }

  Future<T> _executeGrpcOperation<T>(Future<T> Function() operation) async {
    ensureInitialized();
    try {
      return await operation();
    } catch (e, stackTrace) {
      throw ProxyCoreException(e, stackTrace: stackTrace);
    }
  }

  void _startVpnStatusPolling() async {
    _stopVpnStatusPolling();
    _vpnStatusTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      await setVpnStatus();
      if (!isVPNRunning) await stop();
    });
  }

  void _stopVpnStatusPolling() {
    _vpnStatusTimer?.cancel();
    _vpnStatusTimer = null;
  }
}
