import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'app_icon.dart';

/// Full-width filled button. Defaults to the 58-high primary button.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize = 22,
    this.iconFilled = false,
    this.height = 58,
    this.radius = 18,
    this.fontSize = 17,
    this.background,
    this.foreground,
    this.border,
    this.shadow,
  });

  /// Secondary button on surface2 with text colour.
  factory AppButton.secondary(
    BuildContext context, {
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? leadingIcon,
    bool iconFilled = false,
    double height = 58,
    double radius = 18,
  }) {
    final c = AppColors.of(context);
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      leadingIcon: leadingIcon,
      iconFilled: iconFilled,
      height: height,
      radius: radius,
      background: c.surface2,
      foreground: c.text,
    );
  }

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double iconSize;
  final bool iconFilled;
  final double height;
  final double radius;
  final double fontSize;
  final Color? background;
  final Color? foreground;
  final BorderSide? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg = background ?? c.primary;
    final fg = foreground ?? c.onPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border ?? BorderSide.none,
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fg,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            AppIcon(
                              leadingIcon!,
                              size: iconSize,
                              color: fg,
                              filled: iconFilled,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: AppFonts.body(
                              context,
                              fontSize,
                              weight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            AppIcon(
                              trailingIcon!,
                              size: iconSize,
                              color: fg,
                              filled: iconFilled,
                              mirror: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
