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
  String? _caseDescription;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCaseInfo();
  }

  Future<void> _loadCaseInfo() async {
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
          _caseDescription = data['description'];
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading case info: $e");
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

    if (finalScheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Please select a future time"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // 1. Update Firestore status
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(widget.caseId)
          .update({
        'scheduledDate': Timestamp.fromDate(finalScheduledDateTime),
        'status': 'scheduled',
      });

      // 2. Schedule Local Alarm for LAWYER (using client name)
      await NotificationService.scheduleCaseNotification(
        notificationId: widget.caseId.hashCode,
        clientName: _clientName ?? 'Client',
        title: 'Upcoming Case with ${_clientName ?? 'Client'}',
        body: 'Case No: ${widget.caseId.substring(0, 5).toUpperCase()}',
        description: 'Hearing scheduled for today: ${_caseDescription ?? ""}',
        scheduledTime: finalScheduledDateTime,
        caseId: widget.caseId,
      );

      // 3. Inform the client via a Firestore trigger or FCM (Cloud Messaging)
      // Since we are using local notifications, we can't directly schedule on the client's phone from the lawyer's phone.
      // However, we update the case status in Firestore so that when the client opens their app, 
      // the dashboard shows the updated 'scheduled' time.
      
      // ✅ IMPROVEMENT: We add a 'lastUpdated' field to help the client app detect the change.
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(widget.caseId)
          .update({'lastUpdated': FieldValue.serverTimestamp()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case Scheduled. Status updated for Client."), backgroundColor: Colors.green),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Set Hearing Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isDataLoaded && _clientId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: _clientId!, otherUserName: _clientName ?? 'Client'))),
            )
        ],
      ),
      body: _isDataLoaded
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientCard(),
            const SizedBox(height: 30),
            const Text("Select Date & Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildPickerTile(
              icon: Icons.calendar_month,
              label: "Hearing Date",
              value: _selectedDate == null ? "Not Selected" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerTile(
              icon: Icons.access_time_filled,
              label: "Hearing Time",
              value: _selectedTime == null ? "Not Selected" : _selectedTime!.format(context),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            const SizedBox(height: 40),
            _buildSummary(),
            const SizedBox(height: 40),
            _buildConfirmButton(),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildClientCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFFDBEAFE), child: Icon(Icons.person, color: Colors.blue)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_clientName ?? "Loading...", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Case ID: ${widget.caseId.substring(0, 8).toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    bool isSelected = value != "Not Selected";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue.shade200 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    if (_selectedDate == null || _selectedTime == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text("The status will be updated for both you and your client.", style: TextStyle(fontSize: 13, color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    bool canConfirm = _selectedDate != null && _selectedTime != null;
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: canConfirm ? _saveSchedule : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text("Schedule Hearing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
