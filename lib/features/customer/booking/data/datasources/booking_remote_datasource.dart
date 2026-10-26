import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../config/env/env_config.dart';

class CreateBookingResult {
  final String bookingId;
  final double totalFare;

  const CreateBookingResult({required this.bookingId, required this.totalFare});
}

class FareQuoteResult {
  final String priceLockId;
  final Map<String, dynamic> fare;
  final double distanceKm;
  final double durationMin;

  const FareQuoteResult({
    required this.priceLockId,
    required this.fare,
    required this.distanceKm,
    required this.durationMin,
  });
}

/// Client adapter for server-owned booking operations.
/// Firestore is used only to observe booking state; clients never write it.
class BookingRemoteDataSource {
  BookingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  Future<CreateBookingResult> createBooking({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String vehicleTypeId,
    required String paymentMethod,
    String notes = '',
    String goodsType = '',
    bool loadingHelper = false,
    String couponCode = '',
    String referralCode = '',
    List<String> helperLocations = const [],
    bool returnTrip = false,
    bool transitInsurance = false,
    required double expectedTotal,
    List<Map<String, dynamic>> stops = const [],
  }) async {
    if (_auth.currentUser == null) {
      throw StateError('You must be signed in to create a booking.');
    }
    if (!['razorpay', 'cod', 'wallet'].contains(paymentMethod)) {
      throw ArgumentError.value(paymentMethod, 'paymentMethod');
    }

    final result = await _functions.httpsCallable('createBooking').call({
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'drop': {'lat': dropLat, 'lng': dropLng},
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'vehicleTypeId': vehicleTypeId,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'goodsType': goodsType,
      'loadingHelper': loadingHelper,
      'couponCode': couponCode,
      'referralCode': referralCode,
      'helperLocations': helperLocations,
      'returnTrip': returnTrip,
      'transitInsurance': transitInsurance,
      'expectedTotal': expectedTotal,
      'stops': stops,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final fare = Map<String, dynamic>.from(data['fare'] as Map);
    final bookingId = data['bookingId'] as String?;
    if (bookingId == null || bookingId.isEmpty) {
      throw StateError('The booking service returned no booking ID.');
    }
    return CreateBookingResult(
      bookingId: bookingId,
      totalFare: (fare['total'] as num).toDouble(),
    );
  }

  Future<FareQuoteResult> getFareQuote({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String vehicleTypeId,
    List<Map<String, dynamic>> stops = const [],
  }) async {
    final result = await _functions.httpsCallable('createPriceLock').call({
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'drop': {'lat': dropLat, 'lng': dropLng},
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'vehicleTypeId': vehicleTypeId,
      'stops': stops,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return FareQuoteResult(
      priceLockId: data['priceLockId'] as String,
      fare: Map<String, dynamic>.from(data['fareBreakdown'] as Map),
      distanceKm: (data['distanceKm'] as num).toDouble(),
      durationMin: (data['estimatedDurationMin'] as num).toDouble(),
    );
  }

  Stream<String> watchBookingStatus(String bookingId) => _bookings
      .doc(bookingId)
      .snapshots()
      .map((snap) => (snap.data()?['status'] ?? '') as String);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBooking(
    String bookingId,
  ) => _bookings.doc(bookingId).snapshots();

  Future<void> acceptOffer(String bookingId) async {
    await _functions.httpsCallable('acceptOffer').call({
      'bookingId': bookingId,
    });
  }

  Future<void> rejectOffer(String bookingId) async {
    await _functions.httpsCallable('rejectOffer').call({
      'bookingId': bookingId,
    });
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _functions.httpsCallable('cancelBooking').call({
      'bookingId': bookingId,
      'reason': ?reason,
    });
  }

  Future<void> verifyPickupOtp(
    String bookingId,
    String otp, {
    String? proofPath,
  }) async {
    await _functions.httpsCallable('verifyPickupOtp').call({
      'bookingId': bookingId,
      'otp': otp,
      'proofPath': ?proofPath,
    });
  }

  Future<void> verifyDropOtp(
    String bookingId,
    String otp, {
    String? proofPath,
  }) async {
    await _functions.httpsCallable('verifyDropOtp').call({
      'bookingId': bookingId,
      'otp': otp,
      'proofPath': ?proofPath,
    });
  }

  Future<void> verifyIntermediateStopOtp(
    String bookingId,
    int sequence,
    String otp,
  ) async {
    await _functions.httpsCallable('verifyIntermediateStopOtp').call({
      'bookingId': bookingId,
      'sequence': sequence,
      'otp': otp,
    });
  }
}
