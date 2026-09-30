import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../logic/drowsiness_logic.dart';

class FaceMonitoringService {
  final DrowsinessLogic _logic = DrowsinessLogic();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      // Eye-open probabilities and head angles are all the logic needs.
      // Fast mode with no tracking keeps CPU use low on long drives.
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
      // The driver is close to the phone; skip small faces in the back.
      minFaceSize: 0.15,
    ),
  );

  bool _isProcessing = false;
  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// About 8 checks a second: enough to time a 0.5 s microsleep.
  static const int _throttleMillis = 125;

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void dispose() {
    _faceDetector.close();
  }

  /// Starts a new trip's counts (microsleeps, warnings) from zero.
  void resetSession() => _logic.resetMetrics();

  Future<void> processFrame({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required bool isMonitoring,
    required Function(String, Map<String, int>) onStatusChange,
  }) async {
    if (_isProcessing || !isMonitoring) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < _throttleMillis) {
      return;
    }

    _isProcessing = true;
    _lastFrameTime = now;

    try {
      final inputImage = inputImageFromCameraImage(
        image,
        camera,
        deviceOrientation,
      );
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        onStatusChange("NO_FACE", _getMetrics());
      } else {
        final DriverState state = _logic.checkFace(_driverFace(faces));

        String statusString = "AWAKE";
        switch (state) {
          case DriverState.awake:
            statusString = "AWAKE";
            break;
          case DriverState.drowsy:
            statusString = "DROWSY";
            break;
          case DriverState.asleep:
            statusString = "ASLEEP";
            break;
          case DriverState.distracted:
            statusString = "DISTRACTED";
            break;
        }
        onStatusChange(statusString, _getMetrics());
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  DateTime _lastPresenceCheck = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _presenceThrottleMillis = 800;

  /// Pre-trip readiness check: is a face in frame?
  ///
  /// Runs at most about once a second and leaves the drowsiness state
  /// untouched. Returns null when the frame was skipped.
  Future<bool?> detectFacePresence({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) async {
    if (_isProcessing) return null;
    if (DateTime.now().difference(_lastPresenceCheck).inMilliseconds <
        _presenceThrottleMillis) {
      return null;
    }

    _isProcessing = true;
    _lastPresenceCheck = DateTime.now();

    try {
      final inputImage = inputImageFromCameraImage(
        image,
        camera,
        deviceOrientation,
      );
      if (inputImage == null) return null;
      final faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking face presence: $e");
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// The largest face is the driver's; passengers are further away.
  static Face _driverFace(List<Face> faces) {
    var best = faces.first;
    var bestArea = best.boundingBox.width * best.boundingBox.height;
    for (final face in faces.skip(1)) {
      final area = face.boundingBox.width * face.boundingBox.height;
      if (area > bestArea) {
        best = face;
        bestArea = area;
      }
    }
    return best;
  }

  Map<String, int> _getMetrics() {
    return {
      'microsleeps': _logic.microsleepCount,
      'drowsyWarnings': _logic.drowsyWarnings,
      'distractionWarnings': _logic.distractionWarnings,
      'asleepEvents': _logic.asleepEvents,
    };
  }

  /// How far a frame from [camera] must be turned to be upright.
  static InputImageRotation? rotationFor(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (!Platform.isAndroid) return null;
    var rotationCompensation = _orientations[deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  /// Wraps a camera frame for ML Kit, rotated to how the phone is held.
  ///
  /// Returns null for formats ML Kit can't read (it needs NV21 on Android
  /// and BGRA8888 on iOS).
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final rotation = rotationFor(camera, deviceOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    // NV21 and BGRA arrive as a single plane: use it without copying.
    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}
