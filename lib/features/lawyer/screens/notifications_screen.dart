import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // ✅ FIX: Start with a simpler query to verify data exists
          stream: FirebaseFirestore.instance
              .collection('booking_requests')
              .where('lawyerId', isEqualTo: lawyerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // ✅ SORTING LOCALLY: This avoids the "Index Needed" error until you build it
            // ✅ SORTING LOCALLY WITH SAFETY CHECKS
            final notifications = snapshot.data!.docs;

            notifications.sort((a, b) {
              // Use .get() safely to avoid the "field does not exist" crash
              Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
              Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

              // Fallback to a very old date if timestamp is missing so it goes to the bottom
              Timestamp t1 = dataA.containsKey('timestamp') ? dataA['timestamp'] : Timestamp.fromMicrosecondsSinceEpoch(0);
              Timestamp t2 = dataB.containsKey('timestamp') ? dataB['timestamp'] : Timestamp.fromMicrosecondsSinceEpoch(0);

              return t2.compareTo(t1); // Descending order
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final doc = notifications[index]; // Document reference
                final data = doc.data() as Map<String, dynamic>;
                return _buildNotificationCard(context, data, doc.id);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final String clientName = data['clientName'] ?? 'New Client';
    final String status = data['status'] ?? 'pending';
    final String hearingType = data['hearingType'] ?? 'Legal Inquiry';
    final DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.gavel_rounded, color: _getStatusColor(status), size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                clientName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(status),
            // ✅ CROSS SIGN (DELETE BUTTON)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () => _deleteNotification(context, docId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // ✅ Display the specific Case Title instead of just the hearing type
            Text(
              data['caseTitle'] ?? "New Legal Request",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              "Priority: $hearingType",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            // ✅ Optionally show a tiny snippet of details
            if (data['caseDetails'] != null)
              Text(
                data['caseDetails'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (date != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: _getStatusColor(status), fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'scheduled': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("All caught up!", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          Text("No new request notifications.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(BuildContext context, String docId) async {
    try {
      // We show a snackbar first for a responsive feel
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification removed")),
      );

      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete notification")),
        );
      }
    }
  }
}