import 'package:flutter/material.dart';
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

  // ✅ CENTRALIZED COLORS (No more hardcoding in screens)
  static const Color neonGreen = Color.fromARGB(255, 2, 188, 21);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFFF8C00);
  static const Color blue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFFF3B30);

  // --- Themes ---
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color.fromARGB(255, 0, 255, 81),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    colorScheme: const ColorScheme.light(
      primary: Color.fromARGB(255, 2, 242, 86),
      secondary: purple,
      error: red,
      tertiary: orange, // Using tertiary for status orange
      surface: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E1E1E)),
      titleLarge: TextStyle(
        color: Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 0, 255, 64),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    cardColor: const Color(0xFF2A2A2A),
    dividerColor: const Color(0xFF3A3A3A),
    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 0, 255, 30),
      secondary: purple,
      error: red,
      tertiary: orange,
      surface: Color(0xFF2A2A2A),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
