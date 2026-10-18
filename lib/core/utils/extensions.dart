import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get capitalizeWords => split(' ').map((word) => word.capitalize).join(' ');

  bool get isValidPhone => RegExp(r'^[6-9]\d{9}$').hasMatch(this);

  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidOtp => RegExp(r'^\d{4}$').hasMatch(this);

  String get maskPhone => length >= 10 ? '${substring(0, 2)}******${substring(6)}' : this;

  String get maskEmail {
    final parts = split('@');
    if (parts.length != 2) return this;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return this;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  String get initials => split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();
}

extension DateTimeExtensions on DateTime {
  String format({String pattern = 'dd/MM/yyyy'}) => DateFormat(pattern).format(this);

  String formatTime({String pattern = 'HH:mm'}) => DateFormat(pattern).format(this);

  String formatDateTime({String pattern = 'dd/MM/yyyy HH:mm'}) => DateFormat(pattern).format(this);

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return format(pattern: 'dd/MM/yyyy');
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

extension DurationExtensions on Duration {
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedShort {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

extension DoubleExtensions on double {
  String get currencyINR => '₹${toStringAsFixed(0)}';

  String get currencyINRWithDecimals => '₹${toStringAsFixed(2)}';

  String get formattedDistance {
    if (this < 1) {
      return '${(this * 1000).round()}m';
    }
    return '${toStringAsFixed(1)}km';
  }

  double roundTo(int places) {
    final mod = pow(10.0, places);
    return (this * mod).round() / mod;
  }
}

extension IntExtensions on int {
  String get currencyINR => '₹$this';

  String get formattedDistance {
    if (this < 1000) {
      return '${this}m';
    }
    return '${(this / 1000).toStringAsFixed(1)}km';
  }
}

extension NumExtensions on num {
  String get currencyINR => '₹${toStringAsFixed(0)}';

  String get currencyINRWithDecimals => '₹${toStringAsFixed(2)}';
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
  NavigatorState get navigator => Navigator.of(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  void hideKeyboard() => FocusScope.of(this).unfocus();

  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension ListExtensions<T> on List<T> {
  List<T> get distinctById => [
        for (final item in this)
          if (!any((e) => e == item)) item
      ];

  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<List<T>> chunk(int size) {
    if (size <= 0) return [];
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  V? getOrDefault(K key, V? defaultValue) => containsKey(key) ? this[key] : defaultValue;
}

extension GeoExtensions on double {
  double get toRadians => this * pi / 180;
  double get toDegrees => this * 180 / pi;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0; // meters
  final dLat = (lat2 - lat1).toRadians;
  final dLon = (lon2 - lon1).toRadians;

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1.toRadians) * cos(lat2.toRadians) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

String getGeohash(double latitude, double longitude, {int precision = 7}) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  double minLat = -90, maxLat = 90;
  double minLon = -180, maxLon = 180;
  int bit = 0;
  int ch = 0;
  bool evenBit = true;
  final geohash = StringBuffer();

  while (geohash.length < precision) {
    if (evenBit) {
      final mid = (minLon + maxLon) / 2;
      if (longitude >= mid) {
        ch = (ch << 1) | 1;
        minLon = mid;
      } else {
        ch = (ch << 1) | 0;
        maxLon = mid;
      }
    } else {
      final mid = (minLat + maxLat) / 2;
      if (latitude >= mid) {
        ch = (ch << 1) | 1;
        minLat = mid;
      } else {
        ch = (ch << 1) | 0;
        maxLat = mid;
      }
    }

    evenBit = !evenBit;
    bit++;
    if (bit == 5) {
      geohash.write(base32[ch]);
      bit = 0;
      ch = 0;
    }
  }

  return geohash.toString();
}