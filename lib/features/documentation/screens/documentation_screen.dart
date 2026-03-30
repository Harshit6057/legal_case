import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/dashboard_widgets.dart';
import 'legal_notices_screen.dart';
import 'agreements_screen.dart';
import 'attorney_screen.dart';
import 'package:legal_case_manager/features/client/screens/client_dashboard.dart';
import 'package:legal_case_manager/features/profile/screens/profile_screen.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  final List<File> _uploadedDocs = [];

  Future<void> _pickDocument() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _uploadedDocs.add(File(picked.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      bottomNavigationBar: _bottomNav(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DashboardHeader(),
            const SizedBox(height: 20),

            const Text(
              'Documentations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// CATEGORIES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _docCategory(
                  title: 'Legal Notices',
                  image: 'assets/images/legal.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LegalNoticesScreen()),
                  ),
                ),
                _docCategory(
                  title: 'Agreements',
                  image: 'assets/images/agreements.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AgreementsScreen()),
                  ),
                ),
                _docCategory(
                  title: 'Attorney',
                  image: 'assets/images/attorney.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AttorneyScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// UPLOADED DOCS
            const Text(
              'Uploaded Pictures',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _uploadedDocs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _uploadedDocs[i],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            /// ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _pickDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Upload'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Documents submitted')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _docCategory({
    required String title,
    required String image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(image),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}
