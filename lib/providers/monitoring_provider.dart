import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';
import '../services/location_sms_service.dart';
import '../providers/auth_provider.dart';
import 'settings_provider.dart';

class MonitoringProvider with ChangeNotifier {
  final AudioService _audio = AudioService();
  final GeminiService _gemini = GeminiService();
  final LocationSmsService _smsService = LocationSmsService();

  SettingsProvider? _settings;
  AuthProvider? _auth; // always-fresh reference for emergency contact

  bool _isMonitoring = false;
  String _status = "IDLE";
  double _drowsinessLevel = 0.0;
  String _aiMessage = "Press Start";
  bool _isListening = false;
  double _currentScore = 100.0;

  // Dependencies
  String? _emergencyContact;

  bool get isMonitoring => _isMonitoring;
  String get status => _status;
  double get drowsinessLevel => _drowsinessLevel;
  String get aiMessage => _aiMessage;
  bool get isListening => _isListening;
  double get currentScore => _currentScore;

  MonitoringProvider() {
    _audio.init();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    notifyListeners();
  }

  /// Call this whenever AuthProvider changes so we always have the fresh user.
  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  void setEmergencyContact(String contact) {
    _emergencyContact = contact;
  }

  void toggleMonitoring() {
    _isMonitoring = !_isMonitoring;
    if (!_isMonitoring) {
      _audio.stopAll(); // ✅ Stop all audio when monitoring ends (Trip End)
    } else {
      _currentScore = 100.0; // Reset score when starting new trip
    }
    notifyListeners();
  }

  DateTime _lastAiTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );
  DateTime _lastBeepTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );

  void handleStatusChange(String newStatus, Map<String, int> metrics) {
    if (!_isMonitoring) return;

    // Calculate Driver Score
    int mCount = metrics['microsleeps'] ?? 0;
    int dWarnings = metrics['drowsyWarnings'] ?? 0;
    int distWarnings = metrics['distractionWarnings'] ?? 0;

    double calculatedScore =
        100.0 - (mCount * 2) - (distWarnings * 5) - (dWarnings * 10);
    if (newStatus == "ASLEEP") {
      calculatedScore -= 50;
    }
    _currentScore = calculatedScore.clamp(0.0, 100.0);

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
      case "NO_FACE":
        _triggerBeep();
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
    // Alarm Sound
    if (_settings == null || _settings!.sound) {
      await _audio.playAlarm();
    }

    // Auto Emergency SMS — read the CURRENT contact fresh from AuthProvider
    // so updating the number in Settings always takes effect immediately.
    if (_settings != null && _settings!.autoEmergency) {
      final contact =
          (_auth?.currentUser['emergencyContact'] as String?) ??
          _emergencyContact ??
          '';
      if (contact.isNotEmpty) {
        _smsService.sendEmergencySms(
          phoneNumber: contact,
          message:
              'SOS - Driver may be in danger! Automated alert from Yaqdah.',
        );
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
        notifyListeners();

        // 1. Check for Local Commands
        final command = text.toLowerCase();
        if (command.contains("stop monitoring") ||
            command.contains("end trip")) {
          _aiMessage = "Stopping monitoring...";
          notifyListeners();
          await _audio.speak("Stopping monitoring.");
          toggleMonitoring();
          return;
        } else if (command.contains("emergency") || command.contains("help")) {
          _aiMessage = "Triggering SOS...";
          notifyListeners();
          await _audio.speak("Triggering emergency alert.");
          triggerSOS();
          return;
        }

        // 2. Fallback to Gemini
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
