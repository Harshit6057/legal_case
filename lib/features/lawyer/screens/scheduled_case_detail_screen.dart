// lib/features/lawyer/screens/scheduled_case_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledCaseDetailScreen extends StatelessWidget {
  final String caseId;
  const ScheduledCaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details"), backgroundColor: Colors.blue),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('booking_requests').doc(caseId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final date = (data['scheduledDate'] as Timestamp).toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailCard("Client Name", data['clientName'] ?? "N/A", Icons.person),
                _detailCard("Case Type", data['caseType'] ?? "General", Icons.gavel),
                _detailCard("Scheduled For", "${date.day}/${date.month}/${date.year} at ${TimeOfDay.fromDateTime(date).format(context)}", Icons.event),
                const SizedBox(height: 20),
                const Text("Full Description:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: Text(data['description'] ?? "No description provided.", style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}