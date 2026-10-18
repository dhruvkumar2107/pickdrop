import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineActionQueue {
  OfflineActionQueue._();

  static const String storageKey = 'driver_action_queue';

  static const String acceptTrip = 'ACCEPT_TRIP';

  static const String locationPing = 'LOCATION_PING';

  static const String statusUpdate = 'STATUS_UPDATE';

  static final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  static int get pendingCount => pendingCountNotifier.value;

  static Future<void> refresh() async {
    final items = await _read();
    pendingCountNotifier.value = items.length;
  }

  static Future<void> enqueue(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final items = await _read();
    items.add(<String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': type,
      'payload': payload,
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _write(items);
    pendingCountNotifier.value = items.length;
  }

  static Future<void> flush(FirebaseFirestore firestore) async {
    final items = await _read();
    if (items.isEmpty) {
      pendingCountNotifier.value = 0;
      return;
    }
    final remaining = <Map<String, dynamic>>[];
    var stalled = false;
    for (final item in items) {
      if (stalled) {
        remaining.add(item);
        continue;
      }
      try {
        await _execute(item, firestore);
      } catch (_) {
        stalled = true;
        item['attempts'] = ((item['attempts'] as num?) ?? 0).toInt() + 1;
        remaining.add(item);
      }
    }
    await _write(remaining);
    pendingCountNotifier.value = remaining.length;
  }

  static Future<void> _execute(
    Map<String, dynamic> item,
    FirebaseFirestore firestore,
  ) async {
    final type = item['type'];
    final payload = item['payload'];
    if (payload is! Map) return;
    final data = <String, dynamic>{};
    for (final entry in payload.entries) {
      final key = entry.key;
      if (key is String) data[key] = entry.value;
    }
    switch (type) {
      case acceptTrip:
        final bookingId = data['bookingId'];
        if (bookingId is! String || bookingId.isEmpty) return;
        final driverId = data['driverId'];
        final uid = driverId is String && driverId.isNotEmpty
            ? driverId
            : FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) return;
        await firestore
            .collection('bookings')
            .doc(bookingId)
            .set(<String, dynamic>{
              'driverId': uid,
              'status': 'DRIVER_ASSIGNED',
              'acceptedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      case locationPing:
        final driverId = data['driverId'];
        final lat = data['lat'];
        final lng = data['lng'];
        if (driverId is! String || driverId.isEmpty) return;
        if (lat is! num || lng is! num) return;
        await firestore
            .collection('drivers')
            .doc(driverId)
            .set(<String, dynamic>{
              'currentLocation': GeoPoint(lat.toDouble(), lng.toDouble()),
              if (data['geohash'] is String) 'geohash': data['geohash'],
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      case statusUpdate:
        final bookingId = data['bookingId'];
        if (bookingId is! String || bookingId.isEmpty) return;
        await firestore
            .collection('bookings')
            .doc(bookingId)
            .set(<String, dynamic>{
              if (data['status'] is String) 'status': data['status'],
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      default:
        return;
    }
  }

  static Future<List<Map<String, dynamic>>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _write(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(items));
    } catch (_) {
      return;
    }
  }
}
