import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/services/notification_service.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/phone_login_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/profile_creation_page.dart';
import '../../features/customer/home/presentation/pages/customer_home_page.dart';
import '../../features/customer/booking/presentation/pages/pickup_drop_selection_page.dart';
import '../../features/customer/booking/presentation/pages/booking_details_page.dart';
import '../../features/customer/tracking/presentation/pages/finding_driver_page.dart';
import '../../features/customer/tracking/presentation/pages/live_tracking_page.dart';
import '../../features/customer/tracking/presentation/pages/trip_complete_page.dart';
import '../../features/customer/trips/presentation/pages/my_trips_page.dart';
import '../../features/customer/trips/presentation/pages/trip_detail_page.dart';
import '../../features/customer/wallet/presentation/pages/wallet_page.dart';
import '../../features/customer/coupons/presentation/pages/coupons_page.dart';
import '../../features/customer/addresses/presentation/pages/saved_addresses_page.dart';
import '../../features/customer/addresses/presentation/pages/add_address_page.dart';
import '../../features/customer/profile/presentation/pages/customer_profile_page.dart';
import '../../features/customer/help/presentation/pages/help_support_page.dart';
import '../../features/customer/booking/presentation/pages/scheduled_bookings_page.dart';
import '../../features/customer/booking/presentation/pages/business_account_page.dart';
import '../../features/customer/safety/presentation/pages/safety_mode_page.dart';
import '../../features/common/chat/presentation/pages/chat_page.dart';
import '../../features/customer/tracking/presentation/pages/web_tracking_page.dart';
import '../../features/driver/earnings/presentation/pages/driver_payouts_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/common/vehicle_selection/presentation/pages/vehicle_selection_page.dart';
import '../../features/common/map/presentation/pages/map_picker_page.dart';
import '../../features/common/payments/presentation/pages/payment_page.dart';
import '../../features/driver/home/presentation/pages/driver_home_page.dart';
import '../../features/driver/requests/presentation/pages/incoming_request_page.dart';
import '../../features/driver/active_trip/presentation/pages/active_trip_page.dart';
import '../../features/driver/earnings/presentation/pages/driver_earnings_page.dart';
import '../../features/driver/profile/presentation/pages/driver_profile_page.dart';
import '../../features/driver/trips/presentation/pages/driver_trip_history_page.dart';
import '../../features/driver/onboarding/presentation/pages/driver_onboarding_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      // ─── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.phoneLogin,
        name: 'phoneLogin',
        builder: (context, state) => const PhoneLoginPage(),
      ),
      GoRoute(
        path: RouteNames.otpVerify,
        name: 'otpVerify',
        builder: (context, state) {
          final phoneNumber = state.uri.queryParameters['phone'] ?? '';
          final verificationId =
              state.uri.queryParameters['verificationId'] ?? '';
          return OtpVerifyPage(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
          );
        },
      ),
      GoRoute(
        path: RouteNames.roleSelection,
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: RouteNames.profileCreation,
        name: 'profileCreation',
        builder: (context, state) => const ProfileCreationPage(),
      ),

      // ─── Customer ───────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.customerHome,
        name: 'customerHome',
        builder: (context, state) => const CustomerHomePage(),
      ),
      GoRoute(
        path: RouteNames.pickupSelection,
        name: 'pickupSelection',
        builder: (context, state) {
          final label = state.uri.queryParameters['label'];
          final lat =
              double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng =
              double.tryParse(state.uri.queryParameters['lng'] ?? '');
          return PickupSelectionPage(
            initialLabel: label,
            initialLat: lat,
            initialLng: lng,
          );
        },
      ),
      GoRoute(
        path: RouteNames.dropSelection,
        name: 'dropSelection',
        builder: (context, state) {
          final pickupLat =
              double.tryParse(state.uri.queryParameters['pickupLat'] ?? '');
          final pickupLng =
              double.tryParse(state.uri.queryParameters['pickupLng'] ?? '');
          final pickupAddress =
              state.uri.queryParameters['pickupAddress'] ?? '';
          return DropSelectionPage(
            pickupLat: pickupLat ?? 0,
            pickupLng: pickupLng ?? 0,
            pickupAddress: pickupAddress,
          );
        },
      ),
      GoRoute(
        path: RouteNames.vehicleSelection,
        name: 'vehicleSelection',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return VehicleSelectionPage(
            pickupLat: double.tryParse(q['pickupLat'] ?? '') ?? 0,
            pickupLng: double.tryParse(q['pickupLng'] ?? '') ?? 0,
            pickupAddress: q['pickupAddress'] ?? '',
            dropLat: double.tryParse(q['dropLat'] ?? '') ?? 0,
            dropLng: double.tryParse(q['dropLng'] ?? '') ?? 0,
            dropAddress: q['dropAddress'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.bookingDetails,
        name: 'bookingDetails',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return BookingDetailsPage(
            pickupAddress: q['pickupAddress'] ?? '',
            dropAddress: q['dropAddress'] ?? '',
            pickupLat: double.tryParse(q['pickupLat'] ?? '') ?? 0,
            pickupLng: double.tryParse(q['pickupLng'] ?? '') ?? 0,
            dropLat: double.tryParse(q['dropLat'] ?? '') ?? 0,
            dropLng: double.tryParse(q['dropLng'] ?? '') ?? 0,
            vehicleTypeId: q['vehicleTypeId'] ?? '',
            vehicleType: q['vehicleTypeName'] ?? q['vehicleType'] ?? 'Bike',
            distanceKm: double.tryParse(q['distanceKm'] ?? '') ?? 0,
            durationMin: double.tryParse(q['durationMin'] ?? '') ?? 0,
            baseFare: double.tryParse(q['baseFare'] ?? '') ?? 0,
            distanceFare: double.tryParse(q['distanceFare'] ?? '') ?? 0,
            timeFare: double.tryParse(q['timeFare'] ?? '') ?? 0,
            surgeMultiplier: double.tryParse(q['surgeMultiplier'] ?? '') ?? 1,
            subtotal: double.tryParse(q['subtotal'] ?? '') ?? 0,
            gst: double.tryParse(q['gst'] ?? '') ?? 0,
            total: double.tryParse(q['total'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: RouteNames.findingDriver,
        name: 'findingDriver',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return FindingDriverPage(
            pickupAddress: q['pickupAddress'] ?? 'Pickup Location',
            dropAddress: q['dropAddress'] ?? 'Drop Location',
            fare: double.tryParse(q['fare'] ?? '') ?? 0,
            pickupLat: double.tryParse(q['pickupLat'] ?? '') ?? 0,
            pickupLng: double.tryParse(q['pickupLng'] ?? '') ?? 0,
            dropLat: double.tryParse(q['dropLat'] ?? '') ?? 0,
            dropLng: double.tryParse(q['dropLng'] ?? '') ?? 0,
            vehicleTypeId: q['vehicleTypeId'] ?? '',
            vehicleType: q['vehicleType'] ?? 'Bike',
            distanceKm: double.tryParse(q['distanceKm'] ?? '') ?? 0,
            paymentMethod: q['paymentMethod'] ?? 'cod',
            goodsType: q['goodsType'] ?? '',
            loadingHelper: q['loadingHelper'] == 'true',
            couponCode: q['couponCode'] ?? '',
            discount: double.tryParse(q['discount'] ?? '') ?? 0,
            bookingId: q['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.liveTracking,
        name: 'liveTracking',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return LiveTrackingPage(
            bookingId: q['bookingId'],
            fare: double.tryParse(q['fare'] ?? ''),
            pickupAddress: q['pickupAddress'],
            dropAddress: q['dropAddress'],
            pickupLat: double.tryParse(q['pickupLat'] ?? ''),
            pickupLng: double.tryParse(q['pickupLng'] ?? ''),
            dropLat: double.tryParse(q['dropLat'] ?? ''),
            dropLng: double.tryParse(q['dropLng'] ?? ''),
            paymentMethod: q['paymentMethod'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.tripComplete,
        name: 'tripComplete',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return TripCompletePage(
            fare: double.tryParse(q['fare'] ?? ''),
            driverName: q['driver'],
            paymentMethod: q['paymentMethod'],
            bookingId: q['bookingId'],
            driverId: q['driverId'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.myTrips,
        name: 'myTrips',
        builder: (context, state) => const MyTripsPage(),
      ),
      GoRoute(
        path: RouteNames.tripDetail,
        name: 'tripDetail',
        builder: (context, state) => const TripDetailPage(),
      ),
      GoRoute(
        path: RouteNames.wallet,
        name: 'wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: RouteNames.coupons,
        name: 'coupons',
        builder: (context, state) => const CouponsPage(),
      ),
      GoRoute(
        path: RouteNames.savedAddresses,
        name: 'savedAddresses',
        builder: (context, state) => const SavedAddressesPage(),
      ),
      GoRoute(
        path: RouteNames.addAddress,
        name: 'addAddress',
        builder: (context, state) => const AddAddressPage(),
      ),
      GoRoute(
        path: RouteNames.customerProfile,
        name: 'customerProfile',
        builder: (context, state) => const CustomerProfilePage(),
      ),
      GoRoute(
        path: RouteNames.helpSupport,
        name: 'helpSupport',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return HelpSupportPage(
            activeBookingId: q['bookingId'],
            activeTripLabel: q['tripLabel'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.scheduledBookings,
        name: 'scheduledBookings',
        builder: (context, state) => const ScheduledBookingsPage(),
      ),
      GoRoute(
        path: RouteNames.businessAccount,
        name: 'businessAccount',
        builder: (context, state) => const BusinessAccountPage(),
      ),
      GoRoute(
        path: RouteNames.safetyMode,
        name: 'safetyMode',
        builder: (context, state) => const SafetyModePage(),
      ),

      // ─── Public web tracking (WhatsApp share link) ─────────────────────
      GoRoute(
        path: RouteNames.webTracking,
        name: 'webTracking',
        builder: (context, state) =>
            WebTrackingPage(bookingId: state.pathParameters['bookingId'] ?? ''),
      ),

      // ─── Driver ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.driverOnboarding,
        name: 'driverOnboarding',
        builder: (context, state) => const DriverOnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.driverHome,
        name: 'driverHome',
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: RouteNames.incomingRequest,
        name: 'incomingRequest',
        builder: (context, state) => IncomingRequestPage(
          bookingId: state.uri.queryParameters['bookingId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.activeTrip,
        name: 'activeTrip',
        builder: (context, state) => ActiveTripPage(
          bookingId: state.uri.queryParameters['bookingId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.driverEarnings,
        name: 'driverEarnings',
        builder: (context, state) => const DriverEarningsPage(),
      ),
      GoRoute(
        path: RouteNames.driverProfile,
        name: 'driverProfile',
        builder: (context, state) => const DriverProfilePage(),
      ),
      GoRoute(
        path: RouteNames.driverTripHistory,
        name: 'driverTripHistory',
        builder: (context, state) => const DriverTripHistoryPage(),
      ),
      GoRoute(
        path: RouteNames.driverPayouts,
        name: 'driverPayouts',
        builder: (context, state) => const DriverPayoutsPage(),
      ),

      // ─── Common ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.mapPicker,
        name: 'mapPicker',
        builder: (context, state) => const MapPickerPage(),
      ),
      GoRoute(
        path: RouteNames.placesSearch,
        name: 'placesSearch',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Places Search')),
        ),
      ),
      GoRoute(
        path: RouteNames.payment,
        name: 'payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: RouteNames.chat,
        name: 'chat',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ChatPage(
            bookingId: q['bookingId'] ?? '',
            peerName: q['peerName'] ?? 'Driver',
            peerRole: q['role'] == 'driver' ? ChatPeerRole.driver : ChatPeerRole.customer,
          );
        },
      ),

      // ─── Settings ───────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.language,
        name: 'language',
        builder: (context, state) => const LanguagePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
