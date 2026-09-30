import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/trip_records.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_button.dart';
import '../common/app_icon.dart';
import '../common/brand.dart';
import 'drive_buttons.dart';

/// What the readiness card knows about the setup.
class ReadinessState {
  const ReadinessState({
    required this.hasCamera,
    required this.lensDirection,
    required this.faceVisible,
    required this.hasGpsFix,
    required this.gpsAccuracy,
    this.gpsOff = false,
  });

  final bool hasCamera;
  final CameraLensDirection? lensDirection;

  /// null while the first check is still running.
  final bool? faceVisible;
  final bool hasGpsFix;
  final double? gpsAccuracy;

  /// Location permission or the location service is off.
  final bool gpsOff;

  bool get faceOk => faceVisible == true;
  bool get facePending => hasCamera && faceVisible == null;
  bool get allOk => hasCamera && faceOk && hasGpsFix;
  bool get anyFailing => !hasCamera || !hasGpsFix || (faceVisible == false);
}

/// Drive tab before a trip (direction 1a): readiness checklist,
/// destination field, last trip and Start trip.
class PreTripView extends StatefulWidget {
  const PreTripView({
    super.key,
    required this.userName,
    required this.readiness,
    required this.cameraController,
    required this.destinationName,
    required this.destinationEta,
    required this.lastTrip,
    required this.isListening,
    required this.onSwitchCamera,
    required this.onOpenSearch,
    required this.onClearDestination,
    required this.onStartTrip,
    required this.onMicTap,
    required this.onAvatarTap,
  });

  final String userName;
  final ReadinessState readiness;
  final ValueListenable<CameraController?> cameraController;

  /// Set when a destination was picked before the trip.
  final String? destinationName;
  final String? destinationEta;
  final Future<Map<String, dynamic>?>? lastTrip;
  final bool isListening;
  final VoidCallback onSwitchCamera;
  final VoidCallback onOpenSearch;
  final VoidCallback onClearDestination;
  final VoidCallback onStartTrip;
  final VoidCallback onMicTap;
  final VoidCallback onAvatarTap;

  @override
  State<PreTripView> createState() => _PreTripViewState();
}

class _PreTripViewState extends State<PreTripView> {
  static const double _micSize = 56;
  static const double _edge = 20;

