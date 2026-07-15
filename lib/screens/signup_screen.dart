import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _emergencyError;

  // Design Colors
  final Color _bgColor = const Color(0xFF1E1E1E);
  final Color _cardColor = const Color(0xFF2A2A2A);
  final Color _borderColor = const Color(0xFF3A3A3A);
  final Color _accentColor = const Color(0xFFF2D84C); // Gold
  final Color _accentColorDark = const Color(0xFFE5C943);

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
    } else if (!RegExp(r'^\d+$').hasMatch(emergencyText)) {
      setState(() => _emergencyError = l10n.signupErrEmergencyNumbers);
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
        emergencyContact: emergencyText,
      );

      setState(() => _isLoading = false);

      // Update Parent State (HomeScreen)
      // Note: The onLogin callback (from LoginScreen) already handles
      // popping both screens, so we do NOT call Navigator.pop here.
      widget.onLogin(authProvider.currentUser);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = l10n.signupErrEmailInUse;
            break;
          case 'weak-password':
            message = l10n.signupErrWeakPassword;
            break;
          case 'invalid-email':
            message = l10n.signupErrEmailInvalid;
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

  void _navigateToLogin() {
    Navigator.pop(context); // Go back to Login Screen
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            // ✅ Fix: Use ConstrainedBox for width limits
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // --- Logo & Header ---
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'images/yaqdah-05.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => Icon(
                        Icons.monitor_heart,
                        color: _accentColor,
                        size: 60,
                      ),
                    ),
                  ),
                  const Text(
                    "إنشاء حساب جديد",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // --- Form Card ---
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
                          "التسجيل",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        _buildLabel("الاسم الكامل", Icons.person_outline),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: "أحمد محمد",
                          errorText: _nameError,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildLabel("البريد الإلكتروني", Icons.email_outlined),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: "example@email.com",
                          inputType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _buildLabel("كلمة المرور", Icons.lock_outline),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: "••••••••",
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onVisibilityToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        _buildLabel("تأكيد كلمة المرور", Icons.lock_outline),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: "••••••••",
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onVisibilityToggle: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                          errorText: _confirmPasswordError,
                        ),
                        const SizedBox(height: 16),

                        // Emergency Contact
                        _buildLabel("رقم الطوارئ", Icons.phone_outlined),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emergencyContactController,
                          hint: "966501234567",
                          inputType: TextInputType.phone,
                          errorText: _emergencyError,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Signup Button ---
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
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  "إنشاء حساب",
                                  style: TextStyle(
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

                  // --- Login Link ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "لديك حساب بالفعل؟ ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
}
