import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/auth_error_text.dart';
import '../widgets/common/brand.dart';
import '../widgets/common/footer_link.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _rememberMe = true;
  String? _emailError;
  String? _passError;
  bool _isLoading = false;

  void _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _emailError = null;
      _passError = null;
    });

    final emailText = _emailController.text.trim();
    final passText = _passController.text;

    bool isValid = true;
    if (emailText.isEmpty) {
      setState(() => _emailError = l10n.loginErrEmailRequired);
      isValid = false;
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(emailText)) {
      setState(() => _emailError = l10n.loginErrEmailInvalid);
      isValid = false;
    }

    if (passText.isEmpty) {
      setState(() => _passError = l10n.loginErrPassRequired);
      isValid = false;
    } else if (passText.length < 6) {
      setState(() => _passError = l10n.loginErrPassShort);
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        email: emailText,
        password: passText,
        staySignedIn: _rememberMe,
      );
      widget.onLogin(authProvider.currentUser);
      // Signing in replaces this screen.
      if (mounted) setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(authErrorText(e, AppLocalizations.of(context)!));
    } catch (e) {
      debugPrint('Sign in failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppLocalizations.of(context)!.loginErrUnexpected);
    }
  }

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      setState(() => _emailError = l10n.loginErrResetNeedsEmail);
      return;
    }
    setState(() => _emailError = null);
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginResetSent(email))));
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(authErrorText(e, l10n));
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

  void _navigateToSignup() {
    // ✅ Use push (not pushReplacement) to keep HomeScreen alive
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupScreen(
          onLogin: (user) {
            // If signup successful, login and pop back to home
            widget.onLogin(user);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: LogoTile(size: 60, radius: 18, logoWidth: 38),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.loginHeading,
                          style: AppFonts.display(
                            context,
                            34,
                            color: c.text,
                            tracking: -0.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          style: AppFonts.body(context, 17, color: c.subtext),
                        ),
                        const SizedBox(height: 36),
                        AppTextField(
                          controller: _emailController,
                          label: l10n.loginEmail,
                          hint: 'name@example.com',
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _passController,
                          label: l10n.loginPassword,
                          errorText: _passError,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _RememberMe(
                                value: _rememberMe,
                                label: l10n.loginRememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v),
                              ),
                            ),
                            TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(
                                l10n.loginForgotPassword,
                                style: AppFonts.body(
                                  context,
                                  15,
                                  weight: FontWeight.w600,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        AppButton(
                          label: l10n.loginButton,
                          loading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        FooterLink(
                          prompt: l10n.loginNoAccount,
                          action: l10n.loginSignup,
                          onTap: _navigateToSignup,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }
}

/// 22px rounded checkbox with its label.
class _RememberMe extends StatelessWidget {
  const _RememberMe({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? c.primary : c.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: value ? null : Border.all(color: c.line, width: 1.5),
                ),
                child: value
                    ? AppIcon(
                        Symbols.check_rounded,
                        size: 18,
                        color: c.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: AppFonts.body(
                    context,
                    15,
                    weight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
