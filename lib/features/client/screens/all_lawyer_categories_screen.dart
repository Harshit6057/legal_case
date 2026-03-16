import 'package:flutter/material.dart';
// Ensure these paths match your actual project structure
import 'package:legal_case_manager/features/lawyer/screens/lawyer_list_screen.dart';

class AllLawyerCategoriesScreen extends StatelessWidget {
  const AllLawyerCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Standardizing on the primary brand color used in your dashboard
    final Color primaryDark = const Color(0xFF0F172A);

    final categories = [
      {'title': 'Criminal', 'image': 'assets/images/criminal.png', 'key': 'Criminal'},
      {'title': 'Civil', 'image': 'assets/images/civil.png', 'key': 'Civil'},
      {'title': 'Corporate', 'image': 'assets/images/corporate.png', 'key': 'Corporate'},
      {'title': 'Public Interest', 'image': 'assets/images/public.png', 'key': 'Public Interest'},
      {'title': 'Immigration', 'image': 'assets/images/immigration.png', 'key': 'Immigration'},
      {'title': 'Property', 'image': 'assets/images/property.png', 'key': 'Property'},
      {'title': 'Family', 'image': 'assets/images/family.png', 'key': 'Family'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("All Specialists", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75, // Adjusted to prevent text clipping
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final item = categories[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LawyerListScreen(
                      specialization: item['key']!,
                      title: '${item['title']} Lawyers'
                  ))
              ),
              child: Column(
                children: [
                  Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4)
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: Colors.blue, size: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
