import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/screens/chat_screen.dart';

class NewRequestsScreen extends StatelessWidget {
  const NewRequestsScreen({super.key});

  @override

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

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
                elevation: 4, // Adds subtle depth for scannability
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER SECTION ---
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade700,
                            child: Text(
                              clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clientName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  specialization,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // Timestamp indicator (optional but helpful)
                          Text(
                            "New",
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // --- DESCRIPTION SECTION ---
                      const Text(
                        "Case Description:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['caseDetails'] ?? "No details provided", // ✅ Updated from 'description'
                        style: const TextStyle(fontSize: 14, height: 1.4),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // --- ACTION BUTTONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Chat Button
                          _actionButton(
                            icon: Icons.chat_bubble_outline,
                            label: "Chat",
                            color: Colors.blue,
                            onTap: () {
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
                          // Accept Button
                          _actionButton(
                            icon: Icons.check_circle_outline,
                            label: "Accept",
                            color: Colors.green,
                            onTap: () async {
                              await doc.reference.update({
                                'status': 'accepted',
                                'acceptedAt': FieldValue.serverTimestamp(),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request accepted')),
                              );
                            },
                          ),
                          // Reject Button
                          _actionButton(
                            icon: Icons.highlight_off,
                            label: "Reject",
                            color: Colors.redAccent,
                            onTap: () async {
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