import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/brand.dart';
import '../../widgets/common/place_labels.dart';

/// A place to pull over, from `PlacesService` results.
class RestStop {
  const RestStop({required this.place, required this.distanceKm});

  final Place place;
  final double distanceKm;

  LatLng get location => place.location;

  /// Rough drive time at about 40 km/h.
  int get etaMinutes => (distanceKm / 40 * 60).ceil().clamp(1, 999);
}

/// Full-screen drowsy alert. Identical in both themes.
class DrowsyAlertScreen extends StatelessWidget {
  const DrowsyAlertScreen({
    super.key,
    required this.restStop,
    required this.onTakeMeThere,
    required this.onKeepDriving,
  });

  final Future<RestStop?> restStop;
  final void Function(RestStop stop) onTakeMeThere;
  final VoidCallback onKeepDriving;

  static const _ink = FixedColors.drowsyInk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: FixedColors.drowsyBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _ink.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: AppIcon(
                              Symbols.bedtime_rounded,
                              size: 44,
                              color: _ink,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.drowsyAlertTitle,
                          style: AppFonts.display(
                            context,
                            44,
                            color: _ink,
                            height: 1.02,
                            tracking: -0.025,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.drowsyAlertBody,
                          style: AppFonts.body(
                            context,
                            19,
                            weight: FontWeight.w500,
                            color: _ink,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RestStopCard(
                        restStop: restStop,
                        onTakeMeThere: onTakeMeThere,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.keepDriving,
                        onPressed: onKeepDriving,
                        height: 60,
                        background: Colors.transparent,
                        foreground: _ink,
                        border: BorderSide(
                          color: _ink.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                    ],
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

class _RestStopCard extends StatelessWidget {
  const _RestStopCard({required this.restStop, required this.onTakeMeThere});

  final Future<RestStop?> restStop;
  final void Function(RestStop stop) onTakeMeThere;

  static const _ink = FixedColors.drowsyInk;
  static const _sub = FixedColors.drowsyCardSubtext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FixedColors.drowsyCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder<RestStop?>(
        future: restStop,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final stop = snapshot.data;

          final Widget info;
          if (loading) {
            info = Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.findingRestStop,
                    style: AppFonts.body(
                      context,
                      16,
                      weight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            );
          } else if (stop == null) {
            info = Text(
              l10n.noRestStopNearby,
              style: AppFonts.body(
                context,
                16,
                weight: FontWeight.w600,
                color: _ink,
              ),
            );
          } else {
            info = Row(
              children: [
                IconTile(
                  icon: stop.place.icon,
                  background: FixedColors.drowsyTile,
                  foreground: _ink,
                  size: 48,
                  radius: 14,
                  iconSize: 24,
                  filled: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nearestRestStop,
                        style: AppFonts.body(
                          context,
                          13,
                          weight: FontWeight.w500,
                          color: _sub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stop.place.displayName(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          context,
                          18,
                          weight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stop.distanceKm.toStringAsFixed(1)} ${l10n.kmUnit}',
                      style: AppFonts.display(context, 18, color: _ink),
                    ),
                    Text(
                      l10n.minutesShort(stop.etaMinutes),
                      style: AppFonts.body(
                        context,
                        13,
                        weight: FontWeight.w500,
                        color: _sub,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              info,
              if (stop != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.takeMeThere,
                  onPressed: () => onTakeMeThere(stop),
                  leadingIcon: Symbols.navigation_rounded,
                  iconFilled: true,
                  height: 60,
                  background: _ink,
                  foreground: FixedColors.drowsyCard,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
