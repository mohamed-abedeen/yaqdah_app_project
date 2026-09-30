import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Kinds of places the Rest tab lists.
abstract final class PlaceType {
  static const cafe = 'cafe';
  static const mosque = 'mosque';
  static const hotel = 'hotel';
  static const fuel = 'fuel';
  static const restArea = 'rest_area';
}

/// A place to stop, from OpenStreetMap.
@immutable
class Place {
  const Place({
    required this.id,
    required this.type,
    required this.location,
    this.name,
  });

  /// OSM element id, e.g. `node/123`.
  final String id;

  /// One of [PlaceType].
  final String type;
  final LatLng location;

  /// Null when OSM has no name, which is common for mosques and fuel
  /// stations; show the type label instead.
  final String? name;
}

/// Places around [center], nearest first.
class PlacesResult {
  const PlacesResult({
    required this.center,
    required this.radius,
    required this.places,
  });

  final LatLng center;

  /// How far out the search went, in metres.
  final int radius;
  final List<Place> places;
}

/// No Overpass server answered.
class PlacesUnavailableException implements Exception {
  const PlacesUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'PlacesUnavailableException: $cause';
}

/// Finds places to rest near the driver with the OpenStreetMap Overpass API.
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  /// Public Overpass servers, tried in order when one is busy or down.
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const _userAgent = 'Yaqdah/1.1 (driver drowsiness app)';
  static const _requestTimeout = Duration(seconds: 20);

  /// Search radii in metres, widened until enough places turn up. Starting
  /// small keeps city searches fast; hotels are sparse, so they start wider.
  static const _radii = [3000, 10000, 30000];
  static const _hotelRadii = [10000, 30000, 60000];

  static const _cacheLifetime = Duration(minutes: 10);

  /// A cached search is reused when its centre is this close, in metres.
  static const _cacheReuseDistance = 300.0;

  final http.Client _client = http.Client();
  final List<_CacheEntry> _cache = [];
  final Map<String, Future<List<Place>>> _inFlight = {};

  /// Places of [category] (`all` or a [PlaceType] shown as a filter chip)
  /// around [center], nearest first.
  ///
  /// The search widens until at least [minResults] places are found or the
  /// largest radius is reached. Names prefer [languageCode].
  ///
  /// Throws [PlacesUnavailableException] when no server answers.
  Future<PlacesResult> findPlaces({
    required LatLng center,
    required String category,
    String languageCode = 'ar',
    int minResults = 6,
  }) async {
    final radii = category == PlaceType.hotel ? _hotelRadii : _radii;
    PlacesResult? widest;
    for (final radius in radii) {
      final List<Place> places;
      try {
        places = await _placesWithin(center, category, radius, languageCode);
      } on PlacesUnavailableException {
        // A wider search failed: keep what the smaller one found.
        if (widest != null && widest.places.isNotEmpty) return widest;
        rethrow;
      }
      widest = PlacesResult(
        center: center,
        radius: radius,
        places: _sortedByDistance(places, center),
      );
      if (places.length >= minResults) break;
    }
    return widest!;
  }

  Future<List<Place>> _placesWithin(
    LatLng center,
    String category,
    int radius,
    String languageCode,
  ) {
    final now = DateTime.now();
    _cache.removeWhere((e) => now.difference(e.time) > _cacheLifetime);
    for (final entry in _cache) {
      if (entry.category == category &&
          entry.radius == radius &&
          entry.languageCode == languageCode &&
          approxDistanceMeters(entry.center, center) <= _cacheReuseDistance) {
        return Future.value(entry.places);
      }
    }

    final key =
        '$category|$radius|$languageCode|'
        '${center.latitude.toStringAsFixed(3)},'
        '${center.longitude.toStringAsFixed(3)}';
    return _inFlight[key] ??= _query(center, category, radius, languageCode)
        .then((places) {
          _cache.add(
            _CacheEntry(
              category: category,
              radius: radius,
              languageCode: languageCode,
              center: center,
              time: DateTime.now(),
              places: places,
            ),
          );
          if (_cache.length > 12) _cache.removeAt(0);
          return places;
        })
        // Block body: returning the removed future (this one) would make
        // it wait for itself forever.
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  static List<String> _filters(String category) => switch (category) {
    PlaceType.cafe => _cafeFilters,
    PlaceType.mosque => _mosqueFilters,
    PlaceType.hotel => _hotelFilters,
    _ => [..._cafeFilters, ..._mosqueFilters, ..._hotelFilters, ..._roadside],
  };

  static const _cafeFilters = [r'["amenity"~"^(cafe|restaurant|fast_food)$"]'];
  static const _mosqueFilters = [
    '["amenity"="place_of_worship"]["religion"="muslim"]',
    '["building"="mosque"]',
  ];
  static const _hotelFilters = [
    r'["tourism"~"^(hotel|motel|guest_house|hostel)$"]',
  ];

  /// Fuel stations and highway rest areas: only in "All".
  static const _roadside = [
    '["amenity"="fuel"]',
    r'["highway"~"^(rest_area|services)$"]',
  ];

  Future<List<Place>> _query(
    LatLng center,
    String category,
    int radius,
    String languageCode,
  ) async {
    final around =
        '(around:$radius,${center.latitude.toStringAsFixed(6)},'
        '${center.longitude.toStringAsFixed(6)})';
    final query = StringBuffer('[out:json][timeout:25];(');
    for (final filter in _filters(category)) {
      query.write('nwr$filter$around;');
    }
    query.write(');out center;');

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: const {'User-Agent': _userAgent},
              body: {'data': query.toString()},
            )
            .timeout(_requestTimeout);
        if (response.statusCode != 200) {
          lastError = 'HTTP ${response.statusCode} from $endpoint';
          continue;
        }
        // Big cities return thousands of elements: parse off the UI thread.
        return await compute(
          _parsePlaces,
          _ParseJob(
            body: response.bodyBytes,
            category: category,
            languageCode: languageCode,
            latitude: center.latitude,
            longitude: center.longitude,
          ),
        );
      } catch (e) {
        lastError = e;
        debugPrint('Overpass $endpoint failed: $e');
      }
    }
    throw PlacesUnavailableException(lastError ?? 'no response');
  }

  static List<Place> _sortedByDistance(List<Place> places, LatLng from) {
    final withDistance = [
      for (final p in places) (p, approxDistanceMeters(from, p.location)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final entry in withDistance) entry.$1];
  }
}

