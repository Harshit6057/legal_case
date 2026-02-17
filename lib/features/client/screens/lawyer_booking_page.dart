import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LawyerBookingPage extends StatefulWidget {
  final String lawyerId;
  final String lawyerName;

  const LawyerBookingPage({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
  });

  @override
  State<LawyerBookingPage> createState() => _LawyerBookingPageState();
}

class _LawyerBookingPageState extends State<LawyerBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _caseTitleController = TextEditingController();
  final _caseDetailController = TextEditingController();

  String? _selectedHearing;
  int _amount = 0;
  bool _isLoading = false;

  final Color primaryDark = const Color(0xFF0F172A);
  final Color accentBlue = const Color(0xFF2563EB);

  void _calculateAmount(String? type) {
    setState(() {
      _selectedHearing = type;
      _amount = (type == "Fast Hearing") ? 10000 : 5000;
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || _selectedHearing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a hearing type")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser!;
    final String txId = "VIRT_TXN${DateTime.now().millisecondsSinceEpoch}";

    try {
      // ✅ 1. FETCH ACTUAL NAME FROM FIRESTORE
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String actualClientName = userDoc.data()?['name'] ?? "New Client";

      // 2. Create the booking request with the CORRECT name
      await FirebaseFirestore.instance.collection('booking_requests').add({
        'clientId': user.uid,
        'clientName': actualClientName, // ✅ Fixed
        'lawyerId': widget.lawyerId,
        'lawyerName': widget.lawyerName,
        'caseTitle': _caseTitleController.text.trim(),
        'caseDetails': _caseDetailController.text.trim(),
        'status': 'pending',
        'hearingType': _selectedHearing,
        'paymentAmount': _amount,
        'transactionId': txId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Log virtual earnings for lawyer with the CORRECT name
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.lawyerId)
          .collection('earnings')
          .add({
        'amount': _amount,
        'hearingType': _selectedHearing,
        'clientName': actualClientName, // ✅ Fixed
        'timestamp': FieldValue.serverTimestamp(),
        'transactionId': txId,
      });

      if (mounted) {
        _showSuccessDialog(txId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String txId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text("Booking Confirmed!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Case ID: $txId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to profile
              },
              child: const Text("Done"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Book Consultation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("Case Information"),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caseTitleController,
                decoration: _inputStyle("Case Title (e.g. Property Dispute)"),
                validator: (v) => v!.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caseDetailController,
                maxLines: 4,
                decoration: _inputStyle("Briefly explain your legal requirement..."),
                validator: (v) => v!.isEmpty ? "Enter details" : null,
              ),
              const SizedBox(height: 32),
              _sectionHeader("Select Hearing Priority"),
              const SizedBox(height: 12),
              _buildHearingOption("Normal Hearing", 5000, Icons.access_time),
              _buildHearingOption("Fast Hearing", 10000, Icons.bolt),
              const SizedBox(height: 40),
              _buildSummaryCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Confirm Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryDark));
  }

  Widget _buildHearingOption(String title, int price, IconData icon) {
    bool isSelected = _selectedHearing == title;
    return GestureDetector(
      onTap: () => _calculateAmount(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? accentBlue : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentBlue : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text("₹$price", style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: primaryDark, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Virtual Amount", style: TextStyle(color: Colors.white70)),
          Text("₹$_amount", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}