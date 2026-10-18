import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/env/env_config.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> sendOtp(String phoneNumber);
  Future<UserCredential> verifyOtp(String verificationId, String otp);
  Future<UserModel> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String displayName,
    String? email,
    String? photoUrl,
    required String role,
  });
  Future<UserModel?> getUserProfile(String uid);
  Future<UserModel> updateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    EmergencyContactModel? emergencyContact,
  });
  Future<void> updateFcmToken(String uid, String token);
  Future<void> logout();
  Future<void> deleteAccount();
  Stream<User?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  PhoneAuthCredential? _autoRetrievedCredential;

  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
  });

  @override
  Future<String> sendOtp(String phoneNumber) async {
    if (EnvConfig.acceptAnyOtp) {
      // No SMS round-trip: the verification id carries the number and any OTP
      // is accepted on the next screen.
      return 'local-$phoneNumber';
    }

    final formattedPhone = '+91$phoneNumber';
    final completer = Completer<String>();
    await auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (credential) {
        _autoRetrievedCredential = credential;
        // Auto-retrieval (Android) — sign in silently so authStateChanges fires.
        auth.signInWithCredential(credential).ignore();
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(error.message ?? 'Failed to send OTP'));
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    if (verificationId.startsWith('local-')) {
      final phoneNumber = verificationId.substring('local-'.length);
      final credential = await _signInWithAnyOtp(phoneNumber);
      await _ensureUserDoc(uid: credential.user!.uid, phoneNumber: phoneNumber);
      return credential;
    }

    final auto = _autoRetrievedCredential;
    final credential = (auto != null && auto.verificationId == verificationId && auto.smsCode != null)
        ? auto
        : PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: otp,
          );
    final userCredential = await auth.signInWithCredential(credential);
    await _ensureUserDoc(uid: userCredential.user!.uid);
    _autoRetrievedCredential = null;
    return userCredential;
  }

  /// Guarantees a `users/{uid}` document exists right after login so the
  /// authState stream and downstream screens can read a real profile (with the
  /// phone number and a default role) instead of null.
  Future<void> _ensureUserDoc({required String uid, String phoneNumber = ''}) async {
    final ref = firestore.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'phoneNumber': phoneNumber,
        'displayName': null,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (phoneNumber.isNotEmpty &&
        ((snap.data()?['phoneNumber'] as String?) ?? '').isEmpty) {
      await ref.set({
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Signs the given number in with a stable credential so any OTP works and
  /// the same number always lands on the same account.
  Future<UserCredential> _signInWithAnyOtp(String phoneNumber) async {
    final email = '$phoneNumber@pickdrop.app';
    const password = 'PickdropAnyOtp!';

    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return _createAccount(email: email, password: password);
      }
      rethrow;
    }
  }

  Future<UserCredential> _createAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return auth.signInWithEmailAndPassword(email: email, password: password);
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String displayName,
    String? email,
    String? photoUrl,
    required String role,
  }) async {
    final now = DateTime.now();
    final userModel = UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      role: role,
      createdAt: now,
      updatedAt: now,
    );

    await firestore.collection('users').doc(uid).set(userModel.toJson());
    return userModel;
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<UserModel> updateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    EmergencyContactModel? emergencyContact,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (email != null) updates['email'] = email;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (role != null) updates['role'] = role;
    if (emergencyContact != null) updates['emergencyContact'] = emergencyContact.toJson();

    // Upsert so role can be saved before the profile document exists.
    await firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));

    final updatedDoc = await firestore.collection('users').doc(uid).get();
    return UserModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    await firestore.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  @override
  Stream<User?> get authStateChanges => auth.authStateChanges();
}