import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
  String _selectedCategory = "cafe";
  List<dynamic> _places = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces("cafe");
  }

  Future<void> _fetchNearbyPlaces(String category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
      _places = [];
    });

    final center = widget.getCurrentLocation();
    String queryContent = "";

    if (category == "hotel") {
      queryContent = """
        node["tourism"~"hotel|motel|guest_house|hostel"](around:10000,${center.latitude},${center.longitude});
        way["tourism"~"hotel|motel|guest_house|hostel"](around:10000,${center.latitude},${center.longitude});
      """;
    } else if (category == "mosque") {
      queryContent = """
        node["amenity"="place_of_worship"]["religion"="muslim"](around:10000,${center.latitude},${center.longitude});
        way["amenity"="place_of_worship"]["religion"="muslim"](around:10000,${center.latitude},${center.longitude});
      """;
    } else {
      queryContent = """
        node["amenity"="cafe"](around:10000,${center.latitude},${center.longitude});
        way["amenity"="cafe"](around:10000,${center.latitude},${center.longitude});
      """;
    }

    final String fullQuery = '[out:json];($queryContent);out center;';
    final url = Uri.parse("https://overpass-api.de/api/interpreter?data=$fullQuery");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> rawPlaces = data['elements'];
        final Distance distanceCalculator = const Distance();

        for (var place in rawPlaces) {
          double lat = place['lat'] ?? place['center']['lat'];
          double lon = place['lon'] ?? place['center']['lon'];
          place['safe_lat'] = lat;
          place['safe_lon'] = lon;
          place['distance_meters'] = distanceCalculator.as(LengthUnit.Meter, center, LatLng(lat, lon));
        }

        rawPlaces.sort((a, b) => a['distance_meters'].compareTo(b['distance_meters']));

        if (mounted) {
          setState(() {
            _places = rawPlaces;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.toInt()} m";
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rest Places", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Find nearby places to rest", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: const Icon(Icons.compass_calibration, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search for places...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip("All Places", "cafe", true), // Default for now
                      _categoryChip("Coffee", "cafe", false),
                      _categoryChip("Hotels", "hotel", false),
                      _categoryChip("Mosques", "mosque", false),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${_places.length} PLACES FOUND", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text("Sort by distance", style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                String name = place['tags']['name'] ?? "Unknown Place";
                double meters = place['distance_meters'] ?? 0.0;

                if (_selectedCategory == "mosque" && place['tags']['religion'] != 'muslim' && !(place['tags']['name']?.toLowerCase().contains('mosque') ?? false)) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
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
                                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                                child: Icon(_getIconForCategory(), color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 150, child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                  const SizedBox(height: 4),
                                  const Row(children: [Icon(Icons.star, color: Colors.amber, size: 14), SizedBox(width: 4), Text("4.5", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(" • Coffee", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                                ],
                              )
                            ],
                          ),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: const Text("Open", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Approx ${_formatDistance(meters)} away", style: const TextStyle(color: Colors.grey, fontSize: 12))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.near_me, color: Colors.blue, size: 16)),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Distance", style: TextStyle(color: Colors.grey, fontSize: 10)), Text(_formatDistance(meters), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => widget.onPlaceSelected(LatLng(place['safe_lat'], place['safe_lon'])),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text("Navigate", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  IconData _getIconForCategory() {
    if (_selectedCategory == "cafe") return Icons.coffee;
    if (_selectedCategory == "hotel") return Icons.hotel;
    return Icons.mosque;
  }

  Widget _categoryChip(String label, String id, bool isAll) {
    bool isSelected = _selectedCategory == id && !isAll; // Simple logic
    if (isAll && _selectedCategory == "cafe") isSelected = false; // Just visual logic for demo

    return GestureDetector(
      onTap: () => _fetchNearbyPlaces(id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected || (isAll && id == "cafe") ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.white10),
        ),
        child: Row(
          children: [
            if (!isAll) Icon(id == "cafe" ? Icons.coffee : id == "hotel" ? Icons.hotel : Icons.mosque, color: Colors.white, size: 16),
            if (!isAll) const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}