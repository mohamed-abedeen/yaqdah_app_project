import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/location_sms_service.dart';
import '../services/theme_service.dart'; // ✅ Import ThemeService

const String _mapboxAccessToken =
    'pk.eyJ1IjoibW9ob3oiLCJhIjoiY21rNng0eTBhMG1tejNmc2hkZjg2djg5cSJ9.EhZ_hhGrpAGJRb1j-O5eIw';

class DashboardUI extends StatefulWidget {
  final Function(LatLng) onLocationUpdate;
  final bool isMonitoring;
  final String status;
  final double drowsinessLevel;
  final String aiMessage;
  final VoidCallback onToggleMonitoring;
  final VoidCallback onMicToggle;
  final bool isListening;
  final VoidCallback onSwitchCamera;
  final String currentCameraName;

  const DashboardUI({
    super.key,
    required this.onLocationUpdate,
    required this.isMonitoring,
    required this.status,
    required this.drowsinessLevel,
    required this.aiMessage,
    required this.onToggleMonitoring,
    required this.onMicToggle,
    required this.isListening,
    required this.onSwitchCamera,
    required this.currentCameraName,
  });

  @override
  State<DashboardUI> createState() => DashboardUIState();
}

class DashboardUIState extends State<DashboardUI>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationSmsService _smsService = LocationSmsService();
  final Distance _distanceCalculator = const Distance();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(32.8872, 13.1913);
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0;

  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isRouteLoading = false;
  String _tripDistanceDisplay = "0.0";
  String _etaDisplay = "--:--";
  bool _isAutoFollowing = true;

  int _tripDurationSeconds = 0;
  Timer? _tripTimer;

  bool _tripSessionActive = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  DateTime? _tripStartTime;
  double _totalDistanceTraveled = 0.0;
  double _maxSpeed = 0.0;
  double _sumSpeed = 0.0;
  int _speedSamples = 0;

  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  List<String> _tripEvents = [];
  bool _hasDangerousEvents = false;

  @override
  void initState() {
    super.initState();
    _startTripTimer();
    _startLiveLocationUpdates();
  }

  @override
  void didUpdateWidget(DashboardUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tripSessionActive && widget.status != oldWidget.status) {
      final now = DateTime.now().toIso8601String();
      if (widget.status == "DROWSY") {
        _tripEvents.add("$now: ⚠️ Drowsiness Detected");
      } else if (widget.status == "ASLEEP" || widget.status == "DISTRACTED") {
        _tripEvents.add("$now: 🚨 Danger: ${widget.status}");
        setState(() => _hasDangerousEvents = true);
      }
    }
  }

  void _startTripTimer() {
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.isMonitoring && mounted) {
        setState(() => _tripDurationSeconds++);
      }
    });
  }

  Future<void> _startLiveLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    await Permission.location.request();

    LatLng? lastPos;

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          final newLatLong = LatLng(position.latitude, position.longitude);

          double speedKmh = position.speed * 3.6;
          if (speedKmh < 3.0) speedKmh = 0.0;

          if (_tripSessionActive) {
            _maxSpeed = math.max(_maxSpeed, speedKmh);
            if (speedKmh > 0) {
              _sumSpeed += speedKmh;
              _speedSamples++;
            }
            if (lastPos != null) {
              double dist = _distanceCalculator.as(
                LengthUnit.Meter,
                lastPos!,
                newLatLong,
              );
              if (dist > 5) _totalDistanceTraveled += dist;
            }
          }
          lastPos = newLatLong;

          String newDistDisplay = _tripDistanceDisplay;
          if (_destination != null) {
            double meters = _distanceCalculator.as(
              LengthUnit.Meter,
              newLatLong,
              _destination!,
            );
            newDistDisplay = (meters / 1000).toStringAsFixed(1);
          } else {
            newDistDisplay = (_totalDistanceTraveled / 1000).toStringAsFixed(1);
          }

          setState(() {
            _currentLocation = newLatLong;
            _tripDistanceDisplay = newDistDisplay;
            _currentSpeed = speedKmh;
            if (position.speed > 0.5) _currentHeading = position.heading;
          });

          widget.onLocationUpdate(newLatLong);
          if (_isAutoFollowing) _mapController.move(newLatLong, 18.0);
        });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleTrip() {
    if (widget.isMonitoring)
      _endTrip();
    else
      _startTrip();
  }

  void _startTrip() {
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
    });
    widget.onToggleMonitoring();
  }

  void _endTrip() async {
    _tripEvents.add("${DateTime.now().toIso8601String()}: 🛑 Trip Ended");
    String finalStatus = _hasDangerousEvents || widget.drowsinessLevel > 50
        ? "Drowsy"
        : "Safe";
    if (_tripEvents.any((e) => e.contains("Manual SOS")))
      finalStatus = "Emergency";

    final endTime = DateTime.now();
    final avgSpeed = _speedSamples > 0 ? (_sumSpeed / _speedSamples) : 0.0;

    await DatabaseService.instance.saveTrip(
      duration: _formatTime(_tripDurationSeconds),
      distance: "${(_totalDistanceTraveled / 1000).toStringAsFixed(1)} km",
      status: finalStatus,
      alerts: _tripEvents,
      startTime: DateFormat('hh:mm a').format(_tripStartTime ?? endTime),
      endTime: DateFormat('hh:mm a').format(endTime),
      avgSpeed: "${avgSpeed.toStringAsFixed(1)} km/h",
      maxSpeed: "${_maxSpeed.toStringAsFixed(1)} km/h",
    );

    widget.onToggleMonitoring();
    setState(() {
      _tripSessionActive = false;
      _tripDurationSeconds = 0;
      _tripDistanceDisplay = "0.0";
      _totalDistanceTraveled = 0.0;
    });
  }

  void _triggerSOSManual() {
    setState(() => _hasDangerousEvents = true);
    _tripEvents.add("${DateTime.now().toIso8601String()}: 🆘 Manual SOS");
    _smsService.sendEmergencyAlert();
  }

  void startNavigation(LatLng dest) async {
    setState(() {
      _destination = dest;
      _isRouteLoading = true;
      _isAutoFollowing = false;
    });

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${_currentLocation.longitude},${_currentLocation.latitude};${dest.longitude},${dest.latitude}?geometries=geojson&overview=full&annotations=duration&access_token=$_mapboxAccessToken',
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
      "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$_mapboxAccessToken&autocomplete=true&limit=5&country=LY",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setModalState(() {
          _searchResults = data['features'];
          _isSearching = false;
        });
      }
    } catch (e) {
      setModalState(() => _isSearching = false);
    }
  }

  void _openSearchSheet() {
    final theme = Theme.of(context); // ✅ Get theme
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
                    style: theme.textTheme.bodyMedium, // ✅ Dynamic Text Color
                    decoration: InputDecoration(
                      hintText: "Search destination...",
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                      filled: true,
                      fillColor:
                          theme.scaffoldBackgroundColor, // ✅ Dynamic Input BG
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
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
                        return ListTile(
                          title: Text(
                            result['text'] ?? "",
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            result['place_name'] ?? "",
                            maxLines: 1,
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            double lon = result['center'][0];
                            double lat = result['center'][1];
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

  Map<String, dynamic> _getStatusConfig() {
    final red = ThemeService.red;
    final orange = ThemeService.orange;
    final green = ThemeService.Green;

    if (widget.status == "ASLEEP" || widget.status == "DISTRACTED") {
      return {
        'color': red,
        'bgColor': red.withOpacity(0.2),
        'borderColor': red.withOpacity(0.5),
        'text': "خطر - توقف فوراً!",
      };
    } else if (widget.status == "DROWSY") {
      return {
        'color': orange,
        'bgColor': orange.withOpacity(0.2),
        'borderColor': orange.withOpacity(0.5),
        'text': "نعسان",
      };
    } else {
      return {
        'color': green,
        'bgColor': green.withOpacity(0.2),
        'borderColor': green.withOpacity(0.5),
        'text': "يقظ ومستيقظ",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ Get Current Theme
    final isDark = theme.brightness == Brightness.dark;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final statusConfig = _getStatusConfig();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "يقظة",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "نظام كشف النعاس للسائقين",
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  ],
                ),
                Container(
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
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 16.0,
                        onPositionChanged: (p, g) {
                          if (g) setState(() => _isAutoFollowing = false);
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
                              point: _currentLocation,
                              width: 40,
                              height: 40,
                              child: Transform.rotate(
                                angle: _currentHeading * (math.pi / 180),
                                child: const Icon(
                                  Icons.navigation,
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
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _smallMapButton(
                        icon: Icons.search,
                        onTap: _openSearchSheet,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _smallMapButton(
                        icon: Icons.my_location,
                        onTap: () {
                          setState(() => _isAutoFollowing = true);
                          _mapController.move(_currentLocation, 18.0);
                        },
                        isActive: _isAutoFollowing,
                      ),
                    ),
                    if (_destination != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _smallMapButton(
                          icon: Icons.close,
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
                          Icons.remove_red_eye,
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
                              "حالة السائق",
                              style: TextStyle(color: subColor, fontSize: 11),
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
                            "${widget.drowsinessLevel.toInt()}%",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: statusConfig['color'],
                            ),
                          ),
                          Text(
                            "مستوى النعاس",
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
                      label: "طوارئ",
                      icon: Icons.phone,
                      color: ThemeService.red,
                      onTap: _triggerSOSManual,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGlassButton(
                      label: widget.isMonitoring ? "إيقاف" : "بدء",
                      icon: widget.isMonitoring
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.isMonitoring
                          ? ThemeService.orange
                          : theme.primaryColor,
                      onTap: _toggleTrip,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGlassButton(
                      label: "كاميرا",
                      subLabel: widget.currentCameraName,
                      icon: Icons.cameraswitch,
                      color: ThemeService.purple,
                      onTap: widget.onSwitchCamera,
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
                        Icons.access_time,
                        "المدة",
                        _formatTime(_tripDurationSeconds),
                        theme.primaryColor,
                        unit: "",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDarkStatCard(
                        Icons.location_on,
                        "المسافة",
                        _tripDistanceDisplay,
                        ThemeService.blue,
                        unit: "كم",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDarkStatCard(
                        Icons.speed,
                        "السرعة",
                        "${_currentSpeed.toInt()}",
                        ThemeService.purple,
                        unit: "كم/س",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDarkStatCard(
                        Icons.navigation,
                        "الوصول",
                        _etaDisplay,
                        ThemeService.orange,
                        unit: "",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Use Theme.of(context) inside helpers
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
              // In Light mode, make buttons simpler, Dark mode uses glass
              color: isDark ? color.withOpacity(0.15) : theme.cardColor,
              border: Border.all(
                color: isDark ? color.withOpacity(0.4) : theme.dividerColor,
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
                      color: isDark ? color.withOpacity(0.7) : Colors.grey,
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
    final theme = Theme.of(context); // ✅ Dynamic Theme
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ Changed from hardcoded
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
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
