import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String role; // 'customer', 'driver', 'both'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final EmergencyContact? emergencyContact;

  const UserEntity({
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

  bool get isCustomer => role == 'customer' || role == 'both';
  bool get isDriver => role == 'driver' || role == 'both';
  bool get isBoth => role == 'both';

  @override
  List<Object?> get props => [
        uid,
        phoneNumber,
        displayName,
        email,
        photoUrl,
        role,
        createdAt,
        updatedAt,
        fcmToken,
        emergencyContact,
      ];

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    EmergencyContact? emergencyContact,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

class EmergencyContact extends Equatable {
  final String name;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, phone];
}

class DriverEntity extends Equatable {
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

  const DriverEntity({
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

  @override
  List<Object?> get props => [
        uid,
        userId,
        vehicleTypeId,
        vehicleNumber,
        vehicleModel,
        licenseNumber,
        licenseExpiry,
        rcNumber,
        rcExpiry,
        aadhaarNumber,
        aadhaarFrontUrl,
        aadhaarBackUrl,
        photoUrl,
        isOnline,
        isVerified,
        currentLat,
        currentLng,
        geohash,
        rating,
        totalTrips,
        totalEarnings,
        todayEarnings,
        weekEarnings,
        monthEarnings,
        fcmToken,
        createdAt,
        updatedAt,
      ];
}

class VehicleTypeEntity extends Equatable {
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

  const VehicleTypeEntity({
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

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        capacityKg,
        baseFare,
        perKmRate,
        perMinuteRate,
        minimumFare,
        surgeMultiplier,
        isActive,
        sortOrder,
        createdAt,
      ];
}