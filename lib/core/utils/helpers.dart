import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';

class AppHelpers {
  static String generateBookingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(10000).toString().padLeft(4, '0');
    return 'PKD$timestamp$random'.substring(0, 16).toUpperCase();
  }

  static String generateOtp({int length = 4}) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91 $cleaned';
    }
    return phone;
  }

  static String formatCurrency(double amount, {bool withDecimals = false}) {
    if (withDecimals) {
      return '₹${amount.toStringAsFixed(2)}';
    }
    return '₹${amount.round()}';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}min';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return formatDate(dateTime);
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double calculateFare({
    required double baseFare,
    required double perKmRate,
    required double perMinuteRate,
    required double distanceKm,
    required int durationMinutes,
    double surgeMultiplier = 1.0,
    double minimumFare = 0,
    double gstPercent = 5.0,
  }) {
    final distanceFare = distanceKm * perKmRate;
    final timeFare = durationMinutes * perMinuteRate;
    final subtotal = (baseFare + distanceFare + timeFare) * surgeMultiplier;
    final gst = subtotal * (gstPercent / 100);
    final total = subtotal + gst;

    return max(total, minimumFare);
  }

  static Map<String, dynamic> getFareBreakdown({
    required double baseFare,
    required double perKmRate,
    required double perMinuteRate,
    required double distanceKm,
    required int durationMinutes,
    double surgeMultiplier = 1.0,
    double minimumFare = 0,
    double gstPercent = 5.0,
    double discount = 0,
  }) {
    final distanceFare = distanceKm * perKmRate;
    final timeFare = durationMinutes * perMinuteRate;
    final subtotalBeforeSurge = baseFare + distanceFare + timeFare;
    final surgeAmount = subtotalBeforeSurge * (surgeMultiplier - 1);
    final subtotal = subtotalBeforeSurge * surgeMultiplier;
    final gst = (subtotal - discount) * (gstPercent / 100);
    var total = subtotal - discount + gst;

    if (total < minimumFare) {
      total = minimumFare;
    }

    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeMultiplier': surgeMultiplier,
      'surgeAmount': surgeAmount,
      'subtotal': subtotal,
      'discount': discount,
      'gst': gst,
      'gstPercent': gstPercent,
      'total': total,
      'minimumFare': minimumFare,
    };
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openMaps(double lat, double lng, {String? label}) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng${label != null ? '&query_place_id=$label' : ''}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openGoogleMapsNavigation(double lat, double lng) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> shareText(String text, {String? subject}) async {
    // Use share_plus package
  }

  static void copyToClipboard(String text, {String? label}) {
    Clipboard.setData(ClipboardData(text: text));
  }

  static bool isValidVehicleNumber(String vehicleNumber) {
    // Indian vehicle number format: XX##XX#### or XX##X####
    final regex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    return regex.hasMatch(vehicleNumber.toUpperCase().replaceAll(' ', ''));
  }

  static String formatVehicleNumber(String vehicleNumber) {
    final cleaned = vehicleNumber.toUpperCase().replaceAll(' ', '');
    if (cleaned.length >= 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6)}';
    }
    return vehicleNumber;
  }

  static String getVehicleTypeIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'two wheeler':
        return 'assets/icons/ic_bike.svg';
      case '3-wheeler':
      case 'tata ace':
      case '3wheeler':
        return 'assets/icons/ic_three_wheeler.svg';
      case 'mini truck':
      case 'mini truck 8ft':
        return 'assets/icons/ic_mini_truck.svg';
      case 'pickup':
      case 'pickup 9ft':
        return 'assets/icons/ic_pickup.svg';
      default:
        return 'assets/icons/ic_mini_truck.svg';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SEARCHING':
        return AppColors.info;
      case 'DRIVER_ASSIGNED':
        return AppColors.primary;
      case 'ARRIVED':
        return AppColors.warning;
      case 'PICKED_UP':
        return AppColors.primary;
      case 'IN_TRANSIT':
        return AppColors.info;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'NO_DRIVER_FOUND':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SEARCHING':
        return 'Finding Driver';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'ARRIVED':
        return 'Driver Arrived';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'NO_DRIVER_FOUND':
        return 'No Driver Found';
      default:
        return status;
    }
  }

  static String getVehicleCapacityLabel(int capacityKg) {
    if (capacityKg >= 1000) {
      return '${(capacityKg / 1000).toStringAsFixed(1)} ton';
    }
    return '$capacityKg kg';
  }

  static Future<void> vibrate({Duration duration = const Duration(milliseconds: 100)}) async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> vibrateHeavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> vibrateLight() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> vibrateSelection() async {
    await HapticFeedback.selectionClick();
  }

  static double calculateCommission(double amount, double commissionPercent) {
    return amount * (commissionPercent / 100);
  }

  static double calculateNetEarnings(double grossAmount, double commissionPercent) {
    return grossAmount - calculateCommission(grossAmount, commissionPercent);
  }

  static String generateReferralCode(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return 'PKD${cleaned.substring(cleaned.length - 6)}'.toUpperCase();
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void cancel() {
    _timer?.cancel();
  }
}

class Throttler {
  final Duration delay;
  DateTime? _lastRun;

  Throttler({required this.delay});

  void call(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= delay) {
      _lastRun = now;
      callback();
    }
  }
}