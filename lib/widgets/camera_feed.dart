import 'dart:io'; // Needed for Platform check
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Needed for WriteBuffer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- FIXED: Needed for DeviceOrientation
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isMonitoring;
  final bool showFeed;
  final Function(String) onStatusChange;
  final Function(int) onCameraChanged;

  const CameraFeed({
    Key? key,
    required this.cameras,
    required this.isMonitoring,
    required this.showFeed,
    required this.onStatusChange,
    required this.onCameraChanged,
  }) : super(key: key);

  @override
  State<CameraFeed> createState() => CameraFeedState();
}

class CameraFeedState extends State<CameraFeed> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;

  // Face Detector
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // Needed for eyes
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup
                .nv21 // Android standard for ML Kit
          : ImageFormatGroup.bgra8888, // iOS standard
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        widget.onCameraChanged(_selectedCameraIndex);
        _controller!.startImageStream(_processImage);
      }
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  void switchCamera() {
    if (widget.cameras.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });
    _initializeCamera();
  }

  // --- AI PROCESSING LOOP ---
  void _processImage(CameraImage image) async {
    if (_isProcessing || !widget.isMonitoring) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        widget.onStatusChange("DISTRACTED");
      } else {
        final face = faces.first;

        double? leftEyeOpen = face.leftEyeOpenProbability;
        double? rightEyeOpen = face.rightEyeOpenProbability;

        // Threshold: 0.2 means 20% open (mostly closed)
        bool isAsleep =
            (leftEyeOpen != null && leftEyeOpen < 0.2) &&
            (rightEyeOpen != null && rightEyeOpen < 0.2);

        if (isAsleep) {
          widget.onStatusChange("ASLEEP");
        } else {
          widget.onStatusChange("AWAKE");
        }
      }
    } catch (e) {
      print("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // --- NEW CONVERTER FOR LATEST ML KIT ---
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.cameras[_selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      // Only return null if format is totally unknown, otherwise try processing
      if (format == null) return null;
    }

    // Since format is nullable in recent versions, we handle it safely or assume nv21 for Android
    final validFormat = format ?? InputImageFormat.nv21;

    // Compose Metadata
    // Note: 'bytesPerRow' is usually the first plane's bytesPerRow on Android/iOS for these formats
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    // Concatenate planes
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: validFormat,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // Helper for Android Orientation
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFeed ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }
    return CameraPreview(_controller!);
  }
}
