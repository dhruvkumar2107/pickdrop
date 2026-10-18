# PickDrop - On-Demand Goods Delivery App

A Flutter-based on-demand delivery app for India, connecting customers with drivers for goods transportation.

## Features

### Customer App
- **Booking Flow**: Pickup/Drop selection with map & Places Autocomplete
- **Vehicle Selection**: Bike, 3-Wheeler, Mini Truck, Pickup with live pricing
- **Real-time Tracking**: Live driver location, route polyline, OTP verification
- **Payments**: Razorpay (UPI/Card/Netbanking) + Cash on Delivery
- **Wallet**: Add money, transaction history
- **Coupons**: Apply promo codes
- **Trip History**: Past and active trips
- **SOS**: Emergency contact alert with location sharing

### Driver App
- **Onboarding**: Vehicle details, document upload (License, RC, Aadhaar)
- **Home**: Online/Offline toggle, earnings dashboard, trip requests
- **Incoming Requests**: 30s countdown, accept/reject with fare breakdown
- **Active Trip**: Step-by-step flow (Navigate → Pickup → Deliver)
- **Earnings**: Daily/Weekly/Monthly charts, trip-wise breakdown
- **Profile**: Vehicle info, documents, stats

### Backend (Firebase Cloud Functions)
- **Booking Creation**: Server-side fare calculation, OTP generation
- **Driver Matching**: Geohash-based cascade offers with timeouts
- **Status Transitions**: SEARCHING → DRIVER_ASSIGNED → PICKED_UP → DELIVERED
- **OTP Verification**: Pickup & Drop OTP validation
- **Cancellation Logic**: Free within 2min, fee after assignment
- **Payment Verification**: Razorpay signature validation
- **Push Notifications**: FCM for status changes

## Tech Stack

- **Frontend**: Flutter 3.x, Dart 3.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Maps**: Google Maps Flutter, Geolocator
- **Backend**: Firebase (Auth, Firestore, Storage, Functions, Messaging)
- **Payments**: Razorpay Flutter
- **Architecture**: Feature-first, Clean Architecture

## Getting Started

### Prerequisites
- Flutter SDK 3.13+
- Dart SDK 3.x
- Android Studio / VS Code
- Firebase project
- Google Maps API key
- Razorpay account

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd pickdrop
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd functions && npm install && cd ..
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication (Phone), Firestore, Storage, Functions, Messaging
   - Add Android app with package name `com.pickdrop.app`
   - Download `google-services.json` to `android/app/`
   - Run `flutterfire configure` to generate `lib/config/firebase/firebase_options.dart`

4. **Configure environment variables**
   Create `.env` file in project root:
   ```env
   FIREBASE_API_KEY=your_api_key
   FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   GOOGLE_MAPS_API_KEY=your_maps_api_key
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret
   FUNCTIONS_REGION=us-central1
   ```

5. **Configure Google Maps**
   - Enable Maps SDK for Android in Google Cloud Console
   - Add API key to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
     ```

6. **Configure Razorpay**
   - Create account at [razorpay.com](https://razorpay.com)
   - Get Key ID and Secret from Dashboard
   - Add to `.env` file

7. **Run the app**
   ```bash
   flutter run
   ```

### Build for Release

```bash
# Android
flutter build apk --release
# or
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release
```

### Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

## Project Structure

```
lib/
├── main.dart
├── config/
│   ├── router/          # GoRouter configuration
│   ├── firebase/        # Firebase options
│   └── env/             # Environment config
├── core/
│   ├── constants/       # App constants, colors, dimensions
│   ├── theme/           # App theme, text styles
│   ├── utils/           # Extensions, helpers, validators
│   ├── widgets/         # Reusable UI components
│   ├── errors/          # Failures, exceptions
│   ├── network/         # Connectivity
│   └── localization/    # i18n support
├── features/
│   ├── auth/            # Phone auth, onboarding, profile
│   ├── customer/
│   │   ├── home/        # Map, booking entry
│   │   ├── booking/     # Pickup/drop, vehicle, details
│   │   ├── tracking/    # Finding driver, live tracking, complete
│   │   ├── trips/       # My trips, trip detail
│   │   ├── wallet/      # Balance, transactions, add money
│   │   ├── coupons/     # Coupon list, apply
│   │   ├── addresses/   # Saved addresses
│   │   ├── profile/     # Settings, help
│   │   └── help/        # FAQ, contact
│   ├── driver/
│   │   ├── onboarding/  # Vehicle, documents
│   │   ├── home/        # Dashboard, requests
│   │   ├── requests/    # Incoming requests
│   │   ├── active_trip/ # Trip flow
│   │   ├── earnings/    # Charts, history
│   │   ├── profile/     # Vehicle, documents
│   │   └── trips/       # Trip history
│   ├── common/
│   │   ├── map/         # Map picker
│   │   ├── vehicle_selection/
│   │   └── payments/
│   └── notifications/
└── shared/
    ├── models/
    └── services/        # Location, Razorpay, Notifications
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `FIREBASE_API_KEY` | Firebase Web API Key | Yes |
| `FIREBASE_AUTH_DOMAIN` | Firebase Auth Domain | Yes |
| `FIREBASE_PROJECT_ID` | Firebase Project ID | Yes |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage Bucket | Yes |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM Sender ID | Yes |
| `FIREBASE_APP_ID` | Firebase App ID | Yes |
| `GOOGLE_MAPS_API_KEY` | Google Maps API Key | Yes |
| `RAZORPAY_KEY_ID` | Razorpay Key ID | Yes |
| `RAZORPAY_KEY_SECRET` | Razorpay Key Secret | Yes |
| `FUNCTIONS_REGION` | Firebase Functions Region | No (default: us-central1) |

## Testing Checklist

### Customer Flow
- [ ] Phone login with OTP
- [ ] Role selection (Customer)
- [ ] Profile creation
- [ ] Pickup/Drop selection (map + autocomplete)
- [ ] Vehicle selection with live pricing
- [ ] Booking details (goods, notes, coupon, payment)
- [ ] Finding driver (real-time matching)
- [ ] Live tracking (driver marker, route, OTP)
- [ ] Trip completion (fare, payment, rating)
- [ ] Wallet add money (Razorpay)
- [ ] Coupon application
- [ ] SOS activation

### Driver Flow
- [ ] Phone login with OTP
- [ ] Role selection (Driver)
- [ ] Onboarding (vehicle, documents)
- [ ] Go online/offline
- [ ] Receive incoming request (30s timer)
- [ ] Accept/Reject request
- [ ] Navigate to pickup
- [ ] Pickup OTP verification
- [ ] Navigate to drop
- [ ] Drop OTP verification
- [ ] Earnings dashboard
- [ ] Profile & documents

### Edge Cases
- [ ] No internet handling
- [ ] Location permission denied
- [ ] Background location updates
- [ ] Driver cancellation
- [ ] Customer cancellation (fee logic)
- [ ] Payment failure handling
- [ ] App termination during trip

## Firebase Security Rules

Deploy with:
```bash
firebase deploy --only firestore:rules,storage:rules
```

## License

MIT License - see LICENSE file for details.