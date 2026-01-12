import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/placesService.dart';

const String _mapboxAccessToken =
    'pk.eyJ1IjoibW9ob3oiLCJhIjoiY21rNng0eTBhMG1tejNmc2hkZjg2djg5cSJ9.EhZ_hhGrpAGJRb1j-O5eIw';

class RestScreen extends StatefulWidget {
  final Function(LatLng) onPlaceSelected;
  final LatLng Function() getCurrentLocation;

  const RestScreen({
    super.key,
    required this.onPlaceSelected,
    required this.getCurrentLocation,
  });

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  final PlacesService _placesService = PlacesService();

  String _selectedCategory = "all";
  String _searchQuery = "";
  List<dynamic> _allFetchedPlaces = [];
  bool _isLoading = false;

  // Isochrone Filtering
  List<LatLng> _reachabilityPolygon = [];

  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces("all");
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePlaces();
    }
  }

  void _loadMorePlaces() {
    if (_visibleCount < _filteredPlaces.length) {
      setState(() => _visibleCount += 10);
    }
  }

  List<dynamic> get _filteredPlaces {
    var results = _allFetchedPlaces;

    // 1. Filter by Search Text
    if (_searchQuery.isNotEmpty) {
      results = results.where((place) {
        final name = place['tags']['name'] ?? "";
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 2. Filter by Reachability (Isochrone)
    if (_selectedCategory == "all" && _reachabilityPolygon.isNotEmpty) {
      results = results.where((place) {
        return _isPointInPolygon(
          LatLng(place['safe_lat'], place['safe_lon']),
          _reachabilityPolygon,
        );
      }).toList();
    }

    return results;
  }

  // ✅ FIXED: Correct Dart Syntax for Point-in-Polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool c = false;
    // We declare i and j INSIDE the loop header to make it a valid definition list
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        c = !c;
      }
    }
    return c;
  }

  Future<void> _fetchNearbyPlaces(String category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
      _allFetchedPlaces = [];
      _visibleCount = 20;
    });

    final center = widget.getCurrentLocation();

    if (category == "all") {
      await _fetchIsochrone(center);
    } else {
      _reachabilityPolygon = [];
    }

    final places = await _placesService.fetchPlaces(
      center: center,
      category: category,
    );

    if (mounted) {
      setState(() {
        _allFetchedPlaces = places;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIsochrone(LatLng center) async {
    final url = Uri.parse(
      "https://api.mapbox.com/isochrone/v1/mapbox/driving/${center.longitude},${center.latitude}?contours_minutes=15&polygons=true&access_token=$_mapboxAccessToken",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];
        if (features.isNotEmpty) {
          final List coords = features[0]['geometry']['coordinates'][0];
          List<LatLng> points = [];
          for (var point in coords) {
            points.add(LatLng(point[1].toDouble(), point[0].toDouble()));
          }
          _reachabilityPolygon = points;
        }
      }
    } catch (e) {
      debugPrint("Isochrone Error: $e");
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.toInt()} m";
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredPlaces;
    final displayCount = _visibleCount > filtered.length
        ? filtered.length
        : _visibleCount;
    final placesToDisplay = filtered.take(displayCount).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rest Places",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          _selectedCategory == "all" &&
                                  _reachabilityPolygon.isNotEmpty
                              ? "Showing places reachable in 15 mins"
                              : "Find nearby places to rest",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(
                        Icons.compass_calibration,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _visibleCount = 20;
                    });
                  },
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: "Search for places...",
                    hintStyle: theme.textTheme.bodySmall,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip("All (15m Drive)", "all", context),
                      _categoryChip("Coffee", "cafe", context),
                      _categoryChip("Hotels", "hotel", context),
                      _categoryChip("Mosques", "mosque", context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    itemCount:
                        placesToDisplay.length +
                        (displayCount < filtered.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == placesToDisplay.length)
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
                          ),
                        );

                      final place = placesToDisplay[index];
                      String name = place['tags']['name'] ?? "Unknown Place";
                      double meters = place['distance_meters'] ?? 0.0;

                      if (_selectedCategory == "mosque" &&
                          place['tags']['religion'] != 'muslim' &&
                          !(place['tags']['name']?.toLowerCase().contains(
                                'mosque',
                              ) ??
                              false)) {
                        return const SizedBox.shrink();
                      }

                      IconData itemIcon;
                      String itemSubtext;
                      if (place['tags'].containsKey('tourism')) {
                        itemIcon = Icons.hotel;
                        itemSubtext = " • Hotel";
                      } else if (place['tags'].containsKey('religion')) {
                        itemIcon = Icons.mosque;
                        itemSubtext = " • Mosque";
                      } else {
                        itemIcon = Icons.coffee;
                        itemSubtext = " • Coffee";
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            if (theme.brightness == Brightness.light)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        itemIcon,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            name,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "4.5",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              itemSubtext,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Open",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Approx ${_formatDistance(meters)} away",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.scaffoldBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.near_me,
                                          color: theme.primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Distance",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          ),
                                          Text(
                                            _formatDistance(meters),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    widget.onPlaceSelected(
                                      LatLng(
                                        place['safe_lat'],
                                        place['safe_lon'],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Navigate",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String id, BuildContext context) {
    bool isSelected = _selectedCategory == id;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _fetchNearbyPlaces(id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            if (id != "all")
              Icon(
                id == "cafe"
                    ? Icons.coffee
                    : id == "hotel"
                    ? Icons.hotel
                    : Icons.mosque,
                color: isSelected ? Colors.white : theme.iconTheme.color,
                size: 16,
              ),
            if (id != "all") const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
