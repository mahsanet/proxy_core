import 'dart:async';

import 'package:proxy_core/models/proxy_core_config.dart';
import 'package:proxy_core/gen/bindings/ProxyCoreService.pbgrpc.dart';

/// Abstract base class for ProxyCore implementations
///
/// Defines the interface for proxy core services that manage GRPC server connections
/// and core proxy operations.
abstract interface class ProxyCoreInterface {
  /// Initializes required services for the proxy core
  ///
  /// [onCoreStateChanged] Optional callback that will be invoked when core state changes
  Future<void> initialize(
      {Future<void> Function(bool isRunning)? onCoreStateChanged});

  /// Checks if the core is currently running
  Future<bool> get isRunning;

  /// Retrieves the current core version
  Future<String> get version;

  /// Starts the core with the provided configuration
  ///
  /// Throws [ProxyCoreException] if operation fails
  Future<void> start(ProxyCoreConfig config);

  /// Android Only - Does nothing special on iOS
  /// Starts the core with the provided configuration without handling the notification
  /// Good for quick starts/connection for testing purposes
  ///
  /// Throws [ProxyCoreException] if operation fails
  Future<void> simpleStart(ProxyCoreConfig config);

  /// Stops the core and cleans up resources
  ///
  /// Throws [ProxyCoreException] if operation fails
  Future<void> stop();

  /// Measures ping times for the provided URLs
  ///
  /// Returns a list of [PingResult] objects
  /// Throws [ProxyCoreException] if operation fails
  Future<List<PingResult>> measurePing(List<String> urls);

  /// Fetches new logs since last call
  /// Returns a Future with the latest logs
  /// Throws [ProxyCoreException] if operation fails
  Future<LogResponse> fetchLogs();

  /// Clears the logs on the server
  /// Returns a Future indicating the success or failure of the operation
  /// Throws [ProxyCoreException] if operation fails
  Future<Empty> clearLogs();

  /// Ensures a valid initialization state before operations
  void ensureInitialized();
}
