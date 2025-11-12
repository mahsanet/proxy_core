import 'dart:ffi';
import 'dart:io';
import 'package:proxy_core/gen/proxy_core_bindings_generated.dart';

final _nativeGoLibrary = _initFFI();

ProxyCoreBindings _initFFI() {
  const libBaseName = 'proxy_core';

  if (Platform.isAndroid) {
    return ProxyCoreBindings(DynamicLibrary.open("lib$libBaseName.so"));
  } else if (Platform.isMacOS) {
    return ProxyCoreBindings(DynamicLibrary.process());
  } else if (Platform.isWindows) {
    return ProxyCoreBindings(DynamicLibrary.open("lib$libBaseName.dll"));
  } else {
    // If the platform is not Android (supported till now), throw an error
    throw UnsupportedError("${Platform.operatingSystem} not supported");
  }
}

mixin ProxyCoreBindingsMixin {
  ProxyCoreBindings get nativeLib => _nativeGoLibrary;
}
