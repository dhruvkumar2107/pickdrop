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
}