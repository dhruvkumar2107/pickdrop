import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../../config/env/env_config.dart';
import '../models/scheduled_booking_model.dart';

/// Firestore CRUD for the `scheduledBookings` collection.
///
/// Assignment rule: a booking flips to `DRIVER_ASSIGNED` once `scheduledAt`
/// is within 30 minutes and a driver assignment already exists on the doc.
class ScheduledBookingRemoteDataSource {
  static const String collectionName = 'scheduledBookings';
  static const Duration assignmentLeadTime = Duration(minutes: 30);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ScheduledBookingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion);

  Future<ScheduledBookingModel> create({
    required String customerId,
    required DateTime scheduledAt,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String vehicleType,
    required String vehicleTypeId,
    required String goodsType,
    List<Map<String, dynamic>> stops = const [],
    String referralCode = '',
  }) async {
    final result = await _functions.httpsCallable('createScheduledBooking').call({
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'drop': {'lat': dropLat, 'lng': dropLng},
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'vehicleType': vehicleType,
      'vehicleTypeId': vehicleTypeId,
      'goodsType': goodsType,
      'referralCode': referralCode,
      'stops': stops,
      'paymentMethod': 'cod',
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final id = data['scheduledBookingId'] as String;
    final booking = ScheduledBookingModel(
      id: id,
      customerId: data['customerId'] as String? ?? customerId,
      scheduledAt: scheduledAt,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropLat: dropLat,
      dropLng: dropLng,
      dropAddress: dropAddress,
      vehicleType: vehicleType,
      goodsType: goodsType,
      intermediateStops: stops.map((stop) => Map<String, dynamic>.from(stop)).toList(),
      estimatedFare: (data['estimatedFare'] as num).toDouble(),
      createdAt: DateTime.now(),
    );
    return booking;
  }

  Stream<List<ScheduledBookingModel>> watchForCustomer(String customerId) {
    return _firestore
        .collection(collectionName)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(_sorted);
  }

  Future<List<ScheduledBookingModel>> fetchForCustomer(String customerId) async {
    final snap = await _firestore
        .collection(collectionName)
        .where('customerId', isEqualTo: customerId)
        .get();
    return _sorted(snap);
  }

  Future<ScheduledBookingModel> fetchById(String id) async {
    final doc = await _firestore.collection(collectionName).doc(id).get();
    return ScheduledBookingModel.fromFirestore(doc);
  }

  Future<void> cancel(String id) async {
    await _functions.httpsCallable('cancelScheduledBooking').call({'scheduledBookingId': id});
  }

  Future<void> assignDriver(String id, String driverId) async =>
      throw UnsupportedError('Scheduled assignment is controlled by dispatch.');

  bool isAssignmentDue(ScheduledBookingModel booking, {DateTime? now}) {
    if (booking.isClosed || booking.assignedDriverId.isEmpty) return false;
    final reference = now ?? DateTime.now();
    return booking.scheduledAt.difference(reference) <= assignmentLeadTime;
  }

  ScheduledBookingModel ensureDriverAssignment(
    ScheduledBookingModel booking, {
    DateTime? now,
  }) {
    if (!isAssignmentDue(booking, now: now)) return booking;
    if (booking.status == ScheduledBookingModel.statusDriverAssigned) {
      return booking;
    }
    return booking.copyWith(status: ScheduledBookingModel.statusDriverAssigned);
  }

  Future<ScheduledBookingModel> syncDriverAssignment(
    ScheduledBookingModel booking, {
    DateTime? now,
  }) async {
    final updated = ensureDriverAssignment(booking, now: now);
    if (updated.status == booking.status) return updated;
    return updated;
  }

  List<ScheduledBookingModel> _sorted(QuerySnapshot snap) {
    final items = snap.docs.map(ScheduledBookingModel.fromFirestore).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }
}
