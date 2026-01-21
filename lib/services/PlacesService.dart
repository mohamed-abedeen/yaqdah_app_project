import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  Future<List<Map<String, dynamic>>> fetchPlaces({
    required LatLng center,
    required String category,
    int radius = 5000,
  }) async {
    String tagQuery = "";

    // ✅ 1. STRICT FILTERING: Only Hotels & Motels (No Guest Houses)
    if (category == 'hotel') {
      tagQuery = '["tourism"~"hotel|motel"]';
    } else if (category == 'cafe') {
      tagQuery = '["amenity"~"cafe|fast_food|restaurant"]';
    } else if (category == 'mosque') {
      tagQuery = '["amenity"="place_of_worship"]["religion"="muslim"]';
    } else {
      // "All" - Filtered to exclude houses too
      tagQuery = '["tourism"~"hotel|motel"]';
    }

    // 2. Build Overpass Query
    final String query =
        """
      [out:json][timeout:25];
      (
        node$tagQuery(around:$radius,${center.latitude},${center.longitude});
        way$tagQuery(around:$radius,${center.latitude},${center.longitude});
      );
      out body;
      >;
      out skel qt;
    """;

    final url = Uri.parse("https://overpass-api.de/api/interpreter");

    try {
      final response = await http.post(url, body: query);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> elements = data['elements'];

        List<Map<String, dynamic>> places = [];
        final Distance distanceCalculator = const Distance();

        for (var element in elements) {
          if (element['tags'] == null) continue;
          if (!element['tags'].containsKey('name')) continue;

          double lat = element['lat'] ?? 0.0;
          double lon = element['lon'] ?? 0.0;

          if (lat == 0.0 && element['center'] != null) {
            lat = element['center']['lat'];
            lon = element['center']['lon'];
          }

          if (lat == 0.0 || lon == 0.0) continue;

          LatLng pos = LatLng(lat, lon);
          double distMeters = distanceCalculator.as(
            LengthUnit.Meter,
            center,
            pos,
          );

          places.add({
            'id': element['id'].toString(),
            'name': element['tags']['name'] ?? "Unknown",
            'type': category == 'all' ? 'hotel' : category,
            'address':
                element['tags']['addr:street'] ?? "Location", // Simplified text
            'distance': (distMeters / 1000).toStringAsFixed(1),
            'distanceVal': distMeters,
            'location': pos,
          });
        }

        places.sort(
          (a, b) => (a['distanceVal'] as double).compareTo(
            b['distanceVal'] as double,
          ),
        );

        return places;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching Overpass places: $e");
      }
    }

    return [];
  }
}
