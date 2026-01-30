import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';
import '../services/location_sms_service.dart';

import 'settings_provider.dart';

class MonitoringProvider with ChangeNotifier {
  final AudioService _audio = AudioService();
  final GeminiService _gemini = GeminiService();
  final LocationSmsService _smsService = LocationSmsService();

  SettingsProvider? _settings;

  bool _isMonitoring = false;
  String _status = "IDLE";
  double _drowsinessLevel = 0.0;
  String _aiMessage = "Press Start";
  bool _isListening = false;

  // Dependencies
  String? _emergencyContact;

  bool get isMonitoring => _isMonitoring;
  String get status => _status;
  double get drowsinessLevel => _drowsinessLevel;
  String get aiMessage => _aiMessage;
  bool get isListening => _isListening;

  MonitoringProvider() {
    _audio.init();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    notifyListeners();
  }

  void setEmergencyContact(String contact) {
    _emergencyContact = contact;
  }

  void toggleMonitoring() {
    _isMonitoring = !_isMonitoring;
    if (!_isMonitoring) {
      _audio.stopAll(); // ✅ Stop all audio when monitoring ends (Trip End)
    }
    notifyListeners();
  }

  DateTime _lastAiTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );
  DateTime _lastBeepTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );

  void handleStatusChange(String newStatus) {
    if (!_isMonitoring) return;

    switch (newStatus) {
      case "AWAKE":
      case "SAFE": // Handle SAFE if used
        if (_status != "AWAKE" && _status != "SAFE") {
          _audio.stopAll(); // ✅ Stop all audio immediately when safe
        }
        _drowsinessLevel = 0;
        break;
      case "DISTRACTED":
        _triggerBeep(); // ✅ Trigger alert sound for distraction
        _triggerGemini("DISTRACTED");
        _drowsinessLevel = 45;
        break;
      case "DROWSY":
        _triggerBeep();
        _triggerGemini("DROWSY");
        _drowsinessLevel = 75;
        break;
      case "ASLEEP":
        triggerSOS();
        _drowsinessLevel = 100;
        break;
    }

    _status = newStatus;
    notifyListeners();
  }

  Future<void> _triggerBeep() async {
    // Check Settings: Sound
    if (_settings != null && !_settings!.sound) return;

    if (DateTime.now().difference(_lastBeepTrigger).inSeconds < 3) return;
    _lastBeepTrigger = DateTime.now();
    await _audio.playBeep();
  }

  Future<void> _triggerGemini(String state) async {
    // Check Settings: AI Assistance (Auto Interventions)
    if (_settings != null && !_settings!.aiAssistance) return;

    if (DateTime.now().difference(_lastAiTrigger).inSeconds < 5) return;
    _lastAiTrigger = DateTime.now();

    // Optimistic update
    String msg = await _gemini.getIntervention(state);
    _aiMessage = msg;
    notifyListeners();

    await _audio.speak(msg);
  }

  Future<void> triggerSOS() async {
    // Alarm Sound (Critical, but respecting sound setting if explicit)
    // Actually, for safety, Alarm usually overrides, but let's respect the "Sound" toggle for now as requested.
    if (_settings == null || _settings!.sound) {
      await _audio.playAlarm();
    }

    // Auto Emergency SMS
    if (_settings != null && _settings!.autoEmergency) {
      if (_emergencyContact != null && _emergencyContact!.isNotEmpty) {
        _smsService.sendEmergencyAlert(targetNumber: _emergencyContact!);
      }
    }
  }

  void toggleListening() async {
    if (_isListening) {
      await _audio.stopListening();
      _isListening = false;
      notifyListeners();
    } else {
      await _audio
          .stopAll(); // ✅ Stop any running alarm or TTS before listening
      _isListening = true;
      notifyListeners();

      await _audio.listen((text) async {
        _isListening = false;
        _aiMessage = "Analyzing...";
        notifyListeners();

        String reply = await _gemini.chatWithDriver(text);

        _aiMessage = reply;

        await _audio.speak(reply);
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }
}
