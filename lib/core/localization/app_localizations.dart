import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // App
  String get appName => 'PickDrop';
  String get appTagline => 'Move anything, anywhere';

  // Onboarding
  String get onboardingSlide1Title => 'Quick Bookings';
  String get onboardingSlide1Desc => 'Book a vehicle in seconds. Choose from bikes, 3-wheelers, mini trucks, and pickups.';
  String get onboardingSlide2Title => 'Live Tracking';
  String get onboardingSlide2Desc => 'Track your driver in real-time. Get OTP for secure pickup and delivery.';
  String get onboardingSlide3Title => 'Fair Pricing';
  String get onboardingSlide3Desc => 'Transparent fares with no hidden charges. Pay via UPI, Card, or Cash.';

  // Auth
  String get welcomeBack => 'Welcome back';
  String get enterPhoneNumber => 'Enter your phone number';
  String get phoneNumberHint => 'Phone number';
  String get continueButton => 'Continue';
  String get sendingOtp => 'Sending OTP...';
  String get otpSent => 'OTP sent to';
  String get enterOtp => 'Enter OTP';
  String get otpHint => 'Enter the 4-digit code';
  String get verifyOtp => 'Verify OTP';
  String get resendOtp => 'Resend OTP';
  String get resendIn => 'Resend in';
  String get seconds => 'seconds';
  String get didntReceiveOtp => "Didn't receive OTP?";
  String get verifyAndContinue => 'Verify & Continue';
  String get verifyingOtp => 'Verifying OTP...';

  // Role Selection
  String get selectRole => 'How would you like to use PickDrop?';
  String get roleCustomer => 'Customer';
  String get roleCustomerDesc => 'I want to send goods';
  String get roleDriver => 'Driver';
  String get roleDriverDesc => 'I want to deliver goods';
  String get continueAs => 'Continue as';

  // Profile
  String get completeProfile => 'Complete your profile';
  String get fullName => 'Full Name';
  String get fullNameHint => 'Enter your full name';
  String get emailOptional => 'Email (Optional)';
  String get emailHint => 'Enter your email';
  String get saveProfile => 'Save Profile';
  String get profileSaved => 'Profile saved successfully';

  // Common
  String get ok => 'OK';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get edit => 'Edit';
  String get delete => 'Delete';
  String get retry => 'Retry';
  String get close => 'Close';
  String get next => 'Next';
  String get back => 'Back';
  String get skip => 'Skip';
  String get done => 'Done';
  String get yes => 'Yes';
  String get no => 'No';
  String get loading => 'Loading...';
  String get pleaseWait => 'Please wait...';
  String get somethingWentWrong => 'Something went wrong';
  String get tryAgainLater => 'Please try again later';
  String get noInternet => 'No internet connection';
  String get checkConnection => 'Check your connection and try again';
  String get permissionRequired => 'Permission Required';
  String get enableLocation => 'Please enable location access';
  String get enableNotifications => 'Please enable notifications';

  // Validation
  String get requiredField => 'This field is required';
  String get invalidPhone => 'Enter a valid 10-digit phone number';
  String get invalidEmail => 'Enter a valid email address';
  String get invalidOtp => 'Enter a valid 4-digit OTP';
  String get invalidVehicleNumber => 'Enter a valid vehicle number';
  String get nameTooShort => 'Name must be at least 2 characters';
  String get nameTooLong => 'Name must be less than 50 characters';

  // Wallet
  String get wallet => 'Wallet';
  String get walletBalance => 'Wallet Balance';
  String get addMoney => 'Add Money';
  String get transactionHistory => 'Transaction History';
  String get recharge => 'Recharge';

  // Coupons
  String get coupons => 'Coupons';
  String get myCoupons => 'My Coupons';
  String get applyCouponCode => 'Apply Coupon Code';
  String get couponApplied => 'Coupon applied successfully';
  String get invalidCoupon => 'Invalid or expired coupon';
  String get couponExpired => 'This coupon has expired';
  String get couponUsed => 'This coupon has been used';

  // Ratings
  String get rateExperience => 'Rate your experience';
  String get excellent => 'Excellent';
  String get good => 'Good';
  String get average => 'Average';
  String get poor => 'Poor';
  String get terrible => 'Terrible';

  // Help & Support
  String get helpSupport => 'Help & Support';
  String get contactUs => 'Contact Us';
  String get faqs => 'FAQs';
  String get termsConditions => 'Terms & Conditions';
  String get privacyPolicy => 'Privacy Policy';
  String get logout => 'Logout';
  String get confirmLogout => 'Are you sure you want to logout?';

  // SOS
  String get sos => 'SOS';
  String get emergencyContact => 'Emergency Contact';
  String get shareLocation => 'Share Live Location';
  String get sosActivated => 'SOS Activated';
  String get sosMessage => 'Your live location has been shared with your emergency contact';

  // Notifications
  String get newBooking => 'New Booking';
  String get driverAssigned => 'Driver Assigned';
  String get driverArrivedNotification => 'Driver Arrived';
  String get tripCompletedNotification => 'Trip Completed';
  String get paymentReceived => 'Payment Received';

  // Home (Customer)
  String get whereToDeliver => 'Where to deliver?';
  String get pickupLocation => 'Pickup location';
  String get dropLocation => 'Drop location';
  String get searchLocation => 'Search location';
  String get currentLocation => 'Current location';
  String get savedAddresses => 'Saved Addresses';
  String get recentTrips => 'Recent Trips';
  String get noSavedAddresses => 'No saved addresses yet';
  String get noRecentTrips => 'No recent trips';
  String get myTrips => 'My Trips';
  String get addAddress => 'Add Address';
  String get bookNow => 'Book Now';

  // Vehicle Selection
  String get selectVehicle => 'Select Vehicle';
  String get vehicleCapacity => 'Capacity';
  String get estimatedFare => 'Estimated Fare';
  String get eta => 'ETA';
  String get perKm => '/km';
  String get perMin => '/min';
  String get baseFare => 'Base Fare';
  String get minimumFare => 'Minimum Fare';

  // Booking Details
  String get bookingDetails => 'Booking Details';
  String get goodsType => 'Type of Goods';
  String get goodsTypeHint => 'e.g., Furniture, Boxes, Appliances';
  String get notesOptional => 'Notes (Optional)';
  String get notesHint => 'Any special instructions for the driver';
  String get loadingHelper => 'Loading Helper';
  String get loadingHelperDesc => 'Driver will help load/unload goods';
  String get applyCoupon => 'Apply Coupon';
  String get couponCodeHint => 'Enter coupon code';
  String get paymentMethod => 'Payment Method';
  String get payOnline => 'Pay Online (UPI/Card/Netbanking)';
  String get payCash => 'Cash on Delivery';
  String get confirmBooking => 'Confirm Booking';
  String get fareBreakdown => 'Fare Breakdown';
  String get distanceFare => 'Distance Fare';
  String get timeFare => 'Time Fare';
  String get surgeCharges => 'Surge Charges';
  String get gst => 'GST (5%)';
  String get discount => 'Discount';
  String get totalPayable => 'Total Payable';

  // Finding Driver
  String get findingDriver => 'Finding a driver...';
  String get searchingNearby => 'Searching nearby drivers';
  String get cancelSearch => 'Cancel Search';
  String get noDriversFound => 'No drivers found';
  String get tryAgain => 'Try Again';

  // Live Tracking
  String get driverArriving => 'Driver is arriving';
  String get driverArrived => 'Driver has arrived';
  String get tripStarted => 'Trip started';
  String get inTransit => 'In transit';
  String get reachedDestination => 'Reached destination';
  String get shareTrip => 'Share Trip';
  String get callDriver => 'Call Driver';
  String get pickupOtp => 'Pickup OTP';
  String get dropOtp => 'Drop OTP';
  String get shareWith => 'Share with';
  String get tripStatus => 'Trip Status';

  // Trip Complete
  String get tripCompleted => 'Trip Completed';
  String get rateYourDriver => 'Rate your driver';
  String get writeReview => 'Write a review (Optional)';
  String get submitRating => 'Submit Rating';
  String get payNow => 'Pay Now';
  String get paymentSuccessful => 'Payment successful';
  String get receipt => 'Receipt';

  // Driver
  String get goOnline => 'Go Online';
  String get goOffline => 'Go Offline';
  String get youAreOnline => 'You are online';
  String get youAreOffline => 'You are offline';
  String get todaysEarnings => "Today's Earnings";
  String get totalTrips => 'Total Trips';
  String get accept => 'Accept';
  String get reject => 'Reject';
  String get incomingRequest => 'Incoming Request';
  String get navigateToPickup => 'Navigate to Pickup';
  String get arrivedAtPickup => 'Arrived at Pickup';
  String get enterPickupOtp => 'Enter Pickup OTP';
  String get startTrip => 'Start Trip';
  String get navigateToDrop => 'Navigate to Drop';
  String get enterDropOtp => 'Enter Drop OTP';
  String get completeTrip => 'Complete Trip';
  String get collectCash => 'Collect Cash';
  String get earnings => 'Earnings';
  String get daily => 'Daily';
  String get weekly => 'Weekly';
  String get monthly => 'Monthly';
  String get tripHistory => 'Trip History';
  String get commission => 'Commission (15%)';
  String get netEarnings => 'Net Earnings';

  // Driver Onboarding
  String get driverOnboarding => 'Driver Onboarding';
  String get vehicleType => 'Vehicle Type';
  String get vehicleNumber => 'Vehicle Number';
  String get vehicleNumberHint => 'e.g., MH12AB1234';
  String get licenseNumber => 'License Number';
  String get licenseExpiry => 'License Expiry';
  String get rcNumber => 'RC Number';
  String get rcExpiry => 'RC Expiry';
  String get aadhaarNumber => 'Aadhaar Number';
  String get uploadLicense => 'Upload License';
  String get uploadRc => 'Upload RC';
  String get uploadAadhaarFront => 'Upload Aadhaar Front';
  String get uploadAadhaarBack => 'Upload Aadhaar Back';
  String get uploadPhoto => 'Upload Your Photo';
  String get submitForVerification => 'Submit for Verification';
  String get verificationPending => 'Verification Pending';
  String get verificationApproved => 'Verified & Approved';
  String get verificationRejected => 'Verification Rejected';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}