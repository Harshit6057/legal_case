import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_case_manager/common/widgets/dashboard_widgets.dart';
import 'new_requests_screen.dart';
import '../../../features/lawyer/screens/lawyer_profile_edit_screen.dart';
import '../../../features/lawyer/screens/active_cases_screen.dart';
// Import your schedule list screen
import 'schedule_view_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/cases_history_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/earnings_screen.dart';


class LawyerDashboardScreen extends StatelessWidget {
  const LawyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      bottomNavigationBar: _bottomNav(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const DashboardHeader(),
              const SizedBox(height: 20),

              /// BANNER
              Container(
                height: 130,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2B45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Manage Clients\nGrow Your Practice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.balance, size: 70, color: Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle('Your Actions'),

              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1, // Adjusted for better fit
                ),
                children: [
                  // 1. New Requests (Already has built-in GestureDetector)
                  _newRequestsCard(context),

                  // 2. Active Cases
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveCasesScreen()),
                    ),
                    child: _actionCard('Active Cases', Icons.folder),
                  ),

                  // 3. Schedule
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleViewScreen()),
                    ),
                    child: _actionCard('Schedule', Icons.calendar_month),
                  ),

                  // 4. Cases History (Now explicitly linked)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CasesHistoryScreen()),
                    ),
                    child: _actionCard('Cases History', Icons.history),
                  ),

                  // 5. Earnings (Now clickable)
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EarningsScreen())
                    ),
                    child: _actionCard('Earnings', Icons.account_balance_wallet),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= NEW REQUESTS CARD =================
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewRequestsScreen(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inbox, size: 36, color: Colors.blue),
                    SizedBox(height: 10),
                    Text('New Requests'),
                  ],
                ),
                if (count > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.blue),
          const SizedBox(height: 10),
          Text(title),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}