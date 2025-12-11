import 'package:flutter/material.dart';
import '../services/database_service.dart'; // Import DB

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedFilterIndex = 0; // 0: All Time, 1: Week, 2: Month

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column( // Main Column
        children: [
          // 1. SCROLLABLE HEADER (Stats + Filters)
          Expanded(
            flex: 0, // Takes minimum space needed
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Trip Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("Review your driving history", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Overall Statistics Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text("Overall Statistics", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Future Builder for Stats could go here later
                        // For now, static stats based on UI request
                        Row(
                          children: [
                            Expanded(child: _buildStatBox("3", "Total Trips", Icons.trending_up, Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatBox("740", "Total km", Icons.map, Colors.purple)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatBox("65%", "Avg Alertness", Icons.remove_red_eye, Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatBox("19", "Alert Events", Icons.warning_amber_rounded, Colors.orange)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab("All Time", 0),
                        _buildFilterTab("This Week", 1),
                        _buildFilterTab("This Month", 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("RECENT TRIPS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 2. SCROLLABLE TRIP LIST (From Database)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService.instance.getTrips(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_eta_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No trips recorded yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];

                    // Format Date
                    final dateObj = DateTime.tryParse(trip['date']) ?? DateTime.now();
                    final dateStr = "${_monthName(dateObj.month)} ${dateObj.day}, ${dateObj.year}";

                    final isSafe = trip['status'] == "Safe Trip";

                    return _buildTripTile(
                      date: dateStr,
                      duration: trip['duration'] ?? "00:00:00",
                      distance: trip['distance'] ?? "0 km",
                      isSafe: isSafe,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Darker inner bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    bool isActive = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blue : Colors.white10),
        ),
        child: Text(
            label,
            style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _buildTripTile({required String date, required String duration, required String distance, required bool isSafe}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: isSafe ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSafe ? Colors.green : Colors.orange)
                ),
                child: Text(
                    isSafe ? "Safe Trip" : "Drowsiness",
                    style: TextStyle(color: isSafe ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route Line
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text("$distance driven", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}