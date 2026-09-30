import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// One status scale everywhere: ok = awake, warn = drowsy / distracted /
/// no face, danger = asleep.
enum DriverStatus {
  awake,
  drowsy,
  distracted,
  noFace,
  danger;

  /// Maps `MonitoringProvider.status` strings.
  static DriverStatus fromMonitor(String status) {
    switch (status) {
      case "ASLEEP":
        return DriverStatus.danger;
      case "DROWSY":
        return DriverStatus.drowsy;
      case "DISTRACTED":
        return DriverStatus.distracted;
      case "NO_FACE":
        return DriverStatus.noFace;
      default: // AWAKE, SAFE, IDLE
        return DriverStatus.awake;
    }
  }

  Color color(AppColors c) => switch (this) {
    DriverStatus.awake => c.ok,
    DriverStatus.danger => c.danger,
    _ => c.warn,
  };

  Color softColor(AppColors c) => switch (this) {
    DriverStatus.awake => c.okSoft,
    DriverStatus.danger => c.dangerSoft,
    _ => c.warnSoft,
  };

  String label(AppLocalizations l10n) => switch (this) {
    DriverStatus.awake => l10n.statusAwake,
    DriverStatus.drowsy => l10n.statusDrowsy,
    DriverStatus.distracted => l10n.statusDistracted,
    DriverStatus.noFace => l10n.statusNoFace,
    DriverStatus.danger => l10n.statusDanger,
  };
}
