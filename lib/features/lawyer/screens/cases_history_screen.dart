import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting dates if needed

class CasesHistoryScreen extends StatelessWidget {
  const CasesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA), // Matching your dashboard theme
      appBar: AppBar(
        title: const Text("Cases History"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: uid)
        // ✅ Only shows cases that are no longer active
            .where('status', whereIn: ['rejected', 'completed', 'cancelled'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading history. Check Firestore indexes."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No history available."));
          }

          final history = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, i) {
              final data = history[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'N/A';

              // Define color based on status for better scannability
              Color statusColor = Colors.grey;
              if (status == 'rejected') statusColor = Colors.red;
              if (status == 'completed') statusColor = Colors.green;
              if (status == 'cancelled') statusColor = Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.history, color: statusColor),
                  ),
                  title: Text(
                    data['clientName'] ?? 'Client',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Status: ${status.toUpperCase()}"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Optional: Navigate to a detailed view of the past case
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