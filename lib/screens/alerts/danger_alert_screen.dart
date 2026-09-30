import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_icon.dart';

/// Full-screen danger alert (driver asleep). Identical in both themes.
///
/// When automatic SOS is on and a contact is set, a countdown runs and
/// [onCountdownComplete] fires at zero unless the driver responds.
class DangerAlertScreen extends StatefulWidget {
  const DangerAlertScreen({
    super.key,
    required this.contact,
    required this.autoSosEnabled,
    required this.onAwake,
    required this.onSendNow,
    required this.onCountdownComplete,
    this.vibrate = true,
    this.countdownSeconds = 10,
  });

  final String contact;
  final bool autoSosEnabled;
  final VoidCallback onAwake;

  /// These send the SOS text and complete with whether it went out.
  final Future<bool> Function() onSendNow;
  final Future<bool> Function() onCountdownComplete;

  /// Pulse the phone every second while the alert is up.
  final bool vibrate;
  final int countdownSeconds;

  @override
  State<DangerAlertScreen> createState() => _DangerAlertScreenState();
}

class _DangerAlertScreenState extends State<DangerAlertScreen> {
  static const _ink = FixedColors.dangerInk;

  Timer? _timer;
  Timer? _vibrationTimer;
  late int _remaining = widget.countdownSeconds;

  /// null until an SOS is sent; then whether it went out.
  bool? _sendResult;
  bool _sending = false;

  bool get _sent => _sending || _sendResult != null;

  bool get _countingDown =>
      widget.autoSosEnabled && widget.contact.isNotEmpty && !_sent;

  @override
  void initState() {
    super.initState();
    if (widget.vibrate) {
      HapticFeedback.heavyImpact();
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => HapticFeedback.vibrate(),
      );
    }
    if (_countingDown) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _remaining--);
        if (_remaining <= 0) {
          timer.cancel();
          _send(widget.onCountdownComplete);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _send(Future<bool> Function() send) async {
    setState(() {
      _sending = true;
      _sendResult = null;
    });
    final sent = await send();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sendResult = sent;
    });
  }

  void _sendNow() {
    _timer?.cancel();
    _send(widget.onSendNow);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final infoStyle = AppFonts.body(
      context,
      15,
      weight: FontWeight.w600,
      color: _ink,
    );
    final subStyle = AppFonts.body(context, 15, color: _ink);

    final Widget sosInfo;
    if (_sending) {
      sosInfo = _InfoRow(
        leading: const _RingBadge(
          progress: 1,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _ink),
          ),
        ),
        title: Text(l10n.sosSending, style: infoStyle),
        subtitle: widget.contact.isEmpty
            ? null
            : Text(l10n.sosTo(widget.contact), style: subStyle),
      );
    } else if (_sendResult == false) {
      sosInfo = _InfoRow(
        leading: const _RingBadge(
          progress: 1,
          child: AppIcon(Symbols.close_rounded, size: 34, color: _ink),
        ),
        title: Text(l10n.sosSendFailed, style: infoStyle),
        subtitle: widget.contact.isEmpty
            ? null
            : Text(l10n.sosTo(widget.contact), style: subStyle),
      );
    } else if (_sent) {
      sosInfo = _InfoRow(
        leading: const _RingBadge(
          progress: 1,
          child: AppIcon(Symbols.check_rounded, size: 34, color: _ink),
        ),
        title: Text(l10n.sosSentTitle, style: infoStyle),
        subtitle: widget.contact.isEmpty
            ? null
            : Text(l10n.sosTo(widget.contact), style: subStyle),
      );
    } else if (_countingDown) {
      sosInfo = _InfoRow(
        leading: _RingBadge(
          progress: _remaining / widget.countdownSeconds,
          child: Text(
            '$_remaining',
            style: AppFonts.display(context, 34, color: _ink),
          ),
        ),
        title: Text(l10n.sosCountdown(_remaining), style: infoStyle),
        subtitle: Text(l10n.sosTo(widget.contact), style: subStyle),
      );
    } else {
      sosInfo = _InfoRow(
        title: Text(
          widget.contact.isEmpty ? l10n.sosNoContact : l10n.sosAutoOff,
          style: infoStyle,
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: FixedColors.dangerBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _ink.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: AppIcon(
                              Symbols.warning_rounded,
                              size: 44,
                              color: _ink,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.dangerAlertTitle,
                          style: AppFonts.display(
                            context,
                            50,
                            color: _ink,
                            height: 1,
                            tracking: -0.03,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.dangerAlertBody,
                          style: AppFonts.body(
                            context,
                            19,
                            weight: FontWeight.w500,
                            color: _ink,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 32),
                        sosInfo,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AwakeButton(label: l10n.imAwake, onTap: widget.onAwake),
                      // A failed text can be tried again.
                      if (!_sent || _sendResult == false) ...[
                        const SizedBox(height: 12),
                        AppButton(
                          label: l10n.sendSosNow,
                          onPressed: _sendNow,
                          height: 60,
                          background: Colors.transparent,
                          foreground: _ink,
                          border: BorderSide(
                            color: _ink.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AwakeButton extends StatelessWidget {
  const _AwakeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppFonts.display(
                context,
                22,
                color: FixedColors.dangerButtonText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({this.leading, required this.title, this.subtitle});

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 18)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (subtitle != null) ...[const SizedBox(height: 3), subtitle!],
            ],
          ),
        ),
      ],
    );
  }
}

/// 84 ring: white progress on a faint track around a red centre.
class _RingBadge extends StatelessWidget {
  const _RingBadge({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: const Duration(milliseconds: 900),
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
