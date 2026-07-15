import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
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

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String? _emailError;
  String? _passError;
  bool _isLoading = false;

  // Design Colors
  final Color _bgColor = const Color(0xFF1E1E1E);
  final Color _cardColor = const Color(0xFF2A2A2A);
  final Color _borderColor = const Color(0xFF3A3A3A);
  final Color _accentColor = const Color(0xFFF2D84C); // Gold
  final Color _accentColorDark = const Color(0xFFE5C943);

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
      await authProvider.signIn(email: emailText, password: passText);

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', emailText);
      }

      setState(() => _isLoading = false);
      widget.onLogin(authProvider.currentUser);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = l10n.loginErrNotFound;
            break;
          case 'wrong-password':
          case 'invalid-credential':
            message = l10n.loginErrWrongPass;
            break;
          case 'too-many-requests':
            message = l10n.loginErrTooMany;
            break;
          default:
            message = '${l10n.loginErrGeneric}: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.loginErrUnexpected}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'images/yaqdah-05.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => Icon(
                        CupertinoIcons.heart_fill,
                        color: _accentColor,
                        size: 60,
                      ),
                    ),
                  ),
                  Text(
                    l10n.loginTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // --- Login Form Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.loginHeading,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel(l10n.loginEmail, CupertinoIcons.mail),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: "example@email.com",
                          errorText: _emailError,
                          inputType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel(
                          l10n.loginPassword,
                          CupertinoIcons.lock_fill,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passController,
                          hint:
                              "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022",
                          errorText: _passError,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: _accentColor,
                                    side: const BorderSide(color: Colors.grey),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.loginRememberMe,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _accentColor,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                l10n.loginForgotPassword,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Login Button ---
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentColor, _accentColorDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.arrow_right_circle_fill,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.loginButton,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.loginNoAccount,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _navigateToSignup,
                        child: Text(
                          l10n.loginSignup,
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null ? Colors.red : _borderColor,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: inputType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? CupertinoIcons.eye_fill
                            : CupertinoIcons.eye_slash_fill,
                        color: Colors.grey,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
