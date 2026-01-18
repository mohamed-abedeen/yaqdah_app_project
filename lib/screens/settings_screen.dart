import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUser;

  const SettingsScreen({
    super.key,
    required this.onLogout,
    required this.currentUser,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _displayName;
  // late String _displayPhone; // ❌ Removed
  late String _displayEmail;
  late String _displayEmergencyContact;

  bool _pushNotifications = true;
  bool _soundAlerts = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.currentUser['fullName'] ?? "Driver";
    // _displayPhone = widget.currentUser['phone'] ?? "No Phone"; // ❌ Removed
    _displayEmail = widget.currentUser['email'] ?? "No Email";
    _displayEmergencyContact = widget.currentUser['emergencyContact'] ?? "";

    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pushNotifications = prefs.getBool('pushNotifications') ?? true;
        _soundAlerts = prefs.getBool('soundAlerts') ?? true;
      });
    }
  }

  Future<void> _saveLocalPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName);
    // final phoneController = TextEditingController(text: _displayPhone); // ❌ Removed
    final emergencyController = TextEditingController(
      text: _displayEmergencyContact,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "Edit Profile",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 10),
              // ❌ Removed Phone TextField
              TextField(
                controller: emergencyController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: "Emergency Contact",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // ✅ Updated updateUser call (No Phone)
              await DatabaseService.instance.updateUser(
                _displayEmail,
                nameController.text,
                emergencyController.text,
              );

              setState(() {
                _displayName = nameController.text;
                _displayEmergencyContact = emergencyController.text;
                // _displayPhone = phoneController.text; // ❌ Removed
              });

              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile Updated Successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Sign Out", style: Theme.of(context).textTheme.bodyMedium),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService.instance.isDarkMode.value;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Text(
              "Manage your account and preferences",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 1. PROFILE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _displayEmail,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Verified Driver",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _infoBox(
                          Icons.email_outlined,
                          "Email",
                          _displayEmail,
                          Colors.blue,
                          context,
                        ),
                      ),
                      // ❌ Removed Phone InfoBox
                      // const SizedBox(width: 10),
                      // Expanded(
                      //   child: _infoBox(Icons.phone_outlined, "Phone", _displayPhone, Colors.green, context),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _infoBox(
                          Icons.contact_emergency_outlined,
                          "Emergency Contact",
                          _displayEmergencyContact.isEmpty
                              ? "Not Set"
                              : _displayEmergencyContact,
                          Colors.redAccent,
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showEditProfileDialog,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. ALERTS SECTION
            _sectionHeader(
              Icons.notifications_none,
              "Alerts & Notifications",
              textColor,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    "Push Notifications",
                    "Receive alerts and updates",
                    _pushNotifications,
                    (v) {
                      setState(() => _pushNotifications = v);
                      _saveLocalPreference('pushNotifications', v);
                    },
                    textColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  _buildSwitchRow(
                    "Sound Alerts",
                    "Audio warnings for drowsiness",
                    _soundAlerts,
                    (v) {
                      setState(() => _soundAlerts = v);
                      _saveLocalPreference('soundAlerts', v);
                    },
                    textColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. PREFERENCES SECTION
            _sectionHeader(Icons.settings, "App Preferences", textColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSwitchRow("Dark Mode", "Toggle app theme", isDarkMode, (
                    val,
                  ) {
                    setState(() {
                      ThemeService.instance.setDarkMode(val);
                    });
                  }, textColor),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. LOGOUT BUTTON
            ListTile(
              onTap: _showLogoutConfirmation,
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.redAccent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _infoBox(
    IconData icon,
    String label,
    String value,
    Color iconColor,
    BuildContext context,
  ) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textCol = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: textCol,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color textColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
