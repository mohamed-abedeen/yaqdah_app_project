import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

/// Short spoken replies from Gemini.
///
/// Every call returns null when Gemini can't answer (no API key, offline,
/// too slow), so callers speak a built-in phrase instead of an error.
class GeminiService {
  static String get _apiKey => AppConfig.geminiApiKey;
  static const String _modelName = 'gemini-2.5-flash';

  GenerativeModel? _model;

  bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel get _client =>
      _model ??= GenerativeModel(model: _modelName, apiKey: _apiKey);

  /// A nudge for [state] ("DISTRACTED" or "DROWSY") in [locale] ('ar' or
  /// 'en'). It has to arrive while it's still relevant, so it gives up
  /// after a few seconds.
  Future<String?> getIntervention(String state, {String locale = 'ar'}) {
    final bool isAr = locale == 'ar';
    final String prompt;
    switch (state) {
      case "DISTRACTED":
        prompt = isAr
            ? "You are a smart driver assistance AI. The driver is distracted. "
                  "Speak in Arabic. Give a sharp, very short command (max 5 words) "
                  "to make him look at the road. Example: 'انتبه للطريق فوراً!'"
            : "You are a smart driver assistance AI. The driver is distracted. "
                  "Give a sharp, very short English command (max 5 words) to "
                  "make them focus on the road. Example: 'Eyes on the road!'";
        break;
      case "DROWSY":
        prompt = isAr
            ? "You are a smart driver assistance AI. The driver is drowsy. "
                  "Speak in Arabic. Give the single best advice to wake them up (max 8 words)."
            : "You are a smart driver assistance AI. The driver is drowsy. "
                  "Give the single best English advice to wake them up (max 8 words).";
        break;
      default:
        return Future.value(null);
    }
    return _send(prompt, timeout: const Duration(seconds: 4));
  }

  /// Respond to a voice command from the driver in [locale].
  Future<String?> chatWithDriver(String userMessage, {String locale = 'ar'}) {
    final bool isAr = locale == 'ar';
    final String prompt = isAr
        ? "You are 'Yaqdah' (يقظة), a smart AI co-pilot for preventing drowsiness. "
              "The driver is speaking to you in Arabic to stay awake. "
              "Driver said: '$userMessage'\n"
              "Reply in friendly, engaging Arabic to keep the conversation going. "
              "Keep your answers concise (max 2 sentences)."
        : "You are 'Yaqdah', a smart AI co-pilot for preventing drowsiness. "
              "The driver is speaking to you in English. "
              "Driver said: '$userMessage'\n"
              "Reply in friendly, engaging English to keep them awake. "
              "Keep your answers concise (max 2 sentences).";

    return _send(prompt, timeout: const Duration(seconds: 12));
  }

  Future<String?> _send(String prompt, {required Duration timeout}) async {
    if (!isConfigured) return null;
    try {
      final response = await _client
          .generateContent([Content.text(prompt)])
          .timeout(timeout);
      final text = response.text?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } on TimeoutException {
      debugPrint("⏱ GEMINI TIMEOUT");
      return null;
    } catch (e) {
      debugPrint("❌ GEMINI ERROR: $e");
      return null;
    }
  }
}
