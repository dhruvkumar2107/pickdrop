import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledBookingModel {
  static const String statusScheduled = 'SCHEDULED';
  static const String statusDriverAssigned = 'DRIVER_ASSIGNED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusCompleted = 'COMPLETED';

  final String id;
  final String customerId;
  final DateTime scheduledAt;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropLat;
  final double dropLng;
  final String dropAddress;
  final List<Map<String, dynamic>> intermediateStops;
  final String vehicleType;
  final String goodsType;
  final double estimatedFare;
  final String status;
  final String assignedDriverId;
  final DateTime createdAt;

  const ScheduledBookingModel({
    required this.id,
    required this.customerId,
    required this.scheduledAt,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLng,
    required this.dropAddress,
    this.intermediateStops = const [],
    required this.vehicleType,
    required this.goodsType,
    required this.estimatedFare,
    this.status = statusScheduled,
    this.assignedDriverId = '',
    required this.createdAt,
  });

  bool get isClosed => status == statusCancelled || status == statusCompleted;

  bool get isUpcoming => !isClosed && scheduledAt.isAfter(DateTime.now());

  bool get isPast => isClosed || scheduledAt.isBefore(DateTime.now());

  ScheduledBookingModel copyWith({
    String? status,
    String? assignedDriverId,
    DateTime? scheduledAt,
    double? estimatedFare,
  }) {
    return ScheduledBookingModel(
      id: id,
      customerId: customerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropLat: dropLat,
      dropLng: dropLng,
      dropAddress: dropAddress,
      intermediateStops: intermediateStops,
      vehicleType: vehicleType,
      goodsType: goodsType,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupAddress': pickupAddress,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'dropAddress': dropAddress,
      'intermediateStops': intermediateStops,
      'vehicleType': vehicleType,
      'goodsType': goodsType,
      'estimatedFare': estimatedFare,
      'status': status,
      'assignedDriverId': assignedDriverId,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignmentPromise': 'Driver matching starts 30 minutes before scheduled time',
    };
  }

  factory ScheduledBookingModel.fromJson(Map<String, dynamic> json) {
    return ScheduledBookingModel(
      id: json['id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      scheduledAt: _readDate(json['scheduledAt']) ?? DateTime.now(),
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0,
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropLat: (json['dropLat'] as num?)?.toDouble() ?? 0,
      dropLng: (json['dropLng'] as num?)?.toDouble() ?? 0,
      dropAddress: json['dropAddress'] as String? ?? '',
      intermediateStops: (json['intermediateStops'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((stop) => Map<String, dynamic>.from(stop))
          .toList(),
      vehicleType: json['vehicleType'] as String? ?? '',
      goodsType: json['goodsType'] as String? ?? '',
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? statusScheduled,
      assignedDriverId: json['assignedDriverId'] as String? ?? '',
      createdAt: _readDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  factory ScheduledBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScheduledBookingModel.fromJson({...data, 'id': doc.id});
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
