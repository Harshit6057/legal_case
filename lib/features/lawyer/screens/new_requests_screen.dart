import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/screens/chat_screen.dart';

class NewRequestsScreen extends StatelessWidget {
  const NewRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_requests')
            .where('lawyerId', isEqualTo: lawyerId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No new requests'));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final doc = requests[i];
              final data = doc.data() as Map<String, dynamic>;

              final clientName = data['clientName'] ?? 'Client';
              final clientId = data['clientId'] ?? '';
              final specialization = (data['specialization'] ?? '').toString().toUpperCase();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(clientName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(specialization),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// 💬 CHAT / REPLY BUTTON
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

                      /// ✅ ACCEPT
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          await doc.reference.update({
                            'status': 'accepted',
                            'acceptedAt': FieldValue.serverTimestamp(), // Track when it became a case
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request accepted and moved to Active Cases')),
                          );
                        },
                      ),

                      /// ❌ REJECT BUTTON
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () async {
                          await doc.reference.update({
                            'status': 'rejected',
                            'rejectedAt': FieldValue.serverTimestamp(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        },
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

  // ================= REPLY POPUP LOGIC =================
  void _showReplyPopup(BuildContext context, String clientId, String clientName, String lawyerId) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reply to $clientName'),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                // Send to a lightweight 'messages' collection
                await FirebaseFirestore.instance.collection('chats').add({
                  'senderId': lawyerId,
                  'receiverId': clientId,
                  'message': replyController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reply sent to client!")),
                );
              }
            },
            child: const Text("Send", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}