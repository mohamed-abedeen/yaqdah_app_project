import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/sync_service.dart';
import '../widgets/trip_detail_modal.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeFilter = 'week';

  void _handleDelete(int id, String? firestoreId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser['id'].toString();

    // 1. Delete form Firestore (if synced)
    if (firestoreId != null && firestoreId.isNotEmpty) {
      await SyncService.instance.deleteTrip(userId, firestoreId);
    }

    // 2. Delete from Local DB
    await DatabaseService.instance.deleteTrip(id, userId);

    if (mounted) {
      Navigator.pop(context);
      setState(() {});
    }
  }

  int _countRealAlerts(dynamic alertsData) {
    try {
      if (alertsData == null) return 0;
      String s = alertsData.toString();
      if (s == "[]" || s.isEmpty) return 0;
      List<dynamic> list = json.decode(s);
      int count = 0;
      for (var item in list) {
        String event = item.toString().toLowerCase();
        if (event.contains('drowsy') ||
            event.contains('manual') ||
            event.contains('sos') ||
            event.contains('danger')) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color!;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final green = theme.primaryColor;
    final red = theme.colorScheme.error;
    final orange = ThemeService.orange;
    final blue = ThemeService.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // ✅ REMOVED: FloatingActionButton (Clean UI)
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final userId = auth.currentUser['id'].toString();
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                DatabaseService.instance.getTrips(userId),
                DatabaseService.instance.getUserStats(userId),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: green));
                }

                final allTrips =
                    (snapshot.data?[0] as List<Map<String, dynamic>>?) ?? [];
                final userStats =
                    (snapshot.data?[1] as Map<String, dynamic>?) ?? {};
                final filteredTrips = _filterTrips(allTrips, _activeFilter);
                final stats = _calculateStats(filteredTrips);
                final chartData = _generateChartData(filteredTrips);

                int total = filteredTrips.length;
                int tripsWithAlerts = 0;
                for (var t in filteredTrips) {
                  if (_countRealAlerts(t['alerts']) > 0 ||
                      t['status'].toString().toLowerCase().contains('drowsy')) {
                    tripsWithAlerts++;
                  }
                }
                int safeTrips = total - tripsWithAlerts;
                double safePct = total == 0 ? 0 : (safeTrips / total);
                double alertPct = total == 0 ? 0 : (tripsWithAlerts / total);

                int totalAlerts =
                    (stats['drowsyEvents'] as int) +
                    (stats['emergencyEvents'] as int);

                // Show empty state when no trips at all
                if (allTrips.isEmpty) {
                  return _buildEmptyState(l10n, green);
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reportsTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              l10n.reportsSubtitle,
                              style: TextStyle(color: subColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _buildGamificationProfile(
                        userStats,
                        theme,
                        green,
                        textColor,
                        subColor,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    theme.cardColor,
                                    theme.scaffoldBackgroundColor,
                                  ]
                                : [Colors.white, Colors.grey.shade100],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.trending_up, color: green),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.reportsGeneralStats,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _activeFilter == 'week'
                                          ? l10n.reportsThisWeek
                                          : l10n.reportsAllTime,
                                      style: TextStyle(
                                        color: subColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildStatItem(
                                  "${stats['count']}",
                                  l10n.reportsTrips,
                                  green,
                                  subColor,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: theme.dividerColor,
                                ),
                                _buildStatItem(
                                  stats['distance'].toString(),
                                  l10n.kmUnit,
                                  blue,
                                  subColor,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: theme.dividerColor,
                                ),
                                _buildStatItem(
                                  "$totalAlerts",
                                  l10n.reportsAlerts,
                                  orange,
                                  subColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black12
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY:
                                      (chartData
                                          .map((e) => e.y)
                                          .fold(0.0, (p, e) => p > e ? p : e)) *
                                      1.2,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          if (val.toInt() >= 0 &&
                                              val.toInt() < chartData.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                chartData[val.toInt()].x,
                                                style: TextStyle(
                                                  color: subColor,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  barGroups: chartData.asMap().entries.map((e) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.y,
                                          color: green,
                                          width: 12,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                                show: true,
                                                toY:
                                                    (chartData
                                                        .map((e) => e.y)
                                                        .fold(
                                                          0.0,
                                                          (p, e) =>
                                                              p > e ? p : e,
                                                        )) *
                                                    1.2,
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.05,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.05,
                                                      ),
                                              ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.reportsTripStatus,
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 12,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: (safePct * 100).toInt(),
                                          child: Container(color: green),
                                        ),
                                        Expanded(
                                          flex: (alertPct * 100).toInt(),
                                          child: Container(color: orange),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${l10n.reportsSafe} ${(safePct * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${l10n.reportsAlert} ${(alertPct * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Divider(color: theme.dividerColor),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniDetailStat(
                                  l10n.reportsTime,
                                  stats['totalTime'].toString(),
                                  green,
                                  textColor,
                                  subColor,
                                ),
                                _miniDetailStat(
                                  l10n.reportsDrowsy,
                                  "${stats['drowsyEvents']}",
                                  orange,
                                  textColor,
                                  subColor,
                                ),
                                _miniDetailStat(
                                  l10n.reportsEmergency,
                                  "${stats['emergencyEvents']}",
                                  red,
                                  textColor,
                                  subColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _filterTab(l10n.filterAll, 'all', theme),
                              _filterTab(l10n.filterWeek, 'week', theme),
                              _filterTab(l10n.filterMonth, 'month', theme),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final trip = filteredTrips[index];
                          return _buildTripCard(
                            trip,
                            theme,
                            textColor,
                            subColor,
                            l10n,
                          );
                        }, childCount: filteredTrips.length),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    Color color,
    Color subColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: subColor)),
        ],
      ),
    );
  }

  Widget _miniDetailStat(
    String label,
    String value,
    Color color,
    Color textColor,
    Color subColor,
  ) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(radius: 3, backgroundColor: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: subColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _filterTab(String label, String filterKey, ThemeData theme) {
    bool isActive = _activeFilter == filterKey;
    final green = theme.primaryColor;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? green : theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? green : theme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(
    Map<String, dynamic> trip,
    ThemeData theme,
    Color textColor,
    Color subColor,
    AppLocalizations l10n,
  ) {
    int alertsCount = _countRealAlerts(trip['alerts']);
    String status = trip['status'].toString().toLowerCase();
    bool isSafe =
        (alertsCount == 0) &&
        !status.contains('drowsy') &&
        !status.contains('danger') &&
        !status.contains('asleep');

    final date = DateTime.parse(trip['date']);
    final dateStr = intl.DateFormat('d MMMM yyyy').format(date);

    final green = theme.primaryColor;
    final orange = ThemeService.orange;
    final purple = ThemeService.purple;
    final blue = ThemeService.blue;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TripDetailModal(
            trip: trip,
            onDelete: () => _handleDelete(trip['id'], trip['firestoreId']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.calendar, size: 14, color: subColor),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSafe
                        ? green.withValues(alpha: 0.2)
                        : orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSafe
                          ? green.withValues(alpha: 0.3)
                          : orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSafe
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.exclamationmark_triangle_fill,
                        size: 14,
                        color: isSafe ? green : orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSafe ? l10n.tripSafe : l10n.tripAlerted,
                        style: TextStyle(
                          color: isSafe ? green : orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(
                  CupertinoIcons.clock_fill,
                  l10n.tripDuration,
                  trip['duration'],
                  purple,
                  textColor,
                  subColor,
                ),
                _miniStat(
                  CupertinoIcons.map_fill,
                  l10n.tripDistance,
                  trip['distance'],
                  blue,
                  textColor,
                  subColor,
                ),
                _miniStat(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  l10n.tripAlertCount,
                  "$alertsCount",
                  orange,
                  textColor,
                  subColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    IconData icon,
    String label,
    String value,
    Color color,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: subColor)),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterTrips(
    List<Map<String, dynamic>> trips,
    String filter,
  ) {
    final now = DateTime.now();
    return trips.where((t) {
      final date = DateTime.parse(t['date']);
      if (filter == 'week') return now.difference(date).inDays <= 7;
      if (filter == 'month') return now.difference(date).inDays <= 30;
      return true;
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> trips) {
    int count = trips.length;
    double dist = 0;
    int drowsyEvents = 0;
    int emergencyEvents = 0;
    int totalSeconds = 0;

    for (var t in trips) {
      String dStr = t['distance']
          .toString()
          .replaceAll(',', '')
          .replaceAll(' km', '')
          .replaceAll('m', '')
          .trim();
      dist += double.tryParse(dStr) ?? 0;
      if (t['alerts'] != null) {
        try {
          List<dynamic> list = (t['alerts'] is String)
              ? json.decode(t['alerts'])
              : t['alerts'];
          for (var item in list) {
            String s = item.toString().toLowerCase();
            if (s.contains('manual') || s.contains('sos')) {
              emergencyEvents++;
            } else if (s.contains('drowsy') || s.contains('danger')) {
              drowsyEvents++;
            }
          }
        } catch (_) {}
      }
      String dur = t['duration'].toString();
      List<String> parts = dur.split(':');
      if (parts.length == 3) {
        int h = int.tryParse(parts[0]) ?? 0;
        int m = int.tryParse(parts[1]) ?? 0;
        int s = int.tryParse(parts[2]) ?? 0;
        totalSeconds += (h * 3600) + (m * 60) + s;
      }
    }
    int totalHours = totalSeconds ~/ 3600;
    return {
      'count': count,
      'distance': dist.toStringAsFixed(1),
      'drowsyEvents': drowsyEvents,
      'emergencyEvents': emergencyEvents,
      'totalTime': "$totalHours hrs",
    };
  }

  List<_ChartDataPoint> _generateChartData(List<Map<String, dynamic>> trips) {
    Map<String, double> days = {
      'Sat': 0,
      'Sun': 0,
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
    };
    for (var t in trips) {
      final date = DateTime.parse(t['date']);
      final dayName = intl.DateFormat('E').format(date);
      if (days.containsKey(dayName)) {
        String dStr = t['distance']
            .toString()
            .replaceAll(',', '')
            .replaceAll(' km', '')
            .trim();
        days[dayName] = (days[dayName] ?? 0) + (double.tryParse(dStr) ?? 0);
      }
    }
    return days.entries.map((e) => _ChartDataPoint(e.key, e.value)).toList();
  }

  Widget _buildEmptyState(AppLocalizations l10n, Color green) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 48,
                color: green.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.reportsEmptyTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reportsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationProfile(
    Map<String, dynamic> stats,
    ThemeData theme,
    Color green,
    Color textColor,
    Color subColor,
  ) {
    int level = stats['level'] as int? ?? 1;
    double safeKm = (stats['totalSafeKm'] as num?)?.toDouble() ?? 0.0;
    List<String> badges = [];
    if (stats['badges'] != null) {
      badges = List<String>.from(jsonDecode(stats['badges'] as String));
    }

    // calculate progress to next level
    double progress = (safeKm % 50) / 50.0;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_circle_fill,
                    color: Colors.amber,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Level $level Driver",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "${safeKm.toStringAsFixed(1)} Safe KM Total",
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              if (badges.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${badges.length} Badges",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
          if (badges.isNotEmpty) const SizedBox(height: 16),
          if (badges.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                itemBuilder: (ctx, i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badges[i],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartDataPoint {
  final String x;
  final double y;
  _ChartDataPoint(this.x, this.y);
}
