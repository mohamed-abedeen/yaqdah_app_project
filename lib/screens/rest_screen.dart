import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/location_provider.dart';
import '../services/places_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/brand.dart';
import '../widgets/common/place_labels.dart';
import '../widgets/drive/in_trip_view.dart' show mapboxTileUrl;

class RestScreen extends StatefulWidget {
  final void Function(LatLng location, String name) onPlaceSelected;

  /// Whether the tab is on screen. Searches and distance updates wait
  /// until it is.
  final bool active;

  const RestScreen({
    super.key,
    required this.onPlaceSelected,
    required this.active,
  });

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  /// Nearest places listed; the search can return many more.
  static const _maxListed = 25;

  /// Search again after moving this far (metres) from the last search.
  static const _refetchDistance = 1500.0;

  /// Distances are redrawn after moving this far (metres).
  static const _redrawDistance = 50.0;

  late final LocationProvider _location;
  String _category = 'all';
  String? _languageCode;

  /// Where the driver is, updated every [_redrawDistance] or so.
  LatLng? _here;

  /// Centre of the running or latest search.
  LatLng? _searchCenter;
  PlacesResult? _result;
  bool _loading = false;
  bool _failed = false;

  /// Drops answers to searches that were replaced by a newer one.
  int _request = 0;

  List<(Place, double)> _listed = const [];
  PlacesResult? _listedFor;
  LatLng? _listedFrom;

