import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, String>> call(String phoneNumber) {
    return repository.sendOtp(phoneNumber);
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(
    String verificationId,
    String phoneNumber,
    String otp,
  ) {
    return repository.verifyOtp(verificationId, phoneNumber, otp);
  }
}

class CreateProfileUseCase {
  final AuthRepository repository;

  CreateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String uid,
    required String phoneNumber,
    required String displayName,
    String? email,
    String? photoUrl,
    required String role,
  }) {
    return repository.createProfile(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      role: role,
    );
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() {
    return repository.getCurrentUser();
  }
}

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    EmergencyContact? emergencyContact,
  }) {
    return repository.updateProfile(
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      role: role,
      emergencyContact: emergencyContact,
    );
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}

class CreateDriverProfileUseCase {
  final DriverRepository repository;

  CreateDriverProfileUseCase(this.repository);

  Future<Either<Failure, DriverEntity>> call({
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
  }) {
    return repository.createDriverProfile(
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
    );
  }
}

class GetDriverProfileUseCase {
  final DriverRepository repository;

  GetDriverProfileUseCase(this.repository);

  Future<Either<Failure, DriverEntity>> call(String userId) {
    return repository.getDriverProfile(userId);
  }
}

class UpdateDriverProfileUseCase {
  final DriverRepository repository;

  UpdateDriverProfileUseCase(this.repository);

  Future<Either<Failure, DriverEntity>> call({
    String? vehicleTypeId,
    String? vehicleNumber,
    String? vehicleModel,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? geohash,
    String? fcmToken,
  }) {
    return repository.updateDriverProfile(
      vehicleTypeId: vehicleTypeId,
      vehicleNumber: vehicleNumber,
      vehicleModel: vehicleModel,
      isOnline: isOnline,
      currentLat: currentLat,
      currentLng: currentLng,
      geohash: geohash,
      fcmToken: fcmToken,
    );
  }
}

class UpdateDriverLocationUseCase {
  final DriverRepository repository;

  UpdateDriverLocationUseCase(this.repository);

  Future<Either<Failure, void>> call(double lat, double lng, String geohash) {
    return repository.updateLocation(lat, lng, geohash);
  }
}

class SetDriverOnlineStatusUseCase {
  final DriverRepository repository;

  SetDriverOnlineStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(bool isOnline) {
    return repository.setOnlineStatus(isOnline);
  }
}

class GetVehicleTypesUseCase {
  final DriverRepository repository;

  GetVehicleTypesUseCase(this.repository);

  Future<Either<Failure, List<VehicleTypeEntity>>> call() {
    return repository.getVehicleTypes();
  }
}