import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      appBar: AppBar(title: const Text("Total Earnings"), backgroundColor: Colors.blue),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('earnings')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          // Calculate Total
          int total = docs.fold(0, (sum, doc) => sum + (doc['amount'] as int));

          return CustomScrollView(
            slivers: [
              // ✅ Sticky Header for Total Earning
              SliverPersistentHeader(
                pinned: true,
                delegate: _EarningsHeaderDelegate(total: total),
              ),

              // ✅ List of Individual Case Earnings
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.currency_rupee)),
                          title: Text("${data['clientName']} - ${data['hearingType']}"),
                          subtitle: Text(DateFormat('dd MMM, yyyy').format(data['timestamp'].toDate())),
                          trailing: Text("₹${data['amount']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EarningsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int total;
  _EarningsHeaderDelegate({required this.total});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TOTAL EARNINGS", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("₹$total",
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 120.0;
  @override
  double get minExtent => 80.0;
  @override
  bool shouldRebuild(covariant _EarningsHeaderDelegate oldDelegate) => oldDelegate.total != total;
}