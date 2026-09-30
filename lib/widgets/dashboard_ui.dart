import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../logic/gamification_logic.dart';
import '../logic/trip_records.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/alerts/danger_alert_screen.dart';
import '../screens/alerts/drowsy_alert_screen.dart';
import '../services/database_service.dart';
import '../services/places_service.dart';
import '../services/sync_service.dart';
import 'common/place_labels.dart';
import 'drive/destination_search_sheet.dart';
import 'drive/driver_status.dart';
import 'drive/in_trip_view.dart';
import 'drive/pre_trip_view.dart';
import 'drive/standby_view.dart';
import 'drive/trip_sheet.dart';

String get _mapboxAccessToken => AppConfig.mapboxAccessToken;

enum _AlertKind { drowsy, danger }

/// The Drive tab: the pre-trip checklist, the in-trip map and sheet, and
/// the full-screen drowsy / danger alerts.
class DashboardUI extends StatefulWidget {
  final VoidCallback onSwitchCamera;
  final bool hasCamera;
  final CameraLensDirection? lensDirection;
  final ValueListenable<CameraController?> cameraController;
  final ValueListenable<bool?> faceVisible;
  final VoidCallback onOpenAccount;

  const DashboardUI({
    super.key,
    required this.onSwitchCamera,
    required this.hasCamera,
    required this.lensDirection,
    required this.cameraController,
    required this.faceVisible,
    required this.onOpenAccount,
  });

  @override
  State<DashboardUI> createState() => DashboardUIState();
}

class DashboardUIState extends State<DashboardUI> {
  late final MonitoringProvider _monitor;
  late final LocationProvider _location;

  MapController _mapController = MapController();
  bool _mapReady = false;
  final Distance _distanceCalculator = const Distance();

  // Navigation
  LatLng? _destination;
  String? _destinationName;
  List<LatLng> _routePoints = [];
  DateTime? _arrivalTime;
  bool _routeFailed = false;
  bool _isAutoFollowing = true;

  /// Refreshes the "12 min" ETA while a destination is set.
  Timer? _etaTimer;

  // Trip session
  bool _tripSessionActive = false;
  bool _isStandbyMode = false;
  DateTime? _tripStartTime;
  double _totalDistanceTraveled = 0.0;
  double _maxSpeed = 0.0; // m/s
  double _sumSpeed = 0.0; // m/s
  int _speedSamples = 0;
  List<String> _tripEvents = [];
  bool _hadDrowsiness = false;
  bool _hasDangerousEvents = false;
  LatLng? _lastLocation;
  DateTime? _lastLocationTime;
  String _lastStatus = "IDLE";
  int _lastVoiceSosCount = 0;

  // Double tap detection state
  DateTime? _lastTapTime;

  // Alerts
  _AlertKind? _activeAlert;
  Route<void>? _alertRoute;
  bool _alertCheckScheduled = false;
  DateTime? _drowsyAckAt;
  DateTime? _dangerAckAt;

  /// Looks again when a quiet period ends while the driver is still
  /// drowsy or asleep (the status doesn't change, so nothing else would).
  Timer? _alertRecheckTimer;

  /// A dismissed drowsy alert stays quiet this long.
  static const _drowsyQuietPeriod = Duration(minutes: 5);
  static const _dangerQuietPeriod = Duration(seconds: 5);

  Future<Map<String, dynamic>?>? _lastTripFuture;

  @override
  void initState() {
    super.initState();
    _monitor = context.read<MonitoringProvider>();
    _location = context.read<LocationProvider>();
    _lastVoiceSosCount = _monitor.voiceSosCount;
    _monitor.addListener(_onMonitoringStateChange);
    _location.addListener(_onLocationUpdate);
    DatabaseService.instance.tripsRevision.addListener(_loadLastTrip);
    _lastTripFuture = _fetchLastTrip();
  }

