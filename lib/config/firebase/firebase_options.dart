// Firebase options are supplied only by the owner's local ignored `.env.client` file
// (or generated FlutterFire configuration). Placeholder values are deliberately
// not accepted: they can make a production build appear connected when it is not.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../env/env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!EnvConfig.isFirebaseConfigured ||
        EnvConfig.firebaseAppId.isEmpty ||
        EnvConfig.firebaseMessagingSenderId.isEmpty ||
        EnvConfig.firebaseStorageBucket.isEmpty) {
      throw StateError(
        'Firebase is not configured. Copy .env.example to .env.client and supply a Firebase project.',
      );
    }
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase options are not supported for this platform.',
    );
  }

  static FirebaseOptions get web => _fromEnvironment();
  static FirebaseOptions get android => _fromEnvironment();

  static FirebaseOptions _fromEnvironment() => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    appId: EnvConfig.firebaseAppId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    authDomain: EnvConfig.firebaseAuthDomain,
    storageBucket: EnvConfig.firebaseStorageBucket,
  );
}
