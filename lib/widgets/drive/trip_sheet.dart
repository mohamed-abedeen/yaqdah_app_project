import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_icon.dart';
import 'drive_buttons.dart';
import 'driver_status.dart';

/// Meter zone boundaries, as fractions of the drowsiness percentage.
///
/// `MonitoringProvider` reports 0 when awake, 45 when distracted or no face
/// is found, 75 when drowsy and 100 when asleep, so the Drowsy zone spans
/// 40–80% and only ASLEEP reaches Danger.
const double kDrowsyZoneStart = 0.40;
const double kDangerZoneStart = 0.80;

/// In-trip bottom sheet: driver status, drowsiness meter, trip stats and
/// the SOS / End trip / Standby actions.
class TripSheet extends StatelessWidget {
  const TripSheet({
    super.key,
    required this.status,
    required this.drowsiness,
    required this.startedAt,
    required this.distanceKm,
    required this.speedKmh,
    required this.onSos,
    required this.onEndTrip,
    required this.onStandby,
  });

  final DriverStatus status;

  /// 0–100.
  final double drowsiness;
  final DateTime startedAt;
  final double distanceKm;
  final int speedKmh;
  final VoidCallback onSos;
  final VoidCallback onEndTrip;
  final VoidCallback onStandby;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final statusColor = status.color(c);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        bottomInset > 0 ? bottomInset : 20,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Status row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.driverStatus.toUpperCase(),
                      style: AppFonts.overline(context, c.subtext),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: status.softColor(c),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              status.label(l10n),
                              style: AppFonts.display(
                                context,
                                32,
                                color: statusColor,
                                tracking: -0.02,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${drowsiness.round()}%',
                    style: AppFonts.display(context, 24, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.drowsinessCaption,
                    style: AppFonts.body(
                      context,
                      13,
                      weight: FontWeight.w500,
                      color: c.subtext,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Meter(value: drowsiness / 100, color: statusColor),
          const SizedBox(height: 20),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                _ElapsedStat(startedAt: startedAt, label: l10n.statTime),
                _Stat(
                  value: distanceKm.toStringAsFixed(1),
                  unit: l10n.kmUnit,
                  label: l10n.statDistance,
                ),
                _Stat(
                  value: '$speedKmh',
                  unit: l10n.kmhUnit,
                  label: l10n.statSpeed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions
          Row(
            children: [
              Expanded(
                child: HoldToConfirmButton(
                  label: l10n.holdForSos,
                  icon: Symbols.sos_rounded,
                  background: c.danger,
                  foreground: Colors.white,
                  onConfirmed: onSos,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  onTap: onEndTrip,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          Symbols.stop_rounded,
                          size: 22,
                          color: c.text,
                          filled: true,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.endTrip,
                          style: AppFonts.body(
                            context,
                            17,
                            weight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: _SheetButton(
                  onTap: onStandby,
                  semanticLabel: l10n.standbyTitle,
                  child: AppIcon(
                    Symbols.bedtime_rounded,
                    size: 24,
                    color: c.subtext,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "0:42" — hours and minutes.
  static String _formatElapsed(Duration d) =>
      '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
}

/// Trip time as h:mm. Rebuilds itself once a minute instead of making the
/// whole Drive screen rebuild every second.
class _ElapsedStat extends StatefulWidget {
  const _ElapsedStat({required this.startedAt, required this.label});

  final DateTime startedAt;
  final String label;

  @override
  State<_ElapsedStat> createState() => _ElapsedStatState();
}

class _ElapsedStatState extends State<_ElapsedStat> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void didUpdateWidget(_ElapsedStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) _scheduleTick();
  }

  /// Wakes up just after the next whole minute of the trip.
  void _scheduleTick() {
    _timer?.cancel();
    final elapsed = DateTime.now().difference(widget.startedAt);
    final intoMinute = elapsed.inMilliseconds % Duration.millisecondsPerMinute;
    _timer = Timer(
      Duration(milliseconds: Duration.millisecondsPerMinute - intoMinute + 50),
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleTick();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Stat(
    value: TripSheet._formatElapsed(
      DateTime.now().difference(widget.startedAt),
    ),
    label: widget.label,
  );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final caption = AppFonts.body(
      context,
      12,
      weight: FontWeight.w500,
      color: c.subtext,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.surface2)),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: w * value.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    for (final at in const [kDrowsyZoneStart, kDangerZoneStart])
                      PositionedDirectional(
                        start: w * at - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 2, color: c.bg),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: (kDrowsyZoneStart * 100).round(),
              child: Text(l10n.statusAwake, style: caption),
            ),
            Expanded(
              flex: ((kDangerZoneStart - kDrowsyZoneStart) * 100).round(),
              child: Text(l10n.statusDrowsy, style: caption),
            ),
            Expanded(
              flex: ((1 - kDangerZoneStart) * 100).round(),
              child: Text(
                l10n.statusDanger,
                style: caption,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: AppFonts.display(
                context,
                22,
                weight: FontWeight.w600,
                color: c.text,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppFonts.body(
                      context,
                      14,
                      weight: FontWeight.w500,
                      color: c.subtext,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.body(
              context,
              13,
              weight: FontWeight.w500,
              color: c.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        height: 60,
        child: Material(
          color: c.surface2,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
