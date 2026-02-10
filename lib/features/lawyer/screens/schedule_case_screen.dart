import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleCaseScreen extends StatefulWidget {
  final String caseId;
  const ScheduleCaseScreen({super.key, required this.caseId});

  @override
  State<ScheduleCaseScreen> createState() => _ScheduleCaseScreenState();
}

class _ScheduleCaseScreenState extends State<ScheduleCaseScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _saveSchedule() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await FirebaseFirestore.instance
        .collection('booking_requests')
        .doc(widget.caseId)
        .update({
      'scheduledDate': Timestamp.fromDate(scheduledDateTime),
      'notificationSent': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Case scheduled successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Case"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedDate == null
                  ? "No date selected"
                  : "Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedTime == null
                  ? "No time selected"
                  : "Time: ${_selectedTime!.format(context)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: const Text("Pick Date"),
            ),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
              child: const Text("Pick Time"),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedDate != null && _selectedTime != null) ? _saveSchedule : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Confirm Schedule", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}