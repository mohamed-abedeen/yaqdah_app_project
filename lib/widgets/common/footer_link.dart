import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// "New to Yaqdah? Create an account" style footer.
class FooterLink extends StatelessWidget {
  const FooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text.rich(
              TextSpan(
                text: prompt,
                style: AppFonts.body(context, 16, color: c.subtext),
                children: [
                  TextSpan(
                    text: action,
                    style: AppFonts.body(
                      context,
                      16,
                      weight: FontWeight.w700,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
