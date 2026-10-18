import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/extensions.dart';
import '../models/user_model.dart';

abstract class DriverRemoteDataSource {
  Future<DriverModel> createDriverProfile({
    required String userId,
    required String vehicleTypeId,
    required String vehicleNumber,
    String? vehicleModel,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String rcNumber,
    required DateTime rcExpiry,
    required String aadhaarNumber,
    required String aadhaarFrontUrl,
    required String aadhaarBackUrl,
    required String photoUrl,
  });
  Future<DriverModel?> getDriverProfile(String userId);
  Future<DriverModel> updateDriverProfile({
    required String driverId,
    String? vehicleTypeId,
    String? vehicleNumber,
    String? vehicleModel,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? geohash,
    String? fcmToken,
  });
  Future<void> updateLocation(String driverId, double lat, double lng);
  Future<void> setOnlineStatus(String driverId, bool isOnline);
  Future<List<VehicleTypeModel>> getVehicleTypes();
  Future<DriverModel?> getDriverById(String driverId);
  Stream<DriverModel?> watchDriverProfile(String userId);
  Stream<List<DriverModel>> watchNearbyDrivers({
    required String vehicleTypeId,
    required double lat,
    required double lng,
    required double radiusKm,
  });
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final FirebaseFirestore _firestore;

  DriverRemoteDataSourceImpl(this._firestore);

  @override
  Future<DriverModel> createDriverProfile({
    required String userId,
    required String vehicleTypeId,
    required String vehicleNumber,
    String? vehicleModel,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String rcNumber,
    required DateTime rcExpiry,
    required String aadhaarNumber,
    required String aadhaarFrontUrl,
    required String aadhaarBackUrl,
    required String photoUrl,
  }) async {
    final now = DateTime.now();
    final geohash = getGeohash(0, 0, precision: 7); // Will be updated when location is available

    final driverModel = DriverModel(
      uid: userId, // Using userId as driver document ID
      userId: userId,
      vehicleTypeId: vehicleTypeId,
      vehicleNumber: vehicleNumber.toUpperCase().replaceAll(' ', ''),
      vehicleModel: vehicleModel,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      rcNumber: rcNumber,
      rcExpiry: rcExpiry,
      aadhaarNumber: aadhaarNumber,
      aadhaarFrontUrl: aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl,
      photoUrl: photoUrl,
      isOnline: false,
      isVerified: false,
      currentLat: 0,
      currentLng: 0,
      geohash: geohash,
      rating: 0.0,
      totalTrips: 0,
      totalEarnings: 0,
      todayEarnings: 0,
      weekEarnings: 0,
      monthEarnings: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('drivers').doc(userId).set(driverModel.toJson());
    return driverModel;
  }

  @override
  Future<DriverModel?> getDriverProfile(String userId) async {
    final doc = await _firestore.collection('drivers').doc(userId).get();
    if (doc.exists) {
      return DriverModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<DriverModel> updateDriverProfile({
    required String driverId,
    String? vehicleTypeId,
    String? vehicleNumber,
    String? vehicleModel,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? geohash,
    String? fcmToken,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (vehicleTypeId != null) updates['vehicleTypeId'] = vehicleTypeId;
    if (vehicleNumber != null) updates['vehicleNumber'] = vehicleNumber.toUpperCase().replaceAll(' ', '');
    if (vehicleModel != null) updates['vehicleModel'] = vehicleModel;
    if (isOnline != null) updates['isOnline'] = isOnline;
    if (currentLat != null) updates['currentLat'] = currentLat;
    if (currentLng != null) updates['currentLng'] = currentLng;
    if (geohash != null) updates['geohash'] = geohash;
    if (fcmToken != null) updates['fcmToken'] = fcmToken;

    await _firestore.collection('drivers').doc(driverId).update(updates);

    final updatedDoc = await _firestore.collection('drivers').doc(driverId).get();
    return DriverModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> updateLocation(String driverId, double lat, double lng) async {
    final geohash = getGeohash(lat, lng, precision: 7);
    await _firestore.collection('drivers').doc(driverId).update({
      'currentLat': lat,
      'currentLng': lng,
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setOnlineStatus(String driverId, bool isOnline) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'isOnline': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes() async {
    final snapshot = await _firestore
        .collection('vehicleTypes')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();

    return snapshot.docs.map((doc) => VehicleTypeModel.fromFirestore(doc)).toList();
  }

  @override
  Future<DriverModel?> getDriverById(String driverId) async {
    final doc = await _firestore.collection('drivers').doc(driverId).get();
    if (doc.exists) {
      return DriverModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Stream<DriverModel?> watchDriverProfile(String userId) {
    return _firestore.collection('drivers').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return DriverModel.fromFirestore(doc);
      }
      return null;
    });
  }

  @override
  Stream<List<DriverModel>> watchNearbyDrivers({
    required String vehicleTypeId,
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    // Geohash-based query for nearby drivers
    // This is a simplified version - production would use geofirestore or similar
    final geohash = getGeohash(lat, lng, precision: 5);

    return _firestore
        .collection('drivers')
        .where('vehicleTypeId', isEqualTo: vehicleTypeId)
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .where('geohash', isGreaterThanOrEqualTo: geohash.substring(0, 5))
        .where('geohash', isLessThanOrEqualTo: '${geohash.substring(0, 5)}z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromFirestore(doc))
            .toList());
  }
}