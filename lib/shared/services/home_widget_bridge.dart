import 'package:shared_preferences/shared_preferences.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const String statusKey = 'pickdrop_widget_status';
  static const String lastFareKey = 'pickdrop_widget_last_fare';
  static const String defaultStatus = 'Your driver is on the way';

  static Future<void> updateStatus(String status, {String? lastFare}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(statusKey, status);
    if (lastFare != null && lastFare.isNotEmpty) {
      await prefs.setString(lastFareKey, lastFare);
    }
  }

  static Future<void> updateLastFare(String lastFare) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastFareKey, lastFare);
  }

  static Future<void> resetStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(statusKey, defaultStatus);
    await prefs.remove(lastFareKey);
  }

  static Future<String> readStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(statusKey) ?? defaultStatus;
  }

  static Future<String?> readLastFare() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastFareKey);
  }
}
