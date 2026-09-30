import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/face_monitoring_service.dart'; // Use Service

/// Owns the camera and runs face detection.
///
/// It renders nothing itself; the Drive screen shows the preview through
/// [onControllerChanged].
///
/// The camera is open only while [enabled] and the app is on screen, and
/// its preview runs only while [showPreview]: a running preview makes
/// Flutter redraw the whole screen for every camera frame, even when the
/// preview isn't visible.
class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;

  /// Keep the camera open (a trip is running or the Drive tab is showing).
  final bool enabled;

  /// The preview thumbnail is on screen.
  final bool showPreview;
  final bool isMonitoring;

  /// Run a light face-presence check while not monitoring (pre-trip).
  final bool detectPresence;
  final void Function(String, Map<String, int>) onStatusChange;
  final void Function(int) onCameraChanged;

  /// The active controller, or null while the camera is closed.
  final ValueChanged<CameraController?>? onControllerChanged;

  /// Whether a face is in frame, for the readiness checklist.
  final ValueChanged<bool>? onFacePresenceChanged;

  const CameraFeed({
    super.key,
    required this.cameras,
    required this.enabled,
    required this.showPreview,
    required this.isMonitoring,
    this.detectPresence = false,
    required this.onStatusChange,
    required this.onCameraChanged,
    this.onControllerChanged,
    this.onFacePresenceChanged,
  }) : super();

  @override
  State<CameraFeed> createState() => CameraFeedState();
}

class CameraFeedState extends State<CameraFeed> with WidgetsBindingObserver {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  final FaceMonitoringService _faceService = FaceMonitoringService();
  bool _appVisible = true;

  /// Before a trip, frames are only needed for one presence check a
  /// second; the stream rests in between instead of copying ~30 frames a
  /// second to Dart.
  bool _presenceResting = false;
  Timer? _presenceTimer;

  /// Camera operations run one at a time, in order.
  Future<void> _queue = Future.value();

  bool get _wantCamera =>
      mounted && widget.enabled && _appVisible && widget.cameras.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  @override
  void didUpdateWidget(CameraFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Each trip is scored on its own.
    if (widget.isMonitoring && !oldWidget.isMonitoring) {
      _faceService.resetSession();
      _presenceTimer?.cancel();
      _presenceResting = false;
    }
    if (widget.enabled != oldWidget.enabled ||
        widget.showPreview != oldWidget.showPreview ||
        widget.isMonitoring != oldWidget.isMonitoring ||
        widget.detectPresence != oldWidget.detectPresence) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release the camera in the background; reopen it on return.
    final visible =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (visible == _appVisible) return;
    _appVisible = visible;
    _sync();
  }

  void _enqueue(Future<void> Function() operation) {
    _queue = _queue.then((_) => operation()).catchError((Object e) {
      debugPrint("Camera Error: $e");
    });
  }

  /// Brings the camera in line with the widget's settings.
  void _sync() => _enqueue(_apply);

  Future<void> _apply() async {
    if (!_wantCamera) {
      await _release();
      return;
    }
    final controller = _controller ?? await _open();
    if (controller == null || !_wantCamera) return;

    if (widget.showPreview) {
      await controller.resumePreview();
    } else {
      await controller.pausePreview();
    }

    final wantStream =
        widget.isMonitoring || (widget.detectPresence && !_presenceResting);
    if (wantStream && !controller.value.isStreamingImages) {
      await controller.startImageStream(_processImage);
    } else if (!wantStream && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<CameraController?> _open() async {
    final controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      // 15 fps is plenty for ~8 checks a second and halves the frames
      // copied to Dart. Android keeps its default rate: a fixed rate the
      // camera doesn't list can fail there.
      fps: Platform.isIOS ? 15 : null,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint("Camera Error: $e");
      await controller.dispose();
      return null;
    }
    // The tab or app may have changed while the camera was opening.
    if (!_wantCamera) {
      await controller.dispose();
      return null;
    }

    _controller = controller;
    widget.onCameraChanged(_selectedCameraIndex);
    widget.onControllerChanged?.call(controller);
    return controller;
  }

  Future<void> _release() async {
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    if (mounted) {
      widget.onControllerChanged?.call(null);
      // Let the preview leave the screen before its texture goes away.
      if (SchedulerBinding.instance.framesEnabled) {
        await SchedulerBinding.instance.endOfFrame;
      }
    }
    await _disposeController(controller);
  }

  static Future<void> _disposeController(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
    await controller.dispose();
  }

  void switchCamera() {
    if (widget.cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _enqueue(_release);
    _sync();
  }

  // --- AI PROCESSING LOOP ---
  void _processImage(CameraImage image) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final camera = controller.description;

    if (widget.isMonitoring) {
      await _faceService.processFrame(
        image: image,
        camera: camera,
        deviceOrientation: controller.value.deviceOrientation,
        isMonitoring: widget.isMonitoring,
        onStatusChange: (status, metrics) {
          if (!mounted) return;
          widget.onStatusChange(status, metrics);
          widget.onFacePresenceChanged?.call(status != "NO_FACE");
        },
      );
    } else if (widget.detectPresence) {
      final present = await _faceService.detectFacePresence(
        image: image,
        camera: camera,
        deviceOrientation: controller.value.deviceOrientation,
      );
      if (present != null && mounted) {
        widget.onFacePresenceChanged?.call(present);
        _restPresenceStream();
      }
    }
  }

  void _restPresenceStream() {
    if (_presenceResting || widget.isMonitoring) return;
    _presenceResting = true;
    _sync();
    _presenceTimer?.cancel();
    _presenceTimer = Timer(const Duration(seconds: 1), () {
      _presenceResting = false;
      if (mounted) _sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    // Runs after any open still in progress; that open sees `mounted` is
    // false and closes its own controller.
    _enqueue(() async {
      final controller = _controller;
      _controller = null;
      if (controller != null) await _disposeController(controller);
      _faceService.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
