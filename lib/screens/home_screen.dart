import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/monitoring_provider.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_icon.dart';
import 'rest_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

import '../services/connectivity_service.dart';
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
  static const _driveTab = 0;
  static const _reportsTab = 1;
  static const _restTab = 2;
  static const _accountTab = 3;

  int _currentIndex = _driveTab;

  /// Tabs are built the first time they're opened, so e.g. the Rest tab
  /// doesn't search for places at launch.
  final Set<int> _openedTabs = {_driveTab};
  final GlobalKey<CameraFeedState> _cameraKey = GlobalKey();
  final GlobalKey<DashboardUIState> _dashboardKey = GlobalKey();

  final ValueNotifier<CameraController?> _cameraController = ValueNotifier(
    null,
  );
  final ValueNotifier<bool?> _faceVisible = ValueNotifier(null);
  CameraLensDirection? _lensDirection;
  bool _isCameraReady = false;

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

  @override
  void dispose() {
    _cameraController.dispose();
    _faceVisible.dispose();
    super.dispose();
  }

  void _updateCameraName(int index) {
    if (widget.cameras.isEmpty) return;
    _faceVisible.value = null;
    setState(() => _lensDirection = widget.cameras[index].lensDirection);
  }

  void _handlePlaceSelected(LatLng destination, String name) {
    _selectTab(_driveTab);
    Future.delayed(const Duration(milliseconds: 100), () {
      _dashboardKey.currentState?.startNavigation(destination, name: name);
    });
  }

  void _selectTab(int index) {
    // Reports reads from the database; refresh it when it comes back into
    // view (the first time, it loads as it's built).
    if (index == _reportsTab &&
        _currentIndex != _reportsTab &&
        _openedTabs.contains(_reportsTab)) {
      DatabaseService.instance.notifyTripsChanged();
    }
    setState(() {
      _currentIndex = index;
      _openedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMonitoring = context.select<MonitoringProvider, bool>(
      (m) => m.isMonitoring,
    );
    final authProvider = Provider.of<AuthProvider>(context);
    final onDriveTab = _currentIndex == _driveTab;

    final List<Widget> screens = [
      Stack(
        children: [
          if (_isCameraReady)
            CameraFeed(
              key: _cameraKey,
              cameras: widget.cameras,
              // The camera only runs for a trip or the readiness check.
              enabled: isMonitoring || onDriveTab,
              // The preview thumbnail is only shown before a trip.
              showPreview: !isMonitoring && onDriveTab,
              isMonitoring: isMonitoring,
              detectPresence: !isMonitoring && onDriveTab,
              onStatusChange: (status, metrics) => context
                  .read<MonitoringProvider>()
                  .handleStatusChange(status, metrics),
              onCameraChanged: _updateCameraName,
              onControllerChanged: (c) {
                _cameraController.value = c;
                if (c == null) _faceVisible.value = null;
              },
              onFacePresenceChanged: (visible) => _faceVisible.value = visible,
            ),
          DashboardUI(
            key: _dashboardKey,
            onSwitchCamera: () => _cameraKey.currentState?.switchCamera(),
            hasCamera: widget.cameras.isNotEmpty,
            lensDirection: _lensDirection,
            cameraController: _cameraController,
            faceVisible: _faceVisible,
            onOpenAccount: () => _selectTab(_accountTab),
          ),
        ],
      ),
      if (_openedTabs.contains(_reportsTab))
        const ReportsScreen()
      else
        const SizedBox.shrink(),
      if (_openedTabs.contains(_restTab))
        RestScreen(
          onPlaceSelected: _handlePlaceSelected,
          active: _currentIndex == _restTab,
        )
      else
        const SizedBox.shrink(),
      if (_openedTabs.contains(_accountTab))
        SettingsScreen(
          onLogout: authProvider.logout,
          currentUser: authProvider.currentUser,
        )
      else
        const SizedBox.shrink(),
    ];

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: ConnectivityService.instance.isConnectedNotifier,
        builder: (context, isConnected, child) {
          return Column(
            children: [
              if (!isConnected) _OfflineBanner(label: l10n.offlineBanner),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: !isConnected,
                  child: IndexedStack(index: _currentIndex, children: screens),
                ),
              ),
            ],
          );
        },
      ),
      // The nav slides away while a trip is running.
      bottomNavigationBar: TweenAnimationBuilder<double>(
        tween: Tween(end: isMonitoring ? 0 : 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, visible, child) => ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: visible,
            child: child,
          ),
        ),
        child: _BottomNav(
          currentIndex: _currentIndex,
          onSelect: _selectTab,
          items: [
            _NavItem(Symbols.directions_car_rounded, l10n.navDrive),
            _NavItem(Symbols.insights_rounded, l10n.navReports),
            _NavItem(Symbols.local_cafe_rounded, l10n.navRest),
            _NavItem(Symbols.person_rounded, l10n.navAccount),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Flush bottom bar; labels always visible.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onSelect,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        10,
        8,
        bottomInset > 0 ? bottomInset : 12,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavButton(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.primary : c.subtext;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? c.primarySoft
                    : c.primarySoft.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppIcon(
                item.icon,
                size: 24,
                color: color,
                filled: selected,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                context,
                12,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ColoredBox(
      color: c.danger,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(
                Symbols.wifi_off_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    context,
                    13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
