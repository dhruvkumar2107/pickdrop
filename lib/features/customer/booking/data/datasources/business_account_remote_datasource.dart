import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfile {
  const BusinessProfile({
    this.companyName = '',
    this.gstin = '',
    this.billingEmail = '',
  });

  final String companyName;
  final String gstin;
  final String billingEmail;

  factory BusinessProfile.fromMap(Map<String, dynamic> data) => BusinessProfile(
        companyName: data['companyName'] as String? ?? '',
        gstin: data['gstin'] as String? ?? '',
        billingEmail: data['billingEmail'] as String? ?? '',
      );
}

/// One delivered trip for the monthly business statement.
class StatementTrip {
  const StatementTrip({
    required this.bookingId,
    required this.completedAt,
    required this.pickup,
    required this.drop,
    required this.total,
    required this.gst,
    required this.paymentMethod,
  });

  final String bookingId;
  final DateTime completedAt;
  final String pickup;
  final String drop;
  final double total;
  final double gst;
  final String paymentMethod;
}

class BusinessAccountRemoteDataSource {
  static const String collectionName = 'businessAccounts';

  /// Format accepted for a GSTIN: 2-digit state code, PAN, entity code, Z, checksum.
  static final RegExp gstinPattern =
      RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  final FirebaseFirestore _firestore;

  BusinessAccountRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String ownerId) =>
      _firestore.collection(collectionName).doc(ownerId);

  Future<BusinessProfile?> fetch(String ownerId) async {
    final doc = await _doc(ownerId).get();
    final data = doc.data();
    return data == null ? null : BusinessProfile.fromMap(data);
  }

  Future<void> saveProfile({
    required String ownerId,
    required String companyName,
    required String gstin,
    required String billingEmail,
  }) {
    return _doc(ownerId).set({
      'ownerId': ownerId,
      'companyName': companyName,
      'gstin': gstin,
      'billingEmail': billingEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delivered trips completed in [month] (any day within it), newest first.
  Future<List<StatementTrip>> deliveredTrips(String ownerId, DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final snapshot = await _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'DELIVERED')
        .limit(500)
        .get();
    final trips = <StatementTrip>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final completed = data['completedAt'];
      if (completed is! Timestamp) continue;
      final at = completed.toDate();
      if (at.isBefore(start) || !at.isBefore(end)) continue;
      final fare = Map<String, dynamic>.from(data['fareBreakdown'] as Map? ?? {});
      trips.add(StatementTrip(
        bookingId: doc.id,
        completedAt: at,
        pickup: (data['pickup'] as Map?)?['address']?.toString() ?? '',
        drop: (data['drop'] as Map?)?['address']?.toString() ?? '',
        total: (fare['total'] as num?)?.toDouble() ?? 0,
        gst: (fare['gst'] as num?)?.toDouble() ?? 0,
        paymentMethod: data['paymentMethod']?.toString() ?? '',
      ));
    }
    trips.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return trips;
  }

  /// CSV statement of [trips]; quotes every field so addresses with commas stay intact.
  static String statementCsv(BusinessProfile profile, List<StatementTrip> trips) {
    String cell(Object value) => '"${value.toString().replaceAll('"', '""')}"';
    final lines = <String>[
      if (profile.companyName.isNotEmpty) cell('Company: ${profile.companyName}'),
      if (profile.gstin.isNotEmpty) cell('GSTIN: ${profile.gstin}'),
      ['Date', 'Booking ID', 'Pickup', 'Drop', 'Payment', 'GST (INR)', 'Total (INR)']
          .map(cell)
          .join(','),
      for (final trip in trips)
        [
          trip.completedAt.toIso8601String().substring(0, 10),
          trip.bookingId,
          trip.pickup,
          trip.drop,
          trip.paymentMethod,
          trip.gst.toStringAsFixed(2),
          trip.total.toStringAsFixed(2),
        ].map(cell).join(','),
    ];
    return '${lines.join('\n')}\n';
  }
}
