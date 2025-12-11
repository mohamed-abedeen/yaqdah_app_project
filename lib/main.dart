import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // This file now contains the real 'YaqdahApp' class

Future<void> main() async {
  // 1. Initialize Flutter Bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Cameras with Safety Check
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("CRITICAL CAMERA ERROR: $e");
  }

  // 3. Run the App
  // This calls the YaqdahApp class from 'home_screen.dart'
  runApp(YaqdahApp(cameras: cameras));
}