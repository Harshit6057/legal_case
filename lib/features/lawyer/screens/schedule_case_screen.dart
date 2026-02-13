import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_case_manager/services/notification_service.dart';
import '../../chat/screens/chat_screen.dart';

class ScheduleCaseScreen extends StatefulWidget {
  final String caseId;
  const ScheduleCaseScreen({super.key, required this.caseId});

  @override
  State<ScheduleCaseScreen> createState() => _ScheduleCaseScreenState();
}

class _ScheduleCaseScreenState extends State<ScheduleCaseScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _clientName;
  String? _clientId;
  bool _isDataLoaded = false; // Added to track loading state

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
  }

  Future<void> _loadClientInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(widget.caseId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _clientName = data['clientName'];
          _clientId = data['clientId'];
          _isDataLoaded = true; // Mark as loaded
        });
      }
    } catch (e) {
      debugPrint("Error loading client info: $e");
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final finalScheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // Fetch the latest data to get description for the notification
      final docSnap = await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(widget.caseId)
          .get();

      final data = docSnap.data()!;
      final description = data['description'] ?? 'No description provided';
      final clientName = data['clientName'] ?? 'Client';

      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(widget.caseId)
          .update({
        'scheduledDate': Timestamp.fromDate(finalScheduledDateTime),
        'status': 'scheduled',
      });

      // ✅ Trigger alarm with detailed parameters
      await NotificationService.scheduleAlarm(
        id: widget.caseId.hashCode,
        clientName: clientName,
        caseNumber: widget.caseId.substring(0, 5).toUpperCase(), // Using ID fragment as case number
        description: description,
        scheduledTime: finalScheduledDateTime,
        caseId: widget.caseId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Scheduled and Alarm Set!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Scheduling Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Case"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ Refined Chat Button Logic
          if (_isDataLoaded && _clientId != null)
            IconButton(
              tooltip: "Chat with Client",
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUserId: _clientId!,
                      otherUserName: _clientName ?? 'Client',
                    ),
                  ),
                );
              },
            )
          else if (!_isDataLoaded)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon to make the UI look more professional
            const Icon(Icons.calendar_today, size: 64, color: Colors.blue),
            const SizedBox(height: 24),

            // Date Display
            Text(
              _selectedDate == null
                  ? "No date selected"
                  : "Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Time Display
            Text(
              _selectedTime == null
                  ? "No time selected"
                  : "Time: ${_selectedTime!.format(context)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // Picker Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    icon: const Icon(Icons.date_range),
                    label: const Text("Pick Date"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text("Pick Time"),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedDate != null && _selectedTime != null) ? _saveSchedule : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Confirm Schedule",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}