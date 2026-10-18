import 'package:cloud_firestore/cloud_firestore.dart';

class DriverCommissionService {
  DriverCommissionService._();

  static double defaultRate = 0.10;

  static const int freeTrips = 20;

  static bool _configLoaded = false;

  static bool isNewDriver(int completedTrips) => completedTrips < freeTrips;

  static Future<void> loadConfig({FirebaseFirestore? firestore}) async {
    if (_configLoaded) return;
    try {
      final snapshot = await (firestore ?? FirebaseFirestore.instance)
          .collection('config')
          .doc('commission')
          .get();
      _configLoaded = true;
      final data = snapshot.data();
      if (data == null) return;
      final raw = (data['rate'] as num?)?.toDouble();
      if (raw == null || raw < 0) return;
      defaultRate = raw > 1 ? raw / 100 : raw;
    } catch (_) {
      _configLoaded = false;
    }
  }

  static double commissionFor({
    required double fare,
    required int completedTrips,
  }) {
    if (completedTrips < freeTrips) return 0;
    return double.parse((fare * defaultRate).toStringAsFixed(2));
  }

  static Map<String, dynamic> breakdown({
    required double fare,
    required int completedTrips,
    double tip = 0,
  }) {
    final gross = fare + tip;
    final commission =
        commissionFor(fare: gross, completedTrips: completedTrips);
    final freeTier = isNewDriver(completedTrips);
    return <String, dynamic>{
      'gross': gross,
      'commission': commission,
      'net': gross - commission,
      'rate': freeTier ? 0.0 : defaultRate,
      'isFreeTier': freeTier,
      'completedTrips': completedTrips,
      'freeTripsRemaining': freeTier ? freeTrips - completedTrips : 0,
    };
  }
}
