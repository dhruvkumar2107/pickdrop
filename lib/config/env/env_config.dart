import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _firebaseApiKey = 'FIREBASE_API_KEY';
  static const String _firebaseAuthDomain = 'FIREBASE_AUTH_DOMAIN';
  static const String _firebaseProjectId = 'FIREBASE_PROJECT_ID';
  static const String _firebaseStorageBucket = 'FIREBASE_STORAGE_BUCKET';
  static const String _firebaseMessagingSenderId = 'FIREBASE_MESSAGING_SENDER_ID';
  static const String _firebaseAppId = 'FIREBASE_APP_ID';
  static const String _googleMapsApiKey = 'GOOGLE_MAPS_API_KEY';
  static const String _razorpayKeyId = 'RAZORPAY_KEY_ID';
  static const String _functionsRegion = 'FUNCTIONS_REGION';

  static String get firebaseApiKey => dotenv.env[_firebaseApiKey] ?? '';
  static String get firebaseAuthDomain => dotenv.env[_firebaseAuthDomain] ?? '';
  static String get firebaseProjectId => dotenv.env[_firebaseProjectId] ?? '';
  static String get firebaseStorageBucket => dotenv.env[_firebaseStorageBucket] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env[_firebaseMessagingSenderId] ?? '';
  static String get firebaseAppId => dotenv.env[_firebaseAppId] ?? '';
  static String get googleMapsApiKey => dotenv.env[_googleMapsApiKey] ?? '';
  static String get razorpayKeyId => dotenv.env[_razorpayKeyId] ?? '';
  static String get functionsRegion => dotenv.env[_functionsRegion] ?? 'us-central1';

  /// Public (unauthenticated) web tracking page base URL, no trailing slash.
  static String get trackingBaseUrl {
    final configured = dotenv.env['TRACKING_BASE_URL'] ?? '';
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/+$'), '');
    final projectId = firebaseProjectId;
    return projectId.isEmpty
        ? 'https://pickdrop.app'
        : 'https://$projectId.web.app';
  }

  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAuthDomain.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get isGoogleMapsConfigured => googleMapsApiKey.isNotEmpty;

  /// `PHONE_AUTH_MODE`: `any` (default) accepts any 10-digit number and any
  /// OTP without an SMS round-trip; `firebase` uses real phone verification.
  static String get phoneAuthMode =>
      (dotenv.env['PHONE_AUTH_MODE'] ?? 'any').trim().toLowerCase();

  static bool get acceptAnyOtp => phoneAuthMode != 'firebase';

  static bool get isRazorpayConfigured => razorpayKeyId.isNotEmpty;
}