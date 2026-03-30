import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_requests_screen.dart';
import '../../../features/lawyer/screens/lawyer_profile_edit_screen.dart';
import '../../../features/lawyer/screens/active_cases_screen.dart';
import 'schedule_view_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/cases_history_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/earnings_screen.dart';
import 'package:legal_case_manager/features/chat/screens/chat_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/case_notes_selection_screen.dart';
import '../../../common/state/avatar_cache.dart'; // Ensure this import is present
import 'package:legal_case_manager/features/lawyer/screens/notifications_screen.dart';


class LawyerDashboardScreen extends StatelessWidget {
  const LawyerDashboardScreen({super.key});

  final Color primaryDark = const Color(0xFF0F172A); // Midnight Blue
  final Color accentBlue = const Color(0xFF2563EB); // Royal Blue
  final Color background = const Color(0xFFF8FAFC); // Soft Slate

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _bottomNav(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            const SizedBox(height: 10),
            _buildProfessionalHeader(context), // Passed context to handle navigation
            const SizedBox(height: 25),
            _buildPremiumBanner(),
            const SizedBox(height: 30),
            _sectionTitle('Quick Actions'),
            const SizedBox(height: 15),
            _buildActionGrid(context),
            const SizedBox(height: 35),
            _sectionTitle('Recent Conversations'),
            const SizedBox(height: 10),
            _conversationsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // 1. Handle Loading/Error states
        String displayName = "Advocate";
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['name'] ?? "Advocate";
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Profile Circle
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LawyerProfileEditScreen(lawyerId: uid)),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: accentBlue.withOpacity(0.1),
                    backgroundImage: AvatarCache.image != null ? FileImage(AvatarCache.image!) : null,
                    child: AvatarCache.image == null
                        ? Icon(Icons.person, color: accentBlue, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome Back,",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    // ✅ DYNAMIC NAME DISPLAY
                    Text(
                      displayName,
                      style: TextStyle(
                          color: primaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: primaryDark, size: 22),
                onPressed: () {
                  // ✅ NAVIGATE TO NOTIFICATIONS
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Practice Manager',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Streamline your cases and client communications.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.balance_rounded,
              size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      children: [
        _newRequestsCard(context),
        _modernActionCard(context, 'Active Cases', Icons.folder_copy_rounded,
            const ActiveCasesScreen()),
        _modernActionCard(context, 'Schedule', Icons.event_note_rounded,
            const ScheduleViewScreen()),
        _modernActionCard(context, 'History', Icons.assignment_turned_in_rounded,
            const CasesHistoryScreen()),
        _modernActionCard(context, 'Earnings', Icons.payments_rounded,
            const EarningsScreen()),
        _modernActionCard(context, 'Case Notes', Icons.description_rounded,
            const CaseNotesSelectionScreen()),
      ],
    );
  }

  Widget _newRequestsCard(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewRequestsScreen())),
          child: Container(
            decoration: _cardDecoration(),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_unread_rounded,
                          size: 32, color: accentBlue),
                      const SizedBox(height: 8),
                      const Text('New Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modernActionCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: accentBlue),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryDark,
          letterSpacing: 0.3),
    );
  }

  Widget _conversationsSection() {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('lawyerId', isEqualTo: lawyerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final allDocs = snapshot.data!.docs;
        final seenClientIds = <String>{};
        final uniqueChats = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return seenClientIds.add(data['clientId'] ?? '');
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: uniqueChats.length,
          itemBuilder: (context, index) {
            final data = uniqueChats[index].data() as Map<String, dynamic>;
            final String clientName = data['clientName'] ?? 'Client';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDecoration(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUserId: data['clientId'],
                      otherUserName: clientName,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: accentBlue.withOpacity(0.1),
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                    style: TextStyle(fontWeight: FontWeight.bold, color: accentBlue),
                  ),
                ),
                title: Text(clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text("Active Consultation",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey.shade400),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: accentBlue,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 2) {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LawyerProfileEditScreen(lawyerId: uid)),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
        ],
      ),
    );
  }
}