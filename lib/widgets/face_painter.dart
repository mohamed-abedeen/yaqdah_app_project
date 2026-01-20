import 'dart:math'; // ✅ Needed for Point
import 'package:camera/camera.dart'; // ✅ Needed for CameraLensDirection
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00FF7F); // Neon Green

    final Paint paintRed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    // ✅ Fix: Paint does not have copyWith, so we create a new one for the blue mesh
    final Paint paintBlue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue.withOpacity(0.5);

    for (final Face face in faces) {
      // Draw Face Bounding Box
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      canvas.drawRect(rect, paint);

      // Draw Contours (Eyes)
      _paintContour(canvas, size, face, FaceContourType.leftEye, paintRed);
      _paintContour(canvas, size, face, FaceContourType.rightEye, paintRed);
      // Use fixed blue paint
      _paintContour(canvas, size, face, FaceContourType.face, paintBlue);
    }
  }

  void _paintContour(
    Canvas canvas,
    Size size,
    Face face,
    FaceContourType type,
    Paint paint,
  ) {
    final contour = face.contours[type];
    if (contour?.points != null) {
      for (final point in contour!.points) {
        final offset = _scalePoint(
          point: point,
          imageSize: imageSize,
          widgetSize: size,
          rotation: rotation,
          cameraLensDirection: cameraLensDirection,
        );
        canvas.drawCircle(offset, 2, paint);
      }
    }
  }

  // --- COORDINATE MAPPING LOGIC ---
  Offset _scalePoint({
    required Point<int> point,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    final double scaleX = widgetSize.width / imageSize.height;
    final double scaleY = widgetSize.height / imageSize.width;

    double x = point.x.toDouble() * scaleX;
    double y = point.y.toDouble() * scaleY;

    if (cameraLensDirection == CameraLensDirection.front) {
      x = widgetSize.width - x;
    }

    return Offset(x, y);
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    final double scaleX = widgetSize.width / imageSize.height;
    final double scaleY = widgetSize.height / imageSize.width;

    double left = rect.left * scaleX;
    double top = rect.top * scaleY;
    double right = rect.right * scaleX;
    double bottom = rect.bottom * scaleY;

    if (cameraLensDirection == CameraLensDirection.front) {
      final oldLeft = left;
      left = widgetSize.width - right;
      right = widgetSize.width - oldLeft;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.imageSize != imageSize;
  }
}