  @override
  void dispose() {
    _monitor.removeListener(_onMonitoringStateChange);
    _location.removeListener(_onLocationUpdate);
    DatabaseService.instance.tripsRevision.removeListener(_loadLastTrip);
    _etaTimer?.cancel();
    _alertRecheckTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchLastTrip() async {
    final userId = context.read<AuthProvider>().currentUser['id']?.toString();
    if (userId == null) return null;
    return DatabaseService.instance.getLastTrip(userId);
  }

  void _loadLastTrip() {
    if (!mounted) return;
    setState(() => _lastTripFuture = _fetchLastTrip());
  }

  void _logEvent(String text) => _tripEvents.add(TripEvent.entry(text));

  void _onLocationUpdate() {
    if (!mounted || !_tripSessionActive) return;
    final newLoc = _location.currentLocation;
    final speed = _location.currentSpeed;

    // Ignore speed glitches no car could reach (over ~250 km/h).
    if (speed <= 70) {
      _maxSpeed = math.max(_maxSpeed, speed);
      if (speed > 0) {
        _sumSpeed += speed;
        _speedSamples++;
      }
    }

    final now = DateTime.now();
    final last = _lastLocation;
    final lastTime = _lastLocationTime;
    if (last != null && lastTime != null) {
      double dist = _distanceCalculator.as(LengthUnit.Meter, last, newLoc);
      final seconds = now.difference(lastTime).inMilliseconds / 1000;
      // Skip GPS jumps no car could make (over ~250 km/h).
      final plausible = seconds > 0 && dist / seconds < 70;
      if (dist > 5 && plausible) _totalDistanceTraveled += dist;
    }
    _lastLocation = newLoc;
    _lastLocationTime = now;

    // The map isn't drawn in standby; it's recentred on wake.
    if (_isAutoFollowing && _mapReady && !_isStandbyMode) {
      _mapController.move(newLoc, 17.0);
    }
  }

  void _onMonitoringStateChange() {
    if (!mounted) return;

    // Monitoring stopped outside the End trip button (e.g. the voice
    // command): still end and save the trip.
    if (_tripSessionActive && !_monitor.isMonitoring) {
      _endTrip();
      return;
    }
    if (!_tripSessionActive) return;

    // SOS asked for by voice.
    if (_monitor.voiceSosCount != _lastVoiceSosCount) {
      _lastVoiceSosCount = _monitor.voiceSosCount;
      _hasDangerousEvents = true;
      _logEvent(TripEvent.manualSos);
    }

    final status = _monitor.status;
    if (status != _lastStatus) {
      if (status == "DROWSY") {
        _hadDrowsiness = true;
        _logEvent(TripEvent.drowsy);
      } else if (status == "ASLEEP") {
        _hadDrowsiness = true;
        _logEvent(TripEvent.asleep);
        _hasDangerousEvents = true;
      } else if (status == "DISTRACTED") {
        _logEvent(TripEvent.distracted);
      }
      _lastStatus = status;
    }

    if (status == "ASLEEP" || status == "DROWSY") _scheduleAlertCheck();
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTrip() {
    // Fresh map controller per trip; the last trip's map may still be
    // fading out, so the old controller is left for it.
    _mapController = MapController();

    setState(() {
      _tripSessionActive = true;
      _isStandbyMode = false;
      _mapReady = false;
      _isAutoFollowing = true;
      _tripEvents = [];
      _hadDrowsiness = false;
      _hasDangerousEvents = false;
      _logEvent(TripEvent.started);
      _tripStartTime = DateTime.now();
      _maxSpeed = 0.0;
      _sumSpeed = 0.0;
      _speedSamples = 0;
      _totalDistanceTraveled = 0.0;
      // Before the first fix the location is only a stand-in; start
      // measuring from the first real one.
      _lastLocation = _location.hasFix ? _location.currentLocation : null;
      _lastLocationTime = _lastLocation == null ? null : DateTime.now();
      _drowsyAckAt = null;
      _dangerAckAt = null;
    });

    _lastVoiceSosCount = _monitor.voiceSosCount;
    _monitor.toggleMonitoring();
    _lastStatus = _monitor.status;
    _location.startRecording(); // ✅ Start Recording Path
  }

  void _endTrip() async {
    if (!_tripSessionActive) return;
    // Mark the session over first so the monitoring listener ignores the
    // toggle below.
    _tripSessionActive = false;
    _alertRecheckTimer?.cancel();
    _closeAlert();
    if (_monitor.isMonitoring) _monitor.toggleMonitoring();
    setState(() => _isStandbyMode = false);

    try {
      _logEvent(TripEvent.ended);
      // Same rule as the Reports tab: any drowsiness makes it a drowsy trip.
      String finalStatus = _hadDrowsiness || _hasDangerousEvents
          ? "Drowsy"
          : "Safe";
      if (_tripEvents.any((e) => e.contains("SOS"))) {
        finalStatus = "Emergency";
      }

      final endTime = DateTime.now();
      final startTime = _tripStartTime ?? endTime;
      final avgSpeed = _speedSamples > 0 ? (_sumSpeed / _speedSamples) : 0.0;
      final distance =
          "${(_totalDistanceTraveled / 1000).toStringAsFixed(1)} km";

      // ✅ Get Recorded Path
      final routePath = _location.stopRecording();

      // Get current user ID for trip ownership
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser['id'].toString();

      final tripId = await DatabaseService.instance.saveTrip(
        userId: userId,
        // Dated by its start, so a trip past midnight stays on its day.
        customDate: startTime.toIso8601String(),
        duration: _formatTime(endTime.difference(startTime).inSeconds),
        distance: distance,
        status: finalStatus,
        alerts: _tripEvents,
        score: _monitor.currentScore.toInt(),
        startTime: DateFormat('hh:mm a').format(startTime),
        endTime: DateFormat('hh:mm a').format(endTime),
        // Geolocator speeds are m/s; store km/h to match the label.
        avgSpeed: "${(avgSpeed * 3.6).toStringAsFixed(1)} km/h",
        maxSpeed: "${(_maxSpeed * 3.6).toStringAsFixed(1)} km/h",
        routePath: routePath,
      );

      // Process Gamification
      await GamificationLogic.processTripForGamification(userId, {
        'status': finalStatus,
        'distance': distance,
        'score': _monitor.currentScore.toInt(),
        'startHour': startTime.hour,
      });

      // Push trip to cloud in background
      SyncService.instance.pushTrip(userId, tripId);
    } catch (e) {
      debugPrint("Error ending trip: $e");
    } finally {
      if (mounted) setState(() => _totalDistanceTraveled = 0.0);
    }
  }

  Future<void> _triggerSOSManual() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _hasDangerousEvents = true);
    _logEvent(TripEvent.manualSos);

    final contact = _monitor.emergencyContact;
    final sent = await _monitor.triggerSOS(manual: true);
    final String message;
    if (contact.isEmpty) {
      message = l10n.sosNoContact;
    } else if (sent) {
      message = l10n.sosSentTo(contact);
    } else {
      message = l10n.sosSendFailed;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: l10n.stopAlarm,
            onPressed: _monitor.silenceAlarm,
          ),
        ),
      );
  }

  void startNavigation(LatLng dest, {String? name}) async {
    final loc = _location.currentLocation;
    _etaTimer?.cancel();
    setState(() {
      _destination = dest;
      _destinationName = name;
      _routePoints = [];
      _arrivalTime = null;
      _routeFailed = false;
    });

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${loc.longitude},${loc.latitude};${dest.longitude},${dest.latitude}?geometries=geojson&overview=full&annotations=duration&access_token=$_mapboxAccessToken',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (!mounted || _destination != dest) return;
      final routes = response.statusCode == 200
          ? json.decode(response.body)['routes'] as List?
          : null;
      if (routes == null || routes.isEmpty) {
        setState(() => _routeFailed = true);
        return;
      }
      final route = routes.first;
      final List coords = route['geometry']['coordinates'];
      final points = coords
          .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
          .toList();
      final durationSeconds = (route['duration'] as num).toDouble();

      setState(() {
        _routePoints = points;
        _arrivalTime = DateTime.now().add(
          Duration(seconds: durationSeconds.round()),
        );
      });
      // Count the minutes down while driving.
      _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint("Route Error: $e");
      if (mounted && _destination == dest) {
        setState(() => _routeFailed = true);
      }
    }
  }

  void _clearNavigation() {
    _etaTimer?.cancel();
    setState(() {
      _destination = null;
      _destinationName = null;
      _routePoints = [];
      _arrivalTime = null;
      _routeFailed = false;
      _isAutoFollowing = true;
    });
  }

  void _recenter() {
    setState(() => _isAutoFollowing = true);
    if (_mapReady) _mapController.move(_location.currentLocation, 17.0);
  }

  void _wakeFromStandby() {
    setState(() => _isStandbyMode = false);
    if (_isAutoFollowing && _mapReady) {
      _mapController.move(_location.currentLocation, 17.0);
    }
  }

  void _onMapTap(LatLng point) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      startNavigation(point);
      _lastTapTime = null;
    } else {
      _lastTapTime = now;
    }
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DestinationSearchSheet(
        near: _location.hasLocation ? _location.currentLocation : null,
        onSelected: (location, name) => startNavigation(location, name: name),
      ),
    );
  }

  /// "12 min · arrive 9:53", or null while the route is loading.
  String? _etaText(AppLocalizations l10n) {
    if (_routeFailed) return l10n.routeUnavailable;
    final arrival = _arrivalTime;
    if (arrival == null) return null;
    final minutes = math.max(
      0,
      (arrival.difference(DateTime.now()).inSeconds / 60).ceil(),
    );
    final at = DateFormat('h:mm', l10n.localeName).format(arrival);
    return l10n.etaLine(minutes, at);
  }

  // ── Alerts ────────────────────────────────────────────────────────────

  /// Alerts are pushed after the current frame so a provider notification
  /// during a build can't push a route mid-build.
  void _scheduleAlertCheck() {
    if (_alertCheckScheduled) return;
    _alertCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _alertCheckScheduled = false;
      if (!mounted || !_tripSessionActive) return;
      final status = _monitor.status;
      if (status == "ASLEEP") {
        _maybeShowDangerAlert();
      } else if (status == "DROWSY") {
        _maybeShowDrowsyAlert();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Checks again once a quiet period that started at [ack] is over.
  void _recheckAfter(DateTime ack, Duration quietPeriod) {
    final remaining = quietPeriod - DateTime.now().difference(ack);
    _alertRecheckTimer?.cancel();
    _alertRecheckTimer = Timer(
      remaining + const Duration(milliseconds: 100),
      _scheduleAlertCheck,
    );
  }

  void _maybeShowDrowsyAlert() {
    if (_activeAlert != null) return;
    final ack = _drowsyAckAt;
    if (ack != null && DateTime.now().difference(ack) < _drowsyQuietPeriod) {
      _recheckAfter(ack, _drowsyQuietPeriod);
      return;
    }
    _showAlert(_AlertKind.drowsy);
  }

  void _maybeShowDangerAlert() {
    if (_activeAlert == _AlertKind.danger) return;
    final ack = _dangerAckAt;
    if (ack != null && DateTime.now().difference(ack) < _dangerQuietPeriod) {
      _recheckAfter(ack, _dangerQuietPeriod);
      return;
    }
    if (_activeAlert == _AlertKind.drowsy) _closeAlert();
    _showAlert(_AlertKind.danger);
  }

  void _showAlert(_AlertKind kind) {
    final vibrate = context.read<SettingsProvider>().vibration;
    final Widget screen;
    if (kind == _AlertKind.drowsy) {
      if (vibrate) HapticFeedback.heavyImpact();
      final l10n = AppLocalizations.of(context)!;
      screen = DrowsyAlertScreen(
        restStop: _findNearestRestStop(),
        onTakeMeThere: (stop) {
          _logEvent(TripEvent.tookBreak);
          _drowsyAckAt = DateTime.now();
          _closeAlert();
          startNavigation(stop.location, name: stop.place.displayName(l10n));
        },
        onKeepDriving: () {
          _logEvent(TripEvent.keptDriving);
          _drowsyAckAt = DateTime.now();
          _closeAlert();
        },
      );
    } else {
      screen = DangerAlertScreen(
        contact: _monitor.emergencyContact,
        autoSosEnabled: _monitor.autoEmergencyEnabled,
        vibrate: vibrate,
        onAwake: () {
          _monitor.silenceAlarm();
          _logEvent(TripEvent.confirmedAwake);
          _dangerAckAt = DateTime.now();
          _closeAlert();
        },
        onSendNow: () {
          _hasDangerousEvents = true;
          _logEvent(TripEvent.manualSos);
          return _monitor.triggerSOS(manual: true);
        },
        onCountdownComplete: () {
          _logEvent(TripEvent.autoSos);
          return _monitor.triggerSOS();
        },
      );
    }

    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => screen,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    _activeAlert = kind;
    _alertRoute = route;
    Navigator.of(context).push(route);
  }

  void _closeAlert() {
    final route = _alertRoute;
    _alertRoute = null;
    _activeAlert = null;
    if (route == null || !route.isActive) return;
    final navigator = route.navigator;
    if (navigator == null) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  Future<RestStop?> _findNearestRestStop() async {
    // Tripoli stands in before the first fix; don't search around it.
    if (!_location.hasLocation) return null;
    final here = _location.currentLocation;
    try {
      final result = await PlacesService().findPlaces(
        center: here,
        category: 'all',
        languageCode: Localizations.localeOf(context).languageCode,
        minResults: 1,
      );
      if (result.places.isEmpty) return null;
      final place = result.places.first;
      return RestStop(
        place: place,
        distanceKm: approxDistanceMeters(here, place.location) / 1000,
      );
    } catch (e) {
      debugPrint("Rest stop lookup failed: $e");
      return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<MonitoringProvider, LocationProvider>(
      builder: (context, monitor, loc, child) {
        final inTrip = monitor.isMonitoring;
        final status = DriverStatus.fromMonitor(monitor.status);

        final Widget view;
        if (inTrip) {
          final tripView = InTripView(
            mapController: _mapController,
            currentLocation: loc.currentLocation,
            heading: loc.currentHeading,
            routePoints: _routePoints,
            destination: _destination,
            destinationName: _destinationName,
            destinationEta: _etaText(l10n),
            isListening: monitor.isListening,
            onMapReady: () {
              _mapReady = true;
              if (_isAutoFollowing) {
                _mapController.move(_location.currentLocation, 17.0);
              }
            },
            onMapGesture: () {
              if (_isAutoFollowing) setState(() => _isAutoFollowing = false);
            },
            onMapTap: _onMapTap,
            onRecenter: _recenter,
            onMicTap: monitor.toggleListening,
            onClearDestination: _clearNavigation,
            sheet: TripSheet(
              status: status,
              drowsiness: monitor.drowsinessLevel,
              startedAt: _tripStartTime ?? DateTime.now(),
              distanceKm: _totalDistanceTraveled / 1000,
              speedKmh: math.max(0, (loc.currentSpeed * 3.6).round()),
              onSos: _triggerSOSManual,
              onEndTrip: _endTrip,
              onStandby: () => setState(() => _isStandbyMode = true),
            ),
          );
          // Standby covers the trip view without unmounting it, so the map
          // controller stays attached. Offstage skips painting the map and
          // TickerMode pauses its animations.
          view = Stack(
            key: const ValueKey('in-trip'),
            fit: StackFit.expand,
            children: [
              TickerMode(
                enabled: !_isStandbyMode,
                child: Offstage(offstage: _isStandbyMode, child: tripView),
              ),
              if (_isStandbyMode)
                StandbyView(status: status, onWake: _wakeFromStandby),
            ],
          );
        } else {
          final user = context.watch<AuthProvider>().currentUser;
          final name = (user['fullName'] as String?)?.trim();
          view = ValueListenableBuilder<bool?>(
            key: const ValueKey('pre-trip'),
            valueListenable: widget.faceVisible,
            builder: (context, faceVisible, _) => PreTripView(
              userName: (name == null || name.isEmpty)
                  ? (user['email'] as String? ?? '').split('@').first
                  : name,
              readiness: ReadinessState(
                hasCamera: widget.hasCamera,
                lensDirection: widget.lensDirection,
                faceVisible: faceVisible,
                hasGpsFix: loc.hasFix,
                gpsAccuracy: loc.accuracy,
                gpsOff: loc.issue != null,
              ),
              cameraController: widget.cameraController,
              destinationName: _destination == null
                  ? null
                  : (_destinationName ?? l10n.droppedPin),
              destinationEta: _etaText(l10n),
              lastTrip: _lastTripFuture,
              isListening: monitor.isListening,
              onSwitchCamera: widget.onSwitchCamera,
              onOpenSearch: _openSearchSheet,
              onClearDestination: _clearNavigation,
              onStartTrip: _startTrip,
              onMicTap: monitor.toggleListening,
              onAvatarTap: widget.onOpenAccount,
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: view,
        );
      },
    );
  }
}
