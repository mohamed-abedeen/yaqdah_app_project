import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'app_icon.dart';

/// The owl mark, always on a white rounded tile.
class LogoTile extends StatelessWidget {
  const LogoTile({
    super.key,
    required this.size,
    required this.radius,
    required this.logoWidth,
    this.shadow = const [],
  });

  final double size;
  final double radius;
  final double logoWidth;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FixedColors.logoTile,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
        boxShadow: shadow,
      ),
      child: Image.asset(
        'images/Yaqdah-05.png',
        width: logoWidth,
        fit: BoxFit.contain,
        semanticLabel: 'Yaqdah',
      ),
    );
  }
}

/// Circle with the user's initials in primarySoft / primary.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.fontSize,
  });

  final String name;
  final double size;
  final double fontSize;

  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: AppFonts.display(context, fontSize, color: c.primary),
      ),
    );
  }
}

/// Square rounded tile holding an icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 44,
    this.radius = 13,
    this.iconSize = 22,
    this.filled = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double radius;
  final double iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppIcon(icon, size: iconSize, color: foreground, filled: filled),
    );
  }
}

/// Surface card with a 1px line border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.color,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

/// Paints a dashed rounded-rectangle outline (locked badge chips).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dash = 4,
    this.gap = 3,
    this.strokeWidth = 1,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap ||
      oldDelegate.strokeWidth != strokeWidth;
}
