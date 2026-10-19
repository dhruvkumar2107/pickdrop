import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverReliabilityModel {
  final String driverId;
  final double acceptanceRate; // e.g. 96.5%
  final double cancellationRate; // e.g. 1.2%
  final double onTimeRate; // e.g. 98.0%
  final double rating; // e.g. 4.9
  final int totalTrips;
  final bool isFakeGpsDetected;
  final bool isTemporarilyLocked;
  final DateTime lastUpdated;

  const DriverReliabilityModel({
    required this.driverId,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.onTimeRate,
    required this.rating,
    required this.totalTrips,
    this.isFakeGpsDetected = false,
    this.isTemporarilyLocked = false,
    required this.lastUpdated,
  });

  /// Composite score (0 - 100) used for high-priority matching
  double get compositeScore {
    if (isTemporarilyLocked || isFakeGpsDetected) return 0.0;
    final ratingFactor = (rating / 5.0) * 40; // up to 40 pts
    final acceptanceFactor = (acceptanceRate / 100.0) * 30; // up to 30 pts
    final onTimeFactor = (onTimeRate / 100.0) * 20; // up to 20 pts
    final cancelPenalty = (cancellationRate / 100.0) * 50; // penalty
    return (ratingFactor + acceptanceFactor + onTimeFactor - cancelPenalty).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'acceptanceRate': acceptanceRate,
      'cancellationRate': cancellationRate,
      'onTimeRate': onTimeRate,
      'rating': rating,
      'totalTrips': totalTrips,
      'isFakeGpsDetected': isFakeGpsDetected,
      'isTemporarilyLocked': isTemporarilyLocked,
      'compositeScore': compositeScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory DriverReliabilityModel.fromMap(Map<String, dynamic> data) {
    return DriverReliabilityModel(
      driverId: data['driverId'] ?? '',
      acceptanceRate: (data['acceptanceRate'] as num?)?.toDouble() ?? 95.0,
      cancellationRate: (data['cancellationRate'] as num?)?.toDouble() ?? 2.0,
      onTimeRate: (data['onTimeRate'] as num?)?.toDouble() ?? 96.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      totalTrips: (data['totalTrips'] as num?)?.toInt() ?? 50,
      isFakeGpsDetected: data['isFakeGpsDetected'] ?? false,
      isTemporarilyLocked: data['isTemporarilyLocked'] ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class DriverMatchingService {
  /// Validates distance <= 3km and rejects Mock GPS.
  bool validateDriverGps({
    required double driverLat,
    required double driverLng,
    required double pickupLat,
    required double pickupLng,
    required bool isMockLocation,
  }) {
    if (isMockLocation) return false;
    return _calculateDistanceKm(driverLat, driverLng, pickupLat, pickupLng) <= 3.0;
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }
}
