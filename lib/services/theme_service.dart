import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

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

  /// Figtree for English UI text, Cairo for Arabic.
  ThemeData lightTheme({bool isArabic = false}) =>
      _build(AppColors.light, Brightness.light, isArabic);

  ThemeData darkTheme({bool isArabic = false}) =>
      _build(AppColors.dark, Brightness.dark, isArabic);

  ThemeData _build(AppColors c, Brightness brightness, bool isArabic) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final fontTheme = isArabic
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.figtreeTextTheme(base.textTheme);
    final textTheme = fontTheme.apply(bodyColor: c.text, displayColor: c.text);
    TextStyle ui(double size, FontWeight weight, Color color) => isArabic
        ? GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color)
        : GoogleFonts.figtree(fontSize: size, fontWeight: weight, color: color);

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      cardColor: c.surface,
      dividerColor: c.line,
      primaryColor: c.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.primary,
        onSecondary: c.onPrimary,
        error: c.danger,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.subtext,
        surfaceContainerHighest: c.surface2,
        outline: c.line,
        outlineVariant: c.line,
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.text),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surface2,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primarySoft,
        selectionHandleColor: c.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        contentTextStyle: ui(15, FontWeight.w500, c.bg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: ui(19, FontWeight.w700, c.text),
        contentTextStyle: ui(15, FontWeight.w400, c.subtext),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: ui(15, FontWeight.w600, c.primary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: ui(17, FontWeight.w700, c.text),
      ),
      extensions: [c],
    );
  }
}