  /// Top-left of the mic once the driver has dragged it.
  Offset? _micPosition;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.greetingMorning;
    if (hour >= 12 && hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final firstName = widget.userName.trim().split(RegExp(r'\s+')).first;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          // Default: 20 from the end edge, just above the Start button.
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          final defaultLeft = isRtl ? _edge : width - _edge - _micSize;
          final wanted =
              _micPosition ??
              Offset(defaultLeft, height - 16 - 64 - 28 - _micSize);
          final mic = Offset(
            wanted.dx.clamp(0, width - _micSize),
            wanted.dy.clamp(0, height - _micSize),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            greeting: _greeting(l10n),
                            firstName: firstName,
                            fullName: widget.userName,
                            onAvatarTap: widget.onAvatarTap,
                          ),
                          const SizedBox(height: 16),
                          _ReadinessCard(
                            state: widget.readiness,
                            cameraController: widget.cameraController,
                            onSwitchCamera: widget.onSwitchCamera,
                          ),
                          const SizedBox(height: 16),
                          _DestinationField(
                            name: widget.destinationName,
                            eta: widget.destinationEta,
                            onTap: widget.onOpenSearch,
                            onClear: widget.onClearDestination,
                          ),
                          const SizedBox(height: 16),
                          _LastTripLine(trip: widget.lastTrip),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: AppButton(
                      label: l10n.startTrip,
                      onPressed: widget.onStartTrip,
                      leadingIcon: Symbols.play_arrow_rounded,
                      iconFilled: true,
                      iconSize: 26,
                      height: 64,
                      radius: 20,
                      fontSize: 19,
                      shadow: [
                        BoxShadow(
                          color: c.primarySoft,
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: mic.dx,
                top: mic.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final next = (_micPosition ?? mic) + details.delta;
                      _micPosition = Offset(
                        next.dx.clamp(0, width - _micSize),
                        next.dy.clamp(0, height - _micSize),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    final current = _micPosition ?? mic;
                    setState(() {
                      // Snap to the nearest side.
                      final snapLeft = current.dx + _micSize / 2 < width / 2;
                      _micPosition = Offset(
                        snapLeft ? _edge : width - _edge - _micSize,
                        current.dy,
                      );
                    });
                  },
                  child: MicButton(
                    listening: widget.isListening,
                    onTap: widget.onMicTap,
                    semanticLabel: l10n.voiceAssistant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.firstName,
    required this.fullName,
    required this.onAvatarTap,
  });

  final String greeting;
  final String firstName;
  final String fullName;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppFonts.body(
                    context,
                    15,
                    weight: FontWeight.w500,
                    color: c.subtext,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    context,
                    28,
                    color: c.text,
                    tracking: -0.02,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAvatarTap,
            child: InitialsAvatar(name: fullName, size: 46, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.state,
    required this.cameraController,
    required this.onSwitchCamera,
  });

  final ReadinessState state;
  final ValueListenable<CameraController?> cameraController;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final Widget statusLine;
    if (state.allOk) {
      statusLine = _StatusLine(
        icon: Symbols.check_circle_rounded,
        text: l10n.checksPassed,
        color: c.ok,
      );
    } else if (state.anyFailing) {
      statusLine = _StatusLine(
        icon: Symbols.error_rounded,
        text: l10n.checksAttention,
        color: c.warn,
      );
    } else {
      statusLine = _StatusLine(text: l10n.checksRunning, color: c.subtext);
    }

    final trailingStyle = AppFonts.body(
      context,
      14,
      weight: FontWeight.w600,
      color: c.subtext,
    );
    final warnStyle = trailingStyle.copyWith(color: c.warn);

    // Face
    final Widget faceTrailing;
    if (state.faceOk) {
      faceTrailing = AppIcon(
        Symbols.check_circle_rounded,
        size: 20,
        color: c.ok,
        filled: true,
      );
    } else if (state.facePending) {
      faceTrailing = Text(l10n.checkPending, style: trailingStyle);
    } else {
      faceTrailing = Text(l10n.checkFaceFix, style: warnStyle);
    }

    // Camera
    final isBack = state.lensDirection == CameraLensDirection.back;
    final cameraLabel = switch (state.lensDirection) {
      CameraLensDirection.front => l10n.cameraFront,
      CameraLensDirection.back => l10n.cameraBack,
      CameraLensDirection.external => l10n.cameraExternal,
      null => l10n.cameraGeneric,
    };
    final Widget cameraTrailing = state.hasCamera
        ? Semantics(
            button: true,
            label: l10n.checkSwitch,
            child: InkWell(
              onTap: onSwitchCamera,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      Symbols.cameraswitch_rounded,
                      size: 18,
                      color: c.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.checkSwitch,
                      style: trailingStyle.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Text(l10n.checkNoCamera, style: warnStyle);

    // GPS
    final Widget gpsTrailing;
    if (state.gpsOff) {
      gpsTrailing = Text(l10n.gpsOff, style: warnStyle);
    } else if (!state.hasGpsFix) {
      gpsTrailing = Text(l10n.gpsSearching, style: warnStyle);
    } else if ((state.gpsAccuracy ?? 0) <= 25) {
      gpsTrailing = Text(l10n.gpsStrong, style: trailingStyle);
    } else {
      gpsTrailing = Text(l10n.gpsWeak, style: trailingStyle);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CameraThumbnail(controller: cameraController),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.allOk ? l10n.readyTitle : l10n.almostReadyTitle,
                      style: AppFonts.display(
                        context,
                        24,
                        color: c.text,
                        tracking: -0.01,
                      ),
                    ),
                    const SizedBox(height: 4),
                    statusLine,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _CheckRow(
            icon: Symbols.face_rounded,
            label: l10n.checkFace,
            trailing: faceTrailing,
          ),
          _CheckRow(
            icon: isBack
                ? Symbols.photo_camera_back_rounded
                : Symbols.photo_camera_front_rounded,
            label: cameraLabel,
            trailing: cameraTrailing,
            compact: state.hasCamera,
          ),
          _CheckRow(
            icon: Symbols.my_location_rounded,
            label: l10n.checkGps,
            trailing: gpsTrailing,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({this.icon, required this.text, required this.color});

  final IconData? icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: 18, color: color, filled: true),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: AppFonts.body(
              context,
              15,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.compact = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  /// The trailing widget brings its own vertical padding (tap target).
  final bool compact;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.only(
        top: compact ? 2 : 12,
        bottom: compact ? 2 : (last ? 0 : 12),
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 22, color: c.subtext),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppFonts.body(
                context,
                16,
                weight: FontWeight.w500,
                color: c.text,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// 76×76 live camera preview.
class _CameraThumbnail extends StatelessWidget {
  const _CameraThumbnail({required this.controller});

  final ValueListenable<CameraController?> controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 76,
        height: 76,
        child: ValueListenableBuilder<CameraController?>(
          valueListenable: controller,
          builder: (context, cam, _) {
            if (cam == null || !cam.value.isInitialized) {
              return ColoredBox(
                color: c.surface2,
                child: Center(
                  child: AppIcon(
                    Symbols.videocam_rounded,
                    size: 26,
                    color: c.subtext,
                  ),
                ),
              );
            }
            final preview = cam.value.previewSize;
            return FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                // previewSize is reported in landscape.
                width: preview?.height ?? 76,
                height: preview?.width ?? 76,
                child: CameraPreview(cam),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DestinationField extends StatelessWidget {
  const _DestinationField({
    required this.name,
    required this.eta,
    required this.onTap,
    required this.onClear,
  });

  final String? name;
  final String? eta;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasDestination = name != null;

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: EdgeInsetsDirectional.only(
            start: 18,
            end: hasDestination ? 6 : 18,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              AppIcon(
                hasDestination ? Symbols.flag_rounded : Symbols.search_rounded,
                size: 22,
                color: hasDestination ? c.primary : c.subtext,
                filled: hasDestination,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasDestination
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.body(
                              context,
                              16,
                              weight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                          if (eta != null)
                            Text(
                              eta!,
                              style: AppFonts.body(
                                context,
                                14,
                                color: c.subtext,
                              ),
                            ),
                        ],
                      )
                    : Text.rich(
                        TextSpan(
                          text: '${l10n.whereTo} ',
                          style: AppFonts.body(
                            context,
                            16,
                            weight: FontWeight.w500,
                            color: c.subtext,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.whereToOptional,
                              style: AppFonts.body(
                                context,
                                16,
                                color: c.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (hasDestination)
                IconButton(
                  onPressed: onClear,
                  tooltip: l10n.clearDestination,
                  icon: AppIcon(
                    Symbols.close_rounded,
                    size: 22,
                    color: c.subtext,
                  ),
                )
              else
                AppIcon(
                  Symbols.chevron_right_rounded,
                  size: 22,
                  color: c.subtext,
                  mirror: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastTripLine extends StatelessWidget {
  const _LastTripLine({required this.trip});

  final Future<Map<String, dynamic>?>? trip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: trip,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        final alerts = TripRecords.countAlerts(data['alerts']);
        final when = _relativeDay(TripRecords.date(data), l10n);
        final km = TripRecords.distanceKm(data).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: alerts > 0 ? c.warn : c.ok,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.lastTripLine(when, km, l10n.alertCount(alerts)),
                  style: AppFonts.body(context, 15, color: c.subtext),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _relativeDay(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return l10n.lastTripToday;
    if (diff == 1) return l10n.lastTripYesterday;
    final locale = l10n.localeName;
    final label = diff < 7
        ? DateFormat.EEEE(locale).format(date)
        : DateFormat.MMMd(locale).format(date);
    return l10n.lastTripOn(label);
  }
}
