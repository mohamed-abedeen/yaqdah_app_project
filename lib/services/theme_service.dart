import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._internal();
  factory ThemeService() => instance;
  ThemeService._internal();

  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('is_dark_mode') ?? true;
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode.value);
  }

  // ==============================================================================
  // 🎨 STATIC GLOBAL STATUS COLORS
  // These are used for specific logic states (e.g., "Safe", "Danger") regardless of theme mode.
  // ==============================================================================

  // 🟢 Green: Used for "Safe" driver status, Success messages, and Active Toggles
  static const Color green = Color.fromARGB(255, 9, 189, 0);

  // 🟣 Purple: Used for "Time/Duration" icons, Charts, and Secondary stats (Speed)
  static const Color purple = Color.fromARGB(255, 136, 85, 255);

  // 🟠 Orange: Used for "Drowsy" warning status, "Alert" icons, and Caution states
  static const Color orange = Color(0xFFFF8C00);

  // 🔵 Blue: Used for "Distance" icons, Map routes, and informational messages
  static const Color blue = Color(0xFF3B82F6);

  // 🔴 Red: Used for "Emergency/Asleep" status, Delete buttons, and Danger zones
  static const Color red = Color.fromARGB(255, 250, 19, 6);

  /// Cairo for Arabic, Inter for English
  static TextTheme _textTheme({bool isArabic = true}) {
    if (isArabic) {
      return GoogleFonts.cairoTextTheme();
    }
    return GoogleFonts.interTextTheme();
  }

  ThemeData lightThemeFor({bool isArabic = true}) {
    return lightTheme.copyWith(textTheme: _textTheme(isArabic: isArabic));
  }

  ThemeData darkThemeFor({bool isArabic = true}) {
    return darkTheme.copyWith(
      textTheme: _textTheme(
        isArabic: isArabic,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }

  // ==============================================================================
  // ☀️ LIGHT THEME CONFIGURATION
  // ==============================================================================
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color.fromARGB(255, 3, 200, 17),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    colorScheme: const ColorScheme.light(
      primary: Color.fromARGB(255, 2, 242, 86),
      secondary: purple,
      error: red,
      tertiary: orange,
      surface: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Color.fromARGB(255, 6, 6, 6)),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E1E1E)),
      titleLarge: TextStyle(
        color: Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // ==============================================================================
  // 🌙 DARK THEME CONFIGURATION
  // ==============================================================================
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 3, 200, 17),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    cardColor: const Color(0xFF2A2A2A),
    dividerColor: const Color.fromARGB(255, 73, 73, 73),
    colorScheme: ColorScheme.dark(
      primary: const Color.fromARGB(255, 2, 242, 86),
      secondary: const Color.fromARGB(255, 3, 200, 17),
      error: const Color.fromARGB(255, 253, 15, 3),
      tertiary: orange,
      surface: const Color(0xFF2A2A2A),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
