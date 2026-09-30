import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Why there's no live location.
enum LocationIssue { permissionDenied, serviceDisabled }

class LocationProvider with ChangeNotifier {
  LocationProvider() {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChange);
  }

  /// Shown until the first real position arrives (Tripoli).
  LatLng _currentLocation = const LatLng(32.8872, 13.1913);
  bool _hasLocation = false;
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0; // In m/s
  double? _accuracy; // In metres; null until the first live fix
  LocationIssue? _issue;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceSubscription;
  late final AppLifecycleListener _lifecycle;
  bool _starting = false;
  bool _inForeground = true;

  // Route Tracking
  bool _isRecording = false;
  final List<Map<String, double>> _routePath = [];

  /// The latest position, or Tripoli before [hasLocation].
  LatLng get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;

  /// Whether [currentLocation] is a real position: a live fix or the
  /// phone's last known one.
  bool get hasLocation => _hasLocation;

  /// Horizontal accuracy of the latest live fix in metres, or null before one.
  double? get accuracy => _accuracy;
  bool get hasFix => _accuracy != null;

  /// Set when location permission or the location service is off.
  LocationIssue? get issue => _issue;
  List<Map<String, double>> get routePath => _routePath;

  bool get isRecording => _isRecording;

  /// Starts position updates when permission and the location service
  /// allow. Safe to call again, e.g. after the permission prompt.
  Future<void> startLocationUpdates() async {
    if (_starting) return;
    _starting = true;
    try {
      _watchServiceStatus();
      if (!await Geolocator.isLocationServiceEnabled()) {
        _stopUpdates();
        _setIssue(LocationIssue.serviceDisabled);
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        _stopUpdates();
        _setIssue(LocationIssue.permissionDenied);
        return;
      }
      _setIssue(null);
      if (_positionSubscription == null) {
        await _seedFromLastKnown();
        _subscribe();
      }
    } catch (e) {
      debugPrint('Location start failed: $e');
    } finally {
      _starting = false;
    }
  }

  /// Asks for what [issue] needs: the permission prompt, or the settings
  /// page when the prompt can't be shown again.
  Future<void> resolveIssue() async {
    try {
      switch (_issue) {
        case LocationIssue.serviceDisabled:
          await Geolocator.openLocationSettings();
        case LocationIssue.permissionDenied:
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.deniedForever) {
            await Geolocator.openAppSettings();
          } else {
            await Geolocator.requestPermission();
          }
        case null:
          break;
      }
    } catch (e) {
      debugPrint('Location settings failed: $e');
    }
    await startLocationUpdates();
  }

  LocationSettings get _settings {
    // A trip needs smooth map following; otherwise a coarser stream is
    // enough for the readiness check and nearby places.
    final distanceFilter = _isRecording ? 5 : 25;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          intervalDuration: Duration(seconds: _isRecording ? 1 : 5),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          activityType: ActivityType.automotiveNavigation,
        );
      default:
        return LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
    }
  }

  void _subscribe() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: _settings).listen(
          _onPosition,
          onError: (Object error) {
            debugPrint('Location stream error: $error');
            _stopUpdates();
            if (error is LocationServiceDisabledException) {
              _setIssue(LocationIssue.serviceDisabled);
            } else if (error is PermissionDeniedException) {
              _setIssue(LocationIssue.permissionDenied);
            }
          },
        );
  }

  void _stopUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _onPosition(Position position) {
    _currentLocation = LatLng(position.latitude, position.longitude);
    _hasLocation = true;
    // iOS reports -1 when speed or heading is unknown.
    _currentSpeed = position.speed < 0 ? 0 : position.speed;
    // GPS heading is noise when barely moving; keep the last good one.
    if (position.heading >= 0 && _currentSpeed > 1.5) {
      _currentHeading = position.heading;
    }
    _accuracy = position.accuracy;
    _issue = null;

    // ✅ Record Path
    if (_isRecording) {
      _routePath.add({'lat': position.latitude, 'lng': position.longitude});
    }

    notifyListeners();
  }

  /// Shows the phone's last known position while the first fix comes in.
  Future<void> _seedFromLastKnown() async {
    if (_hasLocation) return;
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null || _hasLocation) return;
      _currentLocation = LatLng(last.latitude, last.longitude);
      _hasLocation = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Last known position unavailable: $e');
    }
  }

  void _watchServiceStatus() {
    if (_serviceSubscription != null) return;
    try {
      _serviceSubscription = Geolocator.getServiceStatusStream().listen((
        status,
      ) {
        if (status == ServiceStatus.enabled) {
          startLocationUpdates();
        } else {
          _stopUpdates();
          _setIssue(LocationIssue.serviceDisabled);
        }
      }, onError: (Object e) => debugPrint('Location service status: $e'));
    } catch (e) {
      // Not available on every platform.
      debugPrint('Location service status unavailable: $e');
    }
  }

  void _setIssue(LocationIssue? issue) {
    if (_issue == issue) return;
    _issue = issue;
    if (issue != null) _accuracy = null;
    notifyListeners();
  }

  void _onLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _inForeground = true;
        // Permission may have been granted in Settings meanwhile.
        startLocationUpdates();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _inForeground = false;
        // Keep tracking a trip; otherwise save the battery.
        if (!_isRecording) _stopUpdates();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void startRecording() {
    _isRecording = true;
    _routePath.clear();
    // Add start point, unless it's only the stand-in before the first fix
    if (hasFix) {
      _routePath.add({
        'lat': _currentLocation.latitude,
        'lng': _currentLocation.longitude,
      });
    }
    // Switch to the finer trip stream.
    if (_positionSubscription != null) _subscribe();
    notifyListeners();
  }

  List<Map<String, double>> stopRecording() {
    _isRecording = false;
    if (_positionSubscription != null) {
      _inForeground ? _subscribe() : _stopUpdates();
    }
    notifyListeners();
    return List.from(_routePath);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _positionSubscription?.cancel();
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
