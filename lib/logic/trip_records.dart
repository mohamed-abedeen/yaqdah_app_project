import 'dart:convert';
import 'package:intl/intl.dart' show DateFormat;

/// Event texts written into a trip's `alerts` log.
///
/// Each entry is stored as `"<ISO time>: <text>"`. The keywords matter:
/// [TripRecords.countAlerts] counts entries mentioning drowsiness, danger or
/// SOS, and the response entries deliberately avoid those words.
abstract final class TripEvent {
  static const started = '🏁 Trip Started';
  static const ended = '🛑 Trip Ended';
  static const drowsy = '⚠️ Drowsiness Detected';
  static const distracted = '⚠️ Distraction Detected';
  static const asleep = '🚨 Danger: Asleep';
  static const manualSos = '🆘 Manual SOS';
  static const autoSos = '🆘 Auto SOS sent';

  // Driver responses to an alert.
  static const tookBreak = '☕ Took a break';
  static const keptDriving = '👍 Kept driving';
  static const confirmedAwake = '✅ Confirmed awake';

  static String entry(String text, [DateTime? at]) =>
      '${(at ?? DateTime.now()).toIso8601String()}: $text';
}

enum TripEventKind {
  started,
  ended,
  drowsy,
  distracted,
  danger,
  sos,
  tookBreak,
  keptDriving,
  confirmedAwake,
  other,
}

class ParsedTripEvent {
  const ParsedTripEvent(this.kind, this.time, this.raw);

  final TripEventKind kind;
  final DateTime? time;
  final String raw;

  bool get isResponse =>
      kind == TripEventKind.tookBreak ||
      kind == TripEventKind.keptDriving ||
      kind == TripEventKind.confirmedAwake;
}

/// Read-only helpers over the trip maps stored by `DatabaseService`.
abstract final class TripRecords {
  static List<String> _alertList(dynamic alertsData) {
    if (alertsData == null) return const [];
    try {
      final decoded = alertsData is String
          ? json.decode(alertsData)
          : alertsData;
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }

  static bool _isEmergency(String lower) =>
      lower.contains('manual') || lower.contains('sos');

  static bool _isDrowsyOrDanger(String lower) =>
      lower.contains('drows') || lower.contains('danger');

  /// Alerts in a trip: drowsiness, danger and SOS events.
  static int countAlerts(dynamic alertsData) {
    var count = 0;
    for (final item in _alertList(alertsData)) {
      final lower = item.toLowerCase();
      if (_isEmergency(lower) || _isDrowsyOrDanger(lower)) count++;
    }
    return count;
  }

  /// Whether a trip had no alerts. Pass [alerts] when already counted.
  static bool isSafe(Map<String, dynamic> trip, {int? alerts}) {
    final status = trip['status'].toString().toLowerCase();
    return (alerts ?? countAlerts(trip['alerts'])) == 0 &&
        !status.contains('drowsy') &&
        !status.contains('danger') &&
        !status.contains('asleep') &&
        !status.contains('emergency');
  }

  static DateTime date(Map<String, dynamic> trip) =>
      DateTime.tryParse(trip['date']?.toString() ?? '') ?? DateTime.now();

  /// Kilometres from strings like "42.3 km".
  static double distanceKm(Map<String, dynamic> trip) {
    final s = trip['distance']?.toString() ?? '';
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  /// Duration from "H:MM:SS" (or "MM:SS").
  static Duration duration(Map<String, dynamic> trip) {
    final parts = (trip['duration']?.toString() ?? '')
        .split(':')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    return Duration.zero;
  }

  /// Number from strings like "64.0 km/h".
  static double? speed(dynamic value) {
    final s = value?.toString() ?? '';
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  /// When the trip started: its "Trip started" event, or for trips saved
  /// without one, its saved start time.
  static DateTime? startedAt(Map<String, dynamic> trip) =>
      _eventTime(trip, TripEventKind.started) ??
      _clockOnTripDay(trip, trip['startTime']);

  /// When the trip ended, like [startedAt].
  static DateTime? endedAt(Map<String, dynamic> trip) =>
      _eventTime(trip, TripEventKind.ended) ??
      _clockOnTripDay(trip, trip['endTime']);

  /// A time in the app language, e.g. "8:12 PM"; empty for null.
  static String clockLabel(DateTime? time, String locale) =>
      time == null ? '' : DateFormat.jm(locale).format(time);

  static DateTime? _eventTime(Map<String, dynamic> trip, TripEventKind kind) {
    for (final raw in _alertList(trip['alerts'])) {
      final event = _parseEvent(raw);
      if (event.kind == kind && event.time != null) return event.time;
    }
    return null;
  }

  /// Times were saved as English "hh:mm a", e.g. "08:12 PM".
  static DateTime? _clockOnTripDay(Map<String, dynamic> trip, dynamic value) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*([AaPp])',
    ).firstMatch(value?.toString() ?? '');
    if (match == null) return null;
    var hour = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toLowerCase() == 'p') hour += 12;
    final day = date(trip);
    return DateTime(
      day.year,
      day.month,
      day.day,
      hour,
      int.parse(match.group(2)!),
    );
  }

