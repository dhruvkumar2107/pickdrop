import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    if (online) {
      try {
        await _locationService.startLocationUpdates();
        state = true;
      } catch (e) {
        throw Exception('Failed to start location updates: $e');
      }
    } else {
      await _locationService.stopLocationUpdates();
      state = false;
    }
  }

  Future<void> toggle() async {
    await setOnline(!state);
  }
}