  @override
  void initState() {
    super.initState();
    _location = context.read<LocationProvider>();
    _location.addListener(_onLocationChanged);
    if (_location.hasLocation) _here = _location.currentLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeFetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == _languageCode) return;
    final hadResults = _result != null;
    _languageCode = languageCode;
    // Place names come in the app language: search again.
    if (hadResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetch();
      });
    }
  }

  @override
  void didUpdateWidget(RestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncLocation();
      });
    }
  }

  @override
  void dispose() {
    _location.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (widget.active) _syncLocation();
  }

  void _syncLocation() {
    if (!_location.hasLocation) return;
    final here = _location.currentLocation;
    final previous = _here;
    if (previous == null ||
        approxDistanceMeters(previous, here) >= _redrawDistance) {
      setState(() => _here = here);
    }
    _maybeFetch();
  }

  /// Searches when there's no search for this area yet.
  void _maybeFetch() {
    final here = _here;
    if (here == null || !widget.active) return;
    final center = _searchCenter;
    if (center != null &&
        approxDistanceMeters(center, here) < _refetchDistance) {
      return;
    }
    _fetch();
  }

  Future<void> _fetch() async {
    final here = _here;
    final languageCode = _languageCode;
    if (here == null || languageCode == null) return;
    final request = ++_request;
    final category = _category;
    setState(() {
      _loading = true;
      _failed = false;
      _searchCenter = here;
    });

    try {
      final result = await PlacesService().findPlaces(
        center: here,
        category: category,
        languageCode: languageCode,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching places: $e");
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _selectCategory(String category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      // Never show the previous category's places under the new chip.
      _result = null;
    });
    _fetch();
  }

  /// The nearest places to [_here], with their distance in metres.
  List<(Place, double)> _nearestPlaces() {
    final result = _result;
    final from = _here ?? result?.center;
    if (result == null || from == null) return const [];
    if (identical(result, _listedFor) && from == _listedFrom) return _listed;

    final withDistance = [
      for (final p in result.places)
        (p, const Distance().as(LengthUnit.Meter, from, p.location)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    _listed = withDistance.take(_maxListed).toList();
    _listedFor = result;
    _listedFrom = from;
    return _listed;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final issue = context.select<LocationProvider, LocationIssue?>(
      (l) => l.issue,
    );
    final here = _here;
    final result = _result;
    final places = _nearestPlaces();

    final String subtitle;
    if (result != null) {
      subtitle = l10n.restSubtitle(result.radius ~/ 1000);
    } else if (here == null) {
      subtitle = issue != null
          ? l10n.restLocationOff
          : l10n.restWaitingLocation;
    } else {
      subtitle = l10n.findingRestStop;
    }

    final categories = [
      ('all', l10n.catAll, null),
      (PlaceType.cafe, l10n.catCafes, Symbols.local_cafe_rounded),
      (PlaceType.mosque, l10n.catMosques, Symbols.mosque_rounded),
      (PlaceType.hotel, l10n.catHotels, Symbols.hotel_rounded),
    ];

    final Widget body;
    if (here == null) {
      body = issue != null
          ? _buildMessage(
              c,
              icon: Symbols.location_off_rounded,
              message: l10n.restLocationOff,
              action: l10n.openSettings,
              onAction: _location.resolveIssue,
            )
          : _buildLoading();
    } else if (result == null) {
      body = _failed && !_loading
          ? _buildMessage(
              c,
              icon: Symbols.wifi_off_rounded,
              message: l10n.restLoadFailed,
              action: l10n.restRetry,
              onAction: _fetch,
            )
          : _buildLoading();
    } else if (places.isEmpty) {
      body = _loading
          ? _buildLoading()
          : _buildMessage(
              c,
              icon: Symbols.map_rounded,
              message: l10n.restEmptyState,
              action: l10n.restRetry,
              onAction: _fetch,
            );
    } else {
      body = AppCard(
        padding: EdgeInsets.zero,
        radius: 22,
        clip: true,
        child: Column(
          children: [
            for (var i = 0; i < places.length; i++)
              _PlaceRow(
                place: places[i].$1,
                distanceMeters: places[i].$2,
                nearest: i == 0,
                divider: i > 0,
                onGo: () => widget.onPlaceSelected(
                  places[i].$1.location,
                  places[i].$1.displayName(l10n),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.restTitle,
                    style: AppFonts.display(
                      context,
                      30,
                      color: c.text,
                      tracking: -0.02,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppFonts.body(context, 16, color: c.subtext),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final (id, label, icon) in categories) ...[
                    if (id != 'all') const SizedBox(width: 8),
                    _CategoryChip(
                      label: label,
                      icon: icon,
                      active: _category == id,
                      onTap: () => _selectCategory(id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: here == null
                  ? _MapPlaceholder(color: c.surface2, border: c.line)
                  : _PlacesMap(
                      // New results re-fit the camera.
                      key: ObjectKey(result),
                      center: here,
                      places: [for (final (p, _) in places.take(10)) p],
                    ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _buildMessage(
    AppColors c, {
    required IconData icon,
    required String message,
    required String action,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          IconTile(
            icon: icon,
            background: c.surface2,
            foreground: c.subtext,
            size: 56,
            radius: 18,
            iconSize: 28,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.body(context, 16, color: c.subtext),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // The active chip is inverted: text colour background, bg colour text.
    final fg = active ? c.bg : c.text;

    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 40),
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 16 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: active ? c.text : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? c.text : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 17, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppFonts.body(
                  context,
                  14,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for the map until the driver's position is known.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Center(
        child: AppIcon(
          Symbols.my_location_rounded,
          size: 28,
          color: AppColors.of(context).subtext,
        ),
      ),
    );
  }
}

/// 150-high map with the current position and place pins.
class _PlacesMap extends StatelessWidget {
  const _PlacesMap({super.key, required this.center, required this.places});

  final LatLng center;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final coordinates = [center, for (final p in places) p.location];

    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: FlutterMap(
        options: MapOptions(
          backgroundColor: c.surface2,
          initialCenter: center,
          initialZoom: 13,
          initialCameraFit: coordinates.length > 1
              ? CameraFit.coordinates(
                  coordinates: coordinates,
                  padding: const EdgeInsets.all(28),
                  maxZoom: 15,
                )
              : null,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: mapboxTileUrl(context),
            userAgentPackageName: 'com.example.yaqdah_app',
          ),
          MarkerLayer(
            markers: [
              for (final p in places)
                Marker(
                  point: p.location,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.primary, width: 1.5),
                    ),
                    child: Center(
                      child: AppIcon(
                        p.icon,
                        size: 15,
                        color: c.primary,
                        filled: true,
                      ),
                    ),
                  ),
                ),
              Marker(
                point: center,
                width: 18,
                height: 18,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.distanceMeters,
    required this.nearest,
    required this.divider,
    required this.onGo,
  });

  final Place place;
  final double distanceMeters;

  /// The nearest place gets the solid Go button.
  final bool nearest;
  final bool divider;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final km = distanceMeters / 1000;
    // Rough drive time at about 40 km/h.
    final minutes = (km / 40 * 60).ceil().clamp(1, 999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: divider ? Border(top: BorderSide(color: c.line)) : null,
      ),
      child: Row(
        children: [
          IconTile(
            icon: place.icon,
            background: c.surface2,
            foreground: c.subtext,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.displayName(l10n),
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
                  l10n.placeRowSubtitle(
                    place.typeLabel(l10n),
                    km.toStringAsFixed(1),
                    minutes,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(context, 14, color: c.subtext),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: Material(
              color: nearest ? c.primary : c.primarySoft,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onGo,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      l10n.go,
                      style: AppFonts.body(
                        context,
                        14,
                        weight: FontWeight.w700,
                        color: nearest ? c.onPrimary : c.primary,
                      ),
                    ),
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
