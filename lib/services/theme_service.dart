import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  final ValueNotifier<bool> isDarkMode = ValueNotifier(true);

  // ===========================================================================
  // 🎨 COLOR PALETTE (Matched to Your Image)
  // ===========================================================================

  // --- DARK MODE (Slate & Blue) ---
  static const Color _darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color _darkSurface = Color(0xFF1E293B); // Slate 800 (Cards)
  static const Color _darkPrimary = Color(0xFF2563EB); // Blue 600
  static const Color _darkSecondary = Color(
    0xFF172554,
  ); // Blue 950 (Gradient Accent)
  static const Color _darkTextMain = Colors.white;
  static const Color _darkTextSub = Color(0xFF94A3B8); // Slate 400
  static const Color _darkBorder = Color(0xFF334155); // Slate 700

  // --- LIGHT MODE (Standard) ---
  static const Color _lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color _lightSurface = Colors.white;
  static const Color _lightPrimary = Color(0xFF2563EB); // Blue 600
  static const Color _lightSecondary = Color(0xFFDBEAFE); // Blue 100
  static const Color _lightTextMain = Color(0xFF0F172A); // Slate 900
  static const Color _lightTextSub = Color(0xFF64748B); // Slate 500
  static const Color _lightBorder = Color(0xFFE2E8F0); // Slate 200

  // ===========================================================================
  // ⚙️ LOGIC
  // ===========================================================================

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('darkMode') ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  // ===========================================================================
  // 🌓 THEME DEFINITIONS
  // ===========================================================================

  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _darkBackground,
      primaryColor: _darkPrimary,
      cardColor: _darkSurface,
      dividerColor: _darkBorder,

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary, // Used for Gradient End
        surface: _darkSurface,
        background: _darkBackground, // Used for Gradient Start
        onSurface: _darkTextMain,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: _darkTextMain,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: _darkTextMain),
        bodySmall: TextStyle(color: _darkTextSub),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkTextMain),
        titleTextStyle: TextStyle(
          color: _darkTextMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        hintStyle: const TextStyle(color: _darkTextSub),
        prefixIconColor: _darkTextSub,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: _lightBackground,
      primaryColor: _lightPrimary,
      cardColor: _lightSurface,
      dividerColor: _lightBorder,

      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        background: _lightBackground,
        onSurface: _lightTextMain,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: _lightTextMain,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: _lightTextMain),
        bodySmall: TextStyle(color: _lightTextSub),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: _lightTextMain),
        titleTextStyle: TextStyle(
          color: _lightTextMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _lightTextSub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
