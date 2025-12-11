import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUser; // ✅ Receives User Data

  const SettingsScreen({
    super.key,
    required this.onLogout,
    required this.currentUser // Required now
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _soundAlerts = true;
  bool _darkMode = true;

  // Helper to get initials (e.g. "Ahmed Hassan" -> "AH")
  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Extract user data for easier use
    final name = widget.currentUser['fullName'] ?? "Driver";
    final email = widget.currentUser['email'] ?? "No Email";
    final phone = widget.currentUser['phone'] ?? "No Phone";

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Manage your account and preferences", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // 1. Profile Card (REAL DATA)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.blue, Colors.purple])),
                        child: Center(child: Text(_getInitials(name), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.withOpacity(0.5))),
                            child: const Text("Verified Driver", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(children: [
                    Expanded(child: _infoBox(Icons.email_outlined, "Email", email, Colors.blue)), // Real Email
                    const SizedBox(width: 10),
                    Expanded(child: _infoBox(Icons.phone_outlined, "Phone", phone, Colors.green)), // Real Phone
                  ]),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (){},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Group
            _sectionHeader(Icons.notifications_none, "Alerts & Notifications"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildSwitchRow("Push Notifications", "Receive alerts and updates", _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white10)),
                  _buildSwitchRow("Sound Alerts", "Audio warnings for drowsiness", _soundAlerts, (v) => setState(() => _soundAlerts = v)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionHeader(Icons.settings, "App Preferences"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildSwitchRow("Dark Mode", "Currently enabled", _darkMode, (v) => setState(() => _darkMode = v)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Logout
            ListTile(
              onTap: widget.onLogout,
              tileColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.redAccent, size: 16)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }

  Widget _infoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis), maxLines: 1),
      ]),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.blueAccent,
        ),
      ],
    );
  }
}