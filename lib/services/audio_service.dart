import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _speechReady = false;
  bool _isListening = false;
  VoidCallback? _onListenDone;
  String? _ttsLanguage;

  // Track if the emergency alarm is active so beeps don't interrupt it
  bool _isAlarmActive = false;

  Future<void> init() async {
    // 1. Setup TTS (Voice)
    try {
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      // speak() completes when the sentence has been said, so e.g. the
      // SOS alarm doesn't cut off "Sending an emergency alert".
      await _flutterTts.awaitSpeakCompletion(true);

      if (Platform.isIOS) {
        await _flutterTts
            .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
            ]);
      }
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }

    // 2. The alarm plays on the alarm stream, so a low media volume can't
    // silence it.
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Audio context error: $e");
    }

    // Speech recognition starts on the first mic tap, which is also when
    // the microphone permission is asked for.
  }

  /// Spoken language: 'ar' or 'en'.
  Future<void> setLanguage(String languageCode) async {
    final tag = languageCode == 'ar' ? 'ar' : 'en-US';
    if (_ttsLanguage == tag) return;
    _ttsLanguage = tag;
    try {
      await _flutterTts.setLanguage(tag);
    } catch (e) {
      debugPrint("TTS language error: $e");
    }
  }

  // --- TTS (Speaking) ---
  Future<void> speak(String text) async {
    // Don't speak if emergency alarm is blasting
    if (_isAlarmActive) return;

    if (text.isNotEmpty) {
      await _flutterTts.stop();
      // Never wait on a TTS engine that doesn't report back.
      await _flutterTts
          .speak(text)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
    }
  }

  // --- STT (Listening) ---
  Future<bool> _ensureSpeech() async {
    if (_speechReady) return true;
    _speechReady = await _speechToText.initialize(
      onError: (error) {
        debugPrint('STT Error: $error');
        _finishListening();
      },
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _finishListening();
        }
      },
    );
    if (!_speechReady) debugPrint("Speech recognition not available");
    return _speechReady;
  }

  /// Listens for one utterance in [localeId]. [onResult] gets the words;
  /// [onDone] runs once when listening ends for any reason.
  ///
  /// Returns false when speech recognition isn't available.
  Future<bool> listen({
    required String localeId,
    required void Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (_isListening) await cancelListening();
    if (!await _ensureSpeech()) return false;

    _isListening = true;
    _onListenDone = onDone;
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!result.finalResult) return;
          _finishListening();
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) onResult(words);
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("STT listen failed: $e");
      _finishListening();
      return false;
    }
    return true;
  }

  void _finishListening() {
    _isListening = false;
    final done = _onListenDone;
    _onListenDone = null;
    done?.call();
  }

  /// Stops listening without acting on what was heard.
  Future<void> cancelListening() async {
    if (_speechReady) await _speechToText.cancel();
    _finishListening();
  }

  // --- 🚨 Emergency Alarm (High Priority) ---
  Future<void> playAlarm() async {
    // If alarm is already running, don't restart it (avoids stuttering)
    if (_isAlarmActive) return;

    _isAlarmActive = true;

    // Stop any other sound (Beeps, Speech) immediately
    await _audioPlayer.stop();
    await _flutterTts.stop();

    // Loop for "ASLEEP"
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setSource(AssetSource('sounds/alarm.mp3'));
    await _audioPlayer.setVolume(1.0); // Max volume
    await _audioPlayer.resume();
  }

  // --- ⚠️ Warning Beep (Low Priority) ---
  Future<void> playBeep() async {
    // If Emergency Alarm is active, DO NOT interrupt it with a beep
    if (_isAlarmActive) return;

    // If a previous beep is still playing, we can ignore this one or restart.
    // Generally safe to just restart for warnings.
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.release); // Play once
    await _audioPlayer.setSource(AssetSource('sounds/alarm.mp3'));
    await _audioPlayer.setVolume(0.5); // Lower volume
    await _audioPlayer.resume();
  }

  /// Stops the alarm and beeps, leaving speech and listening alone.
  Future<void> stopAlarm() async {
    _isAlarmActive = false;
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> stopAll() async {
    await stopAlarm();
    await _flutterTts.stop();
    await cancelListening();
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _speechToText.cancel();
  }
}
