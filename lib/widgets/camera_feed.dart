import 'dart:io'; // Needed for ByteData
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // For WriteBuffer
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../logic/drowsiness_logic.dart';

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isMonitoring;
  final bool showFeed;
  final Function(String status) onStatusChange;

  const CameraFeed({
    super.key,
    required this.cameras,
    required this.isMonitoring,
    required this.showFeed,
    required this.onStatusChange,
  });

  @override
  State<CameraFeed> createState() => CameraFeedState();
}

class CameraFeedState extends State<CameraFeed> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    ),
  );
  final DrowsinessLogic _logic = DrowsinessLogic();
  bool _isProcessing = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera(0);
  }

  Future<void> _initCamera(int index) async {
    await [Permission.camera].request();
    if (widget.cameras.isEmpty) return;

    if (index >= widget.cameras.length) index = 0;
    _selectedCameraIndex = index;

    if (_cameraController != null) await _cameraController!.dispose();

    _cameraController = CameraController(
      widget.cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      _cameraController!.startImageStream(_processImage);
      setState(() {});
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  void switchCamera() {
    if (widget.cameras.length < 2) return;
    _initCamera(_selectedCameraIndex + 1);
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing || !widget.isMonitoring) return;
    _isProcessing = true;
    try {
      final inputImage = _convertInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        String newStatus = _logic.checkFace(faces.first);
        widget.onStatusChange(newStatus);
      }
    } catch (e) {
      print("Detection Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final imageRotation = _rotationIntToImageRotation(
      _cameraController!.description.sensorOrientation,
    );
    final inputImageFormat = InputImageFormatValue.fromRawValue(
      image.format.raw,
    );

    if (inputImageFormat == null) return null;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: widget.showFeed ? 300 : 1,
      child: Opacity(
        opacity: widget.showFeed ? 1.0 : 0.0,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height:
                    MediaQuery.of(context).size.width *
                    _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
