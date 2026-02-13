import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart'; // New Import
import 'dart:convert';
import 'package:crypto/crypto.dart'; // For checksum
import '../../chat/screens/chat_screen.dart';
import 'package:legal_case_manager/features/lawyer/screens/earnings_screen.dart';


class LawyerProfileViewScreen extends StatefulWidget {
  final String lawyerId;
  const LawyerProfileViewScreen({super.key, required this.lawyerId});

  @override
  State<LawyerProfileViewScreen> createState() => _LawyerProfileViewScreenState();
}

class _LawyerProfileViewScreenState extends State<LawyerProfileViewScreen> {
  // --- PHONEPE CONFIGURATION ---
  // Note: These are Test/Sandbox credentials. Replace with live ones from PhonePe dashboard later.
  String body = "";
  String callback = "https://webhook.site/callback-url"; // Your backend callback
  String merchantId = "PGTESTPAYUAT";
  String saltKey = "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399";
  String saltIndex = "1";

  @override
  void initState() {
    super.initState();
    _initPhonePe();
  }

  // ✅ Updated signature to accept amount and hearing type
  void _startPhonePePayment(int amount, String hearingType) async {
    // Use a cleaner ID format: 'VIRT_TXN' + timestamp for virtual tracking
    String transactionId = "VIRT_TXN${DateTime.now().millisecondsSinceEpoch}";

    // ✅ SIMULATING SUCCESS FOR VIRTUAL MONEY
    // Since you are using virtual money, we bypass the PhonePe SDK call entirely
    // and jump straight to logging the success in your database.
    _onPaymentSuccess(transactionId, amount, hearingType);
  }
  // void _startPhonePePayment(int amount) async {
  //   // Use a cleaner ID format: 'TXN' + timestamp
  //   String transactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";
  //
  //   final requestData = {
  //     "merchantId": merchantId,
  //     "merchantTransactionId": transactionId, // Fixed: Ensures alphanumeric format
  //     "merchantUserId": FirebaseAuth.instance.currentUser?.uid ?? "user123",
  //     "amount": amount * 100,
  //     "mobileNumber": "9999999999",
  //     "callbackUrl": callback,
  //     "paymentConfiguration": {"type": "PAY_PAGE"}
  //   };
  //
  //   String jsonString = json.encode(requestData);
  //   String base64Body = base64.encode(utf8.encode(jsonString));
  //   String checksum = "${sha256.convert(utf8.encode(base64Body + "/pg/v1/pay" + saltKey)).toString()}###$saltIndex";
  //
  //   try {
  //     // Ensure you are using positional arguments correctly for SDK 3.0.2
  //     var result = await PhonePePaymentSdk.startTransaction(jsonString, checksum);
  //
  //     if (result != null) {
  //       String status = result['status'].toString();
  //       if (status == 'SUCCESS') {
  //         _onPaymentSuccess(transactionId, amount, "Normal Hearing");
  //       } else {
  //         _onPaymentError("Payment Status: $status");
  //       }
  //     }
  //   } catch (e) {
  //     _onPaymentError(e.toString());
  //   }
  // }

// Ensure init matches the test environment exactly
  void _initPhonePe() {
    // Use "SANDBOX" for testing with test Merchant ID
    PhonePePaymentSdk.init("SANDBOX", "PGTESTPAYUAT", "", true).then((isInitialized) {
      debugPrint("PhonePe SDK Initialized: $isInitialized");
    }).catchError((error) {
      debugPrint("PhonePe Init Error: $error");
    });
  }

  void _showHearingTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Hearing Type"),
        content: const Text("Choose the urgency of your legal hearing."),
        actions: [
          ListTile(
            title: const Text("Normal Hearing (₹5,000)"),
            onTap: () {
              Navigator.pop(context);
              // ✅ This now works with the updated signature
              _startPhonePePayment(5000, "Normal Hearing");
            },
          ),
          ListTile(
            title: const Text("Fast Hearing (₹10,000)"),
            onTap: () {
              Navigator.pop(context);
              // ✅ This now works with the updated signature
              _startPhonePePayment(10000, "Fast Hearing");
            },
          ),
        ],
      ),
    );
  }

