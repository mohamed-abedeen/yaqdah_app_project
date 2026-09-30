import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../logic/phone_number.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'common/app_button.dart';
import 'common/app_icon.dart';
import 'common/app_text_field.dart';
import 'common/auth_error_text.dart';
import 'common/brand.dart';

/// Bottom sheet for editing the profile and emergency contact.
class EditProfileModal extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onClose;
  // ✅ NEW: Callback to send updated data back to parent
  final Function(String name, String emergency) onSave;

  const EditProfileModal({
    super.key,
    required this.user,
    required this.onClose,
    required this.onSave, // ✅ Required
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _emergencyController;

  bool _showPasswordFields = false;
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  String? _emergencyError;
  String? _currentPassError;
  String? _newPassError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['fullName']);
    _emailController = TextEditingController(text: widget.user['email']);
    _emergencyController = TextEditingController(
      text: widget.user['emergencyContact'],
    );
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();

    // Stored in international form; an empty field clears the contact.
    final emergencyText = _emergencyController.text.trim();
    final emergency = emergencyText.isEmpty
        ? ''
        : PhoneNumber.normalize(emergencyText);
    final currentPass = _currentPassController.text;
    final newPass = _newPassController.text;
    final changingPassword =
        _showPasswordFields && (currentPass.isNotEmpty || newPass.isNotEmpty);

    setState(() {
      _emergencyError = emergency == null ? l10n.phoneInvalid : null;
      _currentPassError = changingPassword && currentPass.isEmpty
          ? l10n.loginErrPassRequired
          : null;
      _newPassError = changingPassword && newPass.length < 6
          ? l10n.loginErrPassShort
          : null;
    });
    if (emergency == null ||
        _currentPassError != null ||
        _newPassError != null) {
      return;
    }

    if (changingPassword) {
      setState(() => _saving = true);
      try {
        await auth.changePassword(
          currentPassword: currentPass,
          newPassword: newPass,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _currentPassError = l10n.currentPasswordWrong;
          } else if (e.code == 'weak-password') {
            _newPassError = l10n.signupErrWeakPassword;
          } else {
            _currentPassError = authErrorText(e, l10n);
          }
        });
        return;
      } catch (e) {
        debugPrint('Change password failed: $e');
        if (!mounted) return;
        setState(() {
          _saving = false;
          _currentPassError = l10n.loginErrUnexpected;
        });
        return;
      }
    }

    // ✅ Notify parent about the change immediately
    widget.onSave(_nameController.text.trim(), emergency);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          changingPassword ? l10n.passwordChanged : l10n.profileUpdated,
        ),
      ),
    );
    if (mounted) widget.onClose();
  }

  Future<void> _deleteData() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.user['id']?.toString();
    if (userId == null) return;
    // Only this account's trips, and only on this phone.
    await DatabaseService.instance.deleteAllTrips(userId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.allDataDeleted)));
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
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
          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.editProfileTitle,
                        style: AppFonts.display(context, 24, color: c.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.editProfileSubtitle,
                        style: AppFonts.body(context, 15, color: c.subtext),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: AppIcon(Symbols.close_rounded, color: c.subtext),
                ),
              ],
            ),
          ),

          // Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: l10n.signupFullName,
                    height: 50,
                    labelGap: 6,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _emailController,
                    label: l10n.signupEmail,
                    height: 50,
                    labelGap: 6,
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _emergencyController,
                    label: l10n.emergencyContactTitle,
                    height: 50,
                    labelGap: 6,
                    keyboardType: TextInputType.phone,
                    errorText: _emergencyError,
                  ),
                  const SizedBox(height: 20),

                  // Password Section
                  if (!_showPasswordFields)
                    _ActionRow(
                      icon: Symbols.lock_rounded,
                      title: l10n.changePassword,
                      color: c.text,
                      onTap: () => setState(() => _showPasswordFields = true),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.changePassword,
                            style: AppFonts.body(
                              context,
                              16,
                              weight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showPasswordFields = false),
                          style: TextButton.styleFrom(
                            foregroundColor: c.subtext,
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _currentPassController,
                      label: l10n.currentPassword,
                      height: 50,
                      labelGap: 6,
                      isPassword: true,
                      errorText: _currentPassError,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _newPassController,
                      label: l10n.newPassword,
                      height: 50,
                      labelGap: 6,
                      isPassword: true,
                      errorText: _newPassError,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Delete Data
                  _ActionRow(
                    icon: Symbols.delete_forever_rounded,
                    title: l10n.deleteAllData,
                    subtitle: l10n.deleteAllDataSubtitle,
                    color: c.danger,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ),

          // Save Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: AppButton(
                label: l10n.saveChanges,
                onPressed: _handleSave,
                loading: _saving,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDataConfirmTitle),
        content: Text(l10n.deleteDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: c.subtext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteData();
            },
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                background: c.surface2,
                foreground: color,
                size: 40,
                radius: 12,
                iconSize: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.body(
                        context,
                        16,
                        weight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppFonts.body(context, 13, color: c.subtext),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
