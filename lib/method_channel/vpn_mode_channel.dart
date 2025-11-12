import 'package:flutter/services.dart';
import 'package:proxy_core/constants/vpn_mode_methods.dart';
import 'package:proxy_core/models/proxy_core_config.dart';

mixin class VpnModeChannelMixin {
  static const MethodChannel _methCh = MethodChannel('proxy_core/vpn');

  bool _isVpnRunning = false;

  /// To check if the VPN is currently running after the last toggling action
  bool get isVPNRunning => _isVpnRunning;

  /// Prepare the config for VPN mode if needed
  Future<ProxyCoreConfig> prepareConfigForVpnIfNeeded(
      ProxyCoreConfig config) async {
    if (config.vpnMode) {
      await _prepareVpnProfile();
      final fd = await _startVPN();
      config.parcelFileId = fd;
    }
    return config;
  }

  /// Start the VPN and return the file descriptor
  Future<int> _startVPN() async {
    final int fd = await _methCh.invokeMethod(VpnModeMethods.startVPN.name);
    await setVpnStatus();
    return fd;
  }

  /// Stop the VPN
  Future stopVPN() async {
    await _methCh.invokeMethod(VpnModeMethods.stopVPN.name);
    await setVpnStatus();
  }

  /// Check if VPN is currently running
  Future<bool> setVpnStatus() async {
    final result = await _methCh.invokeMethod(VpnModeMethods.isVPNRunning.name);
    // Accept both int and bool from native side
    _isVpnRunning = result == true || result == 1;
    return _isVpnRunning;
  }

  //. Call this before trying to turn on vpn mode
  Future<void> _prepareVpnProfile() async =>
      await _methCh.invokeMethod(VpnModeMethods.prepare.name);

  /// To have a clean state before _simpleStart (test purposes)
  Future<void> stopAnyRunningVPN() async {
    await _prepareVpnProfile();
    await stopVPN();
  }
}
