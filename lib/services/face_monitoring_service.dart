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
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isProcessing = false;
  DateTime _lastFrameTime = DateTime.now();
  final int _throttleMillis = 125;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void dispose() {
    _faceDetector.close();
    // _logic.dispose(); // If logic needs disposal
  }

  Future<void> processFrame({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required bool isMonitoring,
    required Function(String, Map<String, int>) onStatusChange,
  }) async {
    if (_isProcessing || !isMonitoring) return;

    if (DateTime.now().difference(_lastFrameTime).inMilliseconds <
        _throttleMillis) {
      return;
    }

    _isProcessing = true;
    _lastFrameTime = DateTime.now();

    try {
      final inputImage = _inputImageFromCameraImage(
        image,
        camera,
        deviceOrientation,
      );
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        onStatusChange("NO_FACE", _getMetrics());
      } else {
        final face = faces.first;
        final DriverState state = _logic.checkFace(face);

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

  Map<String, int> _getMetrics() {
    return {
      'microsleeps': _logic.microsleepCount,
      'drowsyWarnings': _logic.drowsyWarnings,
      'distractionWarnings': _logic.distractionWarnings,
    };
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}
