import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/edit_profile_modal.dart';
import '../services/theme_service.dart';
import 'test_mode_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final VoidCallback onLogout;
  final Function(Map<String, dynamic>) onUpdateUser;

  const SettingsScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    required this.onUpdateUser,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state removed - using SettingsProvider

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        user: widget.currentUser,
        onClose: () => Navigator.pop(context),
        onSave: (newName, newEmergency) {
          Map<String, dynamic> updatedUser = Map<String, dynamic>.from(
            widget.currentUser,
          );
          updatedUser['fullName'] = newName;
          updatedUser['emergencyContact'] = newEmergency;

          widget.onUpdateUser(updatedUser);
        },
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

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
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
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
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
                                widget.currentUser['email'] ??
                                    "email@example.com",
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
                    settings.autoEmergency,
                    (v) => settings.setAutoEmergency(v),
                    theme,
                  ),

                  const SizedBox(height: 24),

                  _sectionHeader("الذكاء الاصطناعي"),
                  _buildSwitchCard(
                    "مساعد الذكاء الاصطناعي",
                    "نصائح صوتية تلقائية عند الخطر",
                    Icons.smart_toy,
                    const Color(0xFF009688), // Teal
                    settings.aiAssistance,
                    (v) => settings.setAiAssistance(v),
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
                          settings.notifications,
                          (v) => settings.setNotifications(v),
                          theme,
                        ),
                        if (settings.notifications) ...[
                          Divider(color: theme.dividerColor, height: 1),
                          _buildSwitchItem(
                            "الصوت",
                            "",
                            Icons.volume_up,
                            blue,
                            settings.sound,
                            (v) => settings.setSound(v),
                            theme,
                          ),
                          _buildSwitchItem(
                            "الاهتزاز",
                            "",
                            Icons.vibration,
                            purple,
                            settings.vibration,
                            (v) => settings.setVibration(v),
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
                        Colors.yellow,
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
      },
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
    final isDark = theme.brightness == Brightness.dark;
    final activeSwitchColor = isDark
        ? const Color(0xFFFFC107)
        : const Color.fromRGBO(52, 19, 163, 1);

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
    final isDark = theme.brightness == Brightness.dark;
    final activeSwitchColor = isDark
        ? const Color(0xFFFFC107)
        : const Color.fromARGB(255, 86, 19, 163);

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
