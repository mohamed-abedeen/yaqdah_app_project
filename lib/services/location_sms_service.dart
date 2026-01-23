import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_messenger/flutter_background_messenger.dart';

class LocationSmsService {
  // Remove hardcoded number. We now pass it dynamically.
  final FlutterBackgroundMessenger _messenger = FlutterBackgroundMessenger();

  /// Get current GPS location
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  /// Trigger the Emergency Protocol (Automatic Background Send)
  Future<void> sendEmergencyAlert({required String targetNumber}) async {
    if (targetNumber.isEmpty) {
      if (kDebugMode) print("❌ No emergency number provided.");
      return;
    }

    try {
      // 1. Get Location
      Position? position = await _getCurrentLocation();
      String locationText = "Unknown Location";
      String mapsLink = "";

      if (position != null) {
        locationText = "${position.latitude}, ${position.longitude}";
        // ✅ Google Maps Link
        mapsLink =
            "http://maps.google.com/?q=${position.latitude},${position.longitude}";
      }

      // 2. Create Message
      String message =
          "EMERGENCY: The driver using Yaqdah has fallen asleep! \n"
          "Location: $locationText \n"
          "Map: $mapsLink";

      // 3. Send Automatically in Background
      bool success = await _messenger.sendSMS(
        phoneNumber: targetNumber,
        message: message,
      );

      if (success) {
        if (kDebugMode) print("🚨 Emergency SMS sent to $targetNumber");
      } else {
        if (kDebugMode) print("❌ Failed to send SMS to $targetNumber");
      }
    } catch (e) {
      if (kDebugMode) print("Emergency Service Error: $e");
    }
  }
}
