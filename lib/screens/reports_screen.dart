// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;
import '../services/database_service.dart';
import '../services/theme_service.dart'; // ✅ Import ThemeService
import '../widgets/trip_detail_modal.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeFilter = 'week';

  void _handleDelete(int id) async {
    await DatabaseService.instance.deleteTrip(id);
    Navigator.pop(context);
    setState(() {});
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color!;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    // ✅ Colors from Theme Service
    final green = theme.primaryColor;
    final red = theme.colorScheme.error;
    final orange = ThemeService.orange;
    final purple = ThemeService.purple;
    final blue = ThemeService.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseService.instance.getTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: green));
            }

            final allTrips = snapshot.data ?? [];
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

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reports & Statistics",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "Comprehensive driving activity analysis",
                          style: TextStyle(color: subColor, fontSize: 14),
                        ),
                      ],
                    ),
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
                            ? [theme.cardColor, theme.scaffoldBackgroundColor]
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
                                color: green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.trending_up, color: green),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "General Statistics",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _activeFilter == 'week'
                                      ? "This Week"
                                      : "All Time",
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
                              "Trips",
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
                              "KM",
                              blue,
                              subColor,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: theme.dividerColor,
                            ),
                            _buildStatItem(
                              "${stats['drowsyEvents']}",
                              "Alerts",
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
                                      borderRadius: const BorderRadius.vertical(
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
                                                      (p, e) => p > e ? p : e,
                                                    )) *
                                                1.2,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.black.withOpacity(
                                                    0.05,
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
                              "Trip Status Distribution",
                              style: TextStyle(color: subColor, fontSize: 12),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Safe ${(safePct * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    color: green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Alerts ${(alertPct * 100).toStringAsFixed(0)}%",
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
                              "Time",
                              stats['totalTime'].toString(),
                              green,
                              textColor,
                              subColor,
                            ),
                            _miniDetailStat(
                              "Drowsy",
                              "${stats['drowsyEvents']} Events",
                              orange,
                              textColor,
                              subColor,
                            ),
                            _miniDetailStat(
                              "Emergency",
                              "${stats['emergencyEvents']} Times",
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
                          _filterTab("All", 'all', theme),
                          _filterTab("Week", 'week', theme),
                          _filterTab("Month", 'month', theme),
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
                      return _buildTripCard(trip, theme, textColor, subColor);
                    }, childCount: filteredTrips.length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
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
            onDelete: () => _handleDelete(trip['id']),
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
                    Icon(Icons.calendar_today, size: 14, color: subColor),
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
                        ? green.withOpacity(0.2)
                        : orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSafe
                          ? green.withOpacity(0.3)
                          : orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSafe ? Icons.check_circle : Icons.warning,
                        size: 14,
                        color: isSafe ? green : orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSafe ? "Safe Trip" : "Alert",
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
                  Icons.access_time,
                  "Duration",
                  trip['duration'],
                  purple,
                  textColor,
                  subColor,
                ),
                _miniStat(
                  Icons.map,
                  "Distance",
                  trip['distance'],
                  blue,
                  textColor,
                  subColor,
                ),
                _miniStat(
                  Icons.warning_amber,
                  "Alerts",
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
          List<dynamic> list = json.decode(t['alerts']);
          for (var item in list) {
            String s = item.toString().toLowerCase();
            if (s.contains('manual') || s.contains('sos'))
              emergencyEvents++;
            else if (s.contains('drowsy') || s.contains('danger'))
              drowsyEvents++;
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
}

class _ChartDataPoint {
  final String x;
  final double y;
  _ChartDataPoint(this.x, this.y);
}
