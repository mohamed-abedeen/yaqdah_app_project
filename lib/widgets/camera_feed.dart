import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/face_monitoring_service.dart'; // Use Service

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isMonitoring;
  final bool showFeed;
  final void Function(String, Map<String, int>) onStatusChange;
  final void Function(int) onCameraChanged;

  const CameraFeed({
    super.key,
    required this.cameras,
    required this.isMonitoring,
    required this.showFeed,
    required this.onStatusChange,
    required this.onCameraChanged,
  }) : super();

  @override
  State<CameraFeed> createState() => CameraFeedState();
}

class CameraFeedState extends State<CameraFeed> {
  CameraController? _controller;
  int _selectedCameraIndex = 0; // Restored
  //  Create instance of Service
  final FaceMonitoringService _faceService = FaceMonitoringService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void didUpdateWidget(CameraFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Handle monitoring state change
    if (widget.isMonitoring != oldWidget.isMonitoring) {
      if (widget.isMonitoring) {
        if (!_controller!.value.isStreamingImages) {
          _controller!.startImageStream(_processImage);
        }
      } else {
        if (_controller!.value.isStreamingImages) {
          _controller!.stopImageStream();
        }
      }
    }
  }

  void _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
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
        // Only start heavy image stream if monitoring is actively enabled
        if (widget.isMonitoring) {
          _controller!.startImageStream(_processImage);
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void switchCamera() {
    if (widget.cameras.length < 2) return;

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
    if (_controller == null || !mounted) return;

    await _faceService.processFrame(
      image: image,
      camera: widget.cameras[_selectedCameraIndex],
      deviceOrientation: _controller!.value.deviceOrientation,
      isMonitoring: widget.isMonitoring,
      onStatusChange: (status, metrics) {
        if (mounted) widget.onStatusChange(status, metrics);
      },
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceService.dispose();
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
