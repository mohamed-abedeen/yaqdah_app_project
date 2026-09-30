import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'sync_service.dart';
import '../services/auth_service.dart';

/// Monitors network connectivity and triggers sync when connection is restored.
///
/// Uses a simple periodic check to detect connectivity changes.
/// When connectivity is restored after being offline, it triggers a full sync.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _wasOffline = false;
  bool _isMonitoring = false;

  /// Whether the device currently has internet connectivity.
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Reactive notifier — listen to this in the UI for an offline banner.
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(true);

  /// Start monitoring connectivity.
  /// Should be called once on app start.
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // No polling while the app is in the background; check on return.
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) {
        if (!_isMonitoring) return;
        if (state == AppLifecycleState.resumed) {
          _checkConnectivity();
          _startTimer();
        } else if (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) {
          _timer?.cancel();
          _timer = null;
        }
      },
    );
    _startTimer();

    // Initial check
    _checkConnectivity();
  }

  void _startTimer() {
    _timer?.cancel();
    // Check connectivity every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  /// Stop monitoring connectivity.
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
  }

  /// Check if we can reach the internet.
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isConnected = true;
        isConnectedNotifier.value = true;

        // If we were previously offline — trigger sync
        if (_wasOffline) {
          _wasOffline = false;
          _onConnectivityRestored();
        }
      } else {
        _isConnected = false;
        isConnectedNotifier.value = false;
        _wasOffline = true;
      }
    } catch (_) {
      _isConnected = false;
      isConnectedNotifier.value = false;
      _wasOffline = true;
    }
  }

  /// Called when connectivity is restored after being offline.
  void _onConnectivityRestored() {
    final uid = AuthService.instance.uid;
    if (uid != null) {
      if (kDebugMode) {
        debugPrint('🌐 Connectivity restored — syncing trips...');
      }
      SyncService.instance.syncAll(uid);
    }
  }
}
