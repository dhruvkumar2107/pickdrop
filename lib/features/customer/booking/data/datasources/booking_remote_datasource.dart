import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateBookingResult {
  final String bookingId;
  final double totalFare;
  const CreateBookingResult({
    required this.bookingId,
    required this.totalFare,
  });
}

/// Firestore-only booking backend (no Cloud Functions).
///
/// A booking document is created directly from the client and lives in the
/// `bookings` collection. Status transitions are driven by clients
/// (customer cancel, driver accept) and observed through [watchBookingStatus].
class BookingRemoteDataSource {
  BookingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
    required String paymentMethod, // razorpay | cod | wallet
    String notes = '',
    double distanceKm = 0,
    double durationMin = 0,
    double baseFare = 0,
    double distanceFare = 0,
    double timeFare = 0,
    double surgeMultiplier = 1,
    double gst = 0,
    double total = 0,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to create a booking.');
    }

    final ref = _bookings.doc();
    final now = FieldValue.serverTimestamp();

    final fare = <String, dynamic>{
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeMultiplier': surgeMultiplier,
      'gst': gst,
      'total': total,
    };

    await ref.set(<String, dynamic>{
      'bookingId': ref.id,
      'customerId': uid,
      'driverId': null,
      'status': 'SEARCHING',
      'vehicleTypeId': vehicleTypeId,
      'pickup': {
        'lat': pickupLat,
        'lng': pickupLng,
        'address': pickupAddress,
      },
      'drop': {
        'lat': dropLat,
        'lng': dropLng,
        'address': dropAddress,
      },
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'fare': fare,
      'fareBreakdown': {'total': total},
      'createdAt': now,
      'updatedAt': now,
    });

    return CreateBookingResult(bookingId: ref.id, totalFare: total);
  }

  /// Emits the booking's `status` field: SEARCHING → DRIVER_ASSIGNED →
  /// PICKED_UP → DELIVERED (or NO_DRIVER_FOUND / CANCELLED).
  Stream<String> watchBookingStatus(String bookingId) {
    return _bookings
        .doc(bookingId)
        .snapshots()
        .map((snap) => (snap.data()?['status'] ?? '') as String);
  }

  /// Assigns a driver to a SEARCHING booking (client-side matching).
  Future<void> acceptBooking(String bookingId, {String? driverId}) async {
    final uid = driverId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _bookings.doc(bookingId).set(<String, dynamic>{
      'driverId': uid,
      'status': 'DRIVER_ASSIGNED',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _bookings.doc(bookingId).set(<String, dynamic>{
      'status': 'CANCELLED',
      'cancelledAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
