import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LiveActivityNotification {
  LiveActivityNotification._();

  static final LiveActivityNotification instance = LiveActivityNotification._();

  static const int notificationId = 7301;
  static const String channelId = 'pickdrop_live_trip';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _ensureInitialized() async {
    if (_initialized || !_supported) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Live trip updates',
          description: 'Ongoing driver ETA and trip status',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
        ),
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> show({
    required int etaMin,
    required String driverName,
    required String status,
  }) async {
    if (!_supported) return;
    try {
      await _ensureInitialized();
      if (!_initialized) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Live trip updates',
          channelDescription: 'Ongoing driver ETA and trip status',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          showWhen: false,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _plugin.show(
        notificationId,
        '$driverName is $etaMin min away',
        'Sit tight! $status',
        details,
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    if (!_supported) return;
    try {
      await _plugin.cancel(notificationId);
    } catch (_) {}
  }
}
