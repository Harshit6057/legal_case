import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/chat/screens/chat_screen.dart';

class ClientConversationsScreen extends StatelessWidget {
  const ClientConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      appBar: AppBar(
        title: const Text("Lawyer Conversations"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('clientId', isEqualTo: clientId) // ✅ Client views their own chats
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No conversations found."));
          }

          // ✅ Filtering unique lawyers to avoid duplicates
          final requests = snapshot.data!.docs;
          final uniqueLawyerIds = <String>{};
          final filteredLawyers = requests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return uniqueLawyerIds.add(data['lawyerId'] ?? '');
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLawyers.length,
            itemBuilder: (context, i) {
              final data = filteredLawyers[i].data() as Map<String, dynamic>;
              final String lawyerName = data['lawyerName'] ?? 'Lawyer';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    lawyerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Tap to chat'),
                  trailing: const Icon(Icons.chat, color: Colors.blue, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: data['lawyerId'],
                        otherUserName: lawyerName,
                      ),
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