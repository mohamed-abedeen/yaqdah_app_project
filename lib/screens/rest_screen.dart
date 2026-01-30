// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/places_service.dart';
import '../services/theme_service.dart';

class RestScreen extends StatefulWidget {
  final Function(LatLng) onPlaceSelected;
  final LatLng currentLocation; // ✅ Fixed: Expects a value, not a function

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

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'الكل', 'icon': Icons.map},
    {'id': 'hotel', 'label': 'فنادق', 'icon': Icons.hotel},
    {'id': 'cafe', 'label': 'مقاهي', 'icon': Icons.coffee},
    {'id': 'mosque', 'label': 'مساجد', 'icon': Icons.mosque},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void didUpdateWidget(RestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Logic: Check if user moved significantly (> 2km) to refresh places
    double distance = 0.0;
    if (_lastFetchLocation != null) {
      distance = _distanceCalculator.as(
        LengthUnit.Meter,
        _lastFetchLocation!,
        widget.currentLocation,
      );
    }

    bool significantMove = distance > 2000;

    if (significantMove) {
      _fetchPlaces();
    }
  }

  Future<void> _fetchPlaces() async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    int searchRadius = 5000; // Default 5km
    if (_activeCategory == 'hotel' || _activeCategory == 'all') {
      searchRadius = 20000; // 20km for hotels
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
        return {'icon': Icons.hotel, 'color': ThemeService.purple};
      case 'cafe':
        return {'icon': Icons.coffee, 'color': ThemeService.orange};
      case 'mosque':
        return {'icon': Icons.mosque, 'color': ThemeService.blue};
      default:
        return {'icon': Icons.place, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color!;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final green = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "استراحات قريبة",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "أماكن حقيقية حولك",
                    style: TextStyle(color: subColor, fontSize: 14),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = _activeCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activeCategory = cat['id']);
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
                              cat['icon'],
                              size: 16,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat['label'],
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
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _places.length,
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        return _buildPlaceCard(place, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, ThemeData theme) {
    final style = _getStyleForType(place['type']);
    final Color color = style['color'];
    final IconData icon = style['icon'];
    final textColor = theme.textTheme.bodyMedium!.color!;
    final subColor = theme.brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey[600]!;
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
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
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
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
                        "${place['distance']} كم",
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
                color: green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green.withOpacity(0.5)),
              ),
              child: Icon(Icons.navigation, color: green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final green = theme.primaryColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "لا توجد أماكن قريبة (${_activeCategory})",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() => _lastFetchLocation = null);
              _fetchPlaces();
            },
            child: Text("حاول مرة أخرى", style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }
}
