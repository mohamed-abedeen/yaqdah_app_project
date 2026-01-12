import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

// You need to import the actual screen you want to show
// import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.instance.init();

  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("CRITICAL CAMERA ERROR: $e");
  }

  runApp(YaqdahApp(cameras: cameras));
}

class YaqdahApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const YaqdahApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yaqdah App',
          theme: isDarkMode
              ? ThemeService.instance.darkTheme
              : ThemeService.instance.lightTheme,

          // --- FIX IS HERE ---
          // Instead of calling YaqdahApp again, call your actual Main Screen
          home: Homescreen(cameras: cameras),
        );
      },
    );
  }
}
          // 