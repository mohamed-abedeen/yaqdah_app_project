import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.settingsTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Profile Card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: const Color.fromARGB(
                          31,
                          112,
                          112,
                          112,
                        ).withValues(alpha: 0.3),
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
                            CupertinoIcons.person_fill,
                            size: 36,
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
                                  l10n.editProfile,
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

                  // ── Emergency ─────────────────────────────────────────────
                  _sectionHeader(l10n.sectionEmergency),
                  _buildSwitchCard(
                    l10n.autoEmergencyTitle,
                    l10n.autoEmergencySubtitle,
                    CupertinoIcons.exclamationmark_triangle_fill,
                    red,
                    settings.autoEmergency,
                    (v) => settings.setAutoEmergency(v),
                    theme,
                  ),

                  const SizedBox(height: 24),

                  // ── AI ────────────────────────────────────────────────────
                  _sectionHeader(l10n.sectionAI),
                  _buildSwitchCard(
                    l10n.aiAssistantTitle,
                    l10n.aiAssistantSubtitle,
                    CupertinoIcons.waveform_path_ecg,
                    const Color(0xFF009688),
                    settings.aiAssistance,
                    (v) => settings.setAiAssistance(v),
                    theme,
                  ),

                  const SizedBox(height: 24),

                  // ── Notifications ─────────────────────────────────────────
                  _sectionHeader(l10n.sectionNotifications),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchItem(
                          l10n.enableNotifications,
                          l10n.notificationsSubtitle,
                          CupertinoIcons.bell_fill,
                          green,
                          settings.notifications,
                          (v) => settings.setNotifications(v),
                          theme,
                        ),
                        if (settings.notifications) ...[
                          Divider(color: theme.dividerColor, height: 1),
                          _buildSwitchItem(
                            l10n.sound,
                            "",
                            CupertinoIcons.speaker_2_fill,
                            blue,
                            settings.sound,
                            (v) => settings.setSound(v),
                            theme,
                          ),
                          _buildSwitchItem(
                            l10n.vibration,
                            "",
                            CupertinoIcons.waveform,
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

                  // ── App Settings ──────────────────────────────────────────
                  _sectionHeader(l10n.sectionAppSettings),
                  ValueListenableBuilder<bool>(
                    valueListenable: ThemeService.instance.isDarkMode,
                    builder: (context, isDark, child) {
                      return _buildSwitchCard(
                        l10n.darkMode,
                        l10n.darkModeSubtitle,
                        CupertinoIcons.moon_stars_fill,
                        Colors.yellow,
                        isDark,
                        (v) => ThemeService.instance.toggleTheme(),
                        theme,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // ── Test Lab ──────────────────────────────────────────────
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
                              color: ThemeService.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.lab_flask_solid,
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
                                  l10n.testLab,
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium!.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.testLabSubtitle,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_forward,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Language ──────────────────────────────────────────────
                  _sectionHeader(l10n.sectionLanguage),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildLanguageTile(
                            label: l10n.languageEnglish,
                            flag: '🇬🇧',
                            langCode: 'en',
                            isSelected: settings.locale.languageCode == 'en',
                            settings: settings,
                            theme: theme,
                            isFirst: true,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: theme.dividerColor,
                        ),
                        Expanded(
                          child: _buildLanguageTile(
                            label: l10n.languageArabic,
                            flag: '🇸🇦',
                            langCode: 'ar',
                            isSelected: settings.locale.languageCode == 'ar',
                            settings: settings,
                            theme: theme,
                            isFirst: false,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Logout ────────────────────────────────────────────────
                  _buildActionCard(
                    l10n.logout,
                    CupertinoIcons.square_arrow_left,
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

  Widget _buildLanguageTile({
    required String label,
    required String flag,
    required String langCode,
    required bool isSelected,
    required SettingsProvider settings,
    required ThemeData theme,
    required bool isFirst,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFFFFC107)
        : const Color.fromRGBO(52, 19, 163, 1);

    return GestureDetector(
      onTap: () => settings.setLocale(langCode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(20) : Radius.zero,
            right: !isFirst ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : theme.textTheme.bodyMedium!.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: activeColor,
                size: 16,
              ),
            ],
          ],
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
              color: color.withValues(alpha: 0.2),
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
            activeThumbColor: activeSwitchColor,
            activeTrackColor: activeSwitchColor.withValues(alpha: 0.3),
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
              color: color.withValues(alpha: 0.2),
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
            activeThumbColor: activeSwitchColor,
            activeTrackColor: activeSwitchColor.withValues(alpha: 0.3),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
