import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  // Generates a unique, consistent ID for the chat between two specific users
  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Sorting ensures both users access the same document
    return ids.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _getChatId(currentUserId, otherUserId);
    final TextEditingController messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(otherUserName), backgroundColor: Colors.blue),
        body: SafeArea(
          child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUserId;

                    // Inside your ChatScreen itemBuilder
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (isMe)
                            IconButton(
                              // Ensure the button is prominent
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                              onPressed: () => _showDeleteDialog(context, doc.reference),
                            ),
                          const SizedBox(width: 4), // Small gap
                          Flexible( // Add Flexible to prevent layout overflow
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                data['message'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      if (messageController.text.trim().isEmpty) return;
                      final msg = messageController.text.trim();
                      messageController.clear();

                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .add({
                        'senderId': currentUserId,
                        'message': msg,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showDeleteDialog(BuildContext context, DocumentReference messageRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Message?"),
        content: const Text("Are you sure you want to delete this message for everyone?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the document from Firestore
                await messageRef.delete();
                if (context.mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Message deleted")),
                );
              } catch (e) {
                if (kDebugMode) {
                  debugPrint("Error deleting message: $e");
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}