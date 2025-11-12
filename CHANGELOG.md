## 6.9.6
- Remove: `getIosTunnelStatus()` expose.
- Improvement[iOS]: `start()` now checks if the tunnel is already running and acts as
`simpleStart()` if it is.
- Improvement: Documented comments.

## 6.9.4
- Fix: Ping result failure as ProxyCoreException 
- Improvment: Remove ios tunnel delay.
- Feat: `getIosTunnelStatus()` added for determine if the ios tunnel is already running (for example after testing flow etc.).

## 6.9.1
- Fix: ios tunnel stop delay

## 6.9.0 
- Fix: android app crash during disconnecting.
- Enhance: android tunnel fd managment.

## 6.8.0
- Bump: xray-core to v25.8.3
- Feat: now using GFW-knocker's xray-core

## 6.7.0
- Fix: disconnect any existing VPN tunnels on Android before starting to test with `simpleStart`
- Chore: Add doc comments for vpn methods
- Chore: Update dependencies

## 6.6.5
- Feat: Add `simpleStart` method for ios to prevent ios from continuously starting the tunnel.

## 6.6.4
- Fix: Ios Tunnel crash because of the logger changes. 

## 6.6.3
- Fix: GRPC server not started on Android physical devices due to using ipv6 address. Change to use ipv4 address instead.

## 6.6.2
- Fix: await on `_start` then show notification 

## 6.6.1
- Fix: Broken notif logic 

## 6.6.0
- Feat: Add `simpleStart` method for testing purposes (configs and ...)

## 6.5.0
- Fix: Change grpc listener port to fix issue on OnePlus devices
- Improve: Move xray logger to libxray
- Improve: Add slogger package and improve logging
- Improve: liboutline, refactor and improve logging architecture

## 6.1.0

- Fix: Negative FD error on Android
- Fix: Proper VPN Cleanup on Android If the Startup Fails
- Improve: More Consistent Order of Core Initialization and Shutdown

## 6.0.0

- **Feat: Integrated new core: Outline**
- Refactor: New `core` parameter added to `ProxyCoreConfig` class to which accepts `ProxyCoresTypes` enum values

## 5.0.1

- IOS Swift kit new release

## 3.0.0

- Breaking: Removed iOS proxy mode, now only VPN mode is supported on iOS
- Major: Complete platform-specific implementation architecture
- Major: Added comprehensive README with setup instructions for all platforms
- Feature: Improved iOS VPN implementation with better lifecycle management


## 2.7.1

- Fix: Some minor bugs.

## 2.7.0

- Feat: Add functionality to receive core logs
- Fix: Disconnect other VPN tunnels
- Fix: Improve measurePing flow on iOS

## 2.6.1

- Fix: Notification Icon Initialization Crash


## 2.6.0

- Fix: Native (Go) now prevents multiple startGRPC (Hot Restart Fixed)
- Fix: Notification service initialization on iOS exception

## 2.5.0

- Feat: Use onGoing notification to Show connection status on Android
- Feat: initialize now takes onCoreStateChanged callback
  *Breaking Changes:*
- `initializeGrpcServer` renamed to `initialize`

## 2.0.3

*Breaking Changes:*

- Improved Error/Exception, Now has more details and referenced as `ProxyCoreException`
- `getVersion` renamed to `version`
- `isCoreRunning` renamed to `isRunning`
- `startGrpcServer` renamed to `initializeGrpcServer`

## 2.0.2

- Error/Exception now thrown and can be caught

## 2.0.1

- `measurePing` now takes list of url and returns list of results

## 2.0.0

*Breaking Changes:*

- VPN Mode added (Just Android for now)
- Methods name and Config parameters refactored

## 1.3

- Add macOS Support
- Removed iOS initiation exception (Got normal like other platforms)

## 1.2.1

- Add Windows Support

## 1.1.1

- Add `getPing()` method to measure delay of connected config
- Improve performance
- Improve documentation

## 1.1.0

- Add support for iOS

- ## 1.0.0
- Initial release