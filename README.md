# 🌐 Proxy Core

Proxy Core is a powerful Flutter plugin that brings modern proxy tools to your mobile applications.
With implementations of cutting-edge cores like **XRay, Outline** and SingBox (coming soon), Proxy Core enhances
your app's networking capabilities.

## ✨ Features

- 🔔 Persistent notifications for proxy core connection status (Android only)
- 🛡️ Native VPN/proxy tunnel support
- 🧠 Unified core interface
- 🚀 Tun2Socks-based VPN integration on Android/iOS

## Integrated Cores

- **XRay**: A powerful proxy core with advanced features and high performance.
- **Outline**: A user-friendly proxy core designed for easy setup and use.
- **SingBox**: (Soon)

## 📱 Supported Platforms

- ✅ Android (Proxy and Vpn Mode)
- ✅ iOS (VPN Mode)
- 🛠️ macOS (Proxy Mode)
- 🛠️ Windows (Proxy Mode)

## 🏗️ Platform Architecture

ProxyCore uses different architectures depending on the platform to provide optimal performance and native integration:

### iOS Implementation
- Uses **Method Channels** for communication between Dart and Swift
- VPN status updates via **EventChannel** (event-based, real-time)
- Runs proxy cores inside **Network Extension** sandbox (PacketTunnelProvider)
- No polling required - native OS notifications for status changes
- More battery efficient due to event-driven architecture

### Android/Desktop Implementation  
- Uses **gRPC** for communication with native core
- **FFI bindings** for direct native library calls
- **Timer-based polling** (1-second intervals) for VPN status monitoring in VPN mode
- Persistent notifications for user visibility (Android)
- Direct memory access for better performance

## 📡 State Management

The `onCoreStateChanged` callback behaves differently per platform:

- **iOS**: Triggered by OS-level VPN status events (connecting, connected, disconnected, reasserting, etc.) via EventChannel
- **Other platforms**: Called after start/stop operations and during periodic VPN status checks (every 1 second when in VPN mode)

## 🛠️ API Reference

| Function                         | Description                                                                                                                                                                                                                                                                       |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `initialize(onCoreStateChanged)` | Initialize the proxy core and takes an optional Future callback to receive core state changes.<br/>**iOS:** Sets up method channel communication and event listeners<br/>**Other platforms:** Initializes gRPC server, FFI bindings, and notification service                                                                                                              |
| `start(config)`                  | Start the proxy/VPN service with the given configuration.<br/>**iOS:** Checks if tunnel is connected; if yes, calls `simpleStart`. Otherwise prepares VPN manager and starts Network Extension tunnel<br/>**Other platforms:** Requests permissions, stops existing connections, starts core via gRPC, shows notifications, and begins VPN status polling                                                                                                                                                                                                              |
| `simpleStart(config)`            | Start or restart the core with new configuration without stopping VPN tunnel — useful for quick server switching and testing.<br/>**iOS:** Updates configuration in running tunnel without full VPN reconnection<br/>**Android:** Disconnects any running VPN first, skips notifications and permission checks<br/>**Desktop:** Skips notification handling |
| `stop`                           | Gracefully stop the proxy/VPN service.<br/>**iOS:** Sends stop command to VPN tunnel via method channel<br/>**Other platforms:** Stops VPN, stops core via gRPC, cancels notifications, and stops status polling                                                                                                                                                                                                                                                    |
| `measurePing(List<String> urls)` | Measure delay to the provided URLs.<br/>**iOS:** Sends comma-separated URLs to tunnel, receives comma-separated results, parses into PingResult objects<br/>**Other platforms:** Uses gRPC with structured request/response                                                                                                                                                                                                                               |
| `isRunning`                      | Check if the proxy core is currently active.<br/>**iOS:** Queries tunnel status via method channel<br/>**Other platforms:** Checks via gRPC call                                                                                                                                                                                                                                                       |
| `version`                        | Get the current version of the core.<br/>**iOS:** Queries via method channel<br/>**Other platforms:** Retrieves via gRPC (Xray only for now)                                                                                                                                                                                                                           |
| `setIosTunnelInfo`               | **iOS Only:** Set the app name and PacketTunnelProvider bundle ID for VPN mode. Must be called before `initialize()`.                                                                                                                                                                                                    |
| `fetchLogs`                      | Fetch core logs to receive real-time updates.<br/>**iOS:** Retrieves logs from tunnel provider<br/>**Other platforms:** Fetches via gRPC                                                                                                                                                                                                                  |
| `clearLogs`                      | Clear stored core logs to free up memory.<br/>**iOS:** Sends clear command to tunnel provider<br/>**Other platforms:** Clears via gRPC                                                                                                                                                                                                                   |

