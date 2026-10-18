import 'package:flutter/material.dart';

import 'strings_kn.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isKannada => locale.languageCode == 'kn';

  // App
  String get appName => 'PickDrop';
  String get appTagline => isKannada ? AppStringsKn.appTagline : 'Move anything, anywhere';

  // Onboarding
  String get onboardingSlide1Title => isKannada ? AppStringsKn.onboardingSlide1Title : 'Quick Bookings';
  String get onboardingSlide1Desc => isKannada ? AppStringsKn.onboardingSlide1Desc : 'Book a vehicle in seconds. Choose from bikes, 3-wheelers, mini trucks, and pickups.';
  String get onboardingSlide2Title => isKannada ? AppStringsKn.onboardingSlide2Title : 'Live Tracking';
  String get onboardingSlide2Desc => isKannada ? AppStringsKn.onboardingSlide2Desc : 'Track your driver in real-time. Get OTP for secure pickup and delivery.';
  String get onboardingSlide3Title => isKannada ? AppStringsKn.onboardingSlide3Title : 'Fair Pricing';
  String get onboardingSlide3Desc => isKannada ? AppStringsKn.onboardingSlide3Desc : 'Transparent fares with no hidden charges. Pay via UPI, Card, or Cash.';

  // Auth
  String get welcomeBack => isKannada ? AppStringsKn.welcomeBack : 'Welcome back';
  String get enterPhoneNumber => isKannada ? AppStringsKn.enterPhoneNumber : 'Enter your phone number';
  String get phoneNumberHint => isKannada ? AppStringsKn.phoneNumberHint : 'Phone number';
  String get continueButton => isKannada ? AppStringsKn.continueButton : 'Continue';
  String get sendingOtp => isKannada ? AppStringsKn.sendingOtp : 'Sending OTP...';
  String get otpSent => isKannada ? AppStringsKn.otpSent : 'OTP sent to';
  String get enterOtp => isKannada ? AppStringsKn.enterOtp : 'Enter OTP';
  String get otpHint => isKannada ? AppStringsKn.otpHint : 'Enter the 4-digit code';
  String get verifyOtp => isKannada ? AppStringsKn.verifyOtp : 'Verify OTP';
  String get resendOtp => isKannada ? AppStringsKn.resendOtp : 'Resend OTP';
  String get resendIn => isKannada ? AppStringsKn.resendIn : 'Resend in';
  String get seconds => isKannada ? AppStringsKn.seconds : 'seconds';
  String get didntReceiveOtp => isKannada ? AppStringsKn.didntReceiveOtp : "Didn't receive OTP?";
  String get verifyAndContinue => isKannada ? AppStringsKn.verifyAndContinue : 'Verify & Continue';
  String get verifyingOtp => isKannada ? AppStringsKn.verifyingOtp : 'Verifying OTP...';

  // Role Selection
  String get selectRole => isKannada ? AppStringsKn.selectRole : 'How would you like to use PickDrop?';
  String get roleCustomer => isKannada ? AppStringsKn.roleCustomer : 'Customer';
  String get roleCustomerDesc => isKannada ? AppStringsKn.roleCustomerDesc : 'I want to send goods';
  String get roleDriver => isKannada ? AppStringsKn.roleDriver : 'Driver';
  String get roleDriverDesc => isKannada ? AppStringsKn.roleDriverDesc : 'I want to deliver goods';
  String get continueAs => isKannada ? AppStringsKn.continueAs : 'Continue as';

  // Profile
  String get completeProfile => isKannada ? AppStringsKn.completeProfile : 'Complete your profile';
  String get fullName => isKannada ? AppStringsKn.fullName : 'Full Name';
  String get fullNameHint => isKannada ? AppStringsKn.fullNameHint : 'Enter your full name';
  String get emailOptional => isKannada ? AppStringsKn.emailOptional : 'Email (Optional)';
  String get emailHint => isKannada ? AppStringsKn.emailHint : 'Enter your email';
  String get saveProfile => isKannada ? AppStringsKn.saveProfile : 'Save Profile';
  String get profileSaved => isKannada ? AppStringsKn.profileSaved : 'Profile saved successfully';

  // Common
  String get ok => isKannada ? AppStringsKn.ok : 'OK';
  String get cancel => isKannada ? AppStringsKn.cancel : 'Cancel';
  String get save => isKannada ? AppStringsKn.save : 'Save';
  String get edit => isKannada ? AppStringsKn.edit : 'Edit';
  String get delete => isKannada ? AppStringsKn.delete : 'Delete';
  String get retry => isKannada ? AppStringsKn.retry : 'Retry';
  String get close => isKannada ? AppStringsKn.close : 'Close';
  String get next => isKannada ? AppStringsKn.next : 'Next';
  String get back => isKannada ? AppStringsKn.back : 'Back';
  String get skip => isKannada ? AppStringsKn.skip : 'Skip';
  String get done => isKannada ? AppStringsKn.done : 'Done';
  String get yes => isKannada ? AppStringsKn.yes : 'Yes';
  String get no => isKannada ? AppStringsKn.no : 'No';
  String get loading => isKannada ? AppStringsKn.loading : 'Loading...';
  String get pleaseWait => isKannada ? AppStringsKn.pleaseWait : 'Please wait...';
  String get somethingWentWrong => isKannada ? AppStringsKn.somethingWentWrong : 'Something went wrong';
  String get tryAgainLater => isKannada ? AppStringsKn.tryAgainLater : 'Please try again later';
  String get noInternet => isKannada ? AppStringsKn.noInternet : 'No internet connection';
  String get checkConnection => isKannada ? AppStringsKn.checkConnection : 'Check your connection and try again';
  String get permissionRequired => isKannada ? AppStringsKn.permissionRequired : 'Permission Required';
  String get enableLocation => isKannada ? AppStringsKn.enableLocation : 'Please enable location access';
  String get enableNotifications => isKannada ? AppStringsKn.enableNotifications : 'Please enable notifications';

  // Validation
  String get requiredField => isKannada ? AppStringsKn.requiredField : 'This field is required';
  String get invalidPhone => isKannada ? AppStringsKn.invalidPhone : 'Enter a valid 10-digit phone number';
  String get invalidEmail => isKannada ? AppStringsKn.invalidEmail : 'Enter a valid email address';
  String get invalidOtp => isKannada ? AppStringsKn.invalidOtp : 'Enter a valid 4-digit OTP';
  String get invalidVehicleNumber => isKannada ? AppStringsKn.invalidVehicleNumber : 'Enter a valid vehicle number';
  String get nameTooShort => isKannada ? AppStringsKn.nameTooShort : 'Name must be at least 2 characters';
  String get nameTooLong => isKannada ? AppStringsKn.nameTooLong : 'Name must be less than 50 characters';

  // Wallet
  String get wallet => isKannada ? AppStringsKn.wallet : 'Wallet';
  String get walletBalance => isKannada ? AppStringsKn.walletBalance : 'Wallet Balance';
  String get addMoney => isKannada ? AppStringsKn.addMoney : 'Add Money';
  String get transactionHistory => isKannada ? AppStringsKn.transactionHistory : 'Transaction History';
  String get recharge => isKannada ? AppStringsKn.recharge : 'Recharge';

  // Coupons
  String get coupons => isKannada ? AppStringsKn.coupons : 'Coupons';
  String get myCoupons => isKannada ? AppStringsKn.myCoupons : 'My Coupons';
  String get applyCouponCode => isKannada ? AppStringsKn.applyCouponCode : 'Apply Coupon Code';
  String get couponApplied => isKannada ? AppStringsKn.couponApplied : 'Coupon applied successfully';
  String get invalidCoupon => isKannada ? AppStringsKn.invalidCoupon : 'Invalid or expired coupon';
  String get couponExpired => isKannada ? AppStringsKn.couponExpired : 'This coupon has expired';
  String get couponUsed => isKannada ? AppStringsKn.couponUsed : 'This coupon has been used';

  // Ratings
  String get rateExperience => isKannada ? AppStringsKn.rateExperience : 'Rate your experience';
  String get excellent => isKannada ? AppStringsKn.excellent : 'Excellent';
  String get good => isKannada ? AppStringsKn.good : 'Good';
  String get average => isKannada ? AppStringsKn.average : 'Average';
  String get poor => isKannada ? AppStringsKn.poor : 'Poor';
  String get terrible => isKannada ? AppStringsKn.terrible : 'Terrible';

  // Help & Support
  String get helpSupport => isKannada ? AppStringsKn.helpSupport : 'Help & Support';
  String get contactUs => isKannada ? AppStringsKn.contactUs : 'Contact Us';
  String get faqs => isKannada ? AppStringsKn.faqs : 'FAQs';
  String get termsConditions => isKannada ? AppStringsKn.termsConditions : 'Terms & Conditions';
  String get privacyPolicy => isKannada ? AppStringsKn.privacyPolicy : 'Privacy Policy';
  String get logout => isKannada ? AppStringsKn.logout : 'Logout';
  String get confirmLogout => isKannada ? AppStringsKn.confirmLogout : 'Are you sure you want to logout?';

  // SOS
  String get sos => isKannada ? AppStringsKn.sos : 'SOS';
  String get emergencyContact => isKannada ? AppStringsKn.emergencyContact : 'Emergency Contact';
  String get shareLocation => isKannada ? AppStringsKn.shareLocation : 'Share Live Location';
  String get sosActivated => isKannada ? AppStringsKn.sosActivated : 'SOS Activated';
  String get sosMessage => isKannada ? AppStringsKn.sosMessage : 'Your live location has been shared with your emergency contact';

  // Notifications
  String get newBooking => isKannada ? AppStringsKn.newBooking : 'New Booking';
  String get driverAssigned => isKannada ? AppStringsKn.driverAssigned : 'Driver Assigned';
  String get driverArrivedNotification => isKannada ? AppStringsKn.driverArrivedNotification : 'Driver Arrived';
  String get tripCompletedNotification => isKannada ? AppStringsKn.tripCompletedNotification : 'Trip Completed';
  String get paymentReceived => isKannada ? AppStringsKn.paymentReceived : 'Payment Received';

  // Home (Customer)
  String get whereToDeliver => isKannada ? AppStringsKn.whereToDeliver : 'Where to deliver?';
  String get pickupLocation => isKannada ? AppStringsKn.pickupLocation : 'Pickup location';
  String get dropLocation => isKannada ? AppStringsKn.dropLocation : 'Drop location';
  String get searchLocation => isKannada ? AppStringsKn.searchLocation : 'Search location';
  String get currentLocation => isKannada ? AppStringsKn.currentLocation : 'Current location';
  String get savedAddresses => isKannada ? AppStringsKn.savedAddresses : 'Saved Addresses';
  String get recentTrips => isKannada ? AppStringsKn.recentTrips : 'Recent Trips';
  String get noSavedAddresses => isKannada ? AppStringsKn.noSavedAddresses : 'No saved addresses yet';
  String get noRecentTrips => isKannada ? AppStringsKn.noRecentTrips : 'No recent trips';
  String get myTrips => isKannada ? 'ನನ್ನ ಪ್ರವಾಸಗಳು' : 'My Trips';
  String get addAddress => isKannada ? AppStringsKn.addAddress : 'Add Address';
  String get bookNow => isKannada ? AppStringsKn.bookNow : 'Book Now';

  // Vehicle Selection
  String get selectVehicle => isKannada ? AppStringsKn.selectVehicle : 'Select Vehicle';
  String get vehicleCapacity => isKannada ? AppStringsKn.vehicleCapacity : 'Capacity';
  String get estimatedFare => isKannada ? AppStringsKn.estimatedFare : 'Estimated Fare';
  String get eta => isKannada ? AppStringsKn.eta : 'ETA';
  String get perKm => isKannada ? AppStringsKn.perKm : '/km';
  String get perMin => isKannada ? AppStringsKn.perMin : '/min';
  String get baseFare => isKannada ? AppStringsKn.baseFare : 'Base Fare';
  String get minimumFare => isKannada ? AppStringsKn.minimumFare : 'Minimum Fare';

  // Booking Details
  String get bookingDetails => isKannada ? AppStringsKn.bookingDetails : 'Booking Details';
  String get goodsType => isKannada ? AppStringsKn.goodsType : 'Type of Goods';
  String get goodsTypeHint => isKannada ? AppStringsKn.goodsTypeHint : 'e.g., Furniture, Boxes, Appliances';
  String get notesOptional => isKannada ? AppStringsKn.notesOptional : 'Notes (Optional)';
  String get notesHint => isKannada ? AppStringsKn.notesHint : 'Any special instructions for the driver';
  String get loadingHelper => isKannada ? AppStringsKn.loadingHelper : 'Loading Helper';
  String get loadingHelperDesc => isKannada ? AppStringsKn.loadingHelperDesc : 'Driver will help load/unload goods';
  String get applyCoupon => isKannada ? AppStringsKn.applyCoupon : 'Apply Coupon';
  String get couponCodeHint => isKannada ? AppStringsKn.couponCodeHint : 'Enter coupon code';
  String get paymentMethod => isKannada ? AppStringsKn.paymentMethod : 'Payment Method';
  String get payOnline => isKannada ? AppStringsKn.payOnline : 'Pay Online (UPI/Card/Netbanking)';
  String get payCash => isKannada ? AppStringsKn.payCash : 'Cash on Delivery';
  String get confirmBooking => isKannada ? AppStringsKn.confirmBooking : 'Confirm Booking';
  String get fareBreakdown => isKannada ? AppStringsKn.fareBreakdown : 'Fare Breakdown';
  String get distanceFare => isKannada ? AppStringsKn.distanceFare : 'Distance Fare';
  String get timeFare => isKannada ? AppStringsKn.timeFare : 'Time Fare';
  String get surgeCharges => isKannada ? AppStringsKn.surgeCharges : 'Surge Charges';
  String get gst => isKannada ? AppStringsKn.gst : 'GST (5%)';
  String get discount => isKannada ? AppStringsKn.discount : 'Discount';
  String get totalPayable => isKannada ? AppStringsKn.totalPayable : 'Total Payable';

  // Finding Driver
  String get findingDriver => isKannada ? AppStringsKn.findingDriver : 'Finding a driver...';
  String get searchingNearby => isKannada ? AppStringsKn.searchingNearby : 'Searching nearby drivers';
  String get cancelSearch => isKannada ? AppStringsKn.cancelSearch : 'Cancel Search';
  String get noDriversFound => isKannada ? AppStringsKn.noDriversFound : 'No drivers found';
  String get tryAgain => isKannada ? AppStringsKn.tryAgain : 'Try Again';

  // Live Tracking
  String get driverArriving => isKannada ? AppStringsKn.driverArriving : 'Driver is arriving';
  String get driverArrived => isKannada ? AppStringsKn.driverArrived : 'Driver has arrived';
  String get tripStarted => isKannada ? AppStringsKn.tripStarted : 'Trip started';
  String get inTransit => isKannada ? AppStringsKn.inTransit : 'In transit';
  String get reachedDestination => isKannada ? AppStringsKn.reachedDestination : 'Reached destination';
  String get shareTrip => isKannada ? AppStringsKn.shareTrip : 'Share Trip';
  String get callDriver => isKannada ? AppStringsKn.callDriver : 'Call Driver';
  String get pickupOtp => isKannada ? AppStringsKn.pickupOtp : 'Pickup OTP';
  String get dropOtp => isKannada ? AppStringsKn.dropOtp : 'Drop OTP';
  String get shareWith => isKannada ? AppStringsKn.shareWith : 'Share with';
  String get tripStatus => isKannada ? AppStringsKn.tripStatus : 'Trip Status';

  // Trip Complete
  String get tripCompleted => isKannada ? AppStringsKn.tripCompleted : 'Trip Completed';
  String get rateYourDriver => isKannada ? AppStringsKn.rateYourDriver : 'Rate your driver';
  String get writeReview => isKannada ? AppStringsKn.writeReview : 'Write a review (Optional)';
  String get submitRating => isKannada ? AppStringsKn.submitRating : 'Submit Rating';
  String get payNow => isKannada ? AppStringsKn.payNow : 'Pay Now';
  String get paymentSuccessful => isKannada ? AppStringsKn.paymentSuccessful : 'Payment successful';
  String get receipt => isKannada ? AppStringsKn.receipt : 'Receipt';

  // Driver
  String get goOnline => isKannada ? AppStringsKn.goOnline : 'Go Online';
  String get goOffline => isKannada ? AppStringsKn.goOffline : 'Go Offline';
  String get youAreOnline => isKannada ? AppStringsKn.youAreOnline : 'You are online';
  String get youAreOffline => isKannada ? AppStringsKn.youAreOffline : 'You are offline';
  String get todaysEarnings => isKannada ? AppStringsKn.todaysEarnings : "Today's Earnings";
  String get totalTrips => isKannada ? AppStringsKn.totalTrips : 'Total Trips';
  String get accept => isKannada ? AppStringsKn.accept : 'Accept';
  String get reject => isKannada ? AppStringsKn.reject : 'Reject';
  String get incomingRequest => isKannada ? AppStringsKn.incomingRequest : 'Incoming Request';
  String get navigateToPickup => isKannada ? AppStringsKn.navigateToPickup : 'Navigate to Pickup';
  String get arrivedAtPickup => isKannada ? AppStringsKn.arrivedAtPickup : 'Arrived at Pickup';
  String get enterPickupOtp => isKannada ? AppStringsKn.enterPickupOtp : 'Enter Pickup OTP';
  String get startTrip => isKannada ? AppStringsKn.startTrip : 'Start Trip';
  String get navigateToDrop => isKannada ? AppStringsKn.navigateToDrop : 'Navigate to Drop';
  String get enterDropOtp => isKannada ? AppStringsKn.enterDropOtp : 'Enter Drop OTP';
  String get completeTrip => isKannada ? AppStringsKn.completeTrip : 'Complete Trip';
  String get collectCash => isKannada ? AppStringsKn.collectCash : 'Collect Cash';
  String get earnings => isKannada ? AppStringsKn.earnings : 'Earnings';
  String get daily => isKannada ? AppStringsKn.daily : 'Daily';
  String get weekly => isKannada ? AppStringsKn.weekly : 'Weekly';
  String get monthly => isKannada ? AppStringsKn.monthly : 'Monthly';
  String get tripHistory => isKannada ? AppStringsKn.tripHistory : 'Trip History';
  String get commission => isKannada ? AppStringsKn.commission : 'Commission (15%)';
  String get netEarnings => isKannada ? AppStringsKn.netEarnings : 'Net Earnings';

  // Driver Onboarding
  String get driverOnboarding => isKannada ? AppStringsKn.driverOnboarding : 'Driver Onboarding';
  String get vehicleType => isKannada ? AppStringsKn.vehicleType : 'Vehicle Type';
  String get vehicleNumber => isKannada ? AppStringsKn.vehicleNumber : 'Vehicle Number';
  String get vehicleNumberHint => isKannada ? AppStringsKn.vehicleNumberHint : 'e.g., MH12AB1234';
  String get licenseNumber => isKannada ? AppStringsKn.licenseNumber : 'License Number';
  String get licenseExpiry => isKannada ? AppStringsKn.licenseExpiry : 'License Expiry';
  String get rcNumber => isKannada ? AppStringsKn.rcNumber : 'RC Number';
  String get rcExpiry => isKannada ? AppStringsKn.rcExpiry : 'RC Expiry';
  String get aadhaarNumber => isKannada ? AppStringsKn.aadhaarNumber : 'Aadhaar Number';
  String get uploadLicense => isKannada ? AppStringsKn.uploadLicense : 'Upload License';
  String get uploadRc => isKannada ? AppStringsKn.uploadRc : 'Upload RC';
  String get uploadAadhaarFront => isKannada ? AppStringsKn.uploadAadhaarFront : 'Upload Aadhaar Front';
  String get uploadAadhaarBack => isKannada ? AppStringsKn.uploadAadhaarBack : 'Upload Aadhaar Back';
  String get uploadPhoto => isKannada ? AppStringsKn.uploadPhoto : 'Upload Your Photo';
  String get submitForVerification => isKannada ? AppStringsKn.submitForVerification : 'Submit for Verification';
  String get verificationPending => isKannada ? AppStringsKn.verificationPending : 'Verification Pending';
  String get verificationApproved => isKannada ? AppStringsKn.verificationApproved : 'Verified & Approved';
  String get verificationRejected => isKannada ? AppStringsKn.verificationRejected : 'Verification Rejected';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}