import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectivity(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((r) => r != ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectivity(result);
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

// Riverpod provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isConnected;
});