/// Distance in metres, accurate to well under 1% at the few-tens-of-km
/// scale the Rest tab uses, and much cheaper than Vincenty.
double approxDistanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final x =
      (b.longitudeInRad - a.longitudeInRad) *
      math.cos((a.latitudeInRad + b.latitudeInRad) / 2);
  final y = b.latitudeInRad - a.latitudeInRad;
  return math.sqrt(x * x + y * y) * earthRadius;
}

class _CacheEntry {
  const _CacheEntry({
    required this.category,
    required this.radius,
    required this.languageCode,
    required this.center,
    required this.time,
    required this.places,
  });

  final String category;
  final int radius;
  final String languageCode;
  final LatLng center;
  final DateTime time;
  final List<Place> places;
}

class _ParseJob {
  const _ParseJob({
    required this.body,
    required this.category,
    required this.languageCode,
    required this.latitude,
    required this.longitude,
  });

  final Uint8List body;
  final String category;
  final String languageCode;
  final double latitude;
  final double longitude;
}

/// Most places kept from one response.
const _maxPlaces = 150;

/// Types still worth listing without a name.
const _unnamedOk = {PlaceType.mosque, PlaceType.fuel, PlaceType.restArea};

/// Runs in a background isolate.
List<Place> _parsePlaces(_ParseJob job) {
  final data = json.decode(utf8.decode(job.body));
  if (data is! Map) throw const FormatException('Unexpected Overpass reply');
  final elements = data['elements'];
  if (elements is! List) throw const FormatException('No elements');
  final remark = data['remark']?.toString() ?? '';
  // A server-side timeout still answers 200, with a remark and no data.
  if (elements.isEmpty && remark.contains('error')) {
    throw FormatException(remark);
  }

  final center = LatLng(job.latitude, job.longitude);
  final found = <(Place, double)>[];
  for (final element in elements) {
    if (element is! Map) continue;
    final tags = element['tags'];
    if (tags is! Map) continue;

    final type = job.category == 'all' ? _classify(tags) : job.category;
    if (type == null) continue;
    final location = _locationOf(element);
    if (location == null) continue;
    final name = _nameOf(tags, job.languageCode, type);
    if (name == null && !_unnamedOk.contains(type)) continue;

    found.add((
      Place(
        id: '${element['type']}/${element['id']}',
        type: type,
        location: location,
        name: name,
      ),
      approxDistanceMeters(center, location),
    ));
  }
  found.sort((a, b) => a.$2.compareTo(b.$2));

  // The same mosque or café is often mapped twice, e.g. as a point and as
  // its building. Keep one, preferring the entry that has a name.
  final kept = <Place>[];
  final ids = <String>{};
  for (final (place, _) in found) {
    if (!ids.add(place.id)) continue;
    final twin = kept.indexWhere((k) => _samePlace(k, place));
    if (twin >= 0) {
      if (kept[twin].name == null && place.name != null) kept[twin] = place;
      continue;
    }
    kept.add(place);
    if (kept.length >= _maxPlaces) break;
  }
  return kept;
}

String? _classify(Map tags) {
  final amenity = tags['amenity']?.toString();
  final tourism = tags['tourism']?.toString();
  final highway = tags['highway']?.toString();
  if (highway == 'rest_area' || highway == 'services') {
    return PlaceType.restArea;
  }
  if (amenity == 'fuel') return PlaceType.fuel;
  if (const {'hotel', 'motel', 'guest_house', 'hostel'}.contains(tourism)) {
    return PlaceType.hotel;
  }
  if ((amenity == 'place_of_worship' && tags['religion'] == 'muslim') ||
      tags['building'] == 'mosque') {
    return PlaceType.mosque;
  }
  if (const {'cafe', 'restaurant', 'fast_food'}.contains(amenity)) {
    return PlaceType.cafe;
  }
  return null;
}

LatLng? _locationOf(Map element) {
  // Nodes carry lat/lon; ways and relations a `center` from `out center`.
  final center = element['center'];
  final lat = element['lat'] ?? (center is Map ? center['lat'] : null);
  final lon = element['lon'] ?? (center is Map ? center['lon'] : null);
  if (lat is! num || lon is! num) return null;
  return LatLng(lat.toDouble(), lon.toDouble());
}

String? _nameOf(Map tags, String languageCode, String type) {
  String? tag(String key) {
    final value = tags[key]?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  final name = tag('name:$languageCode') ?? tag('name');
  if (name != null) return name;
  // Chains are often tagged with a brand but no name.
  if (type != PlaceType.mosque) return tag('brand');
  return null;
}

bool _samePlace(Place a, Place b) {
  if (a.type != b.type) return false;
  final meters = approxDistanceMeters(a.location, b.location);
  final nameA = a.name?.toLowerCase();
  final nameB = b.name?.toLowerCase();
  if (nameA != null && nameB != null) return nameA == nameB && meters < 250;
  return meters < 60;
}