### ⚙️ ProxyCoreConfig
The ProxyCoreConfig class is used to configure the core with required parameters. Here's an overview
of its parameters:

| Parameter   | Type            | Default | Description                                                                              |
|-------------|-----------------|---------|------------------------------------------------------------------------------------------|
| `core`      | ProxyCoresTypes | xray    | Which core to start (`ProxyCoresTypes.xray`, `ProxyCoresTypes.outline`)                  |
| `dir`       | String          | -       | The directory where the application temporary files saved                                |
| `config`    | String          | -       | The actual configuration, either a JSON string or a path to a configuration file.        |
| `isString`  | bool            | true    | If `true`, treats `config` as a JSON string; if `false`, treats `config` as a file path. |
| `memory`    | int             | 128     | Amount of memory (in MB) to allocate for the proxy core.                                 |
| `proxyPort` | int             | 2080    | Port on which the proxy core will listen for incoming connections (inProxyMode)          |

## 🚀 Getting Started

To use this plugin, add `proxy_core` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  proxy_core: ^latest
```

### Notification

ProxyCore uses [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
to display persistent notifications for proxy core connection status (on Android only) so you need
to do "Gradle
Setup" section first. You can find it
here: [Flutter Local Notifications Gradle Setup](https://pub.dev/packages/flutter_local_notifications#gradle-setup)

#### Notification Icon

The VPN notification icon:

1. Place your notification icon in the `android/app/src/main/res/drawable/` directory
2. Name the icon file `ic_vpn_notif.png` (or appropriate format)
3. Follow Android's notification icon guidelines:

- Use only white (foreground) and transparent (background) colors
- Design should be simple and recognizable at small sizes (24dp × 24dp)

For more information on creating notification icons that follow Material Design guidelines, see
the [Android developer documentation](https://developer.android.com/develop/ui/views/notifications/custom-notification).

> **Important:** As Android strips and deletes unused resources in release mode, you should create a `keep.xml` file in the `android/app/src/main/res/raw/` directory with the following content to preserve your notification icons:
> ```xml
> <?xml version="1.0" encoding="utf-8"?>
> <resources xmlns:tools="http://schemas.android.com/tools"
>     tools:keep="@drawable/*" />
> ```

### iOS Setup

Due to Apple's limitations for running tunnels in separate sandboxes, we need to start the proxy
cores from within the PacketTunnelProvider. The proxy core can only interact with the tunnel if it's
placed within the PacketTunnelProvider sandbox. Because of this restriction, we need to include
another version of the cores as a Swift kit (called ProxyCoreKit) into the iOS project of the
Flutter app and perform these extra steps for iOS VPN mode:

1. Add an "App Group" for the Runner target in Xcode with the same Bundle Identifier but with
   a "group" prefix. For example, if your app's bundle identifier is "
   com.example.YourApp", create an App Group named "group.com.example.YourApp"
2. Add "Network Extension" capability with the "Packet Tunnel" option selected/enabled for the
   Runner target in Xcode
3. Add "Personal VPN" capability for the Runner target in Xcode
4. Create a new target in Xcode:
   - Select "File" > "New" > "Target..."
   - Choose "Network Extension" and select "Packet Tunnel"
   - Name the target "PacketTunnel"
   - Ensure the target's bundle identifier is set to
     "com.example.YourApp.PacketTunnelProvider" (or similar, matching your app's bundle identifier)
5. Add a package dependency from this URL: https://github.com/EbrahimTahernejad/Tun2SocksKit.git to
   the entire project
6. Add a package dependency from this URL: https://github.com/mahsanet/ProxyCoreKit.git
7. Add both newly added dependencies to the created PacketTunnel target (from step 2) as
   requirements in the "Frameworks and Libraries" section
8. Add "libresolv.9.tbd" also to the "Frameworks and Libraries" section of the PacketTunnel target
9. Create a PacketTunnelProvider.swift file (if it doesn't exist already) in the newly created
   PacketTunnel directory (in the root of the iOS directory) and copy the contents from the
   PacketTunnelProvider.sample.swift file located in the repository root

After completing the Xcode setup, you must set the app name and PacketTunnelProvider bundle
identifier before initializing the core in your Flutter app. This step is mandatory and should be
done once at the start of your app:

```dart
void main() async {
  // For iOS VPN mode, set tunnel info before initializing
  if (Platform.isIOS) {
    ProxyCore.ins.setIosTunnelInfo(
        "YourAppName",
        "com.example.YourApp.PacketTunnelProvider"
    );
  }

  // Then continue with initialization
  ProxyCore.ins.initialize();

  // Rest of your code...
}
```

- Make sure to replace "YourAppName" with your actual application name and "
  com.example.YourApp.PacketTunnelProvider" with your actual PacketTunnelProvider bundle identifier.
- The App Group ID must be the same for both the main Runner target and the PacketTunnel target in
  xcode
- The PacketTunnel bundle identifier in xcode must match exactly what you pass to the
  `setIosTunnelInfo()` method

### 📝 Usage

```dart
import 'dart:io';
import 'package:proxy_core/proxy_core.dart';
import 'package:proxy_core/models/proxy_core_config.dart';

