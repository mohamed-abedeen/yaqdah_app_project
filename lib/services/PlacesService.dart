import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  Future<List<dynamic>> fetchPlaces({
    required LatLng center,
    required String category,
    int radius = 3000, // Reduced to 3km for faster loading
    int radius2 = 7000, //hotels reduce
  }) async {
    String queryContent = "";

    // Queries
    String cafeQuery =
        """
      node["amenity"="cafe"](around:$radius,${center.latitude},${center.longitude});
      way["amenity"="cafe"](around:$radius,${center.latitude},${center.longitude});
    """;

    String hotelQuery =
        """
      node["tourism"~"hotel|motel|guest_house|hostel"](around:$radius2,${center.latitude},${center.longitude});
      way["tourism"~"hotel|motel|guest_house|hostel"](around:$radius2,${center.latitude},${center.longitude});
    """;

    String mosqueQuery =
        """
      node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${center.latitude},${center.longitude});
      way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${center.latitude},${center.longitude});
    """;

    // Logic to combine queries
    if (category == "all") {
      queryContent = cafeQuery + hotelQuery + mosqueQuery;
    } else if (category == "hotel") {
      queryContent = hotelQuery;
    } else if (category == "mosque") {
      queryContent = mosqueQuery;
    } else {
      queryContent = cafeQuery;
    }

    final String fullQuery = '[out:json];($queryContent);out center;';
    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=$fullQuery",
    );

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
          place['distance_meters'] = distanceCalculator.as(
            LengthUnit.Meter,
            center,
            LatLng(lat, lon),
          );
        }

        // Sort here so the UI receives ordered data
        rawPlaces.sort(
          (a, b) => a['distance_meters'].compareTo(b['distance_meters']),
        );

        return rawPlaces;
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
    return [];
  }
}
