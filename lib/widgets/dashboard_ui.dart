// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../providers/monitoring_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../config/app_config.dart';
import '../services/sync_service.dart';
import '../logic/gamification_logic.dart';

String get _mapboxAccessToken => AppConfig.mapboxAccessToken;

class DashboardUI extends StatefulWidget {
  final VoidCallback onSwitchCamera;
  final String currentCameraName;

  const DashboardUI({
    super.key,
    required this.onSwitchCamera,
    required this.currentCameraName,
  });

  @override
  State<DashboardUI> createState() => DashboardUIState();
}

class DashboardUIState extends State<DashboardUI>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isRouteLoading = false;
  String _tripDistanceDisplay = "0.0";
  String _etaDisplay = "--:--";
  bool _isAutoFollowing = true;

  int _tripDurationSeconds = 0;
  Timer? _tripTimer;

  bool _tripSessionActive = false;
  bool _isStandbyMode = false;

  DateTime? _tripStartTime;
  double _totalDistanceTraveled = 0.0;
  double _maxSpeed = 0.0;
  double _sumSpeed = 0.0;
  int _speedSamples = 0;

  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  List<String> _tripEvents = [];
  bool _hasDangerousEvents = false;

  LatLng? _lastLocation;

  // Double tap detection state
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _startTripTimer();

    // Listen for Monitoring Status Changes to log events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitor = Provider.of<MonitoringProvider>(context, listen: false);
      monitor.addListener(_onMonitoringStateChange);

      final loc = Provider.of<LocationProvider>(context, listen: false);
      loc.addListener(_onLocationUpdate);
    });
  }

  void _onLocationUpdate() {
    if (!mounted || !_tripSessionActive) return;
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final newLoc = locProvider.currentLocation;
    final speed = locProvider.currentSpeed;

    _maxSpeed = math.max(_maxSpeed, speed);
    if (speed > 0) {
      _sumSpeed += speed;
      _speedSamples++;
    }

    if (_lastLocation != null) {
      double dist = _distanceCalculator.as(
        LengthUnit.Meter,
        _lastLocation!,
        newLoc,
      );
      if (dist > 5) _totalDistanceTraveled += dist;
    }
    _lastLocation = newLoc;

    // Update Display
    if (_destination != null) {
      double meters = _distanceCalculator.as(
        LengthUnit.Meter,
        newLoc,
        _destination!,
      );
      setState(() {
        _tripDistanceDisplay = (meters / 1000).toStringAsFixed(1);
      });
    } else {
      setState(() {
        _tripDistanceDisplay = (_totalDistanceTraveled / 1000).toStringAsFixed(
          1,
        );
      });
    }

    if (_isAutoFollowing) _mapController.move(newLoc, 18.0);
  }

  void _onMonitoringStateChange() {
    if (!mounted || !_tripSessionActive) return;

    // Logic from didUpdateWidget
    // We need to compare with "previous" status but Providers don't give "previous".
    // But since we log EVENTS, maybe just logging "Current status is X" is fine,
    // but we don't want to log duplicates if it stays "DROWSY".
    // I'll keep a local _lastStatus to compare.
  }

  String _lastStatus = "IDLE";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use this to track status changes if addListener is tricky with "previous" value
    final monitor = Provider.of<MonitoringProvider>(context);
    if (_tripSessionActive && monitor.status != _lastStatus) {
      final now = DateTime.now().toIso8601String();
      if (monitor.status == "DROWSY") {
        _tripEvents.add("$now: ⚠️ Drowsiness Detected");
      } else if (monitor.status == "ASLEEP") {
        _tripEvents.add("$now: 🚨 Danger: Asleep");
        setState(() => _hasDangerousEvents = true);
      } else if (monitor.status == "DISTRACTED") {
        _tripEvents.add("$now: ⚠️ Distraction Detected");
      }
      _lastStatus = monitor.status;
    }
  }

  void _startTripTimer() {
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tripSessionActive && mounted && _tripStartTime != null) {
        final duration = DateTime.now().difference(_tripStartTime!);
        setState(() => _tripDurationSeconds = duration.inSeconds);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleTrip() {
    final monitor = Provider.of<MonitoringProvider>(context, listen: false);
    if (monitor.isMonitoring) {
      _endTrip();
    } else {
      _startTrip();
    }
  }

  void _startTrip() {
    final monitor = Provider.of<MonitoringProvider>(context, listen: false);
    final location = Provider.of<LocationProvider>(
      context,
      listen: false,
    ); // ✅ Get LocationProvider

    setState(() {
      _tripSessionActive = true;
      _tripEvents = [];
      _hasDangerousEvents = false;
      _tripEvents.add("${DateTime.now().toIso8601String()}: 🏁 Trip Started");
      _tripStartTime = DateTime.now();
      _maxSpeed = 0.0;
      _sumSpeed = 0.0;
      _speedSamples = 0;
      _totalDistanceTraveled = 0.0;
      _tripDurationSeconds = 0;
      _lastStatus = monitor.status;
    });

    monitor.toggleMonitoring();
    location.startRecording(); // ✅ Start Recording Path
  }

  void _endTrip() async {
    final monitor = Provider.of<MonitoringProvider>(context, listen: false);
    final location = Provider.of<LocationProvider>(context, listen: false);

    // ✅ Immediately update UI to feel responsive and prevent hanging
    monitor.toggleMonitoring();
    setState(() {
      _tripSessionActive = false;
    });

    try {
      _tripEvents.add("${DateTime.now().toIso8601String()}: 🛑 Trip Ended");
      String finalStatus = _hasDangerousEvents || monitor.drowsinessLevel > 50
          ? "Drowsy"
          : "Safe";
      if (_tripEvents.any((e) => e.contains("Manual SOS"))) {
        finalStatus = "Emergency";
      }

      final endTime = DateTime.now();
      final avgSpeed = _speedSamples > 0 ? (_sumSpeed / _speedSamples) : 0.0;

      // ✅ Get Recorded Path
      final routePath = location.stopRecording();

      // Get current user ID for trip ownership
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser['id'].toString();

      await DatabaseService.instance.saveTrip(
        userId: userId,
        duration: _formatTime(_tripDurationSeconds),
        distance: "${(_totalDistanceTraveled / 1000).toStringAsFixed(1)} km",
        status: finalStatus,
        alerts: _tripEvents,
        score: monitor.currentScore.toInt(),
        startTime: DateFormat('hh:mm a').format(_tripStartTime ?? endTime),
        endTime: DateFormat('hh:mm a').format(endTime),
        avgSpeed: "${avgSpeed.toStringAsFixed(1)} km/h",
        maxSpeed: "${_maxSpeed.toStringAsFixed(1)} km/h",
        routePath: routePath,
      );

      // Process Gamification
      await GamificationLogic.processTripForGamification(userId, {
        'status': finalStatus,
        'distance': "${(_totalDistanceTraveled / 1000).toStringAsFixed(1)} km",
        'score': monitor.currentScore.toInt(),
        'startTime': DateFormat('hh:mm a').format(_tripStartTime ?? endTime),
      });

      // Push trip to cloud in background
      final lastId = await DatabaseService.instance.getLastInsertedTripId();
      if (lastId != null) {
        final trips = await DatabaseService.instance.getTrips(userId);
        final savedTrip = trips.firstWhere(
          (t) => t['id'] == lastId,
          orElse: () => {},
        );
        if (savedTrip.isNotEmpty) {
          SyncService.instance.pushTrip(userId, savedTrip);
        }
      }
    } catch (e) {
      debugPrint("Error ending trip: $e");
    } finally {
      if (mounted) {
        setState(() {
          _tripDurationSeconds = 0;
          _tripDistanceDisplay = "0.0";
          _totalDistanceTraveled = 0.0;
        });
      }
    }
  }

  void _triggerSOSManual() {
    final monitor = Provider.of<MonitoringProvider>(context, listen: false);
    setState(() => _hasDangerousEvents = true);
    _tripEvents.add("${DateTime.now().toIso8601String()}: 🆘 Manual SOS");
    monitor.triggerSOS();
  }

  void startNavigation(LatLng dest) async {
    final loc = Provider.of<LocationProvider>(
      context,
      listen: false,
    ).currentLocation;
    setState(() {
      _destination = dest;
      _isRouteLoading = true;
      _isAutoFollowing = false;
    });

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${loc.longitude},${loc.latitude};${dest.longitude},${dest.latitude}?geometries=geojson&overview=full&annotations=duration&access_token=$_mapboxAccessToken',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final List coords = route['geometry']['coordinates'];
        final points = coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
        final double durationSeconds = route['duration'];
        final int minutes = (durationSeconds / 60).round();
        final int hours = minutes ~/ 60;
        final int mins = minutes % 60;
        String eta = hours > 0 ? "${hours}h ${mins}m" : "${mins}m";

        setState(() {
          _routePoints = points;
          _etaDisplay = eta;
          _isRouteLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isRouteLoading = false);
    }
    _mapController.move(dest, 15.0);
  }

  void _clearNavigation() {
    setState(() {
      _destination = null;
      _routePoints = [];
      _tripDistanceDisplay = "0.0";
      _etaDisplay = "--:--";
      _isAutoFollowing = true;
    });
  }

  void _performSearch(String query, StateSetter setModalState) async {
    if (query.isEmpty) return;
    setModalState(() => _isSearching = true);

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search"
      "?q=$query"
      "&format=json"
      "&limit=5"
      "&countrycodes=ly"
      "&addressdetails=1",
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.yaqdah_app_student_project'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setModalState(() {
          _searchResults = data;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      setModalState(() => _isSearching = false);
    }
  }

  void _openSearchSheet() {
    final theme = Theme.of(context);
    _searchResults = [];
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchPlaces,
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: theme.primaryColor,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          CupertinoIcons.arrow_right,
                          color: theme.primaryColor,
                        ),
                        onPressed: () => _performSearch(
                          _searchController.text,
                          setModalState,
                        ),
                      ),
                    ),
                    onSubmitted: (val) => _performSearch(val, setModalState),
                  ),
                  const SizedBox(height: 10),
                  if (_isSearching)
                    LinearProgressIndicator(color: theme.primaryColor),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final name = result['display_name'].toString().split(
                          ',',
                        )[0];
                        final fullAddress = result['display_name'];

                        return ListTile(
                          title: Text(name, style: theme.textTheme.bodyMedium),
                          subtitle: Text(
                            fullAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          onTap: () {
                            double lat = double.parse(result['lat']);
                            double lon = double.parse(result['lon']);
                            Navigator.pop(context);
                            startNavigation(LatLng(lat, lon));
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _getStatusConfig(
    MonitoringProvider monitor,
    AppLocalizations l10n,
  ) {
    final red = ThemeService.red;
    final orange = ThemeService.orange;
    final green = ThemeService.green;
    final blue = ThemeService.blue;

    if (!monitor.isMonitoring) {
      return {
        'color': blue,
        'bgColor': blue.withValues(alpha: 0.2),
        'borderColor': blue.withValues(alpha: 0.5),
        'text': l10n.statusReady,
      };
    }

    if (monitor.status == "ASLEEP") {
      return {
        'color': red,
        'bgColor': red.withValues(alpha: 0.2),
        'borderColor': red.withValues(alpha: 0.5),
        'text': l10n.statusAsleep,
      };
    } else if (monitor.status == "DISTRACTED") {
      return {
        'color': orange,
        'bgColor': orange.withValues(alpha: 0.2),
        'borderColor': orange.withValues(alpha: 0.5),
        'text': l10n.statusDistracted,
      };
    } else if (monitor.status == "NO_FACE") {
      return {
        'color': orange,
        'bgColor': orange.withValues(alpha: 0.2),
        'borderColor': orange.withValues(alpha: 0.5),
        'text': l10n.statusNoFace,
      };
    } else if (monitor.status == "DROWSY") {
      return {
        'color': orange,
        'bgColor': orange.withValues(alpha: 0.2),
        'borderColor': orange.withValues(alpha: 0.5),
        'text': l10n.statusDrowsy,
      };
    } else {
      return {
        'color': green,
        'bgColor': green.withValues(alpha: 0.2),
        'borderColor': green.withValues(alpha: 0.5),
        'text': l10n.statusAlert,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<MonitoringProvider, LocationProvider>(
      builder: (context, monitor, locProvider, child) {
        final statusConfig = _getStatusConfig(monitor, l10n);
        final currentLocation = locProvider.currentLocation;
        final currentSpeed = locProvider.currentSpeed;
        final currentHeading = locProvider.currentHeading;

        if (_isStandbyMode) {
          return GestureDetector(
            onTap: () => setState(() => _isStandbyMode = false),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.moon_stars_fill,
                    color: Colors.blueGrey,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.statusAsleep == "Asleep"
                        ? "Standby Mode"
                        : "وضع الاستعداد",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.statusAsleep == "Asleep"
                        ? "Tap anywhere to wake"
                        : "اضغط للاستيقاظ",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (monitor.status != "AWAKE" &&
                      monitor.status != "SAFE" &&
                      monitor.status != "IDLE") ...[
                    const SizedBox(height: 40),
                    Text(
                      statusConfig['text'],
                      style: TextStyle(
                        color: statusConfig['color'],
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start),
                    SizedBox(
                      width: 118,
                      height: 40,
                      child: Image.asset(
                        'images/yaqdah-13.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: currentLocation,
                              initialZoom: 16.0,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.doubleTapZoom,
                              ),
                              onPositionChanged: (p, g) {
                                if (g) setState(() => _isAutoFollowing = false);
                              },
                              onTap: (tapPosition, point) {
                                final now = DateTime.now();
                                if (_lastTapTime != null &&
                                    now.difference(_lastTapTime!) <
                                        const Duration(milliseconds: 300)) {
                                  startNavigation(point);
                                  _lastTapTime = null;
                                } else {
                                  _lastTapTime = now;
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxAccessToken',
                                userAgentPackageName: 'com.example.yaqdah_app',
                              ),
                              if (_routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4.0,
                                      color: Colors.blueAccent,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: currentLocation,
                                    width: 40,
                                    height: 40,
                                    child: Transform.rotate(
                                      angle: currentHeading * (math.pi / 180),
                                      child: const Icon(
                                        CupertinoIcons.location_north_fill,
                                        color: Colors.blueAccent,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  if (_destination != null)
                                    Marker(
                                      point: _destination!,
                                      width: 35,
                                      height: 35,
                                      child: const Icon(
                                        CupertinoIcons.location_solid,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _smallMapButton(
                            icon: CupertinoIcons.search,
                            onTap: _openSearchSheet,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: _smallMapButton(
                            icon: CupertinoIcons.location_fill,
                            onTap: () {
                              setState(() => _isAutoFollowing = true);
                              _mapController.move(currentLocation, 18.0);
                            },
                            isActive: _isAutoFollowing,
                          ),
                        ),
                        if (_destination != null)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _smallMapButton(
                              icon: CupertinoIcons.xmark,
                              onTap: _clearNavigation,
                              isDanger: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusConfig['bgColor'],
                        border: Border.all(
                          color: statusConfig['borderColor'],
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: statusConfig['bgColor'],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusConfig['borderColor'],
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.eye_fill,
                              color: statusConfig['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.driverStatus,
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusConfig['text'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusConfig['color'],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                !monitor.isMonitoring
                                    ? "--"
                                    : "${monitor.drowsinessLevel.toInt()}%",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: statusConfig['color'],
                                ),
                              ),
                              Text(
                                l10n.drowsinessLevel,
                                style: TextStyle(fontSize: 10, color: subColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassButton(
                          label: l10n.btnEmergency,
                          icon: CupertinoIcons.phone_fill,
                          color: ThemeService.red,
                          onTap: _triggerSOSManual,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassButton(
                          label: monitor.isMonitoring
                              ? l10n.btnStop
                              : l10n.btnStart,
                          icon: monitor.isMonitoring
                              ? CupertinoIcons.stop_fill
                              : CupertinoIcons.play_fill,
                          color: monitor.isMonitoring
                              ? ThemeService.orange
                              : theme.primaryColor,
                          onTap: _toggleTrip,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassButton(
                          label: l10n.btnCamera,
                          subLabel: widget.currentCameraName,
                          icon: CupertinoIcons.camera_rotate_fill,
                          color: isDark
                              ? ThemeService.green
                              : ThemeService.purple,
                          onTap: widget.onSwitchCamera,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGlassButton(
                          label: l10n.statusAsleep == "Asleep"
                              ? "Standby"
                              : "توفير",
                          icon: CupertinoIcons.moon_fill,
                          color: Colors.blueGrey,
                          onTap: () {
                            if (monitor.isMonitoring) {
                              setState(() => _isStandbyMode = true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.statusAsleep == "Asleep"
                                        ? "Start a trip first"
                                        : "ابدأ الرحلة أولاً",
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkStatCard(
                            CupertinoIcons.clock,
                            l10n.statDuration,
                            _formatTime(_tripDurationSeconds),
                            theme.primaryColor,
                            unit: "",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDarkStatCard(
                            CupertinoIcons.location_solid,
                            l10n.statDistance,
                            _tripDistanceDisplay,
                            ThemeService.blue,
                            unit: l10n.kmUnit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkStatCard(
                            CupertinoIcons.speedometer,
                            l10n.statSpeed,
                            "${currentSpeed.toInt()}",
                            isDark ? ThemeService.green : ThemeService.purple,
                            unit: l10n.kmhUnit,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDarkStatCard(
                            CupertinoIcons.location_north_fill,
                            l10n.statHeading,
                            _etaDisplay,
                            ThemeService.blue,
                            unit: "",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _smallMapButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.redAccent
              : (isActive ? theme.primaryColor : theme.cardColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(
          icon,
          size: 18,
          color: (isActive || isDanger) ? Colors.white : theme.iconTheme.color,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    String? subLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? color.withValues(alpha: 0.15) : theme.cardColor,
              border: Border.all(
                color: isDark
                    ? color.withValues(alpha: 0.4)
                    : theme.dividerColor,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? color : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: isDark
                          ? color.withValues(alpha: 0.7)
                          : Colors.grey,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkStatCard(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    required String unit,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
