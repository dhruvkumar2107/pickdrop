import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/driver_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final driverRemoteDataSourceProvider = Provider<DriverRemoteDataSource>((ref) {
  return DriverRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepositoryImpl(ref.watch(driverRemoteDataSourceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>((ref) {
  return CreateProfileUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final createDriverProfileUseCaseProvider = Provider<CreateDriverProfileUseCase>((ref) {
  return CreateDriverProfileUseCase(ref.watch(driverRepositoryProvider));
});

final getDriverProfileUseCaseProvider = Provider<GetDriverProfileUseCase>((ref) {
  return GetDriverProfileUseCase(ref.watch(driverRepositoryProvider));
});

final updateDriverProfileUseCaseProvider = Provider<UpdateDriverProfileUseCase>((ref) {
  return UpdateDriverProfileUseCase(ref.watch(driverRepositoryProvider));
});

final updateDriverLocationUseCaseProvider = Provider<UpdateDriverLocationUseCase>((ref) {
  return UpdateDriverLocationUseCase(ref.watch(driverRepositoryProvider));
});

final setDriverOnlineStatusUseCaseProvider = Provider<SetDriverOnlineStatusUseCase>((ref) {
  return SetDriverOnlineStatusUseCase(ref.watch(driverRepositoryProvider));
});

final getVehicleTypesUseCaseProvider = Provider<GetVehicleTypesUseCase>((ref) {
  return GetVehicleTypesUseCase(ref.watch(driverRepositoryProvider));
});

// Auth State
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});