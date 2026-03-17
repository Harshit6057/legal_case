import 'package:flutter/material.dart';
import 'package:legal_case_manager/features/client/screens/client_dashboard.dart';
import '../../../common/widgets/dashboard_widgets.dart';
import 'package:legal_case_manager/features/profile/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_case_manager/features/documentation/screens/documentation_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/lawyer_profile_view_screen.dart';

class ServiceCategoryScreen extends StatelessWidget {
  final String title;

  const ServiceCategoryScreen({
    super.key,
    required this.title,
  });

  final Color primaryDark = const Color(0xFF0F172A);
  final Color accentBlue = const Color(0xFF2563EB);
  final Color backgroundSlate = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSlate,
      bottomNavigationBar: _bottomNav(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            const SizedBox(height: 10),
            const DashboardHeader(),
            const SizedBox(height: 25),

            /// CATEGORY TITLE
            _sectionTitle(title.toUpperCase()),
            const SizedBox(height: 16),

            /// SUB SERVICES
            _subServicesGrid(context),

            const SizedBox(height: 30),

            /// RECOMMENDED LAWYERS
            _sectionTitle('Recommended Lawyers'),
            const SizedBox(height: 16),

            _recommendedLawyers(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryDark,
        letterSpacing: 0.5,
      ),
    );
  }

  // ================= SUB SERVICES =================
  Widget _subServicesGrid(BuildContext context) {
    final services = [
      {'title': 'Business Setup', 'icon': 'assets/images/b1.png'},
      {'title': 'Documentation', 'icon': 'assets/images/b2.png'},
      {'title': 'Disputes', 'icon': 'assets/images/b3.png'},
      {'title': 'Legal Aid', 'icon': 'assets/images/b4.png'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) {
        final title = services[i]['title'] as String;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (title == 'Documentation') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentationScreen()));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(services[i]['icon'] as String, height: 40),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recommendedLawyers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'lawyer')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lawyers = snapshot.data!.docs;
        if (lawyers.isEmpty) {
          return Center(
            child: Text('No lawyers available yet', style: TextStyle(color: Colors.grey.shade400)),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lawyers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (_, i) {
            final doc = lawyers[i];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Lawyer';
            final avatarUrl = data['avatarUrl'];
            final int experience = (data['experience'] is int) ? data['experience'] : 0;

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LawyerProfileViewScreen(lawyerId: doc.id),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: avatarUrl != null && avatarUrl != ''
                            ? Image.network(avatarUrl, fit: BoxFit.cover, width: double.infinity)
                            : Container(
                          color: accentBlue.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryDark),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_history_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                '$experience+ Years',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: accentBlue,
        unselectedItemColor: Colors.grey.shade400,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientDashboardScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
