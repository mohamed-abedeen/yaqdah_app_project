import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_icon.dart';

/// 56 circle voice-assistant button.
///
/// Before a trip it sits on surface2 with a line border; during a trip it's
/// primary. While listening it turns danger and shows `mic_off`.
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.listening,
    required this.onTap,
    this.prominent = false,
    this.semanticLabel,
  });

  final bool listening;
  final VoidCallback onTap;
  final bool prominent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final Color bg;
    final Color fg;
    if (listening) {
      bg = c.danger;
      fg = Colors.white;
    } else if (prominent) {
      bg = c.primary;
      fg = c.onPrimary;
    } else {
      bg = c.surface2;
      fg = c.text;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: prominent || listening ? null : Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: prominent ? 0.2 : 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: AppIcon(
                listening ? Symbols.mic_off_rounded : Symbols.mic_rounded,
                size: 26,
                color: fg,
                filled: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Button that fires only after being held for [holdDuration], filling up
/// while pressed. Used for "Hold for SOS".
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onConfirmed,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.height = 60,
    this.radius = 18,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onConfirmed;
  final Duration holdDuration;
  final double height;
  final double radius;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
      _progress.value = 0;
    }
  }

  void _start() {
    HapticFeedback.selectionClick();
    _progress.forward();
  }

  void _cancel() {
    if (_progress.isAnimating || _progress.value > 0) {
      _progress.animateBack(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      onLongPress: widget.onConfirmed,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: widget.background),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: _progress.value,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            widget.icon,
                            size: 22,
                            color: widget.foreground,
                            filled: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: AppFonts.body(
                              context,
                              17,
                              weight: FontWeight.w700,
                              color: widget.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 48 square map button (recenter).
class MapSquareButton extends StatelessWidget {
  const MapSquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: AppIcon(icon, size: 22, color: c.primary, filled: true),
            ),
          ),
        ),
      ),
    );
  }
}
