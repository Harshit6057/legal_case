import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_case_manager/common/widgets/dashboard_widgets.dart';
import 'package:legal_case_manager/features/profile/screens/profile_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/lawyer_list_screen.dart';
import 'package:legal_case_manager/services/screens/service_category_screen.dart';
import '../../chat/screens/chat_screen.dart';
import 'package:legal_case_manager/common/widgets/movable_ai_button.dart';
import 'package:legal_case_manager/features/client/screens/client_case_notes_view.dart';
import 'package:legal_case_manager/features/client/screens/all_lawyer_categories_screen.dart';
import 'package:legal_case_manager/features/client/screens/explore_search_screen.dart';
import 'package:legal_case_manager/features/client/screens/affidavit_info_screen.dart';
import 'package:legal_case_manager/features/client/screens/documentataion_screen.dart';
import 'package:legal_case_manager/features/chat/screens/legal_chatbot_screen.dart';



class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  final Color primaryDark = const Color(0xFF0F172A);
  final Color accentBlue = const Color(0xFF2563EB);
  final Color backgroundSlate = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return MovableAIButton(
      child: Scaffold(
        backgroundColor: backgroundSlate,
        bottomNavigationBar: _bottomNav(context),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            // ✅ REMOVED 'const' from children to allow method calls
            children: [
              const SizedBox(height: 10),
              const DashboardHeader(),
              const SizedBox(height: 25),
              _banner(),
              const SizedBox(height: 30),
              // ✅ Pass context to enable 'View All' navigation
              _sectionTitle(context, 'Legal Services', 'Business Setup'),
              _servicesGrid(),
              const SizedBox(height: 30),
              _sectionTitle(context, 'Find Specialists', 'view_all_specialists'),
              _lawyerCategoryGrid(context),
              const SizedBox(height: 30),
              _sectionTitle(context, 'Your Conversations', null),
              _conversationsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CONVERSATIONS SECTION =================
  Widget _conversationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('clientId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyConversations();
        }

        final requests = snapshot.data!.docs;
        final uniqueLawyerIds = <String>{};
        final filteredLawyers = requests.where((doc) {
          final lawyerId = (doc.data() as Map<String, dynamic>)['lawyerId'];
          return uniqueLawyerIds.add(lawyerId);
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredLawyers.length,
          itemBuilder: (context, i) {
            final doc = filteredLawyers[i];
            final data = doc.data() as Map<String, dynamic>;
            final String lawyerName = data['lawyerName'] ?? 'Lawyer';
            final String lawyerId = data['lawyerId'] ?? '';
            final String caseId = doc.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUserId: lawyerId,
                      otherUserName: lawyerName,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: accentBlue.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: accentBlue),
                ),
                title: Text(
                  lawyerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text('Tap to open chat', style: TextStyle(fontSize: 13)),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientCaseNotesView(
                          caseId: caseId,
                          lawyerName: lawyerName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accentBlue,
                    elevation: 0,
                    side: BorderSide(color: accentBlue.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text("Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= BANNER (FIXED OVERFLOW) =================
  // ================= BANNER (RESPONSIVE FIX) =================
  Widget _banner() {
    return Container(
      // ✅ Removed fixed height to allow internal content to define size
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Wrap text in Expanded and FittedBox to prevent 207px overflow
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Shrink-wrap the column
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Expert Legal Help',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with top-rated\nlawyers instantly.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // ✅ Image now scales relative to the available space
          Expanded(
            flex: 2,
            child: Image.asset(
              'assets/images/layer1.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.balance, size: 60, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE (FIXED VIEW ALL NAVIGATION) =================
  Widget _sectionTitle(BuildContext context, String title, String? routeKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryDark
            ),
          ),
          // ✅ This button only appears if routeKey is NOT null
          if (routeKey != null)
            GestureDetector(
              onTap: () {
                if (routeKey == 'view_all_specialists') {
                  // ✅ Navigate to a screen showing ALL lawyer categories
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllLawyerCategoriesScreen())
                  );
                } else {
                  // Fallback for other routes if needed
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ServiceCategoryScreen(title: routeKey))
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'View All',
                  style: TextStyle(
                      color: accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= SERVICES GRID =================
  Widget _servicesGrid() {
    final services = [
      ('Business', Icons.bar_chart),
      ('Docs', Icons.description),
      ('Disputes', Icons.gavel),
      ('Consultant', Icons.headset_mic),
      ('Advice', Icons.chat),
      ('Info', Icons.account_balance),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2B45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) {
          final serviceTitle = services[i].$1;

          return GestureDetector(
            onTap: () {
              if (serviceTitle == 'Advice') {
                // ✅ Redirect to Chatbot Screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalChatbotScreen()));
              }
              else if (serviceTitle == 'Consultant') {
                // ✅ Redirect to Lawyers (Specialists Category Screen)
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLawyerCategoriesScreen()));
              }
              else if (serviceTitle == 'Disputes') {
                // ✅ Redirect to Criminal Lawyers (Disputes)
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerListScreen(
                    specialization: 'criminal',
                    title: 'Criminal Disputes'
                )));
              }
              else if (serviceTitle == 'Info') {
                // ✅ Redirect to Affidavits Download/Share Screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AffidavitInfoScreen()));
              }
              else if (serviceTitle == 'Docs') {
                // ✅ Redirect to existing Documentation Screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentationScreen()));
              }
              else {
                // Default redirection for other services
                Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceCategoryScreen(title: serviceTitle)));
              }
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(services[i].$2, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Text(serviceTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= LAWYER CATEGORY GRID =================
  Widget _lawyerCategoryGrid(BuildContext context) {
    final categories = [
      {'title': 'Criminal', 'image': 'assets/images/criminal.png', 'key': 'criminal'},
      {'title': 'Civil', 'image': 'assets/images/civil.png', 'key': 'civil'},
      {'title': 'Corporate', 'image': 'assets/images/corporate.png', 'key': 'corporate'},
    ];

    return Row(
      children: categories.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LawyerListScreen(
                        specialization: item['key']!,
                        title: '${item['title']} Lawyers'
                    )
                )
            ),
            child: Column(
              children: [
                // ✅ Large, clean container for the icon
                Container(
                  height: 85,
                  width: 85,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Image.asset(
                    item['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(Icons.person, color: accentBlue, size: 30),
                  ),
                ),
                const SizedBox(height: 10),
                // ✅ Text is now placed below the container for better visibility
                Text(
                    item['title']!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryDark
                    )
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyConversations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: const Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text('No active conversations', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        currentIndex: 0, // This should normally be a state variable
        selectedItemColor: accentBlue,
        unselectedItemColor: Colors.grey.shade400,
        onTap: (index) {
          if (index == 1) { // ✅ Index 1 is the 'Explore' tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExploreSearchScreen(initialQuery: '',)),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}