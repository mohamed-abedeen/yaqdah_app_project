import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
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
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI>
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
  String _tripDistanceDisplay = "0 m";
  String _etaDisplay = "--";
  bool _isAutoFollowing = true;

  int _tripDurationSeconds = 0;
  Timer? _tripTimer;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  bool _tripSessionActive = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // ✅ New Logic: Track if the trip was dangerous
  List<String> _tripEvents = [];
  bool _hasDangerousEvents = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTripTimer();
    _startLiveLocationUpdates();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(_pulseController);
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

          double speedKmh = position.speed * 3.6;
          if (speedKmh < 0) speedKmh = 0;

          setState(() {
            _currentLocation = newLatLong;
            _tripDistanceDisplay = newDist;
            _currentSpeed = speedKmh;
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
        String eta = hours > 0 ? "${hours}س ${mins}د" : "${mins}د";

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

  // ✅ UPDATED LOGIC: Start/End Trip Session
  void _startTrip() {
    setState(() {
      _tripSessionActive = true;
      _tripEvents = [];
      _hasDangerousEvents = false; // Reset danger flag
      _tripEvents.add("${DateTime.now().toIso8601String()}: 🏁 بدء الرحلة");
    });
    if (!widget.isMonitoring) {
      widget.onToggleMonitoring();
    }
  }

  void _endTrip() {
    _tripEvents.add("${DateTime.now().toIso8601String()}: 🛑 نهاية الرحلة");

    // ✅ FIXED: Determine status based on HISTORY, not just current moment
    String finalStatus = "رحلة آمنة";
    if (_hasDangerousEvents || widget.drowsinessLevel > 50) {
      finalStatus = "ناعس"; // Mark as Drowsy if ANY bad event happened
    }

    DatabaseService.instance.saveTrip(
      _formatTime(_tripDurationSeconds),
      _tripDistanceDisplay,
      finalStatus,
      _tripEvents,
    );

    if (widget.isMonitoring) {
      widget.onToggleMonitoring();
    }
    setState(() {
      _tripSessionActive = false;
      _tripDurationSeconds = 0;
      _tripDistanceDisplay = "0 m";
    });
  }

  void _triggerSOSManual() {
    setState(() => _hasDangerousEvents = true); // Mark trip as dangerous
    _tripEvents.add(
      "${DateTime.now().toIso8601String()}: 🆘 نداء استغاثة يدوي",
    );
    _smsService.sendEmergencyAlert();
  }

  // ✅ Track Automatic Alerts via Widget Update
  @override
  void didUpdateWidget(DashboardUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tripSessionActive) {
      if (widget.status != oldWidget.status && widget.status == "ASLEEP") {
        setState(() => _hasDangerousEvents = true); // Mark as dangerous
        _tripEvents.add(
          "${DateTime.now().toIso8601String()}: ⚠️ تم اكتشاف نوم السائق!",
        );
      }
      if (widget.status != oldWidget.status && widget.status == "DROWSY") {
        setState(() => _hasDangerousEvents = true); // Mark as dangerous
        _tripEvents.add(
          "${DateTime.now().toIso8601String()}: 😴 تم اكتشاف نعاس",
        );
      }
    }
  }

  String _getLocalizedStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AWAKE':
        return 'يقظ';
      case 'DROWSY':
        return 'نعسان';
      case 'DISTRACTED':
        return 'مشتت';
      case 'ASLEEP':
        return 'نائم';
      case 'IDLE':
        return 'متوقف';
      default:
        return status;
    }
  }

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
                      hintText: "ابحث عن مكان",
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

    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labeledActionButton(
                context,
                label: "رسالة طوارئ",
                icon: Icons.warning_amber_rounded,
                iconColor: const Color.fromARGB(255, 253, 20, 3),
                bgColor: Colors.red.withOpacity(0.1),
                onTap: _triggerSOSManual,
              ),
              if (!_tripSessionActive)
                _labeledActionButton(
                  context,
                  label: "بدء الرحلة",
                  icon: Icons.play_arrow_outlined,
                  iconColor: const Color.fromARGB(255, 2, 249, 11),
                  bgColor: Colors.green.withOpacity(0.1),
                  onTap: _startTrip,
                )
              else ...[
                _labeledActionButton(
                  context,
                  label: widget.isMonitoring ? "توقف" : "استئناف",
                  icon: widget.isMonitoring
                      ? Icons.pause_outlined
                      : Icons.play_arrow_outlined,
                  iconColor: const Color.fromARGB(255, 245, 122, 40),
                  bgColor: Colors.orange.withOpacity(0.1),
                  onTap: widget.onToggleMonitoring,
                ),
                _labeledActionButton(
                  context,
                  label: "إنهاء الرحلة",
                  icon: Icons.stop,
                  iconColor: Colors.red,
                  bgColor: Colors.red.withOpacity(0.1),
                  onTap: _endTrip,
                ),
              ],
              _labeledActionButton(
                context,
                label: widget.currentCameraName,
                icon: Icons.cameraswitch_outlined,
                iconColor: theme.primaryColor,
                bgColor: theme.cardColor,
                onTap: widget.onSwitchCamera,
                hasBorder: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                "حالة السائق",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.isMonitoring
                                    ? _getLocalizedStatus(widget.status)
                                    : "غير نشط",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.isMonitoring)
                                FadeTransition(
                                  opacity: _pulseAnimation,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.greenAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        "المراقبة مفعلة",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
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
                                "مستوى اليقظة",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
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
                            "تنبيه: يبدو أنك تشعر بالنعاس. يرجى التوقف وأخذ قسط من الراحة.",
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
                          onTap: (tapPosition, point) {
                            _navigateToDestination(point);
                          },
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
                      if (_destination != null)
                        Positioned(
                          top: 60,
                          right: 10,
                          child: FloatingActionButton.small(
                            heroTag: "cancel",
                            backgroundColor: Colors.redAccent,
                            child: const Icon(Icons.close, color: Colors.white),
                            onPressed: _clearNavigation,
                          ),
                        ),
                      if (_isRouteLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.timer_outlined,
                        "المدة",
                        _formatTime(_tripDurationSeconds),
                        context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        Icons.near_me_outlined,
                        "المسافة",
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
                      child: _statCard(
                        Icons.speed,
                        "السرعة",
                        "${_currentSpeed.toStringAsFixed(0)} كم/س",
                        context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        Icons.trending_up,
                        "الوصول",
                        _etaDisplay,
                        context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    bool hasBorder = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: hasBorder
                ? Border.all(color: Theme.of(context).dividerColor)
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 32),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (widget.drowsinessLevel < 30) return Colors.green;
    if (widget.drowsinessLevel < 60) return Colors.amber;
    return Colors.red;
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

  @override
  void dispose() {
    _tripTimer?.cancel();
    _pulseController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
