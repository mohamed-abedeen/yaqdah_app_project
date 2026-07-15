import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../services/places_service.dart';
import '../services/theme_service.dart';

class RestScreen extends StatefulWidget {
  final Function(LatLng) onPlaceSelected;
  final LatLng currentLocation;

  const RestScreen({
    super.key,
    required this.onPlaceSelected,
    required this.currentLocation,
  });

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  String _activeCategory = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _places = [];

  LatLng? _lastFetchLocation;
  final Distance _distanceCalculator = const Distance();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void didUpdateWidget(RestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    double distance = 0.0;
    if (_lastFetchLocation != null) {
      distance = _distanceCalculator.as(
        LengthUnit.Meter,
        _lastFetchLocation!,
        widget.currentLocation,
      );
    }

    if (distance > 2000) {
      _fetchPlaces();
    }
  }

  Future<void> _fetchPlaces() async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    int searchRadius = 5000;
    if (_activeCategory == 'hotel' || _activeCategory == 'all') {
      searchRadius = 20000;
    }

    try {
      List<Map<String, dynamic>> results = await PlacesService().fetchPlaces(
        center: widget.currentLocation,
        category: _activeCategory,
        radius: searchRadius,
      );

      if (mounted) {
        setState(() {
          _places = results;
          _isLoading = false;
          _lastFetchLocation = widget.currentLocation;
        });
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getStyleForType(String type) {
    switch (type) {
      case 'hotel':
        return {
          'icon': Icons.hotel,
          'color': ThemeService.purple,
        };
      case 'cafe':
        return {
          'icon': Icons.local_cafe,
          'color': ThemeService.orange,
        };
      case 'mosque':
        return {'icon': Icons.mosque, 'color': ThemeService.blue};
      default:
        return {'icon': CupertinoIcons.map_pin, 'color': Colors.grey};
    }
  }

  List<Map<String, dynamic>> _getCategories(AppLocalizations l10n) => [
    {'id': 'all', 'label': l10n.catAll, 'icon': CupertinoIcons.map},
    {
      'id': 'hotel',
      'label': l10n.catHotels,
      'icon': Icons.hotel,
    },
    {'id': 'cafe', 'label': l10n.catCafes, 'icon': Icons.local_cafe},
    {
      'id': 'mosque',
      'label': l10n.catMosques,
      'icon': Icons.mosque,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color!;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final green = theme.primaryColor;
    final categories = _getCategories(l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.restScreenTitle,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isActive = _activeCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activeCategory = cat['id'] as String);
                        _fetchPlaces();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? green : theme.cardColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isActive ? green : theme.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: green))
                  : _places.isEmpty
                  ? _buildEmptyState(theme, l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _places.length,
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        return _buildPlaceCard(place, theme, l10n, subColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> place,
    ThemeData theme,
    AppLocalizations l10n,
    Color subColor,
  ) {
    final style = _getStyleForType(place['type']);
    final Color color = style['color'] as Color;
    final IconData icon = style['icon'] as IconData;
    final textColor = theme.textTheme.bodyMedium!.color!;
    final green = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['name'],
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place['address'],
                        style: TextStyle(color: subColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${place['distance']} ${l10n.distanceKm}",
                        style: TextStyle(
                          color: green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onPlaceSelected(place['location']),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green.withValues(alpha: 0.5)),
              ),
              child: Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: green,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    final green = theme.primaryColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.map, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.restEmptyState, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() => _lastFetchLocation = null);
              _fetchPlaces();
            },
            child: Text(l10n.restRetry, style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }
}
