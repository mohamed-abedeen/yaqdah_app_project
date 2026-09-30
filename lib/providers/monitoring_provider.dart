import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../l10n/app_localizations.dart';
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
  bool _isListening = false;
  double _currentScore = 100.0;
  int _voiceSosCount = 0;

  // Dependencies
  String? _emergencyContact;

  bool get isMonitoring => _isMonitoring;
  String get status => _status;
  double get drowsinessLevel => _drowsinessLevel;
  bool get isListening => _isListening;
  double get currentScore => _currentScore;

  /// Bumped each time the driver asks for an SOS by voice, so the trip can
  /// log it.
  int get voiceSosCount => _voiceSosCount;

  /// The number the danger alert texts, read fresh from the signed-in user.
  String get emergencyContact =>
      (_auth?.currentUser['emergencyContact'] as String?) ??
      _emergencyContact ??
      '';

  /// Whether the danger alert should text the contact when it times out.
  bool get autoEmergencyEnabled => _settings?.autoEmergency ?? false;

  String get _languageCode => _settings?.locale.languageCode ?? 'ar';
  AppLocalizations get _l10n => lookupAppLocalizations(Locale(_languageCode));

  MonitoringProvider() {
    _audio.init();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    _audio.setLanguage(settings.locale.languageCode);
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
      // Start the trip from a clean status so the last trip's state
      // (e.g. ASLEEP) doesn't show or raise an alert before the first frame.
      _status = "IDLE";
      _drowsinessLevel = 0;
    }
    // Monitoring stops when the screen locks, so keep it on for the trip.
    _setScreenAwake(_isMonitoring);
    notifyListeners();
  }

  Future<void> _setScreenAwake(bool awake) async {
    try {
      await (awake ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (e) {
      debugPrint("Wakelock error: $e");
    }
  }

  DateTime _lastAiTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );
  DateTime _lastBeepTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );

  /// Called for every analysed camera frame. Sounds run each time (they
  /// throttle themselves); listeners only hear about actual changes.
  void handleStatusChange(String newStatus, Map<String, int> metrics) {
    if (!_isMonitoring) return;

    // Calculate Driver Score. Every episode counts once, and still counts
    // after the driver recovers.
    int mCount = metrics['microsleeps'] ?? 0;
    int dWarnings = metrics['drowsyWarnings'] ?? 0;
    int distWarnings = metrics['distractionWarnings'] ?? 0;
    int asleepEvents = metrics['asleepEvents'] ?? 0;

    final double score =
        (100.0 -
                (mCount * 2) -
                (distWarnings * 5) -
                (dWarnings * 10) -
                (asleepEvents * 20))
            .clamp(0.0, 100.0);

    double level = _drowsinessLevel;
    switch (newStatus) {
      case "AWAKE":
      case "SAFE": // Handle SAFE if used
        if (_status != "AWAKE" && _status != "SAFE") {
          // Stop the alarm and beeps, but not the voice assistant.
          _audio.stopAlarm();
        }
        level = 0;
        break;
      case "DISTRACTED":
        _triggerBeep(); // ✅ Trigger alert sound for distraction
        _triggerIntervention("DISTRACTED");
        level = 45;
        break;
      case "NO_FACE":
        _triggerBeep();
        level = 45;
        break;
      case "DROWSY":
        _triggerBeep();
        _triggerIntervention("DROWSY");
        level = 75;
        break;
      case "ASLEEP":
        // The alarm starts now; the danger alert's countdown sends the
        // SOS text (via triggerSOS) if the driver doesn't respond.
        _playAlarm();
        level = 100;
        break;
    }

    final changed =
        newStatus != _status ||
        level != _drowsinessLevel ||
        score != _currentScore;
    _status = newStatus;
    _drowsinessLevel = level;
    _currentScore = score;
    if (changed) notifyListeners();
  }

  Future<void> _triggerBeep() async {
    // Check Settings: Sound
    if (_settings != null && !_settings!.sound) return;

    if (DateTime.now().difference(_lastBeepTrigger).inSeconds < 3) return;
    _lastBeepTrigger = DateTime.now();
    await _audio.playBeep();
  }

  /// Speaks a short nudge: from Gemini when it answers quickly, otherwise a
  /// built-in phrase.
  Future<void> _triggerIntervention(String state) async {
    // Check Settings: AI Assistance (Auto Interventions)
    if (_settings != null && !_settings!.aiAssistance) return;

    if (DateTime.now().difference(_lastAiTrigger).inSeconds < 8) return;
    _lastAiTrigger = DateTime.now();

    final l10n = _l10n;
    final fallback = state == "DROWSY"
        ? l10n.interventionDrowsy
        : l10n.interventionDistracted;
    final message =
        await _gemini.getIntervention(state, locale: _languageCode) ?? fallback;
    if (!_isMonitoring) return;
    await _audio.speak(message);
  }

  Future<void> _playAlarm() async {
    if (_settings == null || _settings!.sound) {
      await _audio.playAlarm();
    }
  }

  /// Stops the alarm and any speech, e.g. when the driver taps "I'm awake".
  Future<void> silenceAlarm() => _audio.stopAll();

  /// Sounds the alarm and texts the emergency contact.
  ///
  /// The text is sent when "Automatic SOS text" is on, or always when
  /// [manual] is true (the driver asked for it: Hold for SOS, Send SOS now).
  /// Returns whether a text went out.
  Future<bool> triggerSOS({bool manual = false}) async {
    // Alarm Sound
    await _playAlarm();

    // Emergency SMS — read the CURRENT contact fresh from AuthProvider
    // so updating the number in Settings always takes effect immediately.
    if (!manual && !autoEmergencyEnabled) return false;
    final contact = emergencyContact;
    if (contact.isEmpty) return false;

    // A driver who asked for help can still answer the permission prompt.
    if (manual && Platform.isAndroid && !await Permission.sms.isGranted) {
      if (!await Permission.sms.request().isGranted) return false;
    }

    final l10n = _l10n;
    return _smsService.sendEmergencySms(
      phoneNumber: contact,
      message: l10n.sosSmsBody,
      locationLabel: l10n.sosSmsLocation,
    );
  }

  void _setListening(bool listening) {
    if (_isListening == listening) return;
    _isListening = listening;
    notifyListeners();
  }

  void toggleListening() async {
    if (_isListening) {
      await _audio.cancelListening();
      _setListening(false);
      return;
    }

    // ✅ Stop any running alarm or TTS before listening
    await _audio.stopAll();
    _setListening(true);
    HapticFeedback.selectionClick();
    final started = await _audio.listen(
      localeId: _languageCode == 'ar' ? 'ar_SA' : 'en_US',
      onResult: _handleVoiceCommand,
      onDone: () => _setListening(false),
    );
    if (!started) _setListening(false);
  }

  Future<void> _handleVoiceCommand(String text) async {
    final l10n = _l10n;
    final command = _normalize(text);

    // 1. Check for Local Commands
    if (_isMonitoring && _matches(command, _endTripPhrases)) {
      await _audio.speak(l10n.voiceEndingTrip);
      if (_isMonitoring) toggleMonitoring();
      return;
    }
    if (_matches(command, _sosPhrases) || _sosExactPhrases.contains(command)) {
      await _audio.speak(l10n.voiceSendingSos);
      if (_isMonitoring) {
        _voiceSosCount++;
        notifyListeners();
      }
      triggerSOS(manual: true);
      return;
    }

    // 2. Fallback to Gemini
    final reply = await _gemini.chatWithDriver(text, locale: _languageCode);
    await _audio.speak(reply ?? l10n.voiceUnavailable);
  }

  // Voice commands, in both app languages whatever the UI language.
  static final _endTripPhrases = [
    'end trip',
    'end the trip',
    'stop trip',
    'finish trip',
    'stop monitoring',
    'انهاء الرحله',
    'انهي الرحله',
    'انه الرحله',
    'انتهاء الرحله',
    'اوقف الرحله',
    'ايقاف الرحله',
    'اوقف المراقبه',
    'ايقاف المراقبه',
  ].map(_normalize).toList();

  static final _sosPhrases = [
    'emergency',
    'sos',
    's o s',
    'call for help',
    'طوارئ',
    'الطوارئ',
    'نجده',
    'النجده',
    'استغاثه',
  ].map(_normalize).toList();

  /// "Help" alone is an SOS; "help me find a café" isn't.
  static final _sosExactPhrases = {'help', 'help me', 'ساعدني'};

  /// Whole-word match of any of [phrases] in [command].
  static bool _matches(String command, List<String> phrases) {
    final padded = ' $command ';
    return phrases.any((phrase) => padded.contains(' $phrase '));
  }

  /// Lower case, no punctuation or Arabic diacritics, and one spelling for
  /// letters speech recognition writes either way (alef forms, taa marbuta
  /// and haa, alef maqsura and yaa).
  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '')
      .replaceAll(RegExp('[\u0622\u0623\u0625]'), '\u0627')
      .replaceAll('\u0629', '\u0647')
      .replaceAll('\u0649', '\u064A')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  @override
  void dispose() {
    _audio.dispose();
    _setScreenAwake(false);
    super.dispose();
  }
}
