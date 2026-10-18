import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsuranceClaimModel {
  final String claimId;
  final String customerId;
  final String bookingId;
  final double amount;
  final String description;
  final List<String> photoUrls;
  final String status;
  final String incidentType;
  final DateTime createdAt;

  const InsuranceClaimModel({
    required this.claimId,
    required this.customerId,
    required this.bookingId,
    required this.amount,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.incidentType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'bookingId': bookingId,
      'amount': amount,
      'description': description,
      'photoUrls': photoUrls,
      'status': status,
      'incidentType': incidentType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory InsuranceClaimModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return InsuranceClaimModel(
      claimId: doc.id,
      customerId: data['customerId'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? const []),
      status: data['status'] as String? ?? 'SUBMITTED',
      incidentType: data['incidentType'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InsuranceClaimRemoteDataSource {
  final FirebaseFirestore _firestore;

  InsuranceClaimRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('insuranceClaims');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String> createClaim({
    required String bookingId,
    required double amount,
    required String description,
    required List<String> photoUrls,
    String incidentType = '',
    String customerId = '',
  }) async {
    final uid = customerId.isNotEmpty ? customerId : _uid;
    final doc = _claims.doc();
    await doc.set({
      'customerId': uid,
      'bookingId': bookingId,
      'amount': amount,
      'description': description,
      'photoUrls': photoUrls,
      'incidentType': incidentType,
      'status': 'SUBMITTED',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<InsuranceClaimModel?> watchClaim(String claimId) {
    return _claims.doc(claimId).snapshots().map(
          (snap) => snap.exists ? InsuranceClaimModel.fromFirestore(snap) : null,
        );
  }

  Future<List<InsuranceClaimModel>> fetchOwnClaims({String? bookingId}) async {
    final snapshot = await _claims.where('customerId', isEqualTo: _uid).get();
    final claims = snapshot.docs.map(InsuranceClaimModel.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (bookingId != null && bookingId.isNotEmpty) {
      return claims.where((c) => c.bookingId == bookingId).toList();
    }
    return claims;
  }
}
