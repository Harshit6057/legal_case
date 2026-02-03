import 'package:flutter/material.dart';
import 'package:legal_case_manager/common/widgets/dashboard_widgets.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// HEADER + SEARCH (UNCHANGED)
            const DashboardHeader(),
            const SizedBox(height: 20),

            /// ✅ FIXED BANNER
            _banner(),
            const SizedBox(height: 24),

            /// SERVICES
            _sectionTitle('Services'),
            _servicesGrid(),
            const SizedBox(height: 24),

            /// ✅ LAWYER CATEGORIES (GRID – NOT ROW)
            _sectionTitle('Lawyers'),
            _lawyerCategoryGrid(),

            const SizedBox(height: 24),

            /// BOTTOM CATEGORIES
            // _categoriesRow(),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= BANNER =================
  Widget _banner() {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Find Best Lawyers\nwith us',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Image.asset(
            'assets/images/layer1.png',
            height: 90,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
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

  // ================= SERVICES GRID =================
  Widget _servicesGrid() {
    final services = [
      ('Business Setup', Icons.bar_chart),
      ('Documentation', Icons.description),
      ('Disputes', Icons.gavel),
      ('Consultant', Icons.headset_mic),
      ('Legal Advice', Icons.chat),
      ('Legal Info', Icons.account_balance),
      ('Cross Border', Icons.public),
      ('Legal Aid', Icons.balance),
      ('Traffic Laws', Icons.traffic),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2B45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (_, i) {
          return Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(services[i].$2, color: Colors.blue),
              ),
              const SizedBox(height: 6),
              Text(
                services[i].$1,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= ✅ LAWYER CATEGORY GRID =================
  Widget _lawyerCategoryGrid() {
    final lawyers = [
      ('Criminal', 'assets/images/criminal.png'),
      ('Civil', 'assets/images/civil.png'),
      ('Corporate', 'assets/images/corporate.png'),
      ('Public Interest', 'assets/images/public.png'),
      ('Immigration', 'assets/images/immigration.png'),
      ('Intellectual Property', 'assets/images/property.png'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lawyers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        return Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                lawyers[i].$2,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lawyers[i].$1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= BOTTOM CATEGORY ROW =================
  // Widget _categoriesRow() {
  //   final categories = [
  //     'Public Interest',
  //     'Immigration',
  //     'Intellectual Property',
  //   ];
  //
  //   return SizedBox(
  //     height: 100,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: categories.length,
  //       itemBuilder: (_, i) {
  //         return Container(
  //           width: 140,
  //           margin: const EdgeInsets.only(right: 12),
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           child: Center(
  //             child: Text(
  //               categories[i],
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  // ================= BOTTOM NAV =================
  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}
