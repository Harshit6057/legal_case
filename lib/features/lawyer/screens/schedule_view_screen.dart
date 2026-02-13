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
              // Inside ScheduleViewScreen's ListView.builder
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10)), // Dynamic Month
                        Text(DateFormat('dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold)), // Dynamic Day
                      ],
                    ),
                  ),
                  title: Text(data['clientName'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Time: ${DateFormat('hh:mm a').format(date)}"), // Formatted Time
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                            otherUserId: data['clientId'], otherUserName: data['clientName'] ?? 'Client'))),
                      ),
                      // ✅ Calendar Button: Shows Date Picker for viewing/rescheduling
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.blue),
                        onPressed: () async {
                          await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                        },
                      ),
                      // ✅ Delete Button: Removes the schedule
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, scheduledCases[i].reference),
                      ),
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


  // Helper function for deletion
  void _confirmDelete(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Schedule?"),
        content: const Text("This will remove the case from your active schedule."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await docRef.update({'status': 'cancelled', 'scheduledDate': FieldValue.delete()});
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}