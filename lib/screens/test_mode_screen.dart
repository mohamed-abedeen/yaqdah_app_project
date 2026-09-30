import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_monitoring_service.dart';
import '../widgets/face_painter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class TestModeScreen extends StatefulWidget {
  const TestModeScreen({super.key});

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
  // The lab is always drawn over the camera, so it uses the dark tokens.
  static final _ok = AppColors.dark.ok;
  static final _warn = AppColors.dark.warn;
  static final _danger = AppColors.dark.danger;

  CameraController? _controller;
  bool _cameraFailed = false;

  // Same settings as the drive monitor, plus contours for the overlay.
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );
  bool _isProcessing = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  List<Face> _faces = [];
  CameraImage? _currentImage;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('noCamera', 'No camera');
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      await controller.startImageStream(_processImage);
    } catch (e) {
      debugPrint("Test lab camera error: $e");
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  void _processImage(CameraImage image) async {
    final controller = _controller;
    if (_isProcessing || controller == null) return;
    // About ten checks a second is plenty to watch the numbers.
    final now = DateTime.now();
    if (now.difference(_lastFrame).inMilliseconds < 100) return;
    _lastFrame = now;
    _isProcessing = true;
    _currentImage = image;

    try {
      final orientation = controller.value.deviceOrientation;
      final inputImage = FaceMonitoringService.inputImageFromCameraImage(
        image,
        controller.description,
        orientation,
      );
      if (inputImage == null) return;
      _rotation =
          FaceMonitoringService.rotationFor(
            controller.description,
            orientation,
          ) ??
          _rotation;

      final faces = await _faceDetector.processImage(inputImage);

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

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((Object _) {});
      }
      controller.dispose();
    }
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.checkNoCamera,
            style: AppFonts.body(context, 16, color: Colors.white),
          ),
        ),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.testLab,
          style: AppFonts.body(
            context,
            17,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
                rotation: _rotation,
                cameraLensDirection: _controller!.description.lensDirection,
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dark.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.dark.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row("STATUS", _status, _status == "ACTIVE" ? _ok : _danger),
                  Divider(color: AppColors.dark.line),
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
                    _headYaw.abs() > 25 ? _warn : Colors.white,
                  ),
                  _row(
                    "Head Pitch",
                    "${_headPitch.toInt()}°",
                    _headPitch.abs() > 20 ? _warn : Colors.white,
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
            style: AppFonts.body(
              context,
              14,
              weight: FontWeight.w600,
              color: AppColors.dark.subtext,
            ),
          ),
          Text(
            value,
            style: AppFonts.display(
              context,
              16,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
