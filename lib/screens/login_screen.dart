import 'package:flutter/material.dart';
import '../services/database_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // ✅ Uses Theme Colors for Gradient
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
            padding: const EdgeInsets.all(24),
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
                      Expanded(child: _authToggleBtn("Login", true)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) =>
                                    SignupScreen(onLogin: widget.onLogin),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: _authToggleBtn("Sign Up", false),
                        ),
                      ),
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
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                    Text(
                      "33%",
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
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

                // Login Form
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "Sign in to continue your journey",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildInput(
                            "Email Address",
                            Icons.email_outlined,
                            _emailController,
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            "Password",
                            Icons.lock_outline,
                            _passController,
                            isPassword: true,
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: false,
                                  onChanged: (v) {},
                                  fillColor: MaterialStateProperty.all(
                                    theme.cardColor,
                                  ),
                                  side: BorderSide(color: theme.disabledColor),
                                ),
                              ),
                              Text(
                                "Remember me",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final user = await DatabaseService.instance
                                    .loginUser(
                                      _emailController.text,
                                      _passController.text,
                                    );

                                if (user != null) {
                                  widget.onLogin(user);
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Invalid email or password",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              "By continuing, you agree to our Terms of Service and Privacy Policy",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    return TextField(
      controller: controller,
      obscureText: isPassword,
      // Input style is now handled globally by ThemeService!
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }
}
