import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../logic/drowsiness_logic.dart'; // ✅ Import Logic

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

  // ✅ UPDATED: 250ms = 4 Frames Per Second (1000/250 = 4)
  DateTime _lastFrameTime = DateTime.now();
  final int _throttleMillis = 250;

  // ✅ Create instance of your Logic Engine
  final DrowsinessLogic _logic = DrowsinessLogic();

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
      // Use Medium (480p/720p) - Good balance of speed/quality
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
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

    // Stop old stream before switching
    _controller?.stopImageStream();
    _controller?.dispose();
    _controller = null;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });
    _initializeCamera();
  }

  // --- AI PROCESSING LOOP ---
  void _processImage(CameraImage image) async {
    // 1. Basic Checks
    if (_isProcessing || !widget.isMonitoring) return;

    // ✅ CHECK: If less than 250ms passed, SKIP this frame.
    if (DateTime.now().difference(_lastFrameTime).inMilliseconds <
        _throttleMillis) {
      return;
    }

    _isProcessing = true;
    _lastFrameTime = DateTime.now(); // Reset timer

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        // If no face seen, wait a moment then trigger Distracted
        widget.onStatusChange("DISTRACTED");
      } else {
        final face = faces.first;

        // ✅ PASS DATA TO LOGIC ENGINE
        final DriverState state = _logic.checkFace(face);

        // ✅ CONVERT RESULT TO STRING FOR APP
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

        widget.onStatusChange(statusString);
      }
    } catch (e) {
      print("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null; // Safety check

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
      format: format!,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void dispose() {
    _controller?.stopImageStream();
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
