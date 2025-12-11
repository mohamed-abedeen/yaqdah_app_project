import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  // ✅ CHANGED: Callback now accepts user data to pass to Settings
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
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF0F172A)],
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
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                  pageBuilder: (context, anim1, anim2) => LoginScreen(onLogin: widget.onLogin),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero
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

                  // ✅ ADDED: PROGRESS BAR (Step 1 of 3)
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

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Create Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text("Let's start with your basic information", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 24),

                        _buildInput("Full Name", Icons.person_outline, _nameController),
                        const SizedBox(height: 16),
                        _buildInput("Email Address", Icons.email_outlined, _emailController),
                        const SizedBox(height: 16),
                        _buildInput("Phone Number", Icons.phone_outlined, _phoneController),
                        const SizedBox(height: 16),
                        _buildInput("Create Password", Icons.lock_outline, _passController, isPassword: true),

                        const SizedBox(height: 30),
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
                              // ✅ DATABASE REGISTER
                              bool success = await DatabaseService.instance.registerUser(
                                _emailController.text,
                                _passController.text,
                                _nameController.text,
                                _phoneController.text,
                              );

                              if (success) {
                                // Create user map manually to pass to Settings immediately
                                Map<String, dynamic> newUser = {
                                  'fullName': _nameController.text,
                                  'email': _emailController.text,
                                  'phone': _phoneController.text
                                };

                                widget.onLogin(newUser); // ✅ Success: Pass data & Login
                                Navigator.popUntil(context, (route) => route.isFirst);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email already exists!"), backgroundColor: Colors.red));
                              }
                            },
                            child: const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Terms Text
                  const Center(
                    child: Text(
                      "By continuing, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 10),
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