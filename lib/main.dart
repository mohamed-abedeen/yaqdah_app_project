import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/location_provider.dart';
import 'services/connectivity_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Start connectivity monitoring for offline sync
  ConnectivityService.instance.startMonitoring();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    if (kDebugMode) {
      print('Error initializing camera: $e');
    }
  }

  // Initialize critical services before app starts
  await ThemeService.instance.init();

  // Debug: only print users in development mode
  if (kDebugMode) {
    await DatabaseService.instance.debugPrintAllUsers();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initApp()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          SettingsProvider,
          MonitoringProvider
        >(
          create: (_) => MonitoringProvider(),
          update: (_, auth, settings, monitor) => monitor!
            ..updateAuth(auth)
            ..updateSettings(settings),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider()..startLocationUpdates(),
        ),
      ],
      child: const YaqdahApp(),
    ),
  );
}

class YaqdahApp extends StatefulWidget {
  const YaqdahApp({super.key});

  @override
  State<YaqdahApp> createState() => _YaqdahAppState();
}

class _YaqdahAppState extends State<YaqdahApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeService.instance.isDarkMode,
          builder: (context, isDark, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Yaqdah',
              theme: ThemeService.instance.lightTheme,
              darkTheme: ThemeService.instance.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

              // ── Localization ──────────────────────────────────────────────
              locale: settings.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,

              // ── RTL / LTR direction ───────────────────────────────────────
              builder: (context, child) {
                final isRtl = settings.locale.languageCode == 'ar';
                return Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },

              home: HomeScreen(cameras: cameras),
            );
          },
        );
      },
    );
  }
}
