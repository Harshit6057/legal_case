import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/auth/screens/entry_choice_screen.dart';
import 'package:legal_case_manager/services/auth_service.dart';
import 'package:legal_case_manager/services/google_auth_service.dart';
import 'package:legal_case_manager/features/auth/screens/lawyer_home_wrapper.dart';
import 'package:legal_case_manager/features/auth/screens/lawyer_signup_screen.dart';


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
          MaterialPageRoute(builder: (_) => const LawyerHomeWrapper()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        _showError('This account is registered as a $role. Please use the correct login portal.');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.code == 'wrong-password' ? 'Incorrect password' : 'Login failed');
    } catch (e) {
      _showError(e.toString());
    }
  }

// ================= GOOGLE LOGIN =================
  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);

    try {
      final user = await GoogleAuthService().signInWithGoogle();

      if (user != null) {
        // ✅ Check if user exists in Firestore
        final exists = await AuthService().checkIfUserExists(user.uid);

        if (!exists) {
          // If user doesn't exist, they MUST sign up first
          await GoogleAuthService().signOut();

          if (!mounted) return;

          _showWarningDialog(
            title: 'No Account Found',
            message: 'This Google email is not registered yet. Please sign up first.',
            onConfirm: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LawyerSignupScreen()),
              );
            },
          );
          return;
        }

        final role = await AuthService().getUserRole(user.uid);

        if (!mounted) return;

        if (role == 'lawyer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LawyerHomeWrapper()),
          );
        } else {
          // Registered with a different role
          await GoogleAuthService().signOut();
          _showError('This email is already registered as a $role. Please use the ${role[0].toUpperCase()}${role.substring(1)} portal.');
        }
      }
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
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

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (e) {
      _showError('Failed to send reset email');
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

  void _showWarningDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
