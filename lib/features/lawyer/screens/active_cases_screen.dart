import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'schedule_case_screen.dart';

class ActiveCasesScreen extends StatelessWidget {
  const ActiveCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Cases'), backgroundColor: Colors.blue),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final cases = snapshot.data!.docs;
          if (cases.isEmpty) return const Center(child: Text("No active cases found."));

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, i) {
              final doc = cases[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.folder)),
                  title: Text(data['clientName'] ?? 'Client'),
                  subtitle: Text(data['caseType'] ?? 'General Case'),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ScheduleCaseScreen(caseId: doc.id)),
                    ),
                    child: const Text("Schedule"),
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