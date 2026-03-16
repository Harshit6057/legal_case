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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _barIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedSpecialization;
  String? _selectedCourtType;
  String? _selectedState;
  String? _selectedDistrict;
  bool _obscurePassword = true;

  // ✅ Data for India (Expand these lists as needed)
  final List<String> _states = ['Maharashtra', 'Delhi', 'Karnataka', 'Gujarat', 'Uttar Pradesh'];
  final Map<String, List<String>> _districts = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane'],
    'Delhi': ['North Delhi', 'South Delhi', 'Central Delhi', 'West Delhi'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Prayagraj'],
  };

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // ✅ Using the updated AuthService with location & status variables
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'lawyer',
        name: _nameController.text.trim(),
        barCouncilId: _barIdController.text.trim(),
        specialization: _selectedSpecialization,
        courtType: _selectedCourtType,
        state: _selectedState,
        district: _selectedDistrict,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted. Profile under review.'),
          backgroundColor: Colors.orange,
        ),
      );

      // Redirect to login; the home screen will handle the "Hold" state via StreamBuilder
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LawyerLoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    } catch (e) {
      _showError('An unexpected error occurred');
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/images/client_signup.png',
                    height: 140,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Lawyer Sign Up',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                _inputField(
                  hint: 'Full Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Full name is required';
                    if (value.trim().length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _inputField(
                  hint: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _inputField(
                  hint: 'Bar Council ID (e.g., MAH/123/2023)',
                  controller: _barIdController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Bar Council ID is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Court Type Dropdown
                _dropdownField(
                  label: 'Court Type',
                  value: _selectedCourtType,
                  items: ['Supreme Court', 'High Court', 'District Court'],
                  onChanged: (v) => setState(() {
                    _selectedCourtType = v;
                    _selectedState = null;
                    _selectedDistrict = null;
                  }),
                ),
                const SizedBox(height: 16),

                // State Dropdown (Shown for High & District Courts)
                if (_selectedCourtType == 'High Court' || _selectedCourtType == 'District Court') ...[
                  _dropdownField(
                    label: 'Select State',
                    value: _selectedState,
                    items: _states,
                    onChanged: (v) => setState(() {
                      _selectedState = v;
                      _selectedDistrict = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // District Dropdown (Only for District Court)
                if (_selectedCourtType == 'District Court' && _selectedState != null) ...[
                  _dropdownField(
                    label: 'Select District',
                    value: _selectedDistrict,
                    items: _districts[_selectedState!] ?? [],
                    onChanged: (v) => setState(() => _selectedDistrict = v),
                  ),
                  const SizedBox(height: 16),
                ],

                _dropdownField(
                  label: 'Specialization',
                  value: _selectedSpecialization,
                  items: ['Criminal', 'Civil', 'Corporate', 'Public Interest', 'Immigration', 'Property', 'Family'],
                  onChanged: (v) => setState(() => _selectedSpecialization = v),
                ),
                const SizedBox(height: 16),

                _inputField(
                  hint: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                _inputField(
                  hint: 'Confirm Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2B45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: _handleSignup,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= REUSABLE WIDGETS =================
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: toggle != null
            ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selection required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}