import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../logic/trip_records.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/brand.dart';
import '../widgets/common/segmented_control.dart';
import 'trip_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeFilter = 'week';
  late Future<_ReportData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
    DatabaseService.instance.tripsRevision.addListener(_reload);
  }

  @override
  void dispose() {
    DatabaseService.instance.tripsRevision.removeListener(_reload);
    super.dispose();
  }

  String get _userId => Provider.of<AuthProvider>(
    context,
    listen: false,
  ).currentUser['id'].toString();

  /// Loads the trips and works out everything the page shows once, so
  /// switching the filter or rebuilding doesn't re-parse every trip.
  Future<_ReportData> _load() async {
    final userId = _userId;
    final rows = await DatabaseService.instance.getTrips(userId);
    final stats = await DatabaseService.instance.getUserStats(userId);
    final trips = rows.map(TripSummary.new).toList();
    return _ReportData(trips, TripRecords.levelProgress(trips, stats));
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _data = _load());
  }

  void _openTrip(Map<String, dynamic> trip) {
    final userId = _userId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          trip: trip,
          // Deletes locally at once (the list reloads itself) and in the
          // cloud when there's a connection.
          onDelete: () =>
              SyncService.instance.deleteTrip(userId, trip['id'] as int),
        ),
      ),
    );
  }

  /// Week: this calendar week, Saturday to Friday, like the bar chart.
  /// Month: the last 30 days.
  List<TripSummary> _filterTrips(List<TripSummary> trips, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.saturday) % 7,
    );
    final monthStart = DateTime(today.year, today.month, today.day - 29);
    return trips.where((t) {
      if (filter == 'week') return !t.date.isBefore(weekStart);
      if (filter == 'month') return !t.date.isBefore(monthStart);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_ReportData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTrips = snapshot.data?.trips ?? const <TripSummary>[];
            final level =
                snapshot.data?.level ??
                TripRecords.levelProgress(const [], null);

            // Show empty state when no trips at all
            if (allTrips.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: _Title(l10n.reportsTitle),
                  ),
                  const Expanded(child: _EmptyState()),
                ],
              );
            }

            final filteredTrips = _filterTrips(allTrips, _activeFilter);

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(child: _Title(l10n.reportsTitle)),
                        SegmentedControl<String>(
                          segments: [
                            Segment('week', l10n.filterWeek),
                            Segment('month', l10n.filterMonth),
                            Segment('all', l10n.filterAll),
                          ],
                          selected: _activeFilter,
                          onChanged: (v) => setState(() => _activeFilter = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LevelCard(level: level),
                  const SizedBox(height: 14),
                  _SummaryCard(trips: filteredTrips),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text(
                      l10n.recentTrips,
                      style: AppFonts.body(
                        context,
                        17,
                        weight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filteredTrips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.reportsNoTripsInRange,
                        textAlign: TextAlign.center,
                        style: AppFonts.body(context, 15, color: c.subtext),
                      ),
                    )
                  else
                    for (final trip in filteredTrips) ...[
                      _TripRow(trip: trip, onTap: () => _openTrip(trip.row)),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.display(
        context,
        30,
        color: AppColors.of(context).text,
        tracking: -0.02,
      ),
    );
  }
}

/// Driver level card on the fixed brand indigo.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final LevelProgress level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeKm = level.safeKm;
    final earned = level.badges;

    // Progress to the next level
    const kmPerLevel = TripRecords.kmPerLevel;
    final progress = (safeKm % kmPerLevel) / kmPerLevel;
    final remaining = kmPerLevel - (safeKm % kmPerLevel);

    final captionStyle = AppFonts.body(
      context,
      14,
      weight: FontWeight.w500,
      color: FixedColors.brandSecondary,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FixedColors.brandIndigo,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.driverLevel.toUpperCase(),
                      style: AppFonts.overline(context, FixedColors.brandLabel),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.levelN(level.level),
                      style: AppFonts.display(
                        context,
                        36,
                        color: Colors.white,
                        tracking: -0.02,
                      ),
                    ),
                  ],
                ),
              ),
              const IconTile(
                icon: Symbols.workspace_premium_rounded,
                background: FixedColors.goldSoft,
                foreground: FixedColors.gold,
                size: 52,
                radius: 16,
                iconSize: 30,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FixedColors.gold,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.safeKm(safeKm.toStringAsFixed(1)),
                  style: captionStyle,
                ),
              ),
              Text(
                l10n.kmToNextLevel(
                  remaining.toStringAsFixed(1),
                  level.level + 1,
                ),
                style: captionStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in TripRecords.badgeIds)
                _BadgeChip(
                  label: _badgeLabel(id, l10n),
                  earned: earned.contains(id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _badgeLabel(String id, AppLocalizations l10n) => switch (id) {
    'First Safe Trip' => l10n.badgeFirstSafeTrip,
    'Perfect 10' => l10n.badgePerfect10,
    'Night Owl' => l10n.badgeNightOwl,
    'Marathoner' => l10n.badgeMarathoner,
    _ => id,
  };
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.earned});

  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            earned ? Symbols.verified_rounded : Symbols.lock_rounded,
            size: 16,
            color: earned ? FixedColors.gold : FixedColors.brandLabel,
            filled: earned,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.body(
              context,
              13,
              weight: FontWeight.w600,
              color: earned ? Colors.white : FixedColors.brandLabel,
            ),
          ),
        ],
      ),
    );

    if (earned) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: content,
      );
    }
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Colors.white.withValues(alpha: 0.3),
        radius: 11,
      ),
      child: content,
    );
  }
}

