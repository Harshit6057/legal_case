import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:legal_case_manager/features/chat/screens/chat_screen.dart';


class ScheduleViewScreen extends StatelessWidget {
  const ScheduleViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      appBar: AppBar(
        title: const Text('Your Schedule'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .where('scheduledDate', isNull: false)
            .orderBy('scheduledDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Waiting for Firestore Index... Please wait."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No cases scheduled yet."));
          }

          final scheduledCases = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scheduledCases.length,
            itemBuilder: (context, i) {
              final data = scheduledCases[i].data() as Map<String, dynamic>;
              final timestamp = data['scheduledDate'] as Timestamp?;
              if (timestamp == null) return const SizedBox();
              final DateTime date = timestamp.toDate();

              // Inside your ScheduleViewScreen's ListView.builder
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text("Feb", style: TextStyle(fontSize: 10)),
                        Text("13", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  title: Text(data['clientName'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Time: ${data['time']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ ADD CHAT BUTTON HERE
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: data['clientId'],
                                otherUserName: data['clientName'] ?? 'Client',
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.calendar_month, color: Colors.blue),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}