import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientRequestStatusScreen extends StatelessWidget {
  const ClientRequestStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      appBar: AppBar(
        title: const Text("My Request Status"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('clientId', isEqualTo: clientId) // ✅ Filter for current client
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You haven't sent any requests yet."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              // ✅ Dynamic styling based on status
              Color statusColor = Colors.orange; // Default for pending
              if (status == 'accepted') statusColor = Colors.green;
              if (status == 'scheduled') statusColor = Colors.blue;
              if (status == 'rejected') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.gavel, color: statusColor),
                  ),
                  title: Text(
                    "Lawyer: ${data['lawyerName'] ?? 'Unknown'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Case: ${data['description']}", maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // Optional: Show a detail dialog or navigate to chat
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}