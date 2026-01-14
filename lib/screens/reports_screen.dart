import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Week, 2: Month

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.instance.getTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          final allTrips = snapshot.data ?? [];
          List<Map<String, dynamic>> filteredTrips = _applyFilter(allTrips);
          final stats = _calculateStats(filteredTrips);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            if (!isDark)
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.analytics_outlined,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "الإحصائيات العامة",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatBox(
                                    stats['count']!,
                                    "عدد الرحلات",
                                    Icons.trending_up,
                                    Colors.blue,
                                    context,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatBox(
                                    stats['distance']!,
                                    "المسافة (كم)",
                                    Icons.map,
                                    Colors.purple,
                                    context,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatBox(
                                    stats['time']!,
                                    "إجمالي الوقت",
                                    Icons.access_time,
                                    Colors.green,
                                    context,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatBox(
                                    stats['alerts']!,
                                    "تنبيهات النعاس",
                                    Icons.warning_amber_rounded,
                                    Colors.orange,
                                    context,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTab("الكل", 0, context),
                            _buildFilterTab("هذا الأسبوع", 1, context),
                            _buildFilterTab("هذا الشهر", 2, context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "أحدث الرحلات (اسحب للحذف)",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredTrips.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.drive_eta_outlined,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "لا توجد رحلات مسجلة",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final trip = filteredTrips.reversed.toList()[index];
                      final dateObj =
                          DateTime.tryParse(trip['date']) ?? DateTime.now();
                      final dateStr =
                          "${dateObj.year}-${dateObj.month}-${dateObj.day}";

                      String rawStatus = (trip['status'] ?? "")
                          .toString()
                          .toLowerCase();
                      bool isSafe = true;
                      String displayStatus = "رحلة آمنة";

                      if (rawStatus.contains("drowsy") ||
                          rawStatus.contains("ناعس") ||
                          rawStatus.contains("danger")) {
                        isSafe = false;
                        displayStatus = "ناعس";
                      }

                      return Dismissible(
                        key: Key(trip['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await _deleteTrip(trip['id']);
                        },
                        child: GestureDetector(
                          onTap: () => _showTripDetails(context, trip),
                          child: _buildTripTile(
                            date: dateStr,
                            duration: trip['duration'] ?? "00:00:00",
                            distance: trip['distance'] ?? "0 m",
                            statusText: displayStatus,
                            isSafe: isSafe,
                            context: context,
                          ),
                        ),
                      );
                    }, childCount: filteredTrips.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // --- Logic Helpers ---
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> trips) {
    final now = DateTime.now();
    if (_selectedFilterIndex == 0) return trips;
    return trips.where((trip) {
      final date = DateTime.tryParse(trip['date']) ?? DateTime.now();
      return now.difference(date).inDays <=
          (_selectedFilterIndex == 1 ? 7 : 30);
    }).toList();
  }

  Map<String, String> _calculateStats(List<Map<String, dynamic>> trips) {
    int count = trips.length;
    double totalDist = 0.0;
    int alerts = 0;
    int totalSeconds = 0;

    for (var t in trips) {
      String dStr = t['distance'] ?? "0";
      if (dStr.contains("km")) {
        totalDist += double.tryParse(dStr.replaceAll("km", "").trim()) ?? 0.0;
      } else if (dStr.contains("m")) {
        totalDist +=
            (double.tryParse(dStr.replaceAll("m", "").trim()) ?? 0.0) / 1000.0;
      }

      String s = (t['status'] ?? "").toString().toLowerCase();
      if (s.contains("drowsy") || s.contains("ناعس")) {
        alerts++;
      }

      String dur = t['duration'] ?? "00:00:00";
      List<String> parts = dur.split(':');
      if (parts.length == 3)
        totalSeconds +=
            int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            int.parse(parts[2]);
    }
    return {
      "count": count.toString(),
      "distance": totalDist.toStringAsFixed(1),
      "time": "${totalSeconds ~/ 3600}س",
      "alerts": alerts.toString(),
    };
  }

  Future<void> _deleteTrip(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
    setState(() {});
  }

  // --- Detail & Share Logic ---
  void _showTripDetails(BuildContext context, Map<String, dynamic> trip) {
    List<dynamic> alerts = [];
    if (trip['alerts'] != null) {
      try {
        alerts = jsonDecode(trip['alerts']);
      } catch (e) {
        alerts = [];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "تفاصيل الرحلة",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: alerts.isEmpty
                      ? Center(
                          child: Text(
                            "لا توجد أحداث في هذه الرحلة",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final event = alerts[index].toString();
                            final parts = event.split(": ");
                            final time = parts.length > 1
                                ? parts[0].split("T")[1].substring(0, 5)
                                : "";
                            final msg = parts.length > 1 ? parts[1] : event;
                            return ListTile(
                              leading: const Icon(
                                Icons.circle,
                                size: 12,
                                color: Colors.blue,
                              ),
                              title: Text(
                                msg,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                time,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _generateAndSharePDF(trip, alerts),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    "مشاركة التقرير (PDF)",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ HELPER: Translate Arabic text to English for PDF
  String _translateToEnglish(String input) {
    if (input.contains("ناعس") || input.contains("drowsy")) return "Drowsy";
    if (input.contains("رحلة آمنة") || input.contains("Safe"))
      return "Safe Trip";
    if (input.contains("تم اكتشاف نوم السائق")) return "Driver Asleep Detected";
    if (input.contains("تم اكتشاف نعاس")) return "Drowsiness Detected";
    if (input.contains("نداء استغاثة يدوي")) return "Manual SOS Triggered";
    if (input.contains("بدء الرحلة")) return "Trip Started";
    if (input.contains("نهاية الرحلة")) return "Trip Ended";
    return input; // Fallback
  }

  // ✅ UPDATED: Professional English PDF Generation with Translation
  Future<void> _generateAndSharePDF(
    Map<String, dynamic> trip,
    List<dynamic> alerts,
  ) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('images/logo.jpg');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {}

    // Translate Status
    String statusEn = _translateToEnglish(trip['status'] ?? "Safe Trip");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "TRIP REPORT",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        "Yaqdah Safety Assistant",
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Image(logoImage, width: 60, height: 60),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.blue900, thickness: 2),
              pw.SizedBox(height: 20),

              // --- Trip Summary Section ---
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfStatItem(
                      "Date",
                      trip['date'].toString().split('T')[0],
                      const pw.TextStyle(fontSize: 14),
                      pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildPdfStatItem(
                      "Duration",
                      trip['duration'],
                      const pw.TextStyle(fontSize: 14),
                      pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildPdfStatItem(
                      "Distance",
                      trip['distance'],
                      const pw.TextStyle(fontSize: 14),
                      pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildPdfStatItem(
                      "Status",
                      statusEn,
                      const pw.TextStyle(fontSize: 14),
                      pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: statusEn.contains("Safe")
                            ? PdfColors.green700
                            : PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // --- Events Timeline ---
              pw.Text(
                "Events Timeline",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              if (alerts.isEmpty)
                pw.Text(
                  "No safety events recorded during this trip.",
                  style: pw.TextStyle(
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              else
                ...alerts.map((e) {
                  String raw = e.toString();
                  String time = "";
                  String msg = raw;
                  if (raw.contains(": ")) {
                    final parts = raw.split(": ");
                    if (parts[0].contains("T")) {
                      time = parts[0].split("T")[1].split(".")[0];
                      // ✅ Translate the Message Part
                      msg = _translateToEnglish(parts.sublist(1).join(": "));
                    }
                  }

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 60,
                          child: pw.Text(
                            time,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 8,
                          height: 8,
                          margin: const pw.EdgeInsets.only(top: 4, right: 10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.blue,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            msg,
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              pw.Spacer(),

              // --- Footer ---
              pw.Divider(color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Generated by Yaqdah App",
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    DateTime.now().toString().split('.')[0],
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/trip_report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Here is my Trip Report.");
  }

  pw.Widget _buildPdfStatItem(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: labelStyle.copyWith(color: PdfColors.grey600, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(value, style: valueStyle),
      ],
    );
  }

  // --- Widget Helpers (Screen) ---
  Widget _buildStatBox(
    String value,
    String label,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index, BuildContext context) {
    final theme = Theme.of(context);
    bool isActive = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : theme.textTheme.bodySmall?.color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTripTile({
    required String date,
    required String duration,
    required String distance,
    required String statusText,
    required bool isSafe,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        duration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSafe ? Colors.green : Colors.red),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: isSafe ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: theme.primaryColor),
              const SizedBox(width: 4),
              Text(
                "المسافة المقطوعة: $distance",
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
