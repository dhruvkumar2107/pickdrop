// All user-facing strings in one place for easy localization later
class AppStrings {
  // App
  static const String appName = 'PickDrop';
  static const String appTagline = 'Move anything, anywhere';

  // Onboarding
  static const String onboardingSlide1Title = 'Quick Bookings';
  static const String onboardingSlide1Desc = 'Book a vehicle in seconds. Choose from bikes, 3-wheelers, mini trucks, and pickups.';
  static const String onboardingSlide2Title = 'Live Tracking';
  static const String onboardingSlide2Desc = 'Track your driver in real-time. Get OTP for secure pickup and delivery.';
  static const String onboardingSlide3Title = 'Fair Pricing';
  static const String onboardingSlide3Desc = 'Transparent fares with no hidden charges. Pay via UPI, Card, or Cash.';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String enterPhoneNumber = 'Enter your phone number';
  static const String phoneNumberHint = 'Phone number';
  static const String continueButton = 'Continue';
  static const String sendingOtp = 'Sending OTP...';
  static const String otpSent = 'OTP sent to';
  static const String enterOtp = 'Enter OTP';
  static const String otpHint = 'Enter the 4-digit code';
  static const String verifyOtp = 'Verify OTP';
  static const String verifyingOtp = 'Verifying OTP...';
  static const String resendOtp = 'Resend OTP';
  static const String resendIn = 'Resend in';
  static const String seconds = 'seconds';
  static const String didntReceiveOtp = "Didn't receive OTP?";
  static const String verifyAndContinue = 'Verify & Continue';

  // Role Selection
  static const String selectRole = 'How would you like to use PickDrop?';
  static const String roleCustomer = 'Customer';
  static const String roleCustomerDesc = 'I want to send goods';
  static const String roleDriver = 'Driver';
  static const String roleDriverDesc = 'I want to deliver goods';
  static const String continueAs = 'Continue as';

  // Profile
  static const String completeProfile = 'Complete your profile';
  static const String fullName = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String emailOptional = 'Email (Optional)';
  static const String emailHint = 'Enter your email';
  static const String saveProfile = 'Save Profile';
  static const String profileSaved = 'Profile saved successfully';

  // Home (Customer)
  static const String whereToDeliver = 'Where to deliver?';
  static const String pickupLocation = 'Pickup location';
  static const String dropLocation = 'Drop location';
  static const String searchLocation = 'Search location';
  static const String currentLocation = 'Current location';
  static const String savedAddresses = 'Saved Addresses';
  static const String recentTrips = 'Recent Trips';
  static const String noSavedAddresses = 'No saved addresses yet';
  static const String noRecentTrips = 'No recent trips';
  static const String addAddress = 'Add Address';
  static const String bookNow = 'Book Now';

  // Vehicle Selection
  static const String selectVehicle = 'Select Vehicle';
  static const String vehicleCapacity = 'Capacity';
  static const String estimatedFare = 'Estimated Fare';
  static const String eta = 'ETA';
  static const String perKm = '/km';
  static const String perMin = '/min';
  static const String baseFare = 'Base Fare';
  static const String minimumFare = 'Minimum Fare';

  // Booking Details
  static const String bookingDetails = 'Booking Details';
  static const String goodsType = 'Type of Goods';
  static const String goodsTypeHint = 'e.g., Furniture, Boxes, Appliances';
  static const String notesOptional = 'Notes (Optional)';
  static const String notesHint = 'Any special instructions for the driver';
  static const String loadingHelper = 'Loading Helper';
  static const String loadingHelperDesc = 'Driver will help load/unload goods';
  static const String applyCoupon = 'Apply Coupon';
  static const String couponCodeHint = 'Enter coupon code';
  static const String paymentMethod = 'Payment Method';
  static const String payOnline = 'Pay Online (UPI/Card/Netbanking)';
  static const String payCash = 'Cash on Delivery';
  static const String confirmBooking = 'Confirm Booking';
  static const String fareBreakdown = 'Fare Breakdown';
  static const String distanceFare = 'Distance Fare';
  static const String timeFare = 'Time Fare';
  static const String surgeCharges = 'Surge Charges';
  static const String gst = 'GST (5%)';
  static const String discount = 'Discount';
  static const String totalPayable = 'Total Payable';

  // Finding Driver
  static const String findingDriver = 'Finding a driver...';
  static const String searchingNearby = 'Searching nearby drivers';
  static const String cancelSearch = 'Cancel Search';
  static const String noDriversFound = 'No drivers found';
  static const String tryAgain = 'Try Again';

  // Live Tracking
  static const String driverArriving = 'Driver is arriving';
  static const String driverArrived = 'Driver has arrived';
  static const String tripStarted = 'Trip started';
  static const String inTransit = 'In transit';
  static const String reachedDestination = 'Reached destination';
  static const String shareTrip = 'Share Trip';
  static const String callDriver = 'Call Driver';
  static const String pickupOtp = 'Pickup OTP';
  static const String dropOtp = 'Drop OTP';
  static const String shareWith = 'Share with';
  static const String tripStatus = 'Trip Status';