/// Trips / distance / alerts plus the by-day bar chart.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.trips});

  final List<TripSummary> trips;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final distance = trips.fold<double>(0, (sum, t) => sum + t.km);
    final totalAlerts = trips.fold<int>(0, (sum, t) => sum + t.alerts);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SummaryStat(value: '${trips.length}', label: l10n.reportsTrips),
              _SummaryStat(
                value: distance.toStringAsFixed(distance >= 100 ? 0 : 1),
                unit: l10n.kmUnit,
                label: l10n.reportsDistance,
              ),
              _SummaryStat(
                value: '$totalAlerts',
                label: l10n.reportsAlerts,
                color: c.warn,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DayBars(trips: trips),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legend(color: c.primary, label: l10n.legendSafeDays),
              _Legend(color: c.warn, label: l10n.legendAlertDays),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    this.unit,
    this.color,
  });

  final String value;
  final String label;
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: AppFonts.display(
                context,
                24,
                weight: FontWeight.w600,
                color: color ?? c.text,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppFonts.body(
                      context,
                      14,
                      weight: FontWeight.w500,
                      color: c.subtext,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.body(
              context,
              13,
              weight: FontWeight.w500,
              color: c.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven bars, Saturday to Friday. Height is distance driven that weekday;
/// days with any alert are warn, safe days primary, empty days surface2.
class _DayBars extends StatelessWidget {
  const _DayBars({required this.trips});

  final List<TripSummary> trips;

  /// DateTime.weekday values from Saturday to Friday.
  static const _order = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final km = {for (final d in _order) d: 0.0};
    final count = {for (final d in _order) d: 0};
    final alerts = {for (final d in _order) d: false};
    for (final t in trips) {
      final day = t.date.weekday;
      km[day] = km[day]! + t.km;
      count[day] = count[day]! + 1;
      if (t.alerts > 0) alerts[day] = true;
    }
    final maxKm = km.values.fold<double>(0, (m, v) => v > m ? v : m);

    // Any week starting on a Saturday gives the weekday labels.
    final saturday = DateTime(2024, 1, 6);
    final labelFormat = intl.DateFormat.E(l10n.localeName);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _order.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: count[_order[i]]! == 0
                            ? 0.08
                            : (maxKm > 0 ? km[_order[i]]! / maxKm : 0.0).clamp(
                                0.15,
                                1.0,
                              ),
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: count[_order[i]]! == 0
                                ? c.surface2
                                : (alerts[_order[i]]! ? c.warn : c.primary),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labelFormat.format(saturday.add(Duration(days: i))),
                    maxLines: 1,
                    style: AppFonts.body(
                      context,
                      11,
                      weight: FontWeight.w500,
                      color: c.subtext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.body(
            context,
            13,
            weight: FontWeight.w500,
            color: c.subtext,
          ),
        ),
      ],
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onTap});

  final TripSummary trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSafe = trip.safe;
    final alerts = trip.alerts;
    final dateLabel = intl.DateFormat(
      'EEE, d MMM',
      l10n.localeName,
    ).format(trip.date);
    final start = TripRecords.clockLabel(trip.startedAt, l10n.localeName);

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              IconTile(
                icon: isSafe
                    ? Symbols.check_circle_rounded
                    : Symbols.warning_rounded,
                background: isSafe ? c.okSoft : c.warnSoft,
                foreground: isSafe ? c.ok : c.warn,
                filled: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      start.isEmpty ? dateLabel : '$dateLabel · $start',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        context,
                        16,
                        weight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tripRowSubtitle(
                        formatTripDuration(
                          TripRecords.duration(trip.row),
                          l10n,
                        ),
                        trip.km.toStringAsFixed(1),
                        l10n.alertCount(alerts),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(context, 14, color: c.subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

/// "52 min" or "1 h 12 min".
String formatTripDuration(Duration d, AppLocalizations l10n) {
  final minutes = d.inMinutes % 60;
  if (d.inHours > 0) return l10n.durationHoursMinutes(d.inHours, minutes);
  return l10n.minutesShort(d.inMinutes);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  Symbols.insights_rounded,
                  size: 44,
                  color: c.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.reportsEmptyTitle,
              textAlign: TextAlign.center,
              style: AppFonts.display(context, 24, color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reportsEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppFonts.body(context, 16, color: c.subtext, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportData {
  const _ReportData(this.trips, this.level);

  final List<TripSummary> trips;
  final LevelProgress level;
}
