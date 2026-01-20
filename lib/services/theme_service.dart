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

  // --- Static Global Colors (Used for specific statuses like "Safe", "Drowsy", "Danger") ---
  static const Color Green = Color.fromARGB(
    255,
    9,
    189,
    0,
  ); // 🟢 CHANGES: "Safe" status, Active Toggles, Success messages
  static const Color purple = Color.fromARGB(
    255,
    136,
    85,
    255,
  ); // 🟣 CHANGES: "Time/Duration" icons, Charts, Secondary stats
  static const Color orange = Color(
    0xFFFF8C00,
  ); // 🟠 CHANGES: "Drowsy" warning status, "Alert" icons
  static const Color blue = Color(
    0xFF3B82F6,
  ); // 🔵 CHANGES: "Distance" icons, Map routes, Info messages
  static const Color red = Color.fromARGB(
    255,
    250,
    19,
    6,
  ); // 🔴 CHANGES: "Emergency" status, Delete buttons, Danger zones

  // --- Light Theme Configuration ---
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    // 🎨 Main Branding Color (Buttons, Active Tab Icons, Links)
    primaryColor: const Color.fromARGB(255, 3, 200, 17),

    // ⬜ Background of the whole screen (Behind the content)
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    // 🃏 Background of Cards, Popups, and Bottom Sheets
    cardColor: Colors.white,

    // ➖ Color of thin lines separating list items
    dividerColor: const Color(0xFFE0E0E0),

    colorScheme: const ColorScheme.light(
      // 🟢 Primary Action Color (Floating Action Button, Active Switches)
      primary: Color.fromARGB(255, 2, 242, 86),

      // 🟣 Secondary Accent (Selection controls, sliders)
      secondary: purple,

      // 🔴 Error Color (Input validation errors, warning borders)
      error: red,

      // 🟠 Tertiary Accent (Used for Warning/Orange statuses)
      tertiary: orange,

      // ⬜ Surface Color (Usually matches Card Color)
      surface: Colors.white,
    ),

    // 🔳 Default color for Icons (Nav bar icons, standard icons)
    iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),

    textTheme: const TextTheme(
      // 📝 Standard Paragraph Text (Settings labels, descriptions)
      bodyMedium: TextStyle(color: Color(0xFF1E1E1E)),

      // 📢 Large Headings (Page Titles like "Settings", "Reports")
      titleLarge: TextStyle(
        color: Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // --- Dark Theme Configuration ---
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // 🎨 Main Branding Color in Dark Mode (Buttons, Active Icons)
    primaryColor: const Color.fromARGB(255, 91, 46, 235),

    // ⬛ Background of the whole screen (The main dark background)
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),

    // 🔲 Background of Cards, Popups, and Bottom Sheets (Slightly lighter dark)
    cardColor: const Color(0xFF2A2A2A),

    // ➖ Color of thin lines in Dark Mode
    dividerColor: const Color.fromARGB(255, 73, 73, 73),

    colorScheme: const ColorScheme.dark(
      // 🟡 Primary Action Color in Dark Mode (High contrast buttons)
      primary: Color.fromARGB(255, 242, 216, 76),

      // 🟣 Secondary Accent
      secondary: purple,

      // 🔴 Error Color
      error: Color.fromARGB(255, 253, 15, 3),

      // 🟠 Tertiary Accent
      tertiary: orange,

      // 🔲 Surface Color (Matches Card Color)
      surface: Color(0xFF2A2A2A),
    ),

    // ⚪ Default color for Icons in Dark Mode (White to stand out)
    iconTheme: const IconThemeData(color: Colors.white),

    textTheme: const TextTheme(
      // 📝 Standard Paragraph Text in Dark Mode (White)
      bodyMedium: TextStyle(color: Colors.white),

      // 📢 Large Headings in Dark Mode (White)
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
