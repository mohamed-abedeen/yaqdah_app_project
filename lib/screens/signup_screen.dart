import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../logic/phone_number.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/auth_error_text.dart';
import '../widgets/common/footer_link.dart';

class SignupScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const SignupScreen({super.key, required this.onLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // State
  bool _isLoading = false;

  // Errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _emergencyError;

  void _handleSignup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _emergencyError = null;
    });

    final nameText = _nameController.text.trim();
    final emailText = _emailController.text.trim();
    final passText = _passwordController.text;
    final confirmPassText = _confirmPasswordController.text;
    final emergencyText = _emergencyContactController.text.trim();
    // Stored in international form: 091 234 5678 → +218912345678.
    final emergencyContact = PhoneNumber.normalize(emergencyText);

    bool isValid = true;

    if (nameText.isEmpty) {
      setState(() => _nameError = l10n.signupErrNameRequired);
      isValid = false;
    }

    if (emailText.isEmpty) {
      setState(() => _emailError = l10n.signupErrEmailRequired);
      isValid = false;
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(emailText)) {
      setState(() => _emailError = l10n.signupErrEmailInvalid);
      isValid = false;
    }

    if (passText.isEmpty) {
      setState(() => _passwordError = l10n.signupErrPassRequired);
      isValid = false;
    } else if (passText.length < 6) {
      setState(() => _passwordError = l10n.signupErrPassShort);
      isValid = false;
    }

    if (confirmPassText.isEmpty) {
      setState(() => _confirmPasswordError = l10n.signupErrConfirmRequired);
      isValid = false;
    } else if (passText != confirmPassText) {
      setState(() => _confirmPasswordError = l10n.signupErrPassMismatch);
      isValid = false;
    }

    if (emergencyText.isEmpty) {
      setState(() => _emergencyError = l10n.signupErrEmergencyRequired);
      isValid = false;
    } else if (emergencyContact == null) {
      setState(() => _emergencyError = l10n.phoneInvalid);
      isValid = false;
    }

    if (!isValid) return;

    // 4. Attempt Registration
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        email: emailText,
        password: passText,
        fullName: nameText,
        emergencyContact: emergencyContact!,
      );

      if (mounted) setState(() => _isLoading = false);

      // Update Parent State (HomeScreen)
      // Note: The onLogin callback (from LoginScreen) pops this screen.
      widget.onLogin(authProvider.currentUser);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(authErrorText(e, AppLocalizations.of(context)!));
    } catch (e) {
      debugPrint('Sign up failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppLocalizations.of(context)!.loginErrUnexpected);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.of(context).danger,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pop(context); // Go back to Login Screen
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: _navigateToLogin,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: AppIcon(
                    Symbols.arrow_back_rounded,
                    color: c.text,
                    mirror: true,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.signupTitle,
                        style: AppFonts.display(
                          context,
                          30,
                          color: c.text,
                          tracking: -0.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.signupSubtitle,
                        style: AppFonts.body(context, 16, color: c.subtext),
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: _nameController,
                        label: l10n.signupFullName,
                        errorText: _nameError,
                        height: 50,
                        labelGap: 6,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _emailController,
                        label: l10n.signupEmail,
                        errorText: _emailError,
                        height: 50,
                        labelGap: 6,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _passwordController,
                        label: l10n.signupPassword,
                        errorText: _passwordError,
                        height: 50,
                        labelGap: 6,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: l10n.signupConfirmPassword,
                        errorText: _confirmPasswordError,
                        height: 50,
                        labelGap: 6,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 22),
                      _EmergencyContactCard(
                        controller: _emergencyContactController,
                        errorText: _emergencyError,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: l10n.signupButton,
                    loading: _isLoading,
                    onPressed: _handleSignup,
                  ),
                  const SizedBox(height: 6),
                  FooterLink(
                    prompt: l10n.signupHaveAccount,
                    action: l10n.signupLogin,
                    onTap: _navigateToLogin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.controller,
    required this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                Symbols.emergency_home_rounded,
                size: 22,
                color: c.danger,
                filled: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.emergencyContactTitle,
                      style: AppFonts.body(
                        context,
                        15,
                        weight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.emergencyContactHelp,
                      style: AppFonts.body(
                        context,
                        14,
                        color: c.subtext,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller,
            errorText: errorText,
            height: 50,
            fill: c.bg,
            hint: '91 234 5678',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            prefix: Container(
              padding: const EdgeInsetsDirectional.only(end: 12),
              margin: const EdgeInsetsDirectional.only(end: 12),
              decoration: BoxDecoration(
                border: BorderDirectional(end: BorderSide(color: c.line)),
              ),
              child: Text(
                PhoneNumber.countryCode,
                textDirection: TextDirection.ltr,
                style: AppFonts.body(context, 16, color: c.subtext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