  static List<ParsedTripEvent> events(Map<String, dynamic> trip) {
    return _alertList(trip['alerts']).map(_parseEvent).toList();
  }

  static ParsedTripEvent _parseEvent(String raw) {
    final split = raw.indexOf(': ');
    final time = split > 0 ? DateTime.tryParse(raw.substring(0, split)) : null;
    final text = (split > 0 ? raw.substring(split + 2) : raw).toLowerCase();

    final TripEventKind kind;
    if (text.contains('trip started')) {
      kind = TripEventKind.started;
    } else if (text.contains('trip ended')) {
      kind = TripEventKind.ended;
    } else if (_isEmergency(text)) {
      kind = TripEventKind.sos;
    } else if (text.contains('danger') || text.contains('asleep')) {
      kind = TripEventKind.danger;
    } else if (text.contains('drows')) {
      kind = TripEventKind.drowsy;
    } else if (text.contains('distract')) {
      kind = TripEventKind.distracted;
    } else if (text.contains('took a break')) {
      kind = TripEventKind.tookBreak;
    } else if (text.contains('kept driving')) {
      kind = TripEventKind.keptDriving;
    } else if (text.contains('confirmed awake')) {
      kind = TripEventKind.confirmedAwake;
    } else {
      kind = TripEventKind.other;
    }
    return ParsedTripEvent(kind, time, raw);
  }

  /// Gamification badge ids, in display order.
  static const badgeIds = [
    'First Safe Trip',
    'Perfect 10',
    'Night Owl',
    'Marathoner',
  ];

  static const kmPerLevel = 50.0;

  /// Level, safe distance and badges worked out from the trips on this
  /// phone, so they agree with the trip list and include trips synced from
  /// the cloud. Badges earned before stay earned.
  static LevelProgress levelProgress(
    List<TripSummary> trips,
    Map<String, dynamic>? stats,
  ) {
    var safeKm = 0.0;
    final badges = <String>{...earnedBadges(stats)};
    for (final t in trips) {
      if (t.safe) {
        safeKm += t.km;
        badges.add('First Safe Trip');
        final hour = t.startedAt?.hour;
        if (t.km >= 5 && hour != null && hour < 5) badges.add('Night Owl');
      }
      final score = (t.row['score'] as num?)?.toInt() ?? 100;
      if (score == 100 && t.km >= 10) badges.add('Perfect 10');
    }
    if (safeKm > 500) badges.add('Marathoner');
    return LevelProgress(
      level: (safeKm / kmPerLevel).floor() + 1,
      safeKm: safeKm,
      badges: badges,
    );
  }

  static List<String> earnedBadges(Map<String, dynamic>? stats) {
    final raw = stats?['badges'];
    if (raw == null) return const [];
    try {
      return List<String>.from(jsonDecode(raw as String));
    } catch (_) {
      return const [];
    }
  }
}

/// A trip row with what the Reports tab shows, parsed once.
class TripSummary {
  factory TripSummary(Map<String, dynamic> row) {
    final alerts = TripRecords.countAlerts(row['alerts']);
    return TripSummary._(
      row,
      TripRecords.date(row),
      TripRecords.distanceKm(row),
      alerts,
      TripRecords.isSafe(row, alerts: alerts),
      TripRecords.startedAt(row),
    );
  }

  const TripSummary._(
    this.row,
    this.date,
    this.km,
    this.alerts,
    this.safe,
    this.startedAt,
  );

  final Map<String, dynamic> row;
  final DateTime date;
  final double km;
  final int alerts;
  final bool safe;
  final DateTime? startedAt;
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.safeKm,
    required this.badges,
  });

  final int level;
  final double safeKm;
  final Set<String> badges;
}
