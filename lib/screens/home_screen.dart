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

class Homescreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Homescreen({super.key, required this.cameras});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic> _currentUser = {};

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await ThemeService.instance.init();
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
    // Only set state here; persistence handled in LoginScreen if needed
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
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yaqdah',
          theme: ThemeService.instance.lightTheme,
          darkTheme: ThemeService.instance.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: _isAuthenticated
              ? MainLayout(
                  cameras: widget.cameras,
                  onLogout: _logout,
                  currentUser: _currentUser,
                )
              : LoginScreen(onLogin: _login),
        );
      },
    );
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

  // Logic State
  LatLng? _currentLocation;
  bool _isMonitoring = false;
  bool _showCameraFeed = false;
  String _status = "IDLE";
  double _drowsinessLevel = 0.0;
  String _aiMessage = "Press Start";
  bool _isListening = false;

  // ✅ NEW: Camera Name State
  String _currentCameraName = "Camera";

  final AudioService _audio = AudioService();
  final GeminiService _gemini = GeminiService();
  final LocationSmsService _smsService = LocationSmsService();
  DateTime _lastAiTrigger = DateTime.now();

  @override
  void initState() {
    super.initState();
    _audio.init();
    // Initialize label
    if (widget.cameras.isNotEmpty) _updateCameraName(0);
  }

  // ✅ HELPER: Generate Camera Name
  void _updateCameraName(int index) {
    if (widget.cameras.isEmpty) return;
    final cam = widget.cameras[index];
    setState(() {
      if (cam.lensDirection == CameraLensDirection.front) {
        _currentCameraName = "Front Cam";
      } else if (cam.lensDirection == CameraLensDirection.back) {
        // Distinguish multiple back cameras if present
        _currentCameraName = "Back Cam ${index + 1}";
      } else {
        _currentCameraName = "Ext Cam";
      }
    });
  }

  void _handleStatusChange(String newStatus) {
    if (!mounted) return;
    setState(() {
      _status = newStatus;
      switch (newStatus) {
        case "AWAKE":
          _drowsinessLevel = 15;
          _audio.stopAll();
          break;
        case "DISTRACTED":
          _drowsinessLevel = 45;
          _triggerGemini("DISTRACTED");
          break;
        case "DROWSY":
          _drowsinessLevel = 75;
          _triggerGemini("DROWSY");
          break;
        case "ASLEEP":
          _drowsinessLevel = 95;
          _triggerSOS();
          break;
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
        setState(() {
          _isListening = false;
          _aiMessage = "Analyzing...";
        });
        String reply = await _gemini.chatWithDriver(text);
        await _audio.speak(reply);
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      Stack(
        children: [
          CameraFeed(
            key: _cameraKey,
            cameras: widget.cameras,
            isMonitoring: _isMonitoring,
            showFeed: _showCameraFeed,
            onStatusChange: _handleStatusChange,
            // ✅ LINKED: Notify home screen when camera changes
            onCameraChanged: _updateCameraName,
          ),
          DashboardUI(
            onLocationUpdate: (loc) => _currentLocation = loc,
            isMonitoring: _isMonitoring,
            status: _status,
            drowsinessLevel: _drowsinessLevel,
            aiMessage: _aiMessage,
            showCameraFeed: _showCameraFeed,
            isListening: _isListening,
            // ✅ LINKED: Pass label to Dashboard
            currentCameraName: _currentCameraName,

            onToggleMonitoring: () =>
                setState(() => _isMonitoring = !_isMonitoring),
            onToggleCamera: () =>
                setState(() => _showCameraFeed = !_showCameraFeed),
            onSwitchCamera: () => _cameraKey.currentState?.switchCamera(),
            onMicToggle: _toggleListening,
          ),
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: "mic",
              backgroundColor: _isListening
                  ? Colors.red
                  : Theme.of(context).primaryColor,
              onPressed: _toggleListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          ),
        ],
      ),
      const ReportsScreen(),
      RestScreen(
        onPlaceSelected: (dest) {},
        getCurrentLocation: () =>
            _currentLocation ?? const LatLng(32.8872, 13.1913),
      ),
      SettingsScreen(
        onLogout: widget.onLogout,
        currentUser: widget.currentUser,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final navBarBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF172554),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFF1F5F9),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
              decoration: BoxDecoration(
                color: navBarColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: navBarBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_rounded, "Home", 0),
                  _navItem(Icons.coffee_outlined, "Rest", 1),
                  _navItem(Icons.description_outlined, "Reports", 2),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.grey : Colors.grey[400]),
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
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
