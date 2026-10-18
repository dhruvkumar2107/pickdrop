class VehicleType {
  final String id;
  final String name;
  final String icon;
  final int capacityKg;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final double surgeMultiplier;

  const VehicleType({
    required this.id,
    required this.name,
    required this.icon,
    required this.capacityKg,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.surgeMultiplier,
  });

  factory VehicleType.fromFirestore(String id, Map<String, dynamic> data) {
    double asDouble(Object? value, double fallback) =>
        (value as num?)?.toDouble() ?? fallback;
    return VehicleType(
      id: id,
      name: data['name'] as String? ?? id,
      icon: data['icon'] as String? ?? 'assets/icons/ic_bike.svg',
      capacityKg: (data['capacityKg'] as num?)?.toInt() ?? 0,
      baseFare: asDouble(data['baseFare'], 0),
      perKmRate: asDouble(data['perKmRate'], 0),
      perMinuteRate: asDouble(data['perMinuteRate'], 0),
      minimumFare: asDouble(data['minimumFare'], 0),
      surgeMultiplier: asDouble(data['surgeMultiplier'], 1.0),
    );
  }

  /// Fallback catalog used only when Firestore has no active vehicle types
  /// (e.g. the collection has not been seeded yet). Prices here are never
  /// authoritative — the server recomputes fare at booking time.
  static const List<VehicleType> defaults = [
    VehicleType(
      id: 'bike',
      name: 'Bike',
      icon: 'assets/icons/ic_bike.svg',
      capacityKg: 20,
      baseFare: 30,
      perKmRate: 12,
      perMinuteRate: 1.5,
      minimumFare: 40,
      surgeMultiplier: 1.0,
    ),
    VehicleType(
      id: 'three_wheeler',
      name: '3-Wheeler / Tata Ace',
      icon: 'assets/icons/ic_three_wheeler.svg',
      capacityKg: 750,
      baseFare: 80,
      perKmRate: 22,
      perMinuteRate: 3,
      minimumFare: 120,
      surgeMultiplier: 1.0,
    ),
    VehicleType(
      id: 'mini_truck',
      name: 'Mini Truck 8ft',
      icon: 'assets/icons/ic_mini_truck.svg',
      capacityKg: 1250,
      baseFare: 150,
      perKmRate: 35,
      perMinuteRate: 5,
      minimumFare: 250,
      surgeMultiplier: 1.0,
    ),
    VehicleType(
      id: 'pickup',
      name: 'Pickup 9ft',
      icon: 'assets/icons/ic_pickup.svg',
      capacityKg: 1500,
      baseFare: 200,
      perKmRate: 45,
      perMinuteRate: 6,
      minimumFare: 350,
      surgeMultiplier: 1.0,
    ),
  ];
}