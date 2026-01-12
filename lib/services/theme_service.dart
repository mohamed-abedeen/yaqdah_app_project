import 'package:yaqdah_app/screens/signup_screen.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // Singleton - Access this anywhere using ThemeService.instance
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  // The Listener that widgets listen to
  final ValueNotifier<bool> isDarkMode = ValueNotifier(true);

  // ===========================================================================
  // 🎨 COLOR PALETTE - CONTROL CENTER
  // ===========================================================================
  // 📝 NOTE: Flutter colors use Hex format: 0xFF + RRGGBB
  // Example: 0xFF000000 is Black, 0xFFFFFFFF is White.

  // ➤ DARK MODE COLORS
  // ---------------------------------------------------------------------------
  static const Color _darkBackground = Color(0xFF0F172A); 
  // ⬆️ MAIN BACKGROUND: The background color of the whole app (Scaffold).

  static const Color _darkSurface = Color(0xFF1E293B);    
  // ⬆️ CARDS & SHEETS: The color of Cards, Bottom Sheets, and Dialog boxes.

  static const Color _darkPrimary = Color(0xFF2563EB);    
  // ⬆️ BRAND COLOR: Used for main Buttons, Switches, and active icons.

  static const Color _darkSecondary = Color(0xFF60A5FA);  
  // ⬆️ ACCENT COLOR: Used for Floating Action Buttons or highlights.

  static const Color _darkTextMain = Colors.white;        
  // ⬆️ MAIN TEXT: Used for Titles and big headers.

  static const Color _darkTextSub = Colors.grey;          
  // ⬆️ SUB TEXT: Used for subtitles, hint text, and descriptions.

  static const Color _darkBorder = Colors.white10;        
  // ⬆️ BORDERS: Used for thin lines around TextFields or Dividers.


  // ➤ LIGHT MODE COLORS
  // ---------------------------------------------------------------------------
  static const Color _lightBackground = Color(0xFFF4F4F4); 
  // ⬆️ MAIN BACKGROUND: The background color of the whole app (Scaffold).
  // (Previously inconsistent grey)

  static const Color _lightSurface = Colors.white;         
  // ⬆️ CARDS & SHEETS: The color of Cards, Bottom Sheets, and Dialog boxes.

  static const Color _lightPrimary = Color(0xFF2563EB);    
  // ⬆️ BRAND COLOR: Used for main Buttons, Switches, and active icons.

  static const Color _lightSecondary = Color(0xFF3B82F6);  
  // ⬆️ ACCENT COLOR: Used for Floating Action Buttons or highlights.

  static const Color _lightTextMain = Color(0xFF0F172A);   
  // ⬆️ MAIN TEXT: Used for Titles (Dark Blue/Black).

  static const Color _lightTextSub = Colors.black54;       
  // ⬆️ SUB TEXT: Used for subtitles and weak text.

  static const Color _lightBorder = Colors.black12;        
  // ⬆️ BORDERS: Used for thin lines around TextFields.


  // ===========================================================================
  // ⚙️ LOGIC (Load/Save Preferences)
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
  // 🌓 THEME DEFINITIONS (MAPPING THE COLORS)
  // ===========================================================================

  // ➤ DARK THEME OBJECT
  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _darkBackground, // Maps to Main Background
      primaryColor: _darkPrimary,
      cardColor: _darkSurface,
      dividerColor: _darkBorder,

      // Global Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        onSurface: _darkTextMain,
      ),

      // Text Styling
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: _darkTextMain),
        bodySmall: TextStyle(color: _darkTextSub),
        titleLarge: TextStyle(color: _darkTextMain, fontWeight: FontWeight.bold),
      ),

      // App Bar Styling
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

      // Input Fields (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        hintStyle: const TextStyle(color: _darkTextSub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
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

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ➤ LIGHT THEME OBJECT
  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: _lightBackground, // Maps to Main Background
      primaryColor: _lightPrimary,
      cardColor: _lightSurface,
      dividerColor: _lightBorder,

      // Global Color Scheme
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        onSurface: _lightTextMain,
      ),

      // Text Styling
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: _lightTextMain),
        bodySmall: TextStyle(color: _lightTextSub),
        titleLarge: TextStyle(color: _lightTextMain, fontWeight: FontWeight.bold),
      ),

      // App Bar Styling
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground, // FIXED: Removed the Lime Green
        elevation: 0,
        iconTheme: IconThemeData(color: _lightTextMain),
        titleTextStyle: TextStyle(
          color: _lightTextMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Input Fields (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Usually white in light mode
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

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}