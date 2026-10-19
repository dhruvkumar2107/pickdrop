import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../shared/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  service.initialize();
  ref.onDispose(() {
    service.stopLocationUpdates();
  });
  return service;
});

final driverOnlineProvider = StateNotifierProvider<DriverOnlineNotifier, bool>((ref) {
  return DriverOnlineNotifier(ref.watch(locationServiceProvider));
});

class DriverOnlineNotifier extends StateNotifier<bool> {
  final LocationService _locationService;

  DriverOnlineNotifier(this._locationService) : super(false);

  Future<void> setOnline(bool online) async {
    if (online == state) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to change driver availability.');

    if (online) {
      try {
        final driverRef = FirebaseFirestore.instance.collection('drivers').doc(uid);
        final profile = await driverRef.get();
        if (!profile.exists || profile.data()?['isVerified'] != true) {
          throw StateError('Driver verification is required before going online.');
        }
        await _locationService.startLocationUpdates();
        await driverRef.update({
          'isOnline': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        state = true;
      } catch (e) {
        await _locationService.stopLocationUpdates();
        throw Exception('Failed to start location updates: $e');
      }
    } else {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'isOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _locationService.stopLocationUpdates();
      state = false;
    }
  }

  Future<void> toggle() async {
    await setOnline(!state);
  }
}
