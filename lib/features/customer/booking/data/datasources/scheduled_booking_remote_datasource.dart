import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scheduled_booking_model.dart';

/// Firestore CRUD for the `scheduledBookings` collection.
///
/// Assignment rule: a booking flips to `DRIVER_ASSIGNED` once `scheduledAt`
/// is within 30 minutes and a driver assignment already exists on the doc.
class ScheduledBookingRemoteDataSource {
  static const String collectionName = 'scheduledBookings';
  static const Duration assignmentLeadTime = Duration(minutes: 30);

  final FirebaseFirestore _firestore;

  ScheduledBookingRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
    required String goodsType,
    required double estimatedFare,
  }) async {
    final doc = _firestore.collection(collectionName).doc();
    final booking = ScheduledBookingModel(
      id: doc.id,
      customerId: customerId,
      scheduledAt: scheduledAt,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropLat: dropLat,
      dropLng: dropLng,
      dropAddress: dropAddress,
      vehicleType: vehicleType,
      goodsType: goodsType,
      estimatedFare: estimatedFare,
      createdAt: DateTime.now(),
    );
    await doc.set(booking.toMap());
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

  Future<void> cancel(String id) {
    return _firestore
        .collection(collectionName)
        .doc(id)
        .update({'status': ScheduledBookingModel.statusCancelled});
  }

  Future<void> assignDriver(String id, String driverId) {
    return _firestore.collection(collectionName).doc(id).update({
      'assignedDriverId': driverId,
      'status': ScheduledBookingModel.statusDriverAssigned,
    });
  }

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
    try {
      await _firestore
          .collection(collectionName)
          .doc(booking.id)
          .update({'status': updated.status});
    } catch (_) {}
    return updated;
  }

  List<ScheduledBookingModel> _sorted(QuerySnapshot snap) {
    final items = snap.docs.map(ScheduledBookingModel.fromFirestore).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }
}
