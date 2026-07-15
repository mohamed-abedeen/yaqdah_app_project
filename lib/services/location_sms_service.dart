import 'package:flutter/foundation.dart';
import 'package:flutter_background_messenger/flutter_background_messenger.dart';
import 'package:geolocator/geolocator.dart';

class LocationSmsService {
  static final LocationSmsService instance = LocationSmsService._internal();
  factory LocationSmsService() => instance;
  LocationSmsService._internal();

  final FlutterBackgroundMessenger _messenger = FlutterBackgroundMessenger();

  Future<void> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    String finalMessage = message;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final link =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      finalMessage = "$message\n\nLocation: $link";
    } catch (e) {
      assert(() {
        debugPrint('LocationSmsService: Failed to get location: $e');
        return true;
      }());
    }

    try {
      await _messenger.sendSMS(phoneNumber: phoneNumber, message: finalMessage);
    } catch (e) {
      assert(() {
        debugPrint('LocationSmsService: Failed to send SMS: $e');
        return true;
      }());
    }
  }
}
