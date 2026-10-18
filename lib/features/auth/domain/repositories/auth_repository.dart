import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> sendOtp(String phoneNumber);
  Future<Either<Failure, UserEntity>> verifyOtp(
    String verificationId,
    String phoneNumber,
    String otp,
  );
  Future<Either<Failure, UserEntity>> createProfile({
    required String uid,
    required String phoneNumber,
    required String displayName,
    String? email,
    String? photoUrl,
    required String role,
  });
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    EmergencyContact? emergencyContact,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> deleteAccount();
  Stream<UserEntity?> get authStateChanges;
}

abstract class DriverRepository {
  Future<Either<Failure, DriverEntity>> createDriverProfile({
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
  Future<Either<Failure, DriverEntity>> getDriverProfile(String userId);
  Future<Either<Failure, DriverEntity>> updateDriverProfile({
    String? vehicleTypeId,
    String? vehicleNumber,
    String? vehicleModel,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? geohash,
    String? fcmToken,
  });
  Future<Either<Failure, void>> updateLocation(double lat, double lng, String geohash);
  Future<Either<Failure, void>> setOnlineStatus(bool isOnline);
  Future<Either<Failure, List<VehicleTypeEntity>>> getVehicleTypes();
  Future<Either<Failure, DriverEntity>> getDriverById(String driverId);
}

abstract class UserRepository {
  Future<Either<Failure, UserEntity>> getUser(String uid);
  Future<Either<Failure, void>> updateFcmToken(String uid, String token);
  Future<Either<Failure, void>> updateEmergencyContact(String uid, EmergencyContact contact);
}