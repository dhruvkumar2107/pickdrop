import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final EmergencyContactModel? emergencyContact;

  const UserModel({
    required this.uid,
    required this.phoneNumber,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.emergencyContact,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'customer',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      fcmToken: json['fcmToken'] as String?,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContactModel.fromJson(json['emergencyContact'] as Map<String, dynamic>)
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromJson({
      ...data,
      'uid': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (emergencyContact != null) 'emergencyContact': emergencyContact!.toJson(),
    };
  }
}

class EmergencyContactModel {
  final String name;
  final String phone;

  const EmergencyContactModel({
    required this.name,
    required this.phone,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

extension UserModelX on UserModel {
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fcmToken: fcmToken,
      emergencyContact: emergencyContact?.toEntity(),
    );
  }
}

extension EmergencyContactModelX on EmergencyContactModel {
  EmergencyContact toEntity() {
    return EmergencyContact(name: name, phone: phone);
  }
}

class DriverModel {
  final String uid;
  final String userId;
  final String vehicleTypeId;
  final String vehicleNumber;
  final String? vehicleModel;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String rcNumber;
  final DateTime rcExpiry;
  final String aadhaarNumber;
  final String aadhaarFrontUrl;
  final String aadhaarBackUrl;
  final String photoUrl;
  final bool isOnline;
  final bool isVerified;
  final double currentLat;
  final double currentLng;
  final String geohash;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverModel({
    required this.uid,
    required this.userId,
    required this.vehicleTypeId,
    required this.vehicleNumber,
    this.vehicleModel,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.rcNumber,
    required this.rcExpiry,
    required this.aadhaarNumber,
    required this.aadhaarFrontUrl,
    required this.aadhaarBackUrl,
    required this.photoUrl,
    required this.isOnline,
    required this.isVerified,
    required this.currentLat,
    required this.currentLng,
    required this.geohash,
    required this.rating,
    required this.totalTrips,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      uid: json['uid'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      vehicleTypeId: json['vehicleTypeId'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      vehicleModel: json['vehicleModel'] as String?,
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseExpiry: json['licenseExpiry'] is Timestamp
          ? (json['licenseExpiry'] as Timestamp).toDate()
          : DateTime.now(),
      rcNumber: json['rcNumber'] as String? ?? '',
      rcExpiry: json['rcExpiry'] is Timestamp
          ? (json['rcExpiry'] as Timestamp).toDate()
          : DateTime.now(),
      aadhaarNumber: json['aadhaarNumber'] as String? ?? '',
      aadhaarFrontUrl: json['aadhaarFrontUrl'] as String? ?? '',
      aadhaarBackUrl: json['aadhaarBackUrl'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      currentLat: (json['currentLat'] as num?)?.toDouble() ?? 0.0,
      currentLng: (json['currentLng'] as num?)?.toDouble() ?? 0.0,
      geohash: json['geohash'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      weekEarnings: (json['weekEarnings'] as num?)?.toDouble() ?? 0.0,
      monthEarnings: (json['monthEarnings'] as num?)?.toDouble() ?? 0.0,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DriverModel.fromJson({
      ...data,
      'uid': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userId': userId,
      'vehicleTypeId': vehicleTypeId,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'licenseNumber': licenseNumber,
      'licenseExpiry': Timestamp.fromDate(licenseExpiry),
      'rcNumber': rcNumber,
      'rcExpiry': Timestamp.fromDate(rcExpiry),
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'geohash': geohash,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'todayEarnings': todayEarnings,
      'weekEarnings': weekEarnings,
      'monthEarnings': monthEarnings,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

extension DriverModelX on DriverModel {
  DriverEntity toEntity() {
    return DriverEntity(
      uid: uid,
      userId: userId,
      vehicleTypeId: vehicleTypeId,
      vehicleNumber: vehicleNumber,
      vehicleModel: vehicleModel,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      rcNumber: rcNumber,
      rcExpiry: rcExpiry,
      aadhaarNumber: aadhaarNumber,
      aadhaarFrontUrl: aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl,
      photoUrl: photoUrl,
      isOnline: isOnline,
      isVerified: isVerified,
      currentLat: currentLat,
      currentLng: currentLng,
      geohash: geohash,
      rating: rating,
      totalTrips: totalTrips,
      totalEarnings: totalEarnings,
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      monthEarnings: monthEarnings,
      fcmToken: fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class VehicleTypeModel {
  final String id;
  final String name;
  final String icon;
  final int capacityKg;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final double surgeMultiplier;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const VehicleTypeModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.capacityKg,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.surgeMultiplier,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      capacityKg: (json['capacityKg'] as num?)?.toInt() ?? 0,
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      perMinuteRate: (json['perMinuteRate'] as num?)?.toDouble() ?? 0.0,
      minimumFare: (json['minimumFare'] as num?)?.toDouble() ?? 0.0,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory VehicleTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return VehicleTypeModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'capacityKg': capacityKg,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'minimumFare': minimumFare,
      'surgeMultiplier': surgeMultiplier,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

extension VehicleTypeModelX on VehicleTypeModel {
  VehicleTypeEntity toEntity() {
    return VehicleTypeEntity(
      id: id,
      name: name,
      icon: icon,
      capacityKg: capacityKg,
      baseFare: baseFare,
      perKmRate: perKmRate,
      perMinuteRate: perMinuteRate,
      minimumFare: minimumFare,
      surgeMultiplier: surgeMultiplier,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}