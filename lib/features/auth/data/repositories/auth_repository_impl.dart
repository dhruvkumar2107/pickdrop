import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, String>> sendOtp(String phoneNumber) async {
    try {
      final verificationId = await _remoteDataSource.sendOtp(phoneNumber);
      return Right(verificationId);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(
    String verificationId,
    String phoneNumber,
    String otp,
  ) async {
    try {
      final userCredential = await _remoteDataSource.verifyOtp(verificationId, otp);
      final user = userCredential.user;

      if (user == null) {
        return const Left(InvalidOtpFailure());
      }

      final userProfile = await _remoteDataSource.getUserProfile(user.uid);

      if (userProfile != null) {
        return Right(userProfile.toEntity());
      } else {
        // User doesn't have a profile yet, return minimal entity
        return Right(UserEntity(
          uid: user.uid,
          phoneNumber: phoneNumber,
          role: 'customer', // default role
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createProfile({
    required String uid,
    required String phoneNumber,
    required String displayName,
    String? email,
    String? photoUrl,
    required String role,
  }) async {
    try {
      final userModel = await _remoteDataSource.createUserProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        role: role,
      );
      return Right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(UserNotFoundFailure());
      }

      final userProfile = await _remoteDataSource.getUserProfile(user.uid);
      if (userProfile == null) {
        return const Left(UserNotFoundFailure());
      }

      return Right(userProfile.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    EmergencyContact? emergencyContact,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(UserNotFoundFailure());
      }

      final updated = await _remoteDataSource.updateUserProfile(
        uid: user.uid,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        role: role,
        emergencyContact: emergencyContact != null
            ? EmergencyContactModel(name: emergencyContact.name, phone: emergencyContact.phone)
            : null,
      );
      return Right(updated.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      var profile = await _remoteDataSource.getUserProfile(user.uid);
      if (profile == null) {
        // The profile document is created right after sign-in; retry once so
        // the stream doesn't emit a stale null for a freshly logged-in user.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        profile = await _remoteDataSource.getUserProfile(user.uid);
      }
      return profile?.toEntity();
    });
  }

  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return const InvalidPhoneNumberFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'operation-not-allowed':
      case 'admin-disabled-email-signin':
        return const AuthFailure(
          'Sign-in is not enabled for this project yet. '
          'Turn on Email/Password in Firebase Console → Authentication.',
          code: 'operation-not-allowed',
        );
      case 'configuration-not-found':
        return const AuthFailure(
          'Authentication is not set up for this project yet. '
          'Open Firebase Console → Authentication → Get started.',
          code: 'configuration-not-found',
        );
      default:
        return AuthFailure(e.message ?? 'Authentication failed', code: e.code);
    }
  }
}