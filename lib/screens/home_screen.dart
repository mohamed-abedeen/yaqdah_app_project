// ignore_for_file: deprecated_member_use

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/location_provider.dart';
import 'rest_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../widgets/camera_feed.dart';
import '../widgets/dashboard_ui.dart';

import 'onboarding_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.hasSeenOnboarding) {
          return const OnboardingScreen();
        }

        return auth.isAuthenticated
            ? MainLayout(cameras: cameras)
            : LoginScreen(onLogin: auth.login);
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainLayout({super.key, required this.cameras});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<CameraFeedState> _cameraKey = GlobalKey();
  final GlobalKey<DashboardUIState> _dashboardKey = GlobalKey();

  String _currentCameraName = "Camera";
  bool _isCameraReady = false;

  // Draggable Mic Position
  double _micLeft = 20.0;
  double _micTop = 500.0;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) _updateCameraName(0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isCameraReady = true);
    });

    // Set emergency contact in MonitoringProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authFn = Provider.of<AuthProvider>(context, listen: false);
      final monitorFn = Provider.of<MonitoringProvider>(context, listen: false);
      monitorFn.setEmergencyContact(
        authFn.currentUser['emergencyContact'] ?? "",
      );
    });
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

  void _handlePlaceSelected(LatLng destination) {
    setState(() => _currentIndex = 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      _dashboardKey.currentState?.startNavigation(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    final List<Widget> screens = [
      Stack(
        children: [
          if (_isCameraReady)
            Offstage(
              offstage: true,
              child: CameraFeed(
                key: _cameraKey,
                cameras: widget.cameras,
                isMonitoring: monitoringProvider.isMonitoring,
                showFeed: true,
                onStatusChange: monitoringProvider.handleStatusChange,
                onCameraChanged: _updateCameraName,
              ),
            ),
          DashboardUI(
            key: _dashboardKey,
            onSwitchCamera: () => _cameraKey.currentState?.switchCamera(),
            currentCameraName: _currentCameraName,
          ),
          Positioned(
            left: _micLeft,
            top: _micTop,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _micLeft += details.delta.dx;
                  _micTop += details.delta.dy;
                });
              },
              child: FloatingActionButton(
                heroTag: "mic",
                backgroundColor: monitoringProvider.isListening
                    ? Colors.red
                    : theme.primaryColor,
                onPressed: monitoringProvider.toggleListening,
                child: Icon(
                  monitoringProvider.isListening ? Icons.mic_off : Icons.mic,
                ),
              ),
            ),
          ),
        ],
      ),
      const ReportsScreen(),
      RestScreen(
        onPlaceSelected: _handlePlaceSelected,
        currentLocation: locationProvider.currentLocation,
      ),
      SettingsScreen(
        onLogout: authProvider.logout,
        currentUser: authProvider.currentUser,
        onUpdateUser: authProvider.updateUser,
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

    final Color selectedColor = isDark
        ? const Color.fromARGB(255, 242, 216, 76)
        : const Color.fromRGBO(91, 46, 235, 1);

    final Color unselectedColor = isDark
        ? const Color.fromRGBO(237, 170, 62, 1)
        : const Color.fromRGBO(52, 19, 163, 1);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
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
                  color: selectedColor,
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
