import 'package:flutter/material.dart';

/// Design tokens for the Yaqdah redesign.
///
/// Read them with `AppColors.of(context)`; they switch with the theme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.subtext,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
  });

  /// Scaffold background.
  final Color bg;

  /// Cards, nav bar, inputs, sheets.
  final Color surface;

  /// Secondary buttons, segmented track, empty chart bars.
  final Color surface2;

  /// 1px borders, dividers, toggle off.
  final Color line;
  final Color text;
  final Color subtext;

  /// Main buttons, active nav, links, toggles on.
  final Color primary;

  /// Icon tiles, active nav pill, avatar background.
  final Color primarySoft;
  final Color onPrimary;

  /// Awake, safe, checks passed.
  final Color ok;
  final Color okSoft;

  /// Drowsy, distracted, no face, alert counts.
  final Color warn;
  final Color warnSoft;

  /// Asleep, SOS, delete, sign out, errors.
  final Color danger;
  final Color dangerSoft;

  static const dark = AppColors(
    bg: Color(0xFF0D0A18),
    surface: Color(0xFF171329),
    surface2: Color(0xFF231E3D),
    line: Color(0xFF2E2850),
    text: Color(0xFFF3F1FA),
    subtext: Color(0xFFA7A1C4),
    primary: Color(0xFF7B5CFF),
    primarySoft: Color(0x2E7B5CFF),
    onPrimary: Color(0xFFFFFFFF),
    ok: Color(0xFF3DCB8E),
    okSoft: Color(0x263DCB8E),
    warn: Color(0xFFF59A3A),
    warnSoft: Color(0x29F59A3A),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0x29E5484D),
  );

  static const light = AppColors(
    bg: Color(0xFFF7F6FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEECF5),
    line: Color(0xFFE2DFEC),
    text: Color(0xFF16122B),
    subtext: Color(0xFF645E7C),
    primary: Color(0xFF5B2EEB),
    primarySoft: Color(0x1A5B2EEB),
    onPrimary: Color(0xFFFFFFFF),
    ok: Color(0xFF12875A),
    okSoft: Color(0x1A12875A),
    warn: Color(0xFFB85F0A),
    warnSoft: Color(0x29F59A3A),
    danger: Color(0xFFD0343D),
    dangerSoft: Color(0x17D0343D),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? text,
    Color? subtext,
    Color? primary,
    Color? primarySoft,
    Color? onPrimary,
    Color? ok,
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? danger,
    Color? dangerSoft,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      okSoft: Color.lerp(okSoft, other.okSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
    );
  }
}

/// Colours that stay the same in both themes.
abstract final class FixedColors {
  // Driver level card on Reports.
  static const brandIndigo = Color(0xFF2A1491);
  static const brandLabel = Color(0xFFC9BEFF);
  static const brandSecondary = Color(0xFFDCD4FF);
  static const gold = Color(0xFFF2C94C);
  static const goldSoft = Color(0x2EF2C94C);

  // Drowsy alert.
  static const drowsyBg = Color(0xFFF59A3A);
  static const drowsyInk = Color(0xFF1E1104);
  static const drowsyCard = Color(0xFFFFF6EC);
  static const drowsyTile = Color(0xFFFCE3C6);
  static const drowsyCardSubtext = Color(0xFF7A4A12);

  // Danger alert.
  static const dangerBg = Color(0xFFD42A33);
  static const dangerInk = Color(0xFFFFFFFF);
  static const dangerButtonText = Color(0xFFB01E27);

  /// Tile behind the owl logo.
  static const logoTile = Color(0xFFFFFFFF);
}
