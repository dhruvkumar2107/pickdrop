# PickDrop - Project Plan

## Folder Structure (Feature-First Architecture)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── colors.dart
│   │   ├── dimensions.dart
│   │   └── strings.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   ├── helpers.dart
│   │   └── validators.dart
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── inputs/
│   │   ├── cards/
│   │   ├── loaders/
│   │   ├── dialogs/
│   │   └── common/
│   ├── errors/
│   │   ├── app_exceptions.dart
│   │   └── failure.dart
│   ├── network/
│   │   └── connectivity.dart
│   └── localization/
│       ├── app_localizations.dart
│       └── strings.g.dart
├── config/
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── firebase/
│   │   └── firebase_options.dart
│   └── env/
│       └── env_config.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   ├── customer/
│   │   ├── home/
│   │   ├── booking/
│   │   ├── tracking/
│   │   ├── trips/
│   │   ├── wallet/
│   │   ├── profile/
│   │   └── shared/
│   ├── driver/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── requests/
│   │   ├── active_trip/
│   │   ├── earnings/
│   │   ├── profile/
│   │   └── shared/
│   ├── common/
│   │   ├── map/
│   │   ├── places/
│   │   ├── vehicle_selection/
│   │   └── payments/
│   └── notifications/
├── shared/
│   ├── models/
│   ├── services/
│   └── providers/
└── main.dart
```

## Firestore Collections Schema

### users
```javascript
{
  uid: string,
  phoneNumber: string,
  displayName: string,
  email?: string,
  photoURL?: string,
  role: 'customer' | 'driver' | 'both',
  createdAt: Timestamp,
  updatedAt: Timestamp,
  fcmToken?: string,
  emergencyContact?: {
    name: string,
    phone: string
  }
}
```

### drivers
```javascript
{
  uid: string,
  userId: string, // reference to users
  vehicleTypeId: string, // reference to vehicleTypes
  vehicleNumber: string,
  vehicleModel?: string,
  licenseNumber: string,
  licenseExpiry: Timestamp,
  rcNumber: string,
  rcExpiry: Timestamp,
  aadhaarNumber: string, // encrypted
  aadhaarFrontUrl: string,
  aadhaarBackUrl: string,
  photoUrl: string,
  isOnline: boolean,
  isVerified: boolean,
  currentLocation: GeoPoint,
  geohash: string,
  rating: number,
  totalTrips: number,
  totalEarnings: number,
  todayEarnings: number,
  weekEarnings: number,
  monthEarnings: number,
  fcmToken?: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### vehicleTypes
```javascript
{
  id: string,
  name: string,
  icon: string, // asset path or icon name
  capacityKg: number,
  baseFare: number,
  perKmRate: number,
  perMinuteRate: number,
  minimumFare: number,
  surgeMultiplier: number, // default 1.0
  isActive: boolean,
  sortOrder: number,
  createdAt: Timestamp
}
```

### bookings
```javascript
{
  id: string,
  customerId: string,
  driverId?: string,
  vehicleTypeId: string,
  status: 'SEARCHING' | 'DRIVER_ASSIGNED' | 'ARRIVED' | 'PICKED_UP' | 'IN_TRANSIT' | 'DELIVERED' | 'CANCELLED' | 'NO_DRIVER_FOUND',
  pickup: {
    address: string,
    lat: number,
    lng: number,
    geohash: string,
    otp?: string // 4-digit
  },
  drop: {
    address: string,
    lat: number,
    lng: number,
    geohash: string,
    otp?: string // 4-digit
  },
  distanceKm: number,
  estimatedDurationMin: number,
  fareBreakdown: {
    baseFare: number,
    distanceFare: number,
    timeFare: number,
    surgeMultiplier: number,
    subtotal: number,
    gst: number, // 5%
    total: number,
    discount?: number,
    couponCode?: string
  },
  paymentMethod: 'razorpay' | 'cod',
  paymentStatus: 'pending' | 'paid' | 'failed' | 'refunded',
  razorpayOrderId?: string,
  razorpayPaymentId?: string,
  goodsType: string,
  notes?: string,
  loadingHelper: boolean,
  cancelReason?: string,
  cancelledBy?: 'customer' | 'driver' | 'system',
  cancellationFee: number,
  driverAssignedAt?: Timestamp,
  driverArrivedAt?: Timestamp,
  pickupOtpVerifiedAt?: Timestamp,
  tripStartedAt?: Timestamp,
  dropOtpVerifiedAt?: Timestamp,
  completedAt?: Timestamp,
  cancelledAt?: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### payments
```javascript
{
  id: string,
  bookingId: string,
  userId: string,
  amount: number,
  method: 'razorpay' | 'cod' | 'wallet',
  status: 'pending' | 'success' | 'failed' | 'refunded',
  razorpayOrderId?: string,
  razorpayPaymentId?: string,
  razorpaySignature?: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### ratings
```javascript
{
  id: string,
  bookingId: string,
  fromUserId: string,
  toUserId: string,
  rating: number, // 1-5
  review?: string,
  type: 'customer_to_driver' | 'driver_to_customer',
  createdAt: Timestamp
}
```

### coupons
```javascript
{
  id: string,
  code: string,
  type: 'percentage' | 'flat',
  value: number, // percentage (0-100) or flat amount
  minOrderValue: number,
  maxDiscount?: number,
  usageLimit: number,
  usedCount: number,
  validFrom: Timestamp,
  validUntil: Timestamp,
  isActive: boolean,
  applicableVehicleTypes?: string[], // empty = all
  createdAt: Timestamp
}
```

### savedAddresses
```javascript
{
  id: string,
  userId: string,
  label: string, // 'Home', 'Work', 'Other'
  address: string,
  lat: number,
  lng: number,
  isDefault: boolean,
  createdAt: Timestamp
}
```

### config (single document)
```javascript
{
  surgeMultiplier: number, // global surge
  commissionPercent: number, // driver commission (default 15)
  cancellationFreeWindowMinutes: number, // default 2
  cancellationFeeAfterAssignment: number, // default 50
  driverMatchingRadiusKm: number, // default 5
  driverOfferTimeoutSeconds: number, // default 30
  maxMatchingDurationMinutes: number, // default 3
  gstPercent: number // default 5
}
```

## Phase Checklist

### Phase 1: Setup + Auth ✅ COMPLETE
- [x] Create Flutter project with dependencies
- [x] Set up folder structure
- [x] Configure theme (deep orange #FF6B00, Poppins font)
- [x] Create reusable widgets (buttons, inputs, cards, loaders, dialogs)
- [x] Set up error handling (Failures, Exceptions)
- [x] Configure Firebase (Auth, Firestore, Storage, Messaging, Functions) — needs real `google-services.json` + `.env` values
- [x] Set up google_maps_flutter, geolocator, flutter_polyline_points
- [x] Set up Riverpod providers
- [x] Set up go_router navigation
- [x] Create .env.example and flutter_dotenv config
- [x] Splash screen (onboarding/session/role-aware routing)
- [x] 3-slide Onboarding
- [x] Phone login screen
- [x] OTP verification screen (verificationId threaded end-to-end)
- [x] Role selection screen (Customer / Driver) — role persisted to Firestore
- [x] Profile creation screen — routes by persisted role
- [x] Firestore security rules (firestore.rules + storage.rules + firebase.json)
- [x] Run `flutter analyze` and `flutter build apk --debug` - fix all errors

### Phase 2: Customer Flow ✅ COMPLETE
- [x] Customer Home: Map with current location, "Where to deliver?" card, saved addresses, recent trips
- [x] Pickup/Drop selection: Places Autocomplete + move-pin-on-map
- [x] Vehicle Selection: Cards with icon, capacity, ETA, live price
- [x] Booking Details: goods type, notes, loading helper, coupon, payment method, Confirm → calls `createBooking` Cloud Function (demo fallback if backend offline)
- [x] Finding Driver: Animated searching screen, cancel option → listens to real booking status stream
- [x] Live Tracking: Smooth moving driver marker, route polyline, driver card, call button, OTP display, share trip, status stepper
- [x] Trip Complete: Fare breakdown, pay, rate driver
- [x] My Trips, Wallet, Coupons, Saved Addresses, Profile, Help, Logout

### Phase 3: Fare + Matching (Cloud Functions) ✅ COMPLETE
- [x] Fare calculation Cloud Function (`functions/src/fare.ts`)
- [x] Booking statuses enum and transitions (SEARCHING → DRIVER_ASSIGNED → PICKED_UP → DELIVERED / NO_DRIVER_FOUND / CANCELLED)
- [x] Driver matching Cloud Function (geohash query, cascade offers, timeouts) (`functions/src/matching.ts`)
- [x] Pickup/Drop OTP generation and verification (`verifyPickupOtp` / `verifyDropOtp`)
- [x] Cancellation logic (free within 2 min, fee after assignment) (`cancelBooking`)

> Backend status: `functions/` compiles (`npm run build`); deploy with
> `firebase deploy --only functions` after setting a real project ID in
> `.firebaserc`. Seed `vehicleTypes` + `config/app` docs before live testing.

### Phase 4: Driver Flow ✅ COMPLETE
- [x] Driver Onboarding: Vehicle type, vehicle number, documents upload
- [x] Driver Home: Online/Offline toggle, earnings, trip count
- [x] Incoming Request: Full-screen popup with 30s countdown, Accept/Reject, sound/vibration
- [x] Active Trip: Navigate to pickup (Google Maps intent), Arrived, Pickup OTP, Start, Navigate to drop, Drop OTP, Complete, Collect Cash
- [x] Live Location Updates: Foreground service, 3-5 second intervals
- [x] Earnings: Daily/Weekly/Monthly, trip-wise, commission config, history, ratings

### Phase 5: Payments + Extras ✅ COMPLETE
- [x] Razorpay checkout with server-side verification (Cloud Function)
- [x] Customer wallet top-up
- [x] Coupons system
- [x] Two-way ratings and reviews
- [x] SOS button (emergency contact)
- [x] Trip share link
- [x] Push notifications for status changes

### Phase 6: Polish ✅ MOSTLY COMPLETE
- [x] Loading skeletons, empty states (implemented in widgets)
- [x] Input validation (validators.dart + form validation on screens)
- [x] Runtime permissions (location, notifications, background location handled)
- [ ] Release build config (app icon, splash, signing, proguard) — needs production setup
- [x] Seed script for vehicle types and demo data (`scripts/seed.js`)
- [x] Final README with setup, env variables, test checklist

## Definition of Done
- Customer signs in → picks pickup/drop → sees prices → books → gets matched → tracks live → pays → rates
- Driver goes online → accepts → completes trip with OTPs → sees earnings
- All runs on Android device using README steps