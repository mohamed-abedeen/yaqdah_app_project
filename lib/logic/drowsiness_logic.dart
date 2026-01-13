import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum DriverState { awake, drowsy, asleep, distracted }

class DrowsinessLogic {
  // --- THRESHOLDS ---
  static const double _eyeOpenThreshold = 0.5;
  static const double _headYawThreshold = 25.0;
  static const double _headPitchThreshold = 20.0;

  // --- TIME (milliseconds) ---
  static const int _timeToDrowsyMs = 900;
  static const int _timeToSleepMs = 1500;

  DateTime? _eyesClosedStart;
  DateTime? _distractedStart;

  DriverState checkFace(Face face) {
    final now = DateTime.now();

    // --- DISTRACTION ---
    final bool isDistracted =
        (face.headEulerAngleY?.abs() ?? 0) > _headYawThreshold ||
        (face.headEulerAngleX?.abs() ?? 0) > _headPitchThreshold;

    // --- EYES ---
    final double leftEye = face.leftEyeOpenProbability ?? 1.0;
    final double rightEye = face.rightEyeOpenProbability ?? 1.0;

    final bool eyesClosed =
        leftEye < _eyeOpenThreshold && rightEye < _eyeOpenThreshold;

    // --- EYES CLOSED LOGIC (PRIORITY) ---
    if (eyesClosed) {
      _distractedStart = null;
      _eyesClosedStart ??= now;

      final closedMs = now.difference(_eyesClosedStart!).inMilliseconds;

      if (closedMs >= _timeToSleepMs) {
        return DriverState.asleep;
      }

      if (closedMs >= _timeToDrowsyMs) {
        return DriverState.drowsy;
      }

      return DriverState.awake; // blink
    }

    // --- EYES OPEN ---
    _eyesClosedStart = null;

    if (isDistracted) {
      _distractedStart ??= now;

      final distractedMs = now.difference(_distractedStart!).inMilliseconds;

      if (distractedMs >= _timeToDrowsyMs) {
        return DriverState.distracted;
      }
    } else {
      _distractedStart = null;
    }

    return DriverState.awake;
  }

  void dispose() {}
}
