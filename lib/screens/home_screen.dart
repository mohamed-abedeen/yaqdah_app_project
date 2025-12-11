import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // For BackdropFilter

// ✅ IMPORTS
import 'rest_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../widgets/camera_feed.dart'; // ✅ NEW
import '../widgets/dashboard_ui.dart'; // ✅ NEW
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';
import '../services/location_sms_service.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
// ==========================================
// 1. ROOT WIDGET
// ==========================================
class YaqdahApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const YaqdahApp({super.key, required this.cameras});

  @override
  State<YaqdahApp> createState() => _YaqdahAppState();
}

class _YaqdahAppState extends State<YaqdahApp> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic> _currentUser = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseService.instance.getUserByEmail(email);
      if (user != null) {
        setState(() { _currentUser = user; _isAuthenticated = true; });
      }
    }
    setState(() => _isLoading = false);
  }

  void _login(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user['email']);
    setState(() { _isAuthenticated = true; _currentUser = user; });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    setState(() { _isAuthenticated = false; _currentUser = {}; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF2563EB),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF2563EB), surface: Color(0xFF1E293B)),
      ),
      home: _isAuthenticated
          ? MainLayout(cameras: widget.cameras, onLogout: _logout, currentUser: _currentUser)
          : LoginScreen(onLogin: _login),
    );
  }
}

// ==========================================
// 2. MAIN LAYOUT
// ==========================================
class MainLayout extends StatefulWidget {
  final List<CameraDescription> cameras;
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUser;

  const MainLayout({super.key, required this.cameras, required this.onLogout, required this.currentUser});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<CameraFeedState> _cameraKey = GlobalKey(); // To switch cameras

  // Logic State
  LatLng? _currentLocation;
  bool _isMonitoring = false;
  bool _showCameraFeed = false;
  String _status = "IDLE";
  double _drowsinessLevel = 0.0;
  String _aiMessage = "Press Start";
  bool _isListening = false;

  final AudioService _audio = AudioService();
  final GeminiService _gemini = GeminiService();
  final LocationSmsService _smsService = LocationSmsService();
  DateTime _lastAiTrigger = DateTime.now();

  @override
  void initState() {
    super.initState();
    _audio.init();
  }

  // --- LOGIC HANDLERS ---
  void _handleStatusChange(String newStatus) {
    if (!mounted) return;
    setState(() {
      _status = newStatus;
      switch (newStatus) {
        case "AWAKE": _drowsinessLevel = 15; _audio.stopAll(); break;
        case "DISTRACTED": _drowsinessLevel = 45; _triggerGemini("DISTRACTED"); break;
        case "DROWSY": _drowsinessLevel = 75; _triggerGemini("DROWSY"); break;
        case "ASLEEP": _drowsinessLevel = 95; _triggerSOS(); break;
      }
    });
  }

  void _triggerGemini(String state) async {
    if (DateTime.now().difference(_lastAiTrigger).inSeconds < 5) return;
    _lastAiTrigger = DateTime.now();
    String msg = await _gemini.getIntervention(state);
    if (mounted) setState(() => _aiMessage = msg);
    await _audio.speak(msg);
  }

  void _triggerSOS() async {
    await _audio.playAlarm();
    _smsService.sendEmergencyAlert();
    String msg = await _gemini.getIntervention("ASLEEP");
    await _audio.speak(msg);
  }

  void _toggleListening() async {
    if (_isListening) {
      await _audio.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _audio.listen((text) async {
        if (!mounted) return;
        setState(() { _isListening = false; _aiMessage = "Analyzing..."; });
        String reply = await _gemini.chatWithDriver(text);
        await _audio.speak(reply);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screens List
    final List<Widget> screens = [
      Stack(
        children: [
          // 1. Camera Feed (Background)
          CameraFeed(
            key: _cameraKey,
            cameras: widget.cameras,
            isMonitoring: _isMonitoring,
            showFeed: _showCameraFeed,
            onStatusChange: _handleStatusChange,
          ),
          // 2. Dashboard UI (Foreground)
          DashboardUI(
            onLocationUpdate: (loc) => _currentLocation = loc,
            isMonitoring: _isMonitoring,
            status: _status,
            drowsinessLevel: _drowsinessLevel,
            aiMessage: _aiMessage,
            showCameraFeed: _showCameraFeed,
            isListening: _isListening,
            onToggleMonitoring: () => setState(() => _isMonitoring = !_isMonitoring),
            onToggleCamera: () => setState(() => _showCameraFeed = !_showCameraFeed),
            onSwitchCamera: () => _cameraKey.currentState?.switchCamera(),
            onMicToggle: _toggleListening,
          ),
          // 3. Mic Button Overlay
          Positioned(
            bottom: 110, right: 20,
            child: FloatingActionButton(
              heroTag: "mic",
              backgroundColor: _isListening ? Colors.red : Colors.blueAccent,
              onPressed: _toggleListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          ),
        ],
      ),
      const ReportsScreen(),
      RestScreen(
        onPlaceSelected: (dest) { /* Handle Nav */ }, // Simplified for brevity
        getCurrentLocation: () => _currentLocation ?? const LatLng(32.8872, 13.1913),
      ),
      SettingsScreen(onLogout: widget.onLogout, currentUser: widget.currentUser),
    ];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_rounded, "Home", 0),
                  _navItem(Icons.description_outlined, "Reports", 1),
                  _navItem(Icons.coffee_outlined, "Rest", 2),
                  _navItem(Icons.person_outline, "Account", 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? const Color(0xFF60A5FA) : Colors.grey, size: 24),
          if (isSelected) Text(label, style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}