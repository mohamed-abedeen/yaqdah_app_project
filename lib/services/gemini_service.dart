import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAUFsbasVXZtubHgxGgd2KdFZIp-oqIF0g';
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

  Future<String> getIntervention(String state) async {
    String prompt;
    switch (state) {
      case "DISTRACTED":
        prompt =
            "You are a smart driver assistance AI. The driver is distracted and looking away from the road. "
            "Speak in Arabic. Give a sharp, authoritative, and very short command (max 5 words) to make him look at the road immediately. "
            "Choose the most effective phrase for this critical safety situation. Example: 'انتبه للطريق فوراً!'";
        break;
      case "DROWSY":
        prompt =
            "You are a smart driver assistance AI. The driver is showing signs of drowsiness (closing eyes, yawning). "
            "Speak in Arabic. Your goal is to wake him up. Give the single best piece of advice for this moment (e.g., open window, stop car, wash face). "
            "Keep it short, urgent, and loud. (Max 8 words).";
        break;
      case "ASLEEP":
        prompt =
            "The driver has fallen ASLEEP! This is a life-threatening emergency. "
            "Scream in Arabic to WAKE UP NOW! Use the most alarming words possible. (Max 3 words). Example: 'اصحى! خطر!'";
        break;
      default:
        prompt = "Say Hello in Arabic";
    }
    return _sendPrompt(prompt);
  }

  Future<String> chatWithDriver(String userMessage) async {
    String prompt =
        "You are 'Yaqdah' (يقظة), a smart AI co-pilot for preventing drowsiness. "
        "The driver is speaking to you in Arabic to stay awake. "
        "Driver said: '$userMessage'\n"
        "Reply in friendly, engaging Arabic to keep the conversation going and keep him awake. "
        "Keep your answers concise (max 2 sentences).";

    return _sendPrompt(prompt);
  }

  Future<String> _sendPrompt(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "لا يوجد رد";
    } catch (e) {
      debugPrint("❌ GEMINI ERROR DETAILED: $e");

      if (e.toString().contains("404") || e.toString().contains("not found")) {
        return "خطأ: الموديل غير موجود (404). تأكد من المفتاح.";
      }
      if (e.toString().contains("403")) {
        return "خطأ: مفتاح API غير صالح (403)";
      }
      if (e.toString().contains("User location is not supported")) {
        return "خطأ: الخدمة غير متوفرة في منطقتك";
      }

      return "خطأ في الاتصال: $e";
    }
  }
}
