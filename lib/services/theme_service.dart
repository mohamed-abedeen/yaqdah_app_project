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

  // ==============================================================================
  // 🎨 STATIC GLOBAL STATUS COLORS
  // These are used for specific logic states (e.g., "Safe", "Danger") regardless of theme mode.
  // ==============================================================================

  // 🟢 Green: Used for "Safe" driver status, Success messages, and Active Toggles
  static const Color Green = Color.fromARGB(255, 9, 189, 0);

  // 🟣 Purple: Used for "Time/Duration" icons, Charts, and Secondary stats (Speed)
  static const Color purple = Color.fromARGB(255, 136, 85, 255);

  // 🟠 Orange: Used for "Drowsy" warning status, "Alert" icons, and Caution states
  static const Color orange = Color(0xFFFF8C00);

  // 🔵 Blue: Used for "Distance" icons, Map routes, and informational messages
  static const Color blue = Color(0xFF3B82F6);

  // 🔴 Red: Used for "Emergency/Asleep" status, Delete buttons, and Danger zones
  static const Color red = Color.fromARGB(255, 250, 19, 6);

  // ==============================================================================
  // ☀️ LIGHT THEME CONFIGURATION
  // Used when the app is in "Day Mode"
  // ==============================================================================
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    // 🎨 Main Brand Color: Used for active tab icons, links, and focus borders
    primaryColor: const Color.fromARGB(255, 3, 200, 17),

    // ⬜ Screen Background: The color behind everything (e.g., the settings page background)
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    // 🃏 Card Background: Used for the white boxes in Reports, Settings, and Dashboard stats
    cardColor: Colors.white,

    // ➖ Divider Color: The thin grey lines separating list items
    dividerColor: const Color(0xFFE0E0E0),

    colorScheme: const ColorScheme.light(
      // 🟢 Primary Action: Color of Floating Action Buttons (Mic) and Switches
      primary: Color.fromARGB(255, 2, 242, 86),

      // 🟣 Secondary Accent: Used for selection controls and sliders
      secondary: purple,

      // 🔴 Error: Used for input validation errors (e.g., wrong password)
      error: red,

      // 🟠 Tertiary: Helper color often used for warnings in this app
      tertiary: orange,

      // ⬜ Surface: Usually matches Card Color (background of dialogs/popups)
      surface: Colors.white,
    ),

    // 🔳 Icon Color: The default color for navigation bar icons and standard icons
    iconTheme: const IconThemeData(color: Color.fromARGB(255, 6, 6, 6)),

    textTheme: const TextTheme(
      // 📝 Body Text: Standard paragraph text (e.g., settings labels)
      bodyMedium: TextStyle(color: Color(0xFF1E1E1E)),

      // 📢 Titles: Large page headings (e.g., "Settings", "Reports")
      titleLarge: TextStyle(
        color: Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // ==============================================================================
  // 🌙 DARK THEME CONFIGURATION
  // Used when the app is in "Night Mode" (Neon Style)
  // ==============================================================================
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // 🎨 Main Brand Color: Used for active tab icons (Neon Purple in Dark Mode)
    primaryColor: const Color.fromARGB(255, 91, 46, 235),

    // ⬛ Screen Background: The main dark background behind all content
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),

    // 🔲 Card Background: Slightly lighter dark color for panels/cards to stand out
    cardColor: const Color(0xFF2A2A2A),

    // ➖ Divider Color: Thin lines separating items (Dark Grey)
    dividerColor: const Color.fromARGB(255, 73, 73, 73),

    colorScheme: const ColorScheme.dark(
      // 🟡 Primary Action: High contrast buttons (Neon Yellow/Gold for visibility)
      primary: Color.fromARGB(255, 242, 216, 76),

      // 🟣 Secondary Accent: Used for sliders and secondary UI elements
      secondary: purple,

      // 🔴 Error: High contrast red for errors in dark mode
      error: Color.fromARGB(255, 253, 15, 3),

      // 🟠 Tertiary: Warning color
      tertiary: orange,

      // 🔲 Surface: Matches Card Color (popups/dialogs)
      surface: Color(0xFF2A2A2A),
    ),

    // ⚪ Icon Color: Default icons are White to stand out against dark background
    iconTheme: const IconThemeData(color: Colors.white),

    textTheme: const TextTheme(
      // 📝 Body Text: Standard text is White in dark mode
      bodyMedium: TextStyle(color: Colors.white),

      // 📢 Titles: Page headings are White and Bold
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