void main() async {
  // For iOS VPN mode, set tunnel info before initializing
  if (Platform.isIOS) {
    ProxyCore.ins.setIosTunnelInfo(
        "YourAppName",
        "com.example.YourApp.PacketTunnelProvider"
    );
  }

  // Initialize the gRPC server before using other methods
  ProxyCore.ins.initialize();

  // Define your core configuration
  final config = ProxyCoreConfig.inVpnMode(
    core: ProxyCoresTypes.xray // or ProxyCoresTypes.outline
    dir: "/path/to/application_temp_dir",
    config: "config string or file path",
  );

  // Start the proxy core with the configuration
  await ProxyCore.ins.start(config);

  // Other logics

  // Stop the proxy core
  await ProxyCore.ins.stop();
}
```

> **Note:** Calling `start()` with a new configuration or mode will act as a restart. Even if the
> core is already running, invoking `start()` will automatically call `stop()` to gracefully
> terminate the existing instance before applying the new configuration. This ensures a clean start
> with the updated settings.

## 🔍 Troubleshooting

### iOS Issues

**VPN Not Starting:**
- Ensure `setIosTunnelInfo()` is called **before** `initialize()`
- Verify App Group ID matches exactly between Runner and PacketTunnel targets in Xcode
- Check that the PacketTunnelProvider bundle identifier matches exactly what you pass to `setIosTunnelInfo()`
- Make sure all required capabilities are enabled (Network Extension, Personal VPN)

**Configuration Not Updating:**
- Use `simpleStart()` to update configuration without reconnecting the VPN tunnel
- Check that the tunnel is in "connected" state before calling `simpleStart()`

### Android Issues

**Notification Not Showing:**
- Ensure notification permissions are granted (required for Android 13+)
- Check that `ic_vpn_notif.png` exists in `android/app/src/main/res/drawable/`
- Verify `keep.xml` is present in `android/app/src/main/res/raw/` to prevent icon removal in release builds

**VPN Permission Denied:**
- The app will request VPN permission on first start
- If denied, user must grant permission manually in system settings

### General Issues

**Core Not Stopping:**
- Check logs using `fetchLogs()` to identify any errors
- On Android/Desktop: VPN status polling will auto-stop the core if VPN disconnects
- On iOS: EventChannel will notify of disconnection immediately

**Memory Issues:**
- Adjust the `memory` parameter in `ProxyCoreConfig` (default is 128 MB)
- Use `clearLogs()` periodically to free up log storage

## ⚡ Performance Considerations

### Battery Impact
- **iOS**: Uses event-driven architecture with native OS notifications - minimal battery impact
- **Android/Desktop (VPN mode)**: Polls VPN status every 1 second - slight battery impact during VPN session
- **Android/Desktop (Proxy mode)**: No polling - minimal battery impact

### Server Switching
- **iOS**: Use `simpleStart()` for fast server switching without VPN reconnection overhead
- **Android/Desktop**: `simpleStart()` and `start()` have similar performance as they both restart the core

### Notification Overhead
- Persistent notifications (Android/Linux/macOS) have negligible performance impact
- Can be avoided in testing scenarios by using `simpleStart()`

## 🔧 Pre-Run Clean Script

Use the `pre_run_clean.sh` script to prepare your environment before running the app, helps to make
sure that new builds are replaced. The script
removes `.lock` files, clears `build` directories, and uninstalls the app on connected devices (
optional). To customize:

- `-v`, `--verbose`: Enable verbose mode
- `--skip-adb`: Skip ADB uninstall
- `-p`, `--package`: Specify package name for ADB uninstall

```bash
./pre_run_clean.sh -v
```

Or add it as a launch configuration in your IDE/Editor to run it automatically before starting the
app.

## 🎯 Example

Check out our [example project](/example) to see Proxy Core in action!

## 🔨 Building the Plugin

Add your desired changes to Go files in `src/` directory and then update the flutter-related functions in `lib/` (if
necessary) then build the plugin for your target platforms like this:

### Android

1. Install Android Studio and the Android NDK through the SDK Manager
2. Set the NDK_HOME environment variable to point to your latest NDK installation:
   ```bash
   # For macOS/Linux
   export NDK_HOME=$HOME/Library/Android/sdk/ndk/[latest_version]
   
   # For Windows
   set NDK_HOME=C:\Users\YourUsername\AppData\Local\Android\Sdk\ndk\[latest_version]
   ```
   Replace `[latest_version]` with your installed NDK version (e.g., `25.2.9519653`)

The plugin will handle the building process automatically when you run your Flutter application. No
manual build steps are required.

### iOS Kit

To build the plugin for ios:

1. Run the provided `build_ios_kit.sh` script.
2. Make a fork from current `ProxyCoreKit` swift
   plugin [repo](https://github.com/mahsanet/ProxyCoreKit) into your github account.
3. The script will generate `ProxyCoreKit.xcframework` in the `scripts/build` folder.
4. Make a zip archive from the `ProxyCoreKit.xcframework` & make a release github of it (on your
   personal repo).
5. Replace the `checksum` variable in `Package.swift` with your own created
   `ProxyCoreKit.xcframework.zip` file, using: `sha256 /path/to/file.zip`.
6. Now you can add the forked repo as a swift package dependency, in your Xcode project (
   see [iOS setup instructions](#ios-setup) step 5).
7. Done!

### macOS

To build the plugin for macOS:

1. Run the provided `build_mac.sh` script.
2. The script will generate `libproxy_core.xcframework.zip` and in the `scripts` folder.
3. Copy the `libproxy_core.xcframework.zip` into the `macos/frameworks/` directory.
4. Done!

### Windows

To build the plugin for Windows, you'll need to meet the following requirements on a Windows
machine:

- Visual Studio: Required for Flutter.
- LLVM: Install via `winget install -e --id LLVM.LLVM`
- MinGW/MSYS: [Download and install from the official site](https://www.msys2.org/)
- Toolchain: Install the required toolchain by running
  `pacman -Sy mingw-w64-cross-toolchain mingw-w64-cross` in the MSYS terminal
- System Path Variables: Add `C:\msys64\opt\bin` and `C:\msys64\usr\bin` to your system's Path under
  Environment Variables.

Steps:

1. Run the provided `build_windows.bat` script.
2. The script will generate `libproxy_core.zip` and `libproxy_core.h` in the `scripts` folder.
3. Copy the `libproxy_core.zip` into the `windows/` directory.
4. Done!

## 🔄 Generating FFI Bindings

After building the native libraries, you need to generate the Dart FFI bindings:

1. Make sure the header file `libproxy_core.h` is in the `scripts` folder.
2. Run `dart run ffigen --config ffigen.yaml` to generate the bindings.
3. The bindings will be generated in `lib/gen/proxy_core_bindings_generated.dart`.

## License

[MIT License](https://github.com/mahsanet/proxy_core_private/blob/main/LICENSE)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
