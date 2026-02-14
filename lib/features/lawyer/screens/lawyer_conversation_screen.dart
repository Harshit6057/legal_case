// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_case_manager/features/chat/screens/chat_screen.dart';

class LawyerConversationsScreen extends StatelessWidget {
  const LawyerConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Conversations"), backgroundColor: Colors.blue),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;
          final seenClientIds = <String>{};
          // ✅ Filtering unique clients to avoid repetitive names
          final uniqueChats = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return seenClientIds.add(data['clientId'] ?? '');
          }).toList();

          if (uniqueChats.isEmpty) return const Center(child: Text("No conversations found."));

          return ListView.builder(
            itemCount: uniqueChats.length,
            itemBuilder: (context, index) {
              final data = uniqueChats[index].data() as Map<String, dynamic>;
              final String clientName = data['clientName'] ?? 'Client';

              return ListTile(
                leading: CircleAvatar(child: Text(clientName[0].toUpperCase())),
                title: Text(clientName),
                subtitle: const Text("Tap to view messages"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUserId: data['clientId'],
                      otherUserName: clientName,
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