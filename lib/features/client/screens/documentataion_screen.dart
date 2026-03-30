import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

// ✅ FIXED: Renamed from _EditProfileScreenState to match the class above
class _DocumentationScreenState extends State<DocumentationScreen> {
  final Color primaryDark = const Color(0xFF0F172A);
  final Color accentBlue = const Color(0xFF2563EB);
  final Color backgroundSlate = const Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _requiredDocs = [
    {'title': 'Identity Proof', 'subtitle': 'Aadhar, Pan, or Passport', 'status': 'Missing'},
    {'title': 'Address Proof', 'subtitle': 'Voter ID or Utility Bill', 'status': 'Pending'},
    {'title': 'Marriage Certificate', 'subtitle': 'If applicable for case', 'status': 'Verified'},
  ];

  Future<void> _pickAndUploadDoc(String docTitle) async {
    // Implementation for picking local files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      // ✅ FIXED: Check if the widget is still mounted before using context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Uploading $docTitle..."),
          backgroundColor: accentBlue,
        ),
      );
      // Future logic for saving to local storage or Firestore goes here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: AppBar(
        title: const Text("Legal Vault", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _sectionTitle("Required Documents"),
          const SizedBox(height: 12),
          // ✅ FIXED: Removed Unnecessary .toList() inside spread
          ..._requiredDocs.map((doc) => _buildDocTile(doc)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accentBlue, const Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Secure Storage", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Your documents are encrypted and shared only with your lawyer.",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryDark),
    );
  }

  Widget _buildDocTile(Map<String, dynamic> doc) {
    Color statusColor = doc['status'] == 'Verified' ? Colors.green :
    doc['status'] == 'Pending' ? Colors.orange : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.description_outlined, color: statusColor),
        ),
        title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(doc['subtitle'], style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: Icon(Icons.cloud_upload_outlined, color: accentBlue),
          onPressed: () => _pickAndUploadDoc(doc['title']),
        ),
      ),
    );
  }
}