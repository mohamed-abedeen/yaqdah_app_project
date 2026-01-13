import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../services/location_sms_service.dart';

// ⚠️ PASTE YOUR MAPBOX TOKEN HERE
const String _mapboxAccessToken =
    'pk.eyJ1IjoibW9ob3oiLCJhIjoiY21rNng0eTBhMG1tejNmc2hkZjg2djg5cSJ9.EhZ_hhGrpAGJRb1j-O5eIw';

class DashboardUI extends StatefulWidget {
  final Function(LatLng) onLocationUpdate;
  final bool isMonitoring;
  final String status;
  final double drowsinessLevel;
  final String aiMessage;
  final VoidCallback onToggleMonitoring;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onMicToggle;
  final bool isListening;
  final bool showCameraFeed;
  final String currentCameraName; // ✅

  const DashboardUI({
    super.key,
    required this.onLocationUpdate,
    required this.isMonitoring,
    required this.status,
    required this.drowsinessLevel,
    required this.aiMessage,
    required this.onToggleMonitoring,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onMicToggle,
    required this.isListening,
    required this.showCameraFeed,
    required this.currentCameraName,
  });

  @override
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI> {
  final MapController _mapController = MapController();
  final LocationSmsService _smsService = LocationSmsService();
  final Distance _distanceCalculator = const Distance();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(32.8872, 13.1913);
  double _currentHeading = 0.0;

  // Navigation State
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isRouteLoading = false;
  String _tripDistanceDisplay = "0 m";
  String _etaDisplay = "--";

  // Map State
  bool _isAutoFollowing = true;
  List<Polygon> _isochrones = [];
  bool _showIsochrone = false;

  int _tripDurationSeconds = 0;
  Timer? _tripTimer;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _tripSessionActive = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startTripTimer();
    _startLiveLocationUpdates();
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

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          final newLatLong = LatLng(position.latitude, position.longitude);

          String newDist = _tripDistanceDisplay;
          if (_destination != null) {
            double meters = _distanceCalculator.as(
              LengthUnit.Meter,
              newLatLong,
              _destination!,
            );
            newDist = meters < 1000
                ? "${meters.toInt()} m"
                : "${(meters / 1000).toStringAsFixed(1)} km";
          }

          setState(() {
            _currentLocation = newLatLong;
            _tripDistanceDisplay = newDist;
            if (position.speed > 0.5) _currentHeading = position.heading;
            _updateRouteLine(newLatLong);
          });

          widget.onLocationUpdate(newLatLong);
          if (_isAutoFollowing) _mapController.move(newLatLong, 18.0);
        });
  }

  void _updateRouteLine(LatLng carPos) {
    if (_routePoints.isEmpty) return;
  }

  Future<void> _performSearch(String query, StateSetter setModalState) async {
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

  void _navigateToDestination(LatLng dest) async {
    setState(() {
      _destination = dest;
      _isRouteLoading = true;
      _isAutoFollowing = false;
      _isochrones.clear();
      _showIsochrone = false;
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

  void _toggleIsochrone() async {
    if (_showIsochrone) {
      setState(() {
        _showIsochrone = false;
        _isochrones = [];
      });
      return;
    }
    setState(() => _showIsochrone = true);

    final url = Uri.parse(
      "https://api.mapbox.com/isochrone/v1/mapbox/driving/${_currentLocation.longitude},${_currentLocation.latitude}?contours_minutes=15&polygons=true&access_token=$_mapboxAccessToken",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];

        List<Polygon> polygons = [];
        for (var f in features) {
          final List coords = f['geometry']['coordinates'];
          if (coords.isNotEmpty) {
            List<LatLng> points = [];
            for (var point in coords[0]) {
              points.add(LatLng(point[1].toDouble(), point[0].toDouble()));
            }
            polygons.add(
              Polygon(
                points: points,
                color: Colors.blue.withOpacity(0.3),
                borderStrokeWidth: 2,
                borderColor: Colors.blueAccent,
                isFilled: true,
              ),
            );
          }
        }
        if (mounted) setState(() => _isochrones = polygons);
      }
    } catch (e) {}
  }

  void _recenterMap() {
    setState(() => _isAutoFollowing = true);
    _mapController.move(_currentLocation, 18.0);
  }

  void _clearNavigation() {
    setState(() {
      _destination = null;
      _routePoints = [];
      _tripDistanceDisplay = "0 m";
      _etaDisplay = "--";
      _isAutoFollowing = true;
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ✅ FIXED: Method defined inside State class
  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
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
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "Where to (Libya)?",
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).primaryColor,
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
                    LinearProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(
                            result['text'] ?? "",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            result['place_name'] ?? "",
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            double lon = result['center'][0];
                            double lat = result['center'][1];
                            Navigator.pop(context);
                            _navigateToDestination(LatLng(lat, lon));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mapStyle = 'mapbox/navigation-day-v1';

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tripSessionActive
                  ? Expanded(
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onToggleMonitoring,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isMonitoring
                                  ? Colors.orange[800]
                                  : Colors.green[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              widget.isMonitoring
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            label: Text(
                              widget.isMonitoring
                                  ? "Pause Trip"
                                  : "Resume Trip",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back \nDriver",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          "Stay safe on your journey",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBtn(
                    widget.showCameraFeed ? Icons.videocam_off : Icons.videocam,
                    widget.onToggleCamera,
                    context,
                    widget.showCameraFeed ? "Hide Feed" : "Show Feed",
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(
                    Icons.cameraswitch,
                    widget.onSwitchCamera,
                    context,
                    widget.currentCameraName,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.status == "ASLEEP"
                    ? [Colors.red.shade900, Colors.red.shade800]
                    : [theme.cardColor, theme.cardColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_red_eye,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Driver Status",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          widget.isMonitoring ? widget.status : "Paused",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${widget.drowsinessLevel.toInt()}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const Text(
                          "Alertness",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.drowsinessLevel / 100,
                    minHeight: 8,
                    color: _getStatusColor(),
                    backgroundColor: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.drowsinessLevel > 50)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.red, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Drowsiness Detected! Please rest.",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.timer_outlined,
                  "Duration",
                  _formatTime(_tripDurationSeconds),
                  context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.near_me_outlined,
                  "Distance",
                  _tripDistanceDisplay,
                  context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(Icons.speed, "Avg Speed", "68 km/h", context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.trending_up,
                  "ETA",
                  _etaDisplay,
                  context,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 18.0,
                    onPositionChanged: (p, g) {
                      if (g) setState(() => _isAutoFollowing = false);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.mapbox.com/styles/v1/$mapStyle/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxAccessToken',
                      userAgentPackageName: 'com.example.yaqdah_app',
                      retinaMode: true,
                    ),
                    PolygonLayer(polygons: _isochrones),
                    PolylineLayer(
                      polylines: [
                        if (_routePoints.isNotEmpty)
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.0,
                            color: Colors.blueAccent,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 50,
                          height: 50,
                          child: Transform.rotate(
                            angle: _currentHeading * (math.pi / 180),
                            child: Icon(
                              Icons.navigation,
                              color: Colors.blueAccent,
                              size: 40,
                            ),
                          ),
                        ),
                        if (_destination != null)
                          Marker(
                            point: _destination!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 35,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // ✅ FIXED: Correctly referenced here
                Positioned(
                  top: 10,
                  left: 10,
                  child: FloatingActionButton.small(
                    heroTag: "search",
                    backgroundColor: theme.primaryColor,
                    child: const Icon(Icons.search, color: Colors.white),
                    onPressed: _openSearchSheet,
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: "recenter",
                    backgroundColor: _isAutoFollowing
                        ? theme.primaryColor
                        : Colors.grey,
                    child: Icon(Icons.my_location, color: Colors.white),
                    onPressed: _recenterMap,
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: "isochrone",
                    backgroundColor: _showIsochrone
                        ? Colors.orange
                        : theme.cardColor,
                    child: Icon(
                      Icons.layers,
                      color: _showIsochrone
                          ? Colors.white
                          : theme.iconTheme.color,
                    ),
                    onPressed: _toggleIsochrone,
                  ),
                ),
                if (_destination != null)
                  Positioned(
                    top: 10,
                    right: 60,
                    child: FloatingActionButton.small(
                      heroTag: "cancel",
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.close, color: Colors.white),
                      onPressed: _clearNavigation,
                    ),
                  ),
                if (_isRouteLoading)
                  Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(context),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.drowsinessLevel < 30) return Colors.green;
    if (widget.drowsinessLevel < 60) return Colors.amber;
    return Colors.red;
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback onTap,
    BuildContext context,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: IconButton(
            icon: Icon(icon, color: Theme.of(context).primaryColor),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (_tripSessionActive) {
                DatabaseService.instance.saveTrip(
                  _formatTime(_tripDurationSeconds),
                  _tripDistanceDisplay,
                  widget.drowsinessLevel > 50 ? "Drowsy" : "Safe Trip",
                );
                if (widget.isMonitoring) {
                  widget.onToggleMonitoring();
                }
                setState(() {
                  _tripSessionActive = false;
                  _tripDurationSeconds = 0;
                  _tripDistanceDisplay = "0 m";
                });
              } else {
                setState(() => _tripSessionActive = true);
                if (!widget.isMonitoring) {
                  widget.onToggleMonitoring();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _tripSessionActive
                  ? Colors.red[900]
                  : Colors.green[800],
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              _tripSessionActive ? Icons.stop_circle : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              _tripSessionActive ? "End Trip" : "Start Trip",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _smsService.sendEmergencyAlert(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text("SOS", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
