class RouteNames {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String phoneLogin = '/phone-login';
  static const String otpVerify = '/otp-verify';
  static const String roleSelection = '/role-selection';
  static const String profileCreation = '/profile-creation';

  // Customer routes
  static const String customerHome = '/customer/home';
  static const String pickupSelection = '/customer/pickup-selection';
  static const String dropSelection = '/customer/drop-selection';
  static const String vehicleSelection = '/customer/vehicle-selection';
  static const String bookingDetails = '/customer/booking-details';
  static const String findingDriver = '/customer/finding-driver';
  static const String liveTracking = '/customer/live-tracking';
  static const String tripComplete = '/customer/trip-complete';
  static const String myTrips = '/customer/my-trips';
  static const String tripDetail = '/customer/trip-detail';
  static const String wallet = '/customer/wallet';
  static const String addMoney = '/customer/add-money';
  static const String coupons = '/customer/coupons';
  static const String savedAddresses = '/customer/saved-addresses';
  static const String addAddress = '/customer/add-address';
  static const String customerProfile = '/customer/profile';
  static const String helpSupport = '/customer/help-support';
  static const String scheduledBookings = '/customer/scheduled-bookings';
  static const String businessAccount = '/customer/business';
  static const String safetyMode = '/customer/safety';

  // Public tracking (web, no auth required)
  static const String webTracking = '/track/:bookingId';

  // Driver routes
  static const String driverOnboarding = '/driver/onboarding';
  static const String driverHome = '/driver/home';
  static const String incomingRequest = '/driver/incoming-request';
  static const String activeTrip = '/driver/active-trip';
  static const String driverEarnings = '/driver/earnings';
  static const String driverTripHistory = '/driver/trip-history';
  static const String driverPayouts = '/driver/payouts';
  static const String driverProfile = '/driver/profile';
  static const String driverVerification = '/driver/verification';

  // Common routes
  static const String chat = '/common/chat';
  static const String mapPicker = '/common/map-picker';
  static const String placesSearch = '/common/places-search';
  static const String payment = '/common/payment';
  static const String ratings = '/common/ratings';

  // Settings
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String language = '/language';
}