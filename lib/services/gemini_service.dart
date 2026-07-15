import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

class GeminiService {
  static String get _apiKey => AppConfig.geminiApiKey;
  // Replace with your actual API key after you publish the app.

  late GenerativeModel _model;

  String _currentModelName = 'gemini-2.5-flash';

  GeminiService() {
    _model = GenerativeModel(model: _currentModelName, apiKey: _apiKey);

    // Attempt to validate access immediately
    _checkModelAccess();
  }

  // --- DIAGNOSTIC TOOL ---
  Future<void> _checkModelAccess() async {
    try {
      // We send a dummy prompt to see if the model is reachable
      debugPrint(
        "GeminiService: Testing model access for $_currentModelName...",
      );
      final testContent = [Content.text("Test")];
      await _model.generateContent(testContent);
      debugPrint("GeminiService: ✅ Access Confirmed for $_currentModelName");
    } catch (e) {
      debugPrint(
        "GeminiService: ❌ Access Failed for $_currentModelName. Error: $e",
      );

      // If Flash fails, fallback to Pro
      if (e.toString().contains("404") || e.toString().contains("not found")) {
        debugPrint(
          "GeminiService: 🔄 Switching to 'gemini-pro' as fallback...",
        );

        _currentModelName = 'gemini-pro'; // Update our local tracker
        _model = GenerativeModel(model: _currentModelName, apiKey: _apiKey);
      }
    }
  }

  /// Returns an intervention message for [state].
  /// Set [locale] to 'en' for English; defaults to Arabic.
  Future<String> getIntervention(String state, {String locale = 'ar'}) async {
    final bool isAr = locale == 'ar';
    String prompt;
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
      case "ASLEEP":
        prompt = isAr
            ? "The driver has fallen ASLEEP! Scream in Arabic to wake up NOW (max 3 words). Example: 'اصحى! خطر!'"
            : "The driver has fallen ASLEEP! Shout a very short English wake-up command (max 3 words). Example: 'WAKE UP NOW!'";
        break;
      default:
        prompt = isAr ? "قل مرحبا" : "Say Hello";
    }
    return _sendPrompt(prompt);
  }

  /// Respond to a voice command from the driver.
  /// Set [locale] to 'en' for English; defaults to Arabic.
  Future<String> chatWithDriver(
    String userMessage, {
    String locale = 'ar',
  }) async {
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

    return _sendPrompt(prompt);
  }

  Future<String> _sendPrompt(String prompt) async {
    if (_apiKey.isEmpty) {
      return "خطأ: مفتاح API غير مُعيَّن. شغّل التطبيق مع --dart-define=GEMINI_API_KEY=xxx";
    }
    try {
      final content = [Content.text(prompt)];
      final response = await _model
          .generateContent(content)
          .timeout(const Duration(seconds: 15));
      return response.text ?? "لا يوجد رد";
    } on TimeoutException {
      debugPrint("⏱ GEMINI TIMEOUT");
      return "انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.";
    } catch (e) {
      debugPrint("❌ GEMINI ERROR: $e");
      final msg = e.toString();
      if (msg.contains("404") || msg.contains("not found")) {
        return "خطأ: الموديل غير موجود (404). تأكد من المفتاح.";
      }
      if (msg.contains("403")) {
        return "خطأ: مفتاح API غير صالح (403)";
      }
      if (msg.contains("User location is not supported")) {
        return "خطأ: الخدمة غير متوفرة في منطقتك";
      }
      return "خطأ في الاتصال. حاول مرة أخرى.";
    }
  }
}
