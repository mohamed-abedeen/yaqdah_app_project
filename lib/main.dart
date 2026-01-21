import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    if (kDebugMode) {
      print('Error initializing camera: $e');
    }
  }

  // Initialize critical services before app starts
  await ThemeService.instance.init();

  // ✅ DEBUG: Print all registered users to the console on startup
  await DatabaseService.instance.debugPrintAllUsers();

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

          home: HomeScreen(cameras: cameras),
        );
      },
    );
  }
}
