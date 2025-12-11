import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../services/location_sms_service.dart';

// ✅ This widget contains the UI + Map Logic only
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
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isRouteLoading = false;
  String _tripDistanceDisplay = "0 m";
  bool _isAutoFollowing = true;
  int _tripDurationSeconds = 0;
  Timer? _tripTimer;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _startTripTimer();
    _startLiveLocationUpdates();
  }

  void _startTripTimer() {
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.isMonitoring && mounted) setState(() => _tripDurationSeconds++);
    });
  }

  Future<void> _startLiveLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    await Permission.location.request();

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        )
    ).listen((Position position) {
      if (!mounted) return;
      final newLatLong = LatLng(position.latitude, position.longitude);

      String newDist = _tripDistanceDisplay;
      if (_destination != null) {
        double meters = _distanceCalculator.as(LengthUnit.Meter, newLatLong, _destination!);
        newDist = meters < 1000 ? "${meters.toInt()} m" : "${(meters / 1000).toStringAsFixed(1)} km";
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
    int closestIndex = -1;
    double minDistance = double.infinity;
    int checkLimit = _routePoints.length < 20 ? _routePoints.length : 20;

    for (int i = 0; i < checkLimit; i++) {
      double dist = _distanceCalculator.as(LengthUnit.Meter, carPos, _routePoints[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    if (closestIndex > 0) {
      _routePoints.removeRange(0, closestIndex);
      if (_routePoints.isNotEmpty) _routePoints[0] = carPos;
    }
  }

  void _openSearchSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2937),
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Where to?",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
                          onPressed: () => _performSearch(_searchController.text, setModalState),
                        )
                    ),
                    onSubmitted: (val) => _performSearch(val, setModalState),
                  ),
                  const SizedBox(height: 10),
                  if (_isSearching) const LinearProgressIndicator(color: Colors.blueAccent),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result['display_name'].split(',')[0], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(result['display_name'], maxLines: 1, style: const TextStyle(color: Colors.grey)),
                          onTap: () {
                            double lat = double.parse(result['lat']);
                            double lon = double.parse(result['lon']);
                            Navigator.pop(context);
                            _navigateToDestination(LatLng(lat, lon));
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          });
        }
    );
  }

  Future<void> _performSearch(String query, StateSetter setModalState) async {
    if (query.isEmpty) return;
    setModalState(() => _isSearching = true);
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
      final response = await http.get(url, headers: {'User-Agent': 'com.example.yaqdah_app'});
      if (response.statusCode == 200) {
        setModalState(() {
          _searchResults = json.decode(response.body);
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

    // Fetch Route Logic (Simplified)
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${_currentLocation.longitude},${_currentLocation.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          _isRouteLoading = false;
        });
      }
    } catch(e) {
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
      _isAutoFollowing = true;
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    if (widget.drowsinessLevel < 30) return Colors.green;
    if (widget.drowsinessLevel < 60) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("Stay safe on your journey", style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  _iconBtn(widget.showCameraFeed ? Icons.videocam_off : Icons.videocam, widget.onToggleCamera),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.cameraswitch, widget.onSwitchCamera),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.status == "ASLEEP" ? [Colors.red.shade900, Colors.red.shade800] : [const Color(0xFF1E293B), const Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.remove_red_eye, color: Colors.white)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Driver Status", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(widget.isMonitoring ? widget.status : "Paused", style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold))]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${widget.drowsinessLevel.toInt()}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const Text("Alertness", style: TextStyle(color: Colors.grey, fontSize: 10))])
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: widget.drowsinessLevel / 100, minHeight: 8, color: statusColor, backgroundColor: Colors.grey[800])),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.drowsinessLevel > 50)
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withOpacity(0.3))),
                child: Row(children: const [Icon(Icons.warning, color: Colors.red, size: 30), SizedBox(width: 12), Expanded(child: Text("Drowsiness Detected! Please rest.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))])
            ),

          const SizedBox(height: 16),

          // Stats
          Row(

            children: [
              Expanded(child: _statCard(Icons.timer_outlined, "Duration", _formatTime(_tripDurationSeconds))),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.near_me_outlined, "Distance", _tripDistanceDisplay)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.speed, "Avg Speed", "68 km/h")),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.trending_up, "ETA", "2h 35m")),
            ],

          ),

          const SizedBox(height: 20),

          // Map
          Container(
            height: 350,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2))),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _currentLocation, initialZoom: 18.0, onPositionChanged: (p, g) { if(g) setState(()=> _isAutoFollowing=false); }),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.yaqdah_app'),
                    PolylineLayer(polylines: [if (_routePoints.isNotEmpty) Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent)]),
                    MarkerLayer(markers: [
                      Marker(point: _currentLocation, width: 50, height: 50, child: Transform.rotate(angle: _currentHeading * (math.pi / 180), child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 40))),
                      if (_destination != null) Marker(point: _destination!, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                    ]),
                  ],
                ),
                Positioned(top: 10, left: 10, child: FloatingActionButton.small(heroTag: "search", backgroundColor: Colors.blueAccent, child: const Icon(Icons.search, color: Colors.white), onPressed: _openSearchSheet)),
                Positioned(top: 10, right: 10, child: FloatingActionButton.small(heroTag: "recenter", backgroundColor: _isAutoFollowing ? Colors.blueAccent : Colors.grey, child: Icon(Icons.my_location, color: _isAutoFollowing ? Colors.white : Colors.black), onPressed: _recenterMap)),
                if (_destination != null) Positioned(top: 10, right: 60, child: FloatingActionButton.small(heroTag: "cancel", backgroundColor: Colors.redAccent, child: const Icon(Icons.close, color: Colors.white), onPressed: _clearNavigation)),
                if (_isRouteLoading) const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () {
            if (widget.isMonitoring) {
              // SAVE TO DB LOGIC
              // NOTE: Passed trip data via callback usually, but for simplicity here:
              DatabaseService.instance.saveTrip(_formatTime(_tripDurationSeconds), _tripDistanceDisplay, widget.drowsinessLevel > 50 ? "Drowsy" : "Safe Trip");
            }
            widget.onToggleMonitoring();
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.isMonitoring ? Colors.red[900] : Colors.green[800], padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: Icon(widget.isMonitoring ? Icons.stop_circle : Icons.play_arrow),
          label: Text(widget.isMonitoring ? "End Trip" : "Start Trip"),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _smsService.sendEmergencyAlert(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: const Icon(Icons.emergency),
          label: const Text("SOS"),
        )),
      ],
    );
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }
}