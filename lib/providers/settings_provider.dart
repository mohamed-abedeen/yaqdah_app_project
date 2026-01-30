import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _autoEmergency = false;
  bool _aiAssistance = true;

  bool get notifications => _notifications;
  bool get sound => _sound;
  bool get vibration => _vibration;
  bool get autoEmergency => _autoEmergency;
  bool get aiAssistance => _aiAssistance;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifications = prefs.getBool('notifications_enabled') ?? true;
    _sound = prefs.getBool('sound_enabled') ?? true;
    _vibration = prefs.getBool('vibration_enabled') ?? true;
    _autoEmergency = prefs.getBool('auto_emergency') ?? false;
    _aiAssistance = prefs.getBool('ai_assistance_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _vibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  Future<void> setAutoEmergency(bool value) async {
    _autoEmergency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_emergency', value);
    notifyListeners();
  }

  Future<void> setAiAssistance(bool value) async {
    _aiAssistance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_assistance_enabled', value);
    notifyListeners();
  }
}
