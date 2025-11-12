import 'dart:io';
import 'package:proxy_core/gen/bindings/ProxyCoreService.pb.dart';
import 'package:proxy_core/models/proxy_core_exception.dart';
import 'package:proxy_core/constants/core_names.dart'; // Assuming enum is here

class ProxyCoreConfig {
  final CoreNames core;
  final String dir;
  final String config;
  final int memory;
  final bool isString;
  final int proxyPort;
  final bool _vpnMode;
  late final int? _parcelFileId;

  ProxyCoreConfig.inProxyMode({
    this.core = CoreNames.xray,
    required this.dir,
    required this.config,
    this.memory = 128,
    this.isString = true,
    this.proxyPort = 2080,
  })  : _vpnMode = false,
        _parcelFileId = null {
    if (Platform.isIOS) {
      throw ProxyCoreException('Proxy Mode is not supported on iOS');
    }
  }

  ProxyCoreConfig.inVpnMode({
    this.core = CoreNames.xray,
    required this.dir,
    required this.config,
    this.memory = 128,
    this.isString = true,
    this.proxyPort = 2080,
  }) : _vpnMode = true;

  bool get vpnMode => _vpnMode;
  set parcelFileId(int id) => _parcelFileId = id;

  StartCoreRequest toGrpcModel() {
    if (_vpnMode && (_parcelFileId == null || _parcelFileId == 0)) {
      throw ProxyCoreException(
        'ParcelFileId must be provided and non-zero in VPN mode.',
      );
    }

    final request = StartCoreRequest()
      ..coreName = core.name
      ..dir = dir
      ..config = config
      ..memory = memory
      ..isString = isString
      ..isVpnMode = _vpnMode
      ..proxyPort = proxyPort;

    if (_vpnMode && _parcelFileId != null) {
      request.tunFD = _parcelFileId;
    }

    return request;
  }
}
