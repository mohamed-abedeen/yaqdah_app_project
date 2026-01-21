import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'rest_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../widgets/camera_feed.dart';
import '../widgets/dashboard_ui.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';
import '../services/location_sms_service.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic> _currentUser = {};

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseService.instance.getUserByEmail(email);
      if (user != null) {
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isAuthenticated = true;
          });
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _login(Map<String, dynamic> user) async {
    setState(() {
      _isAuthenticated = true;
      _currentUser = user;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    setState(() {
      _isAuthenticated = false;
      _currentUser = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isAuthenticated
        ? MainLayout(
            cameras: widget.cameras,
            onLogout: _logout,
            currentUser: _currentUser,
          )
        : LoginScreen(onLogin: _login);
  }
}

class MainLayout extends StatefulWidget {
  final List<CameraDescription> cameras;
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUser;

  const MainLayout({
    super.key,
    required this.cameras,
    required this.onLogout,
    required this.currentUser,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<CameraFeedState> _cameraKey = GlobalKey();
  final GlobalKey<DashboardUIState> _dashboardKey = GlobalKey();

  LatLng? _currentLocation;
  bool _isMonitoring = false;
  String _status = "IDLE";
  double _drowsinessLevel = 0.0;
  String _aiMessage = "Press Start";
  bool _isListening = false;
  String _currentCameraName = "Camera";

  final AudioService _audio = AudioService();
  final GeminiService _gemini = GeminiService();
  final LocationSmsService _smsService = LocationSmsService();

  // Timers to prevent audio spam
  DateTime _lastAiTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );
  DateTime _lastBeepTrigger = DateTime.now().subtract(
    const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    _audio.init();
    if (widget.cameras.isNotEmpty) _updateCameraName(0);
  }

  void _updateCameraName(int index) {
    if (widget.cameras.isEmpty) return;
    final cam = widget.cameras[index];
    setState(() {
      if (cam.lensDirection == CameraLensDirection.front) {
        _currentCameraName = "Front Cam";
      } else if (cam.lensDirection == CameraLensDirection.back) {
        _currentCameraName = "Back Cam ${index + 1}";
      } else {
        _currentCameraName = "Ext Cam";
      }
    });
  }

  void _handleStatusChange(String newStatus) {
    if (!mounted) return;

    // Logic is executed regardless of UI updates
    switch (newStatus) {
      case "AWAKE":
        // Only stop audio if we were previously in danger/drowsy to avoid cutting off normal speech
        if (_status == "ASLEEP" || _status == "DROWSY") {
          _audio.stopAll();
        }
        break;
      case "DISTRACTED":
        _triggerGemini("DISTRACTED");
        break;
      case "DROWSY":
        _triggerBeep(); // ✅ Trigger the Beep
        _triggerGemini("DROWSY");
        break;
      case "ASLEEP":
        _triggerSOS();
        break;
    }

    setState(() {
      _status = newStatus;
      switch (newStatus) {
        case "AWAKE":
          _drowsinessLevel = 0;
          break;
        case "DISTRACTED":
          _drowsinessLevel = 45;
          break;
        case "DROWSY":
          _drowsinessLevel = 75;
          break;
        case "ASLEEP":
          _drowsinessLevel = 100;
          break;
      }
    });
  }

  // ✅ NEW: Triggers a short warning beep every 3 seconds
  void _triggerBeep() async {
    if (DateTime.now().difference(_lastBeepTrigger).inSeconds < 3) return;
    _lastBeepTrigger = DateTime.now();
    await _audio.playBeep();
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
  }

  void _toggleListening() async {
    if (_isListening) {
      await _audio.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _audio.listen((text) async {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _aiMessage = "Analyzing...";
        });
        String reply = await _gemini.chatWithDriver(text);
        await _audio.speak(reply);
      });
    }
  }

  void _handlePlaceSelected(LatLng destination) {
    setState(() => _currentIndex = 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      _dashboardKey.currentState?.startNavigation(destination);
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      Stack(
        children: [
          Offstage(
            offstage: true,
            child: CameraFeed(
              key: _cameraKey,
              cameras: widget.cameras,
              isMonitoring: _isMonitoring,
              showFeed: true,
              onStatusChange: _handleStatusChange,
              onCameraChanged: _updateCameraName,
            ),
          ),
          DashboardUI(
            key: _dashboardKey,
            onLocationUpdate: (loc) => _currentLocation = loc,
            isMonitoring: _isMonitoring,
            status: _status,
            drowsinessLevel: _drowsinessLevel,
            aiMessage: _aiMessage,
            isListening: _isListening,
            onToggleMonitoring: () =>
                setState(() => _isMonitoring = !_isMonitoring),
            onMicToggle: _toggleListening,
            currentCameraName: _currentCameraName,
            onSwitchCamera: () => _cameraKey.currentState?.switchCamera(),
          ),
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: "mic",
              backgroundColor: _isListening ? Colors.red : theme.primaryColor,
              onPressed: _toggleListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          ),
        ],
      ),
      const ReportsScreen(),
      // ✅ UPDATED: Passing the value directly
      RestScreen(
        onPlaceSelected: _handlePlaceSelected,
        currentLocation: _currentLocation ?? const LatLng(32.8872, 13.1913),
      ),
      SettingsScreen(
        onLogout: widget.onLogout,
        currentUser: widget.currentUser,
      ),
    ];

    final navBarColor = theme.cardColor.withOpacity(isDark ? 0.8 : 0.95);
    final navBarBorder = theme.dividerColor;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
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
              decoration: BoxDecoration(
                color: navBarColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: navBarBorder),
              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 1. Define Selected Color (Changes based on Theme)
    final Color selectedColor = isDark
        ? const Color.fromARGB(
            255,
            242,
            216,
            76,
          ) // Yellow/Gold for Dark Mode (Pop color)
        : const Color.fromRGBO(91, 46, 235, 1); // Purple for Light Mode

    // ✅ 2. Define Unselected Color
    final Color unselectedColor = isDark
        ? const Color.fromRGBO(237, 170, 62, 1) // Muted Orange for Dark Mode
        : const Color.fromRGBO(52, 19, 163, 1); // Purple for Light Mode

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Background bubble color
          color: isSelected
              ? selectedColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: selectedColor, // Text matches icon color
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
