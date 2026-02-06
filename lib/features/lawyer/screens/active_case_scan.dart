import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveCasesScreen extends StatelessWidget {
  const ActiveCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Cases'), backgroundColor: Colors.blue),
      body: StreamBuilder<QuerySnapshot>(
        // Only fetch requests that have been 'accepted'
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final cases = snapshot.data!.docs;
          if (cases.isEmpty) return const Center(child: Text("No active cases"));

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, i) {
              final data = cases[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blue),
                  title: Text(data['clientName'] ?? 'Client'),
                  subtitle: Text('Status: Active'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to case details if needed
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