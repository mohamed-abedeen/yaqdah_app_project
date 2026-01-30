import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  LatLng _currentLocation = const LatLng(32.8872, 13.1913); // Default (Tripoli)
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0; // In m/s
  StreamSubscription<Position>? _positionStreamSubscription;

  // Route Tracking
  bool _isRecording = false;
  final List<Map<String, double>> _routePath = [];

  LatLng get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;
  List<Map<String, double>> get routePath => _routePath;

  bool get isRecording => _isRecording;

  Future<void> requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        startLocationUpdates();
      } else {
        if (kDebugMode) {
          print('Location services are disabled.');
        }
      }
    } else {
      if (kDebugMode) {
        print('Location permission denied.');
      }
    }
  }

  void startLocationUpdates() {
    _positionStreamSubscription?.cancel();

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _currentSpeed = position.speed; // m/s
          _currentHeading = position.heading;

          // ✅ Record Path
          if (_isRecording) {
            _routePath.add({
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }

          notifyListeners();
        });
  }

  void startRecording() {
    _isRecording = true;
    _routePath.clear();
    // Add start point
    _routePath.add({
      'lat': _currentLocation.latitude,
      'lng': _currentLocation.longitude,
    });
    notifyListeners();
  }

  List<Map<String, double>> stopRecording() {
    _isRecording = false;
    notifyListeners();
    return List.from(_routePath);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
