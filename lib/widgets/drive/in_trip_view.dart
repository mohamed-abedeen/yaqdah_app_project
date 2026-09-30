import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_icon.dart';
import 'drive_buttons.dart';

/// Mapbox raster tiles matching the app theme.
String mapboxTileUrl(BuildContext context) {
  final style = Theme.of(context).brightness == Brightness.dark
      ? 'navigation-night-v1'
      : 'navigation-day-v1';
  return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}';
}

/// Drive tab during a trip (direction 1a): full-screen map with the
/// destination card, map buttons and the status [sheet] on top.
class InTripView extends StatelessWidget {
  const InTripView({
    super.key,
    required this.mapController,
    required this.currentLocation,
    required this.heading,
    required this.routePoints,
    required this.destination,
    required this.destinationName,
    required this.destinationEta,
    required this.isListening,
    required this.sheet,
    required this.onMapReady,
    required this.onMapGesture,
    required this.onMapTap,
    required this.onRecenter,
    required this.onMicTap,
    required this.onClearDestination,
  });

  final MapController mapController;
  final LatLng currentLocation;
  final double heading;
  final List<LatLng> routePoints;
  final LatLng? destination;
  final String? destinationName;
  final String? destinationEta;
  final bool isListening;
  final Widget sheet;
  final VoidCallback onMapReady;
  final VoidCallback onMapGesture;
  final void Function(LatLng point) onMapTap;
  final VoidCallback onRecenter;
  final VoidCallback onMicTap;
  final VoidCallback onClearDestination;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // The map repaints on every GPS update; keep that off the sheet and
        // buttons drawn on top.
        Positioned.fill(
          child: RepaintBoundary(
            child: ColoredBox(
              color: c.surface2,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 17,
                  backgroundColor: c.surface2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                  ),
                  onMapReady: onMapReady,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) onMapGesture();
                  },
                  onTap: (_, point) => onMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapboxTileUrl(context),
                    userAgentPackageName: 'com.example.yaqdah_app',
                    // The map scrolls all trip long: skip the per-tile fade
                    // animation and its extra frames.
                    tileDisplay: const TileDisplay.instantaneous(),
                  ),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 5,
                          color: c.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 40,
                        height: 40,
                        child: _HeadingMarker(heading: heading),
                      ),
                      if (destination != null)
                        Marker(
                          point: destination!,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: AppIcon(
                            Symbols.location_on_rounded,
                            size: 40,
                            color: c.primary,
                            filled: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: destination == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _DestinationCard(
                        name: destinationName ?? l10n.droppedPin,
                        eta: destinationEta,
                        onClose: onClearDestination,
                      ),
                    ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapSquareButton(
                        icon: Symbols.near_me_rounded,
                        onTap: onRecenter,
                        semanticLabel: l10n.recenterMap,
                      ),
                      const SizedBox(height: 12),
                      MicButton(
                        listening: isListening,
                        onTap: onMicTap,
                        prominent: true,
                        semanticLabel: l10n.voiceAssistant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Slides up as the trip starts.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => FractionalTranslation(
                translation: Offset(0, t),
                child: child,
              ),
              child: RepaintBoundary(child: sheet),
            ),
          ],
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.name,
    required this.eta,
    required this.onClose,
  });

  final String name;
  final String? eta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AppIcon(
            Symbols.flag_rounded,
            size: 24,
            color: c.primary,
            filled: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    context,
                    16,
                    weight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eta ?? l10n.findingRoute,
                  style: AppFonts.body(context, 14, color: c.subtext),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: l10n.clearDestination,
            icon: AppIcon(Symbols.close_rounded, size: 22, color: c.subtext),
          ),
        ],
      ),
    );
  }
}

class _HeadingMarker extends StatelessWidget {
  const _HeadingMarker({required this.heading});

  final double heading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Transform.rotate(
          angle: heading * (math.pi / 180),
          child: AppIcon(
            Symbols.navigation_rounded,
            size: 22,
            color: c.primary,
            filled: true,
          ),
        ),
      ),
    );
  }
}
