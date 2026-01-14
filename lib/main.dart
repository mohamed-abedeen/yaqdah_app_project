import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart'; // ✅ FIXED: Added Import
import 'screens/login_screen.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error initializing camera: $e');
  }

  // Initialize critical services before app starts
  await ThemeService.instance.init();

  runApp(const YaqdahApp());
}

class YaqdahApp extends StatefulWidget {
  const YaqdahApp({super.key});

  @override
  State<YaqdahApp> createState() => _YaqdahAppState();
}

class _YaqdahAppState extends State<YaqdahApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yaqdah',
          theme: ThemeService.instance.lightTheme,
          darkTheme: ThemeService.instance.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // ✅ FIXED: Correctly referencing Homescreen
          home: Homescreen(cameras: cameras),
        );
      },
    );
  }
}
