import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  Future<void> initialize() async {
    await _setupNotifications();
    await _configureBackgroundService();
  }

  Future<void> _setupNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_updates',
      'Location Updates',
      description: 'Background location tracking for driver',
      importance: Importance.low,
    );
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> _configureBackgroundService() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_updates',
        initialNotificationTitle: 'PickDrop Driver',
        initialNotificationContent: 'Tracking location for trip matching',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_updates',
      'Location Updates',
      description: 'Background location tracking for driver',
      importance: Importance.low,
    );
    await notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!(await _hasLocationPermission())) {
        timer.cancel();
        service.stopSelf();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _updateDriverLocation(position);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'PickDrop Driver',
          content: 'Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        );
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<bool> _hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<void> _updateDriverLocation(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final geohash = _encodeGeohash(position.latitude, position.longitude);
      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'geohash': geohash,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Failed to update driver location: $e');
    }
  }

  static String _encodeGeohash(double lat, double lng) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    double latMin = -90, latMax = 90;
    double lngMin = -180, lngMax = 180;
    String geohash = '';
    int bit = 0;
    int ch = 0;
    bool evenBit = true;

    while (geohash.length < 8) {
      if (evenBit) {
        double mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          ch = (ch << 1) | 1;
          lngMin = mid;
        } else {
          ch = (ch << 1) | 0;
          lngMax = mid;
        }
      } else {
        double mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch = (ch << 1) | 1;
          latMin = mid;
        } else {
          ch = (ch << 1) | 0;
          latMax = mid;
        }
      }
      evenBit = !evenBit;
      if (bit < 4) {
        bit++;
      } else {
        geohash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return geohash;
  }

  Future<void> startLocationUpdates() async {
    if (!await _hasLocationPermission()) {
      throw Exception('Location permission not granted');
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      await _updateDriverLocation(position);
    });

    if (await _backgroundService.isRunning()) return;
    await _backgroundService.startService();
  }

  Future<void> stopLocationUpdates() async {
    _positionStream?.cancel();
    _positionStream = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    _backgroundService.invoke('stopService');
  }

  Future<bool> isRunning() async {
    return await _backgroundService.isRunning();
  }
}