import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_datasource.dart';
import '../models/user_model.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource _remoteDataSource;

  DriverRepositoryImpl(this._remoteDataSource);

  @override
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
  }) async {
    try {
      final driverModel = await _remoteDataSource.createDriverProfile(
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
      return Right(driverModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverEntity>> getDriverProfile(String userId) async {
    try {
      final driverModel = await _remoteDataSource.getDriverProfile(userId);
      if (driverModel == null) {
        return const Left(UserNotFoundFailure());
      }
      return Right(driverModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverEntity>> updateDriverProfile({
    String? vehicleTypeId,
    String? vehicleNumber,
    String? vehicleModel,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? geohash,
    String? fcmToken,
  }) async {
    try {
      final driverId = _currentUid();

      final driverModel = await _remoteDataSource.updateDriverProfile(
        driverId: driverId,
        vehicleTypeId: vehicleTypeId,
        vehicleNumber: vehicleNumber,
        vehicleModel: vehicleModel,
        isOnline: isOnline,
        currentLat: currentLat,
        currentLng: currentLng,
        geohash: geohash,
        fcmToken: fcmToken,
      );
      return Right(driverModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation(double lat, double lng, String geohash) async {
    try {
      final driverId = _currentUid();
      await _remoteDataSource.updateLocation(driverId, lat, lng);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setOnlineStatus(bool isOnline) async {
    try {
      final driverId = _currentUid();
      await _remoteDataSource.setOnlineStatus(driverId, isOnline);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _currentUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('No authenticated user');
    }
    return uid;
  }

  @override
  Future<Either<Failure, List<VehicleTypeEntity>>> getVehicleTypes() async {
    try {
      final vehicleTypes = await _remoteDataSource.getVehicleTypes();
      return Right(vehicleTypes.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverEntity>> getDriverById(String driverId) async {
    try {
      final driverModel = await _remoteDataSource.getDriverById(driverId);
      if (driverModel == null) {
        return const Left(UserNotFoundFailure());
      }
      return Right(driverModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}