// Update your payment success logic to save to Firestore
//   void _onPaymentSuccess(String txId, int amount, String hearingType) async {
//     final user = FirebaseAuth.instance.currentUser!;
//
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.lawyerId)
//         .collection('earnings')
//         .add({
//       'amount': amount,
//       'hearingType': hearingType,
//       'clientName': user.displayName ?? "Client",
//       'timestamp': FieldValue.serverTimestamp(),
//       'transactionId': txId,
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Payment Successful! Earning logged."), backgroundColor: Colors.green),
//     );
//   }

  // ✅ This logs the virtual payment to the lawyer's earnings sub-collection
  void _onPaymentSuccess(String txId, int amount, String hearingType) async {
    final user = FirebaseAuth.instance.currentUser!;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.lawyerId)
          .collection('earnings') // ✅ Saved for the lawyer's Earnings Screen
          .add({
        'amount': amount,
        'hearingType': hearingType,
        'clientName': user.displayName ?? "Client",
        'timestamp': FieldValue.serverTimestamp(),
        'transactionId': txId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Virtual Payment of ₹$amount successful!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _onPaymentError("Database Error: $e");
    }
  }

  // void _onPaymentSuccess(String txId) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("Payment Successful! ID: $txId"), backgroundColor: Colors.green),
  //   );
  // }

  void _onPaymentError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $msg"), backgroundColor: Colors.red),
    );
  }

  // --- MAP & DIRECTION HELPERS ---
  String _getOSMMapUrl(double lat, double lng) {
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=16&size=600x300&markers=$lat,$lng,ol-marker';
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.lawyerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: Text("Lawyer not found")));

        final String name = data['name'] ?? 'Lawyer';
        final String specialization = data['specialization'] ?? 'General';
        final String about = data['about'] ?? 'No description available';
        final int experience = data['experience'] ?? 0;
        final int cases = data['cases'] ?? 0;
        final double rating = (data['rating'] ?? 0.0).toDouble();

        final double? lat = data['officeLat']?.toDouble();
        final double? lng = data['officeLng']?.toDouble();
        final String? officeAddress = data['officeAddress'];

        return Scaffold(
          backgroundColor: const Color(0xFFEFF6FF),
          appBar: AppBar(
            title: Text(name),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: () => _showRatingDialog(context),
                tooltip: "Rate Lawyer",
              )
            ],
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: widget.lawyerId,
                    otherUserName: name,
                  ),
                ),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.chat, color: Colors.white),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEEFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'L',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      const SizedBox(height: 12),
                      // Capitalizing 'name' and 'specialization' directly in the Text widgets
                      Text(
                          name.isNotEmpty ? "${name[0].toUpperCase()}${name.substring(1)}" : "",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                      ),
                      Text(
                          specialization.isNotEmpty
                              ? "${specialization[0].toUpperCase()}${specialization.substring(1)} Lawyer"
                              : "Lawyer",
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 14)
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statChip('$cases+', 'Cases'),
                          _statChip('$experience+', 'Exp'),
                          _statChip(rating.toStringAsFixed(1), 'Rating'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('About'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(about, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ),

                const SizedBox(height: 24),
                if (lat != null && lng != null) ...[
                  _sectionTitle('Office Location'),
                  GestureDetector(
                    onTap: () => _openGoogleMaps(lat, lng),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[200]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(_getOSMMapUrl(lat, lng), width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.map)),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(officeAddress ?? 'View directions', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ),
                                    const Icon(Icons.directions, color: Colors.blue, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => _showBookingDialog(context, data),
                        child: const Text("Book Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded( // ✅ Changed from GestureDetector to ElevatedButton
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Color for payments
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        // ✅ Triggers the selection dialog (Normal vs Fast)
                        onPressed: () => _showHearingTypeDialog(context),
                        child: const Text("Pay Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Portfolio view coming soon")));
                  },
                  child: const Center(child: Text("View Portfolio", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPERS (Rating, StatChips, Booking) ---

  Widget _statChip(String value, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: Colors.blue, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)));
  }

  void _showRatingDialog(BuildContext context) {
    double selectedRating = 3.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rate this Lawyer"),
        content: RatingBar.builder(
          initialRating: 3,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) => selectedRating = rating,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _submitRating(selectedRating);
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          )
        ],
      ),
    );
  }

  Future<void> _submitRating(double rating) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.lawyerId);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        double currentRating = (data['rating'] ?? 0.0).toDouble();
        int totalReviews = data['totalReviews'] ?? 0;
        double newRating = ((currentRating * totalReviews) + rating) / (totalReviews + 1);
        transaction.update(docRef, {
          'rating': newRating,
          'totalReviews': totalReviews + 1,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rating submitted!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Rating Error: $e");
    }
  }

  // Inside lib/features/lawyer/screens/lawyer_profile_view_screen.dart

  Future<void> _showBookingDialog(BuildContext context, Map<String, dynamic> lawyerData) async {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Describe Your Case"),
        content: TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter a brief description of your legal issue...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.trim().isNotEmpty) {
                _bookLawyer(context, lawyerData, descriptionController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );
  }

  Future<void> _bookLawyer(BuildContext context, Map<String, dynamic> lawyerData, String description) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('booking_requests').add({
        'clientId': user.uid,
        'lawyerId': widget.lawyerId,
        'lawyerName': lawyerData['name'],
        'clientName': user.displayName ?? "Client", // Ensure you store the client name
        'description': description, // New field
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Request Sent!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }


}