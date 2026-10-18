import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> getUser(String uid) async {
    try {
      final userModel = await _remoteDataSource.getUserProfile(uid);
      if (userModel == null) {
        return const Left(UserNotFoundFailure());
      }
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken(String uid, String token) async {
    try {
      await _remoteDataSource.updateFcmToken(uid, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmergencyContact(String uid, EmergencyContact contact) async {
    try {
      await _remoteDataSource.updateUserProfile(
        uid: uid,
        emergencyContact: EmergencyContactModel(name: contact.name, phone: contact.phone),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}