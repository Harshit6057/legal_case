import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/auth/screens/lawyer_login_screen.dart';
import 'package:legal_case_manager/services/auth_service.dart';

class LawyerSignupScreen extends StatefulWidget {
  const LawyerSignupScreen({super.key});

  @override
  State<LawyerSignupScreen> createState() => _LawyerSignupScreenState();
}

class _LawyerSignupScreenState extends State<LawyerSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _barIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _barIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= SIGNUP LOGIC =================
  Future<void> _handleSignup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    try {
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'lawyer',
        name: _nameController.text.trim(),
        barCouncilId: _barIdController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lawyer signup successful')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LawyerLoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// BACK BUTTON
            Align(
            alignment: Alignment.centerLeft,
            child:
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),

              const SizedBox(height: 20),

              /// ILLUSTRATION
              Center(
                child: Image.asset(
                  'assets/images/client_signup.png',
                  height: 160,
                ),
              ),

              const SizedBox(height: 24),

              /// TITLE
              const Center(
                child: Text(
                  'Lawyer Sign Up',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _inputField(
                hint: 'Full Name',
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              _inputField(
                hint: 'Email',
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              _inputField(
                hint: 'Bar Council ID',
                controller: _barIdController,
              ),
              const SizedBox(height: 16),

              _inputField(
                hint: 'Password',
                controller: _passwordController,
                isPassword: true,
                toggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 16),

              _inputField(
                hint: 'Confirm Password',
                controller: _confirmPasswordController,
                isPassword: true,
                toggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),

              const SizedBox(height: 24),

              /// SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2B45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _handleSignup,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    VoidCallback? toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: toggle != null
            ? IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: toggle,
        )
            : null,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Signup Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
