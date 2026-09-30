import 'package:flutter/material.dart';

/// A Material Symbols Rounded icon with the design's fill axis.
///
/// Pass `Symbols.*_rounded` icons. [filled] switches the FILL axis to 1.
/// [mirror] flips directional icons (arrows, chevrons) in right-to-left
/// layouts when the glyph doesn't already do so.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.mirror = false,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;
  final bool mirror;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(
      icon,
      size: size,
      color: color,
      fill: filled ? 1 : 0,
      semanticLabel: semanticLabel,
    );
    final flip =
        mirror &&
        !icon.matchTextDirection &&
        Directionality.of(context) == TextDirection.rtl;
    return flip ? Transform.flip(flipX: true, child: glyph) : glyph;
  }
}
