import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum DriverState { awake, drowsy, asleep, distracted }

class DrowsinessLogic {
  // --- THRESHOLDS ---
  static const double _eyeOpenThreshold = 0.25;
  static const double _headYawThreshold = 25.0;
  static const double _headPitchThreshold = 20.0;

  // --- TIME (milliseconds) ---
  static const int _timeToDrowsyMs = 1000;
  static const int _timeToSleepMs = 2000;
  static const int _microsleepThresholdMs = 500;

  DateTime? _eyesClosedStart;
  DateTime? _distractedStart;

  // --- Scoring Metrics ---
  int _microsleepCount = 0;
  int _drowsyWarnings = 0;
  int _distractionWarnings = 0;

  bool _drowsyAlertFired = false;
  bool _distractedAlertFired = false;

  int get microsleepCount => _microsleepCount;
  int get drowsyWarnings => _drowsyWarnings;
  int get distractionWarnings => _distractionWarnings;

  void resetMetrics() {
    _microsleepCount = 0;
    _drowsyWarnings = 0;
    _distractionWarnings = 0;
    _drowsyAlertFired = false;
    _distractedAlertFired = false;
    _eyesClosedStart = null;
    _distractedStart = null;
  }

  DriverState checkFace(Face face) {
    final now = DateTime.now();

    final bool isDistracted =
        (face.headEulerAngleY?.abs() ?? 0) > _headYawThreshold ||
        (face.headEulerAngleX?.abs() ?? 0) > _headPitchThreshold;

    final double leftEye = face.leftEyeOpenProbability ?? 1.0;
    final double rightEye = face.rightEyeOpenProbability ?? 1.0;
    final bool eyesClosed =
        leftEye < _eyeOpenThreshold && rightEye < _eyeOpenThreshold;

    if (eyesClosed) {
      _distractedStart = null;
      _distractedAlertFired = false;
      _eyesClosedStart ??= now;

      final closedMs = now.difference(_eyesClosedStart!).inMilliseconds;

      if (closedMs >= _timeToSleepMs) {
        return DriverState.asleep;
      }

      if (closedMs >= _timeToDrowsyMs) {
        if (!_drowsyAlertFired) {
          _drowsyWarnings++;
          _drowsyAlertFired = true;
        }
        return DriverState.drowsy;
      }

      return DriverState.awake;
    }

    // Eyes are open
    if (_eyesClosedStart != null) {
      // Check if it was a microsleep before resetting
      final closedMs = now.difference(_eyesClosedStart!).inMilliseconds;
      if (closedMs >= _microsleepThresholdMs && closedMs < _timeToDrowsyMs) {
        _microsleepCount++;
      }
      _eyesClosedStart = null;
      _drowsyAlertFired = false;
    }

    if (isDistracted) {
      _distractedStart ??= now;
      final distractedMs = now.difference(_distractedStart!).inMilliseconds;

      if (distractedMs >= _timeToDrowsyMs) {
        if (!_distractedAlertFired) {
          _distractionWarnings++;
          _distractedAlertFired = true;
        }
        return DriverState.distracted;
      }
    } else {
      _distractedStart = null;
      _distractedAlertFired = false;
    }

    return DriverState.awake;
  }

  void dispose() {}
}
