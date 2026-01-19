import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum DriverState { awake, drowsy, asleep, distracted }

class DrowsinessLogic {
  // --- THRESHOLDS ---
  // ✅ FIX 1: Lowered from 0.5 to 0.25.
  // Now detection only starts when eyes are truly closed, preventing false alarms from squinting or looking down.
  static const double _eyeOpenThreshold = 0.25;

  static const double _headYawThreshold = 25.0;
  static const double _headPitchThreshold = 20.0;

  // --- TIME (milliseconds) ---
  // ✅ FIX 2: Adjusted timings for better realism
  static const int _timeToDrowsyMs = 1000; // 1 second closed = Drowsy
  static const int _timeToSleepMs = 2000; // 2 seconds closed = SLEEP (Danger)

  DateTime? _eyesClosedStart;
  DateTime? _distractedStart;

  DriverState checkFace(Face face) {
    final now = DateTime.now();

    // --- DISTRACTION CHECK ---
    // Checks if head is turned too far left/right (Yaw) or up/down (Pitch)
    final bool isDistracted =
        (face.headEulerAngleY?.abs() ?? 0) > _headYawThreshold ||
        (face.headEulerAngleX?.abs() ?? 0) > _headPitchThreshold;

    // --- EYE CLOSURE CHECK ---
    final double leftEye = face.leftEyeOpenProbability ?? 1.0;
    final double rightEye = face.rightEyeOpenProbability ?? 1.0;

    // Both eyes must be below 0.25 to count as closed
    final bool eyesClosed =
        leftEye < _eyeOpenThreshold && rightEye < _eyeOpenThreshold;

    // --- LOGIC: EYES CLOSED ---
    if (eyesClosed) {
      // If eyes are closed, we don't care about distraction
      _distractedStart = null;

      // Start the timer if this is the first frame eyes are closed
      _eyesClosedStart ??= now;

      final closedMs = now.difference(_eyesClosedStart!).inMilliseconds;

      if (closedMs >= _timeToSleepMs) {
        return DriverState.asleep; // 🚨 CRITICAL DANGER
      }

      if (closedMs >= _timeToDrowsyMs) {
        return DriverState.drowsy; // ⚠️ WARNING
      }

      // If closed less than 1000ms, it's just a blink (Safe)
      return DriverState.awake;
    }

    // --- LOGIC: EYES OPEN ---
    // Reset eye timer immediately when eyes open
    _eyesClosedStart = null;

    // Only check distraction if eyes are open
    if (isDistracted) {
      _distractedStart ??= now;

      final distractedMs = now.difference(_distractedStart!).inMilliseconds;

      if (distractedMs >= _timeToDrowsyMs) {
        // Use drowsy timer for distraction too
        return DriverState.distracted;
      }
    } else {
      _distractedStart = null;
    }

    return DriverState.awake;
  }

  void dispose() {}
}
