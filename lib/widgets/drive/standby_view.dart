import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_icon.dart';
import 'driver_status.dart';

/// Black screen that saves power during a trip. Monitoring keeps running;
/// a non-awake status is still shown. Tap anywhere to wake.
class StandbyView extends StatelessWidget {
  const StandbyView({super.key, required this.status, required this.onWake});

  final DriverStatus status;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Always drawn on black, so use the dark tokens.
    const c = AppColors.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onWake,
        child: ColoredBox(
          color: Colors.black,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  Symbols.bedtime_rounded,
                  size: 60,
                  color: c.subtext,
                  filled: true,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.standbyTitle,
                  style: AppFonts.display(context, 24, color: c.text),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.standbyHint,
                  style: AppFonts.body(context, 16, color: c.subtext),
                ),
                if (status != DriverStatus.awake) ...[
                  const SizedBox(height: 40),
                  Text(
                    status.label(l10n),
                    style: AppFonts.display(
                      context,
                      36,
                      color: status.color(c),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
