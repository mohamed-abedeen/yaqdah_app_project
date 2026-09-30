import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers.
///
/// English uses Outfit for headings and numbers and Figtree for body and UI
/// text. Arabic keeps Cairo for both, without the negative tracking that
/// would break joined letters.
abstract final class AppFonts {
  /// Built styles by their inputs. The Drive screen rebuilds often, and
  /// each google_fonts lookup costs more than a map hit.
  static final Map<(bool, bool, double, int, int?, double?, double), TextStyle>
  _cache = {};

  static bool _isArabic(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

  static TextStyle _style({
    required bool arabic,
    required bool display,
    required double size,
    required FontWeight weight,
    required Color? color,
    required double? height,
    required double tracking,
  }) {
    final key = (
      arabic,
      display,
      size,
      weight.value,
      color?.toARGB32(),
      height,
      tracking,
    );
    return _cache[key] ??= arabic
        ? GoogleFonts.cairo(
            fontSize: size,
            fontWeight: weight,
            color: color,
            height: height,
          )
        : (display ? GoogleFonts.outfit : GoogleFonts.figtree)(
            fontSize: size,
            fontWeight: weight,
            color: color,
            height: height,
            letterSpacing: tracking * size,
          );
  }

  /// Outfit: headings, status words and numbers.
  ///
  /// [tracking] is in em, like the design's `letter-spacing`.
  static TextStyle display(
    BuildContext context,
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
    double tracking = 0,
  }) => _style(
    arabic: _isArabic(context),
    display: true,
    size: size,
    weight: weight,
    color: color,
    height: height,
    tracking: tracking,
  );

  /// Figtree: body copy, labels, buttons and navigation.
  static TextStyle body(
    BuildContext context,
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double tracking = 0,
  }) => _style(
    arabic: _isArabic(context),
    display: false,
    size: size,
    weight: weight,
    color: color,
    height: height,
    tracking: tracking,
  );

  /// Uppercase section header, e.g. "SAFETY".
  static TextStyle overline(BuildContext context, Color color) =>
      body(context, 13, weight: FontWeight.w600, color: color, tracking: 0.04);
}
