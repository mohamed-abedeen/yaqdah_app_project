import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/edit_profile_modal.dart';
import '../services/theme_service.dart';
import 'test_mode_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _autoEmergency = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifications = prefs.getBool('notifications_enabled') ?? true;
        _sound = prefs.getBool('sound_enabled') ?? true;
        _vibration = prefs.getBool('vibration_enabled') ?? true;
        _autoEmergency = prefs.getBool('auto_emergency') ?? false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        user: widget.currentUser,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium!.color!;
    final green = theme.primaryColor;
    final red = theme.colorScheme.error;
    final purple = ThemeService.purple;
    final blue = ThemeService.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "الإعدادات",
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "إدارة حسابك والتطبيق",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  ),
                  border: Border.all(
                    color: const Color.fromARGB(
                      31,
                      112,
                      112,
                      112,
                    ).withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 91, 89, 92),

                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentUser['fullName'] ?? "User",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.currentUser['email'] ?? "email@example.com",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _openEditProfile,
                            child: Text(
                              "تعديل الملف الشخصي",
                              style: TextStyle(
                                color: purple,
                                // decoration: TextDecoration.underline,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader("إعدادات الطوارئ"),
              _buildSwitchCard(
                "اتصال طوارئ تلقائي",
                "عند النعاس الشديد",
                Icons.warning_amber,
                red,
                _autoEmergency,
                (v) {
                  setState(() => _autoEmergency = v);
                  _updateSetting('auto_emergency', v);
                },
                theme,
              ),

              const SizedBox(height: 24),

              _sectionHeader("الإشعارات"),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildSwitchItem(
                      "تفعيل الإشعارات",
                      "تنبيهات النعاس والتحذيرات",
                      Icons.notifications,
                      green,
                      _notifications,
                      (v) {
                        setState(() => _notifications = v);
                        _updateSetting('notifications_enabled', v);
                      },
                      theme,
                    ),
                    if (_notifications) ...[
                      Divider(color: theme.dividerColor, height: 1),
                      _buildSwitchItem(
                        "الصوت",
                        "",
                        Icons.volume_up,
                        blue,
                        _sound,
                        (v) {
                          setState(() => _sound = v);
                          _updateSetting('sound_enabled', v);
                        },
                        theme,
                      ),
                      _buildSwitchItem(
                        "الاهتزاز",
                        "",
                        Icons.vibration,
                        purple,
                        _vibration,
                        (v) {
                          setState(() => _vibration = v);
                          _updateSetting('vibration_enabled', v);
                        },
                        theme,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionHeader("إعدادات التطبيق"),
              ValueListenableBuilder<bool>(
                valueListenable: ThemeService.instance.isDarkMode,
                builder: (context, isDark, child) {
                  return _buildSwitchCard(
                    "المظهر الداكن",
                    "تغيير مظهر التطبيق",
                    Icons.dark_mode,
                    Colors
                        .yellow, // Using Yellow for the icon in Dark Mode context
                    isDark,
                    (v) => ThemeService.instance.toggleTheme(),
                    theme,
                  );
                },
              ),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestModeScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeService.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bug_report,
                          color: ThemeService.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "اختبار النظام (Test Lab)",
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium!.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "مشاهدة بيانات المودل مباشرة",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _sectionHeader("منطقة الخطر"),
              _buildActionCard(
                "تسجيل الخروج",
                Icons.logout,
                red,
                widget.onLogout,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    // ✅ Logic: Yellow for Dark Mode, Green for Light Mode
    final isDark = theme.brightness == Brightness.dark;
    final activeSwitchColor = isDark
        ? const Color(0xFFFFC107) // Yellow/Gold
        : const Color.fromRGBO(52, 19, 163, 1); // Green

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // ✅ Applied Dynamic Color
            activeColor: activeSwitchColor,
            activeTrackColor: activeSwitchColor.withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: theme.dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    // ✅ Logic: Yellow for Dark Mode, Green for Light Mode
    final isDark = theme.brightness == Brightness.dark;
    final activeSwitchColor = isDark
        ? const Color(0xFFFFC107) // Yellow/Gold
        : const Color.fromARGB(255, 86, 19, 163); // Green

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // ✅ Applied Dynamic Color
            activeColor: activeSwitchColor,
            activeTrackColor: activeSwitchColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
