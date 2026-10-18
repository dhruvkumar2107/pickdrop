import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    // Setup local notifications
    await setupFlutterNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Get FCM token and save to user profile
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }

    _messaging.onTokenRefresh.listen((token) {
      _saveFcmToken(token);
    });

    _isInitialized = true;
  }

  Future<void> setupFlutterNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationAction(details.payload);
      },
    );

    // Create notification channel for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'booking_updates',
      'Booking Updates',
      description: 'Notifications for booking status changes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_updates',
      'Booking Updates',
      channelDescription: 'Notifications for booking status changes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['bookingId'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final bookingId = message.data['bookingId'];
    if (bookingId != null) {
      _navigateToBooking(bookingId);
    }
  }

  void _handleNotificationAction(String? payload) {
    if (payload != null) {
      _navigateToBooking(payload);
    }
  }

  void _navigateToBooking(String bookingId) {
    // Navigation will be handled by the main app via notification tap
    // This is a placeholder for future implementation
  }

  Future<void> _saveFcmToken(String token) async {
    // Save token to user profile in Firestore
    // This will be implemented in the auth repository
  }
}
