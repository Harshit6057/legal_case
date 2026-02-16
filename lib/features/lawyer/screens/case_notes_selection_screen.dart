import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'case_notes_screen.dart'; // Ensure this path is correct

class CaseNotesSelectionScreen extends StatelessWidget {
  const CaseNotesSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      appBar: AppBar(
        title: const Text("Select Case for Notes"),
        backgroundColor: const Color(0xFF0B2B45),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetching cases that are either scheduled or already active
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .where('status', whereIn: ['scheduled', 'active'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No active or scheduled cases found."),
                ],
              ),
            );
          }

          final cases = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final doc = cases[index];
              final data = doc.data() as Map<String, dynamic>;
              final String clientName = data['clientName'] ?? 'Unknown Client';
              final String caseId = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDDEEFF),
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  title: Text(
                    clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Type: ${data['hearingType'] ?? 'General'}"),
                      Text("Status: ${data['status']}",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  // ✅ THE REDIRECTION BUTTON
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaseNotesScreen(
                            caseId: caseId,
                            clientName: clientName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text("Notes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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