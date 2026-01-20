import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../widgets/face_painter.dart';
import '../services/theme_service.dart';

class TestModeScreen extends StatefulWidget {
  const TestModeScreen({super.key});

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  List<Face> _faces = [];
  CameraImage? _currentImage;

  double _leftEyeProb = 0.0;
  double _rightEyeProb = 0.0;
  double _headYaw = 0.0;
  double _headPitch = 0.0;
  String _status = "WAITING...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCam,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _controller!.startImageStream(_processImage);
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _currentImage = image;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces = faces;
          if (faces.isNotEmpty) {
            final f = faces.first;
            _leftEyeProb = f.leftEyeOpenProbability ?? -1;
            _rightEyeProb = f.rightEyeOpenProbability ?? -1;
            _headYaw = f.headEulerAngleY ?? 0;
            _headPitch = f.headEulerAngleX ?? 0;

            if (_leftEyeProb < 0.25 && _rightEyeProb < 0.25) {
              _status = "EYES CLOSED (0.25)";
            } else if (_headYaw.abs() > 25 || _headPitch.abs() > 20) {
              _status = "DISTRACTED (Angle)";
            } else {
              _status = "ACTIVE";
            }
          } else {
            _status = "NO FACE";
            _leftEyeProb = 0;
            _rightEyeProb = 0;
            _headYaw = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _controller!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotation.rotation270deg;
    } else {
      rotation = InputImageRotation.rotation0deg;
    }

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

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

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Detection Lab",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_currentImage != null)
            CustomPaint(
              painter: FacePainter(
                faces: _faces,
                imageSize: Size(
                  _currentImage!.width.toDouble(),
                  _currentImage!.height.toDouble(),
                ),
                rotation: InputImageRotation.rotation270deg,
                cameraLensDirection: CameraLensDirection.front,
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeService.Green),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    "STATUS",
                    _status,
                    _status == "ACTIVE" ? ThemeService.Green : ThemeService.red,
                  ),
                  const Divider(color: Colors.grey),
                  _row(
                    "Left Eye",
                    "${(_leftEyeProb * 100).toInt()}%",
                    Colors.white,
                  ),
                  _row(
                    "Right Eye",
                    "${(_rightEyeProb * 100).toInt()}%",
                    Colors.white,
                  ),
                  const SizedBox(height: 8),
                  _row(
                    "Head Yaw",
                    "${_headYaw.toInt()}°",
                    _headYaw.abs() > 25 ? ThemeService.orange : Colors.white,
                  ),
                  _row(
                    "Head Pitch",
                    "${_headPitch.toInt()}°",
                    _headPitch.abs() > 20 ? ThemeService.orange : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
