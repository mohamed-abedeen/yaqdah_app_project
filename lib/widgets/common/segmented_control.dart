import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class Segment<T> {
  const Segment(this.value, this.label);

  final T value;
  final String label;
}

/// Pill segmented control: surface2 track, selected segment on surface.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Smaller variant used inside settings rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackRadius = compact ? 11.0 : 12.0;
    final segmentRadius = compact ? 8.0 : 9.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 7);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in segments)
            Semantics(
              button: true,
              selected: s.value == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(s.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: padding,
                  constraints: const BoxConstraints(minHeight: 32),
                  decoration: BoxDecoration(
                    color: s.value == selected
                        ? c.surface
                        : c.surface.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(segmentRadius),
                    boxShadow: s.value == selected && !isDark
                        ? const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    s.label,
                    style: AppFonts.body(
                      context,
                      14,
                      weight: FontWeight.w600,
                      color: s.value == selected ? c.text : c.subtext,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