  // Trip Complete
  static const String tripCompleted = 'Trip Completed';
  static const String rateYourDriver = 'Rate your driver';
  static const String writeReview = 'Write a review (Optional)';
  static const String submitRating = 'Submit Rating';
  static const String payNow = 'Pay Now';
  static const String paymentSuccessful = 'Payment successful';
  static const String receipt = 'Receipt';

  // Driver
  static const String goOnline = 'Go Online';
  static const String goOffline = 'Go Offline';
  static const String youAreOnline = 'You are online';
  static const String youAreOffline = 'You are offline';
  static const String todaysEarnings = "Today's Earnings";
  static const String totalTrips = 'Total Trips';
  static const String accept = 'Accept';
  static const String reject = 'Reject';
  static const String incomingRequest = 'Incoming Request';
  static const String navigateToPickup = 'Navigate to Pickup';
  static const String arrivedAtPickup = 'Arrived at Pickup';
  static const String enterPickupOtp = 'Enter Pickup OTP';
  static const String startTrip = 'Start Trip';
  static const String navigateToDrop = 'Navigate to Drop';
  static const String enterDropOtp = 'Enter Drop OTP';
  static const String completeTrip = 'Complete Trip';
  static const String collectCash = 'Collect Cash';
  static const String earnings = 'Earnings';
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String monthly = 'Monthly';
  static const String tripHistory = 'Trip History';
  static const String commission = 'Commission (15%)';
  static const String netEarnings = 'Net Earnings';

  // Driver Onboarding
  static const String driverOnboarding = 'Driver Onboarding';
  static const String vehicleType = 'Vehicle Type';
  static const String vehicleNumber = 'Vehicle Number';
  static const String vehicleNumberHint = 'e.g., MH12AB1234';
  static const String licenseNumber = 'License Number';
  static const String licenseExpiry = 'License Expiry';
  static const String rcNumber = 'RC Number';
  static const String rcExpiry = 'RC Expiry';
  static const String aadhaarNumber = 'Aadhaar Number';
  static const String uploadLicense = 'Upload License';
  static const String uploadRc = 'Upload RC';
  static const String uploadAadhaarFront = 'Upload Aadhaar Front';
  static const String uploadAadhaarBack = 'Upload Aadhaar Back';
  static const String uploadPhoto = 'Upload Your Photo';
  static const String submitForVerification = 'Submit for Verification';
  static const String verificationPending = 'Verification Pending';
  static const String verificationApproved = 'Verified & Approved';
  static const String verificationRejected = 'Verification Rejected';

  // Common
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String retry = 'Retry';
  static const String close = 'Close';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String done = 'Done';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait...';
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgainLater = 'Please try again later';
  static const String noInternet = 'No internet connection';
  static const String checkConnection = 'Check your connection and try again';
  static const String permissionRequired = 'Permission Required';
  static const String enableLocation = 'Please enable location access';
  static const String enableNotifications = 'Please enable notifications';

  // Validation
  static const String requiredField = 'This field is required';
  static const String invalidPhone = 'Enter a valid 10-digit phone number';
  static const String invalidEmail = 'Enter a valid email address';
  static const String invalidOtp = 'Enter a valid 4-digit OTP';
  static const String invalidVehicleNumber = 'Enter a valid vehicle number';
  static const String nameTooShort = 'Name must be at least 2 characters';
  static const String nameTooLong = 'Name must be less than 50 characters';

  // Wallet
  static const String wallet = 'Wallet';
  static const String walletBalance = 'Wallet Balance';
  static const String addMoney = 'Add Money';
  static const String transactionHistory = 'Transaction History';
  static const String recharge = 'Recharge';

  // Coupons
  static const String coupons = 'Coupons';
  static const String myCoupons = 'My Coupons';
  static const String applyCouponCode = 'Apply Coupon Code';
  static const String couponApplied = 'Coupon applied successfully';
  static const String invalidCoupon = 'Invalid or expired coupon';
  static const String couponExpired = 'This coupon has expired';
  static const String couponUsed = 'This coupon has been used';

  // Ratings
  static const String rateExperience = 'Rate your experience';
  static const String excellent = 'Excellent';
  static const String good = 'Good';
  static const String average = 'Average';
  static const String poor = 'Poor';
  static const String terrible = 'Terrible';

  // Help & Support
  static const String helpSupport = 'Help & Support';
  static const String contactUs = 'Contact Us';
  static const String faqs = 'FAQs';
  static const String termsConditions = 'Terms & Conditions';
  static const String privacyPolicy = 'Privacy Policy';
  static const String logout = 'Logout';
  static const String confirmLogout = 'Are you sure you want to logout?';

  // SOS
  static const String sos = 'SOS';
  static const String emergencyContact = 'Emergency Contact';
  static const String shareLocation = 'Share Live Location';
  static const String sosActivated = 'SOS Activated';
  static const String sosMessage = 'Your live location has been shared with your emergency contact';

  // Notifications
  static const String newBooking = 'New Booking';
  static const String driverAssigned = 'Driver Assigned';
  static const String driverArrivedNotification = 'Driver Arrived';
  static const String tripCompletedNotification = 'Trip Completed';
  static const String paymentReceived = 'Payment Received';


  // Common
  static const String submit = 'Submit';
}
