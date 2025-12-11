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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF0F172A)],
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
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.monitor_heart_outlined, size: 40, color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                const Text("yaqdah", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("Your Safety, Our Priority", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // Toggle Button
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(child: _authToggleBtn("Login", true)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) => SignupScreen(onLogin: widget.onLogin),
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
                    const Text("Step 1 of 3", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text("33%", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.33,
                    minHeight: 6,
                    color: Colors.blueAccent,
                    backgroundColor: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Form
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome Back", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text("Sign in to continue your journey", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 24),

                          _buildInput("Email Address", Icons.email_outlined, _emailController),
                          const SizedBox(height: 16),
                          _buildInput("Password", Icons.lock_outline, _passController, isPassword: true),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: false,
                                  onChanged: (v){},
                                  fillColor: MaterialStateProperty.all(const Color(0xFF1E293B)),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                              ),
                              const Text("Remember me", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const Spacer(),
                              TextButton(onPressed: () {}, child: const Text("Forgot Password?", style: TextStyle(color: Colors.blueAccent, fontSize: 12))),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // --- SIGN IN BUTTON (UPDATED) ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: Colors.blue.withOpacity(0.4),
                              ),
                              onPressed: () async {
                                final user = await DatabaseService.instance.loginUser(
                                    _emailController.text,
                                    _passController.text
                                );

                                if (user != null) {
                                  // 1. Tell App we are logged in
                                  widget.onLogin(user);

                                  // 2. ✅ CRITICAL FIX: Clear the screen stack!
                                  // This forces the Login/Signup screens to close and reveals the Home Screen.

                                    Navigator.of(context).popUntil((route) => route.isFirst);

                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Invalid email or password"), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              child: const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          // -------------------------------

                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              "By continuing, you agree to our Terms of Service and Privacy Policy",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          )
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF2563EB) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildInput(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}