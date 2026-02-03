import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/auth/screens/entry_choice_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/lawyer_dashboard.dart';
import 'package:legal_case_manager/services/auth_service.dart';
import 'package:legal_case_manager/services/google_auth_service.dart';

class LawyerLoginScreen extends StatefulWidget {
  const LawyerLoginScreen({super.key});

  @override
  State<LawyerLoginScreen> createState() => _LawyerLoginScreenState();
}

class _LawyerLoginScreenState extends State<LawyerLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= EMAIL LOGIN =================
  Future<void> _handleEmailLogin() async {
    try {
      final user = await AuthService().loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final role = await AuthService().getUserRole(user.uid);

      if (!mounted) return;

      if (role == 'lawyer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LawyerDashboardScreen(),
          ),
        );
      } else {
        _showError('This account is not a lawyer account');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.code == 'wrong-password'
          ? 'Incorrect password'
          : 'Login failed');
    }
  }



  // ================= GOOGLE LOGIN =================
  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);

    try {
      final user = await GoogleAuthService().signInWithGoogle();

      if (user != null) {
        await AuthService().saveGoogleUserIfNew(
          user: user,
          role: 'lawyer',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LawyerDashboardScreen(),
          ),
        );
      }

    } catch (_) {
      _showError('Google Sign-In failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= FORGOT PASSWORD =================
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email first');
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
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
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child:
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EntryChoiceScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Image.asset(
                'assets/images/client_login.png',
                height: 160,
              ),

              const SizedBox(height: 24),

              const Text(
                'Lawyer Login',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              _inputField(
                hint: 'Email',
                controller: _emailController,
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

              /// FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: 24),

              _primaryButton('Login', onTap: _handleEmailLogin),

              const SizedBox(height: 24),

              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Or continue with'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              _googleButton(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS =================
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

  Widget _primaryButton(String text, {required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B2B45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _handleGoogleLogin,
        icon: Image.asset(
          'assets/images/google.png',
          height: 20,
        ),
        label: _loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text('Continue with Gmail'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Error'),
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
