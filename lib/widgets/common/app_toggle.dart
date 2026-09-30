import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 50×30 switch: primary with the knob at the end when on, line when off.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      toggled: value,
      label: semanticLabel,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          // Pads the 30px track up to a 44px hit target.
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? c.primary : c.line,
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
