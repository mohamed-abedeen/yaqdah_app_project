import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️ CRITICAL: Paste your actual API Key here
  static const String _apiKey = '';

  late GenerativeModel _model;

  // ✅ FIXED: Use the correct model name (1.5, not 2.5)
  String _currentModelName = 'gemini-1.5-flash';

  GeminiService() {
    _model = GenerativeModel(model: _currentModelName, apiKey: _apiKey);
    _checkModelAccess();
  }

  // --- DIAGNOSTIC TOOL ---
  Future<void> _checkModelAccess() async {
    try {
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

      // Fallback logic if the model name is wrong or deprecated
      if (e.toString().contains("404") || e.toString().contains("not found")) {
        debugPrint(
          "GeminiService: 🔄 Switching to 'gemini-pro' as fallback...",
        );
        _currentModelName = 'gemini-pro';
        _model = GenerativeModel(model: _currentModelName, apiKey: _apiKey);
      }
    }
  }

  Future<String> getIntervention(String state) async {
    String prompt;
    switch (state) {
      case "DISTRACTED":
        prompt =
            "You are a co-pilot. The driver is distracted. Speak in Arabic. Warning the driver by giving him a good advice. Keep it short .";
        break;
      case "DROWSY":
        prompt =
            "You are a co-pilot. The driver is drowsy. Speak in Arabic. Tell the driver to wake up and suggest a him good advice like take a break or open the window or stopping for coffee or whatever suits. Keep it short .";
        break;
      case "ASLEEP":
        prompt =
            "You are a co-pilot. The driver fell asleep! Scream in Arabic to WAKE UP NOW! Keep it very short and urgent.";
        break;
      default:
        prompt = "Say Hello in Arabic";
    }
    return _sendPrompt(prompt);
  }

  Future<String> chatWithDriver(String userMessage) async {
    String prompt =
        "Act as a helpful car co-pilot. The driver is speaking to you in Arabic.\n"
        "Driver said: '$userMessage'\n"
        "Reply in helpful Arabic. Keep the response concise so the driver is not distracted.";

    return _sendPrompt(prompt);
  }

  Future<String> _sendPrompt(String prompt) async {
    if (_apiKey.isEmpty) {
      return "خطأ: مفتاح API مفقود";
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "لا يوجد رد";
    } catch (e) {
      debugPrint("❌ GEMINI ERROR DETAILED: $e");

      if (e.toString().contains("404") || e.toString().contains("not found")) {
        return "خطأ: الموديل غير موجود (404).";
      }
      if (e.toString().contains("403") || e.toString().contains("API key")) {
        return "خطأ: مفتاح API غير صالح (403)";
      }
      if (e.toString().contains("User location")) {
        return "خطأ: الخدمة غير متوفرة في منطقتك (VPN قد يساعد)";
      }

      return "خطأ في الاتصال";
    }
  }
}
