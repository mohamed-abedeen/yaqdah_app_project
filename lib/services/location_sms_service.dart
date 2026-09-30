import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_messenger/flutter_background_messenger.dart';
import 'package:geolocator/geolocator.dart';

class LocationSmsService {
  static final LocationSmsService instance = LocationSmsService._internal();
  factory LocationSmsService() => instance;
  LocationSmsService._internal();

  final FlutterBackgroundMessenger _messenger = FlutterBackgroundMessenger();

  /// Texts [message] to [phoneNumber], then a map link to where the phone
  /// is, labelled [locationLabel].
  ///
  /// They go as two texts: the plugin can only send single-part SMS, and
  /// one Arabic SMS holds just 70 characters. Returns whether the first
  /// one was accepted. The plugin only sends on Android and needs the SMS
  /// permission already granted.
  Future<bool> sendEmergencySms({
    required String phoneNumber,
    required String message,
    String locationLabel = 'Location',
  }) async {
    if (!Platform.isAndroid) return false;
    final position = await _position();
    final sent = await _send(phoneNumber, message);
    if (sent && position != null) {
      final link =
          "https://maps.google.com/?q=${position.latitude.toStringAsFixed(6)},"
          "${position.longitude.toStringAsFixed(6)}";
      await _send(phoneNumber, "$locationLabel: $link");
    }
    return sent;
  }

  Future<bool> _send(String phoneNumber, String message) async {
    try {
      return await _messenger.sendSMS(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      debugPrint('LocationSmsService: Failed to send SMS: $e');
      return false;
    }
  }

  /// A recent fix without waiting when there is one (during a trip there
  /// always is); otherwise a fresh one, given a few seconds at most.
  Future<Position?> _position() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <
              const Duration(minutes: 2)) {
        return last;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('LocationSmsService: Failed to get location: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
