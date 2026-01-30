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
    // Queries for each type
    const String hotelQuery = '["tourism"~"hotel|motel"]';
    const String cafeQuery = '["amenity"~"cafe|fast_food|restaurant"]';
    const String mosqueQuery =
        '["amenity"="place_of_worship"]["religion"="muslim"]';

    // Build the partial query statements based on category
    List<String> queryParts = [];

    if (category == 'hotel') {
      queryParts.add(hotelQuery);
    } else if (category == 'cafe') {
      queryParts.add(cafeQuery);
    } else if (category == 'mosque') {
      queryParts.add(mosqueQuery);
    } else {
      // 'all' -> Add all keys
      queryParts.add(hotelQuery);
      queryParts.add(cafeQuery);
      queryParts.add(mosqueQuery);
    }

    // Construct the final Overpass QL Union
    // ( node[...](...); way[...](...); node[...](...); ... );
    StringBuffer unionBody = StringBuffer();
    for (String q in queryParts) {
      unionBody.writeln(
        'node$q(around:$radius,${center.latitude},${center.longitude});',
      );
      unionBody.writeln(
        'way$q(around:$radius,${center.latitude},${center.longitude});',
      );
    }

    final String query =
        """
      [out:json][timeout:25];
      (
        ${unionBody.toString()}
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

          // Handle 'way' elements with center
          if (lat == 0.0 && element['center'] != null) {
            lat = element['center']['lat'];
            lon = element['center']['lon'];
          }
          // Handle 'way' nodes flow down (Overpass 'out center' is better but we use >; so we might get nodes)
          // If strict lat/lon missing, skip
          if (lat == 0.0 || lon == 0.0) continue;

          LatLng pos = LatLng(lat, lon);
          double distMeters = distanceCalculator.as(
            LengthUnit.Meter,
            center,
            pos,
          );

          // Determine specific type from filtering
          String itemType = category;
          if (category == 'all') {
            final tags = element['tags'];
            final tourism = tags['tourism']?.toString() ?? "";
            final amenity = tags['amenity']?.toString() ?? "";
            final religion = tags['religion']?.toString() ?? "";

            if (tourism == 'hotel' || tourism == 'motel') {
              itemType = 'hotel';
            } else if (amenity == 'cafe' ||
                amenity == 'fast_food' ||
                amenity == 'restaurant') {
              itemType = 'cafe';
            } else if (amenity == 'place_of_worship' && religion == 'muslim') {
              itemType = 'mosque';
            } else {
              // Fallback logic
              if (amenity.contains('food') || amenity.contains('cafe')) {
                itemType = 'cafe';
              } else {
                itemType = 'hotel'; // Default fallback
              }
            }
          }

          // specific address parsing
          String address = "موقع محدد";
          if (element['tags']['addr:street'] != null) {
            address = element['tags']['addr:street'];
          } else if (element['tags']['addr:city'] != null) {
            address = element['tags']['addr:city'];
          }

          places.add({
            'id': element['id'].toString(),
            'name': element['tags']['name'] ?? "Unknown",
            'type': itemType,
            'address': address,
            'distance': (distMeters / 1000).toStringAsFixed(1),
            'distanceVal': distMeters,
            'location': pos,
          });
        }

        // Deduplicate by ID
        final ids = <String>{};
        final uniquePlaces = places.where((p) => ids.add(p['id'])).toList();

        uniquePlaces.sort(
          (a, b) => (a['distanceVal'] as double).compareTo(
            b['distanceVal'] as double,
          ),
        );

        return uniquePlaces;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching Overpass places: $e");
      }
    }

    return [];
  }
}
