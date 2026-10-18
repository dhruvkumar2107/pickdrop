import 'package:flutter/animation.dart';

// App-wide constants
class AppConstants {
  static const String appName = 'PickDrop';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String driversCollection = 'drivers';
  static const String vehicleTypesCollection = 'vehicleTypes';
  static const String bookingsCollection = 'bookings';
  static const String paymentsCollection = 'payments';
  static const String ratingsCollection = 'ratings';
  static const String couponsCollection = 'coupons';
  static const String savedAddressesCollection = 'savedAddresses';
  static const String configCollection = 'config';

  // Booking Statuses
  static const String statusSearching = 'SEARCHING';
  static const String statusDriverAssigned = 'DRIVER_ASSIGNED';
  static const String statusArrived = 'ARRIVED';
  static const String statusPickedUp = 'PICKED_UP';
  static const String statusInTransit = 'IN_TRANSIT';
  static const String statusDelivered = 'DELIVERED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusNoDriverFound = 'NO_DRIVER_FOUND';

  // Payment Methods
  static const String paymentRazorpay = 'razorpay';
  static const String paymentCod = 'cod';
  static const String paymentWallet = 'wallet';

  // Payment Statuses
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleDriver = 'driver';
  static const String roleBoth = 'both';

  // Driver Verification Status
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';

  // OTP
  static const int otpLength = 4;
  static const int otpTimeoutSeconds = 60;

  // Matching Config (defaults, overridden by Firestore config)
  static const double defaultMatchingRadiusKm = 5.0;
  static const int defaultOfferTimeoutSeconds = 30;
  static const int defaultMaxMatchingDurationMinutes = 3;
  static const int defaultCancellationFreeWindowMinutes = 2;
  static const double defaultCancellationFeeAfterAssignment = 50.0;
  static const double defaultCommissionPercent = 15.0;
  static const double defaultGstPercent = 5.0;
  static const double defaultSurgeMultiplier = 1.0;

  // Location Updates
  static const int locationUpdateIntervalSeconds = 5;
  static const double locationAccuracyMeters = 10.0;

  // Map
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 10.0;
  static const double maxMapZoom = 19.0;

  // Animation Durations
  static const Duration instantAnimation = Duration(milliseconds: 100);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration dramaticAnimation = Duration(milliseconds: 800);
  static const Duration springAnimation = Duration(milliseconds: 600);

  // Animation Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutExpo;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);

  // Keys for SharedPreferences
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keyLastKnownLocation = 'last_known_location';
}