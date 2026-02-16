import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaseNotesScreen extends StatefulWidget {
  final String caseId;
  final String clientName;

  const CaseNotesScreen({super.key, required this.caseId, required this.clientName});

  @override
  State<CaseNotesScreen> createState() => _CaseNotesScreenState();
}

class _CaseNotesScreenState extends State<CaseNotesScreen> {
  final TextEditingController _noteController = TextEditingController();

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('booking_requests')
        .doc(widget.caseId)
        .collection('notes')
        .add({
      'content': _noteController.text.trim(),
      'lawyerId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _noteController.clear();
    if (mounted) Navigator.pop(context); // Close dialog/bottom sheet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notes: ${widget.clientName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('booking_requests')
                  .doc(widget.caseId)
                  .collection('notes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final notes = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final data = notes[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['content']),
                        subtitle: Text(data['timestamp']?.toDate().toString() ?? "Just now"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddNoteDialog(),
              child: const Text("Add Case Note"),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Enter case observations...", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addNote, child: const Text("Save Note")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}