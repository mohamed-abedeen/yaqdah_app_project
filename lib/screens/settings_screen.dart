import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/app_toggle.dart';
import '../widgets/common/brand.dart';
import '../widgets/common/segmented_control.dart';
import '../widgets/edit_profile_modal.dart';
import 'test_mode_screen.dart';

/// Account & settings.
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
  /// The automatic text goes out while the driver can't answer a
  /// permission prompt, so SMS access is asked for when it's turned on.
  Future<void> _setAutoSos(SettingsProvider settings, bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await settings.setAutoEmergency(enabled);
    if (!enabled || !Platform.isAndroid) return;
    if (await Permission.sms.request().isGranted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.smsPermissionNeeded),
        action: SnackBarAction(
          label: l10n.openSettings,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => EditProfileModal(
        user: widget.currentUser,
        onClose: () => Navigator.pop(sheetContext),
        onSave: (newName, newEmergency) {
          // Saves to Firestore and updates the signed-in user.
          context.read<AuthProvider>().updateProfile(
            fullName: newName,
            emergencyContact: newEmergency,
          );
        },
      ),
    );
  }

  void _openLanguagePicker(SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.language,
                  style: AppFonts.display(context, 22, color: c.text),
                ),
              ),
              const SizedBox(height: 12),
              _Group(
                children: [
                  for (final (code, label) in [
                    ('en', l10n.languageEnglish),
                    ('ar', l10n.languageArabic),
                  ])
                    _SettingsRow(
                      title: label,
                      onTap: () {
                        settings.setLocale(code);
                        Navigator.pop(sheetContext);
                      },
                      trailing: settings.locale.languageCode == code
                          ? AppIcon(
                              Symbols.check_rounded,
                              size: 22,
                              color: c.primary,
                            )
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.currentUser['fullName'] as String?)?.trim() ?? '';
    final email = widget.currentUser['email'] as String? ?? '';
    final contact = widget.currentUser['emergencyContact'] as String? ?? '';

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    l10n.accountTitle,
                    style: AppFonts.display(
                      context,
                      30,
                      color: c.text,
                      tracking: -0.02,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Profile ─────────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  radius: 22,
                  child: Row(
                    children: [
                      InitialsAvatar(
                        name: name.isEmpty ? email : name,
                        size: 52,
                        fontSize: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? l10n.userFallbackName : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                context,
                                17,
                                weight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                context,
                                14,
                                color: c.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(11),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _openEditProfile,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.edit,
                              style: AppFonts.body(
                                context,
                                14,
                                weight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Safety ──────────────────────────────────────────────
                _SectionHeader(l10n.sectionSafety),
                _Group(
                  children: [
                    _SettingsRow(
                      title: l10n.autoSosTitle,
                      subtitle: l10n.autoSosSubtitle,
                      trailing: AppToggle(
                        value: settings.autoEmergency,
                        onChanged: (v) => _setAutoSos(settings, v),
                        semanticLabel: l10n.autoSosTitle,
                      ),
                      onTap: () =>
                          _setAutoSos(settings, !settings.autoEmergency),
                    ),
                    _SettingsRow(
                      title: l10n.emergencyContactTitle,
                      value: contact.isEmpty ? l10n.notSet : contact,
                      valueIsLtr: contact.isNotEmpty,
                      chevron: true,
                      onTap: _openEditProfile,
                    ),
                  ],
                ),

                // ── Alerts ──────────────────────────────────────────────
                _SectionHeader(l10n.sectionAlerts),
                _Group(
                  children: [
                    _SettingsRow(
                      title: l10n.voiceAssistant,
                      subtitle: l10n.voiceAssistantSubtitle,
                      trailing: AppToggle(
                        value: settings.aiAssistance,
                        onChanged: settings.setAiAssistance,
                        semanticLabel: l10n.voiceAssistant,
                      ),
                      onTap: () =>
                          settings.setAiAssistance(!settings.aiAssistance),
                    ),
                    _SettingsRow(
                      title: l10n.alarmSound,
                      trailing: AppToggle(
                        value: settings.sound,
                        onChanged: settings.setSound,
                        semanticLabel: l10n.alarmSound,
                      ),
                      onTap: () => settings.setSound(!settings.sound),
                    ),
                    _SettingsRow(
                      title: l10n.vibration,
                      trailing: AppToggle(
                        value: settings.vibration,
                        onChanged: settings.setVibration,
                        semanticLabel: l10n.vibration,
                      ),
                      onTap: () => settings.setVibration(!settings.vibration),
                    ),
                  ],
                ),

                // ── App ─────────────────────────────────────────────────
                _SectionHeader(l10n.sectionApp),
                _Group(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: ThemeService.instance.isDarkMode,
                      builder: (context, isDark, _) => _SettingsRow(
                        title: l10n.appearance,
                        dense: true,
                        trailing: SegmentedControl<bool>(
                          compact: true,
                          segments: [
                            Segment(true, l10n.themeDark),
                            Segment(false, l10n.themeLight),
                          ],
                          selected: isDark,
                          onChanged: (dark) {
                            if (dark != isDark) {
                              ThemeService.instance.toggleTheme();
                            }
                          },
                        ),
                      ),
                    ),
                    _SettingsRow(
                      title: l10n.language,
                      value: settings.locale.languageCode == 'ar'
                          ? l10n.languageArabic
                          : l10n.languageEnglish,
                      chevron: true,
                      onTap: () => _openLanguagePicker(settings),
                    ),
                    _SettingsRow(
                      title: l10n.testLab,
                      value: l10n.testLabValue,
                      chevron: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TestModeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // ── Sign out ────────────────────────────────────────────
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: widget.onLogout,
                    style: TextButton.styleFrom(
                      foregroundColor: c.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text(
                      l10n.signOut,
                      style: AppFonts.body(
                        context,
                        16,
                        weight: FontWeight.w600,
                        color: c.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.overline(context, AppColors.of(context).subtext),
      ),
    );
  }
}

/// Grouped card with 1px dividers between rows.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 20,
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(color: c.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.subtitle,
    this.value,
    this.valueIsLtr = false,
    this.trailing,
    this.chevron = false,
    this.dense = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Current value shown before the chevron.
  final String? value;

  /// Forces left-to-right for values such as phone numbers.
  final bool valueIsLtr;
  final Widget? trailing;
  final bool chevron;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 8 : 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.body(
                    context,
                    16,
                    weight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppFonts.body(
                      context,
                      13,
                      color: c.subtext,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: valueIsLtr ? TextDirection.ltr : null,
                style: AppFonts.body(context, 15, color: c.subtext),
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
          if (chevron) ...[
            const SizedBox(width: 6),
            AppIcon(
              Symbols.chevron_right_rounded,
              size: 20,
              color: c.subtext,
              mirror: true,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
