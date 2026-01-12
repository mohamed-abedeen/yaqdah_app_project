import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const SignupScreen({super.key, required this.onLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // ✅ Uses Theme Colors
            colors: isDark
                ? [
                    theme.colorScheme.background,
                    theme.colorScheme.secondary,
                    theme.colorScheme.background,
                  ]
                : [
                    theme.colorScheme.background,
                    Colors.white,
                    theme.colorScheme.background,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      size: 40,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "yaqdah",
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
                  ),
                  Text(
                    "Your Safety, Our Priority",
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 30),

                  // Toggle Button
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) =>
                                    LoginScreen(onLogin: widget.onLogin),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            ),
                            child: _authToggleBtn("Login", false),
                          ),
                        ),
                        Expanded(child: _authToggleBtn("Sign Up", true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step 1 of 3",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "33%",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.33,
                      minHeight: 6,
                      color: theme.primaryColor,
                      backgroundColor: theme.cardColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Account",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          "Let's start with your basic information",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildInput(
                          "Full Name",
                          Icons.person_outline,
                          _nameController,
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          "Email Address",
                          Icons.email_outlined,
                          _emailController,
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          "Phone Number",
                          Icons.phone_outlined,
                          _phoneController,
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          "Create Password",
                          Icons.lock_outline,
                          _passController,
                          isPassword: true,
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success = await DatabaseService.instance
                                  .registerUser(
                                    _emailController.text,
                                    _passController.text,
                                    _nameController.text,
                                    _phoneController.text,
                                  );

                              if (success) {
                                Map<String, dynamic> newUser = {
                                  'fullName': _nameController.text,
                                  'email': _emailController.text,
                                  'phone': _phoneController.text,
                                };
                                widget.onLogin(newUser);
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Email already exists!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "By continuing, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authToggleBtn(String text, bool isActive) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? theme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : theme.textTheme.bodySmall?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    // Uses Global Theme for styles
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }
}
