import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proxy_core/models/proxy_core_exception.dart';
import 'package:proxy_core/proxy_core.dart';

// @pragma('vm:entry-point')

/// Service to handle all notification-related functionality for ProxyCore
class PersistentNotificationService {
  static final PersistentNotificationService _instance =
      PersistentNotificationService._();

  static PersistentNotificationService get instance => _instance;

  PersistentNotificationService._();

  static const int _notifId = 888;
  static const String _notifDisconnectActionId = "disconnect";
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _areNotificationsInitialized = false;

  /// Initialize the notification plugin with platform-specific settings
  Future<void> initialize() async {
    if (_areNotificationsInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_vpn_notif');

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationAction,
      // onDidReceiveBackgroundNotificationResponse: _handleNotificationAction,
    );

    _areNotificationsInitialized = true;
  }

  void _handleNotificationAction(NotificationResponse response) {
    if (response.actionId == _notifDisconnectActionId) {
      ProxyCore.ins.stop();
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Show a persistent notification for active proxy connection
  Future<void> showActiveNotification(String mode) async {
    if (Platform.isWindows) return;

    if (!_areNotificationsInitialized) {
      throw ProxyCoreException.message(
          'Notifications not initialized. Call initialize() first.');
    }

    final androidDetails = AndroidNotificationDetails(
      'proxy_core_channel',
      'Proxy Status',
      channelDescription: 'Shows proxy connection status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: [
        const AndroidNotificationAction(_notifDisconnectActionId, 'Disconnect',
            titleColor: Colors.red,
            cancelNotification: false,
            showsUserInterface: true),
      ],
    );

    await _notificationsPlugin.show(
      _notifId,
      'Proxy is Active',
      'Connected in $mode mode',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Cancel the persistent notification
  Future<void> cancelProxyNotification() async {
    if (Platform.isWindows) return;
    await _notificationsPlugin.cancel(_notifId);
  }
}
