import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/auth/screens/lawyer_login_screen.dart';
import 'package:legal_case_manager/services/auth_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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

  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _validityController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  XFile? _panImage;
  XFile? _barFrontImage;
  XFile? _barBackImage;

  // ✅ Store extracted data for "matching" verification
  final Map<String, String> _extractedData = {};

  String? _selectedSpecialization;
  String? _selectedCourtType;
  String? _selectedState;
  String? _selectedDistrict;
  bool _obscurePassword = true;
  bool _isProcessingOCR = false;

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
    _fatherNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _validityController.dispose();
    _panController.dispose();
    super.dispose();
  }

  // ================= UPLOAD LOGIC (PICK SOURCE) =================
  Future<void> _pickImage(String type) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo (Camera)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload Document (Gallery)'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85, // Adjust quality for better OCR balance
    );

    if (image == null) return;

    setState(() {
      if (type == 'pan') _panImage = image;
      if (type == 'bar_front') _barFrontImage = image;
      if (type == 'bar_back') _barBackImage = image;
    });

    // Automatically trigger OCR for PAN or Bar Front
    if (type == 'pan' || type == 'bar_front') {
      _runOCR(image, type);
    }
  }

  // ================= OCR LOGIC (ROBUST PARSING) =================
  Future<void> _runOCR(XFile imageFile, String docType) async {
    setState(() => _isProcessingOCR = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // ✅ Fixed: Use gemini-1.5-flash (not 2.5)
        apiKey: 'AIzaSyDvvT7-BYY6lu4k8MLULnGx9PEISfOzTWA',
      );

      final bytes = await imageFile.readAsBytes();
      
      final prompt = """
      You are an OCR expert. Extract data from this Indian ${docType == 'pan' ? 'PAN Card' : 'Bar Council ID'}. 
      Return ONLY a JSON object with these keys: 
      "Name", "EnrolmentNo", "FatherName", "DOB", "Address", "Validity", "PanNumber". 
      
      Instructions:
      1. Use "PanNumber" for PAN Card number.
      2. Use "EnrolmentNo" for Bar ID number.
      3. For DOB, use format DD/MM/YYYY.
      4. If a field is not present or unreadable, leave it as empty string "".
      5. Return ONLY the raw JSON, no markdown, no explanations.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      String? responseText = response.text;

      if (responseText != null) {
        // Robust JSON extraction
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        
        if (jsonMatch != null) {
          String jsonString = jsonMatch.group(0)!;
          final Map<String, dynamic> data = jsonDecode(jsonString);

          setState(() {
            // Update extracted data map (persistent for matching)
            data.forEach((key, value) {
              if (value != null && value.toString().isNotEmpty) {
                _extractedData[key] = value.toString();
              }
            });

            // Autofill fields
            if (data['Name']?.toString().isNotEmpty == true) _nameController.text = data['Name'].toString();
            if (data['EnrolmentNo']?.toString().isNotEmpty == true) _barIdController.text = data['EnrolmentNo'].toString();
            if (data['FatherName']?.toString().isNotEmpty == true) _fatherNameController.text = data['FatherName'].toString();
            if (data['DOB']?.toString().isNotEmpty == true) _dobController.text = data['DOB'].toString();
            if (data['Address']?.toString().isNotEmpty == true) _addressController.text = data['Address'].toString();
            if (data['Validity']?.toString().isNotEmpty == true) _validityController.text = data['Validity'].toString();
            if (data['PanNumber']?.toString().isNotEmpty == true) _panController.text = data['PanNumber'].toString();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document successfully scanned! Please verify the autofilled details.'), backgroundColor: Colors.green),
          );
        } else {
          throw 'AI returned malformed data';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("OCR Error: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Scanning helper failed. You can still fill the details manually below.'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } finally {
      setState(() => _isProcessingOCR = false);
    }
  }

  // ================= SIGNUP LOGIC =================
  Future<void> _handleSignup() async {
    // Check if images are uploaded
    if (_panImage == null || _barFrontImage == null || _barBackImage == null) {
      _showError('Please upload all 3 required documents for verification.');
      return;
    }

    // Optional Mismatch Check (User can override)
    if (_extractedData.isNotEmpty) {
      List<String> mismatches = [];
      if (_extractedData['Name'] != null && _nameController.text != _extractedData['Name']) mismatches.add('Name');
      if (_extractedData['PanNumber'] != null && _panController.text != _extractedData['PanNumber']) mismatches.add('PAN Number');

      if (mismatches.isNotEmpty) {
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Note'),
            content: Text('The entered ${mismatches.join(", ")} differs from the scanned document. Proceed with manual values?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Fix')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    try {
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
        fatherName: _fatherNameController.text.trim(),
        dob: _dobController.text.trim(),
        address: _addressController.text.trim(),
        validity: _validityController.text.trim(),
        panCardNo: _panController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Pending verification.'), backgroundColor: Colors.orange),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LawyerLoginScreen()));
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                ),
                const Center(child: Text('Lawyer Registration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 20),

                // DOCUMENT UPLOAD SECTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text("Identity Documents (3 Required)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 16),
                      _uploadTile("PAN Card (OCR Reader)", _panImage, () => _pickImage('pan')),
                      const SizedBox(height: 12),
                      _uploadTile("Bar ID Front (OCR Reader)", _barFrontImage, () => _pickImage('bar_front')),
                      const SizedBox(height: 12),
                      _uploadTile("Bar ID Back", _barBackImage, () => _pickImage('bar_back')),
                      if (_isProcessingOCR)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _inputField(hint: 'Full Name', controller: _nameController, ocrKey: 'Name'),
                const SizedBox(height: 16),
                _inputField(hint: 'Father\'s Name', controller: _fatherNameController, ocrKey: 'FatherName'),
                const SizedBox(height: 16),
                _inputField(hint: 'Email Address', controller: _emailController),
                const SizedBox(height: 16),
                _inputField(hint: 'Enrolment No / Bar ID', controller: _barIdController, ocrKey: 'EnrolmentNo'),
                const SizedBox(height: 16),
                _inputField(hint: 'PAN Card Number', controller: _panController, ocrKey: 'PanNumber'),
                const SizedBox(height: 16),
                _inputField(hint: 'Date of Birth (DD/MM/YYYY)', controller: _dobController, ocrKey: 'DOB'),
                const SizedBox(height: 16),
                _inputField(hint: 'Address', controller: _addressController, maxLines: 2, ocrKey: 'Address'),
                const SizedBox(height: 16),

                _dropdownField(
                  label: 'Court Type',
                  value: _selectedCourtType,
                  items: ['Supreme Court', 'High Court', 'District Court'],
                  onChanged: (v) => setState(() { _selectedCourtType = v; _selectedState = null; _selectedDistrict = null; }),
                ),
                const SizedBox(height: 16),
                _dropdownField(label: 'Specialization', value: _selectedSpecialization, items: ['Criminal', 'Civil', 'Corporate', 'Public Interest', 'Immigration', 'Property', 'Family'], onChanged: (v) => setState(() => _selectedSpecialization = v)),
                const SizedBox(height: 16),

                _inputField(hint: 'Create Password', controller: _passwordController, isPassword: true),
                const SizedBox(height: 16),
                _inputField(hint: 'Confirm Password', controller: _confirmPasswordController, isPassword: true),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B2B45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                    onPressed: _handleSignup,
                    child: const Text('SUBMIT FOR VERIFICATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadTile(String label, XFile? image, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: image != null ? Colors.green : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(image != null ? Icons.check_circle : Icons.camera_alt, color: image != null ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: image != null ? Colors.green : Colors.black))),
            if (image != null) const Icon(Icons.visibility, size: 20, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint, 
    required TextEditingController controller, 
    bool isPassword = false, 
    TextInputType keyboardType = TextInputType.text, 
    int maxLines = 1,
    String? ocrKey,
  }) {
    bool isMatched = ocrKey != null && _extractedData.containsKey(ocrKey) && controller.text.trim() == _extractedData[ocrKey]?.trim();

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (v) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isMatched 
            ? const Icon(Icons.verified_user, color: Colors.green, size: 20)
            : (isPassword ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ) : null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
    );
  }

  void _showError(String message) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Required'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }
}
