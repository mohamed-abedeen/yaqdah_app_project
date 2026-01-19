import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  // Singleton
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  Future<List<Map<String, dynamic>>> fetchPlaces({
    required LatLng center,
    required String category,
    int radius = 5000,
  }) async {
    String queryContent = "";

    // 1. Define Queries
    String cafeQuery =
        """
      node["amenity"~"cafe|fast_food|restaurant"](around:$radius,${center.latitude},${center.longitude});
    """;

    // ✅ REFINED: Removed 'guest_house', 'hostel', 'apartment' to hide private houses
    String hotelQuery =
        """
      node["tourism"~"hotel|motel"](around:$radius,${center.latitude},${center.longitude});
    """;

    String mosqueQuery =
        """
      node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${center.latitude},${center.longitude});
    """;

    // 2. Select Query based on Category
    if (category == 'hotel') {
      queryContent = hotelQuery;
    } else if (category == 'cafe') {
      queryContent = cafeQuery;
    } else if (category == 'mosque') {
      queryContent = mosqueQuery;
    } else {
      // 'all' -> Combine essential ones (Removed Rest Areas)
      queryContent = cafeQuery + hotelQuery;
    }

    final String fullQuery = '[out:json];($queryContent);out center;';
    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=$fullQuery",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> elements = data['elements'];
        final Distance distanceCalculator = const Distance();

        List<Map<String, dynamic>> results = [];

        for (var place in elements) {
          var tags = place['tags'] ?? {};
          String name =
              tags['name:ar'] ??
              tags['name:en'] ??
              tags['name'] ??
              'مكان بدون اسم';

          String type = 'place';
          if (tags.containsKey('tourism'))
            type = 'hotel';
          else if (tags['religion'] == 'muslim')
            type = 'mosque';
          else if (tags['amenity'] == 'cafe' || tags['amenity'] == 'fast_food')
            type = 'cafe';

          double lat = place['lat'] ?? place['center']['lat'];
          double lon = place['lon'] ?? place['center']['lon'];
          LatLng pos = LatLng(lat, lon);

          double distMeters = distanceCalculator.as(
            LengthUnit.Meter,
            center,
            pos,
          );

          results.add({
            'id': place['id'],
            'name': name,
            'type': type,
            'address': tags['addr:street'] ?? 'قريب منك',
            'distance': (distMeters / 1000).toStringAsFixed(1),
            'distanceVal': distMeters,
            'location': pos,
          });
        }

        results.sort(
          (a, b) => (a['distanceVal'] as double).compareTo(
            b['distanceVal'] as double,
          ),
        );

        return results;
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }

    return <Map<String, dynamic>>[];
  }
}
