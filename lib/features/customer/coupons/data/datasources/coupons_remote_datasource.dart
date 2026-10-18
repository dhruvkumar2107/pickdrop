import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final String type; // 'percentage' | 'flat'
  final double value;
  final double minOrderValue;
  final double? maxDiscount;
  final int usageLimit;
  final int usedCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final List<String>? applicableVehicleTypes;

  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minOrderValue,
    this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.applicableVehicleTypes,
  });

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      type: data['type'] ?? 'flat',
      value: (data['value'] ?? 0).toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0).toDouble(),
      maxDiscount: data['maxDiscount']?.toDouble(),
      usageLimit: data['usageLimit'] ?? 0,
      usedCount: data['usedCount'] ?? 0,
      validFrom: (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      applicableVehicleTypes: (data['applicableVehicleTypes'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
      'applicableVehicleTypes': applicableVehicleTypes,
    };
  }
}

class CouponsRemoteDataSource {
  CouponsRemoteDataSource({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Coupon>> getAvailableCoupons() async {
    final now = Timestamp.now();
    final snapshot = await _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .where('validFrom', isLessThanOrEqualTo: now)
        .where('validUntil', isGreaterThanOrEqualTo: now)
        .get();

    return snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
  }

  Future<Coupon?> validateCoupon({
    required String code,
    required double orderValue,
    String? vehicleTypeId,
  }) async {
    final snapshot = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final coupon = Coupon.fromFirestore(snapshot.docs.first);
    final now = DateTime.now();

    if (!coupon.isActive) return null;
    if (now.isBefore(coupon.validFrom) || now.isAfter(coupon.validUntil)) return null;
    if (coupon.usedCount >= coupon.usageLimit) return null;
    if (orderValue < coupon.minOrderValue) return null;
    if (coupon.applicableVehicleTypes != null &&
        coupon.applicableVehicleTypes!.isNotEmpty &&
        vehicleTypeId != null &&
        !coupon.applicableVehicleTypes!.contains(vehicleTypeId)) {
      return null;
    }

    return coupon;
  }

  double calculateDiscount(Coupon coupon, double orderValue) {
    double discount = 0;
    if (coupon.type == 'percentage') {
      discount = orderValue * coupon.value / 100;
      if (coupon.maxDiscount != null) {
        discount = discount.clamp(0, coupon.maxDiscount!);
      }
    } else {
      discount = coupon.value;
    }
    return discount.clamp(0, orderValue);
  }

  Future<void> applyCoupon(String couponId) async {
    await _firestore.collection('coupons').doc(couponId).update({
      'usedCount': FieldValue.increment(1),
    });
  }
}
