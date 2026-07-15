import 'dart:convert';
import '../services/database_service.dart';

class GamificationLogic {
  static Future<void> processTripForGamification(
    String userId,
    Map<String, dynamic> tripData,
  ) async {
    // 1. Fetch current stats
    var stats = await DatabaseService.instance.getUserStats(userId);
    int level = stats?['level'] as int? ?? 1;
    double totalSafeKm = (stats?['totalSafeKm'] as num?)?.toDouble() ?? 0.0;
    List<String> badges = [];
    if (stats != null && stats['badges'] != null) {
      badges = List<String>.from(jsonDecode(stats['badges'] as String));
    }

    // 2. Parse trip data
    bool isSafeTrip = tripData['status'].toString().toLowerCase().contains(
      'safe',
    );
    double tripDist =
        double.tryParse(
          tripData['distance'].toString().replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    int tripScore = tripData['score'] as int? ?? 100;

    // 3. Update logic
    if (isSafeTrip) {
      totalSafeKm += tripDist;
    }

    // Evaluate Level (Every 50 safe km = 1 level, max out at 50, but let's just let it scale)
    int newLevel = (totalSafeKm / 50).floor() + 1;
    if (newLevel > level) level = newLevel;

    // Evaluate Badges
    if (isSafeTrip && !badges.contains("First Safe Trip")) {
      badges.add("First Safe Trip");
    }

    if (tripScore == 100 && tripDist >= 10 && !badges.contains("Perfect 10")) {
      badges.add("Perfect 10");
    }

    if (totalSafeKm > 500 && !badges.contains("Marathoner")) {
      badges.add("Marathoner");
    }

    final startTimeStr = tripData['startTime'].toString();
    if (isSafeTrip &&
        tripDist >= 5 &&
        (startTimeStr.contains("AM") &&
            (startTimeStr.startsWith("12") ||
                startTimeStr.startsWith("01") ||
                startTimeStr.startsWith("02") ||
                startTimeStr.startsWith("03") ||
                startTimeStr.startsWith("04"))) &&
        !badges.contains("Night Owl")) {
      badges.add("Night Owl");
    }

    // 4. Save
    await DatabaseService.instance.updateUserStats(
      userId,
      level,
      totalSafeKm,
      badges,
    );
  }
}
