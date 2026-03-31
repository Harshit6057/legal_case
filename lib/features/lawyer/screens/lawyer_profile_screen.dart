import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../common/widgets/dashboard_widgets.dart';

class LawyerProfileScreen extends StatefulWidget {
  final String lawyerId;

  const LawyerProfileScreen({
    super.key,
    required this.lawyerId,
  });

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  // ===== LOCATION FIELDS =====
  double? officeLat;
  double? officeLng;
  String? officeAddress;

  // ================= LOCATION HELPERS =================

  String _parseOSMAddress(Map<String, dynamic> data) {
    final addr = data['address'] ?? {};

    final parts = [
      addr['house_number'],
      addr['road'],
      addr['suburb'],
      addr['city'] ?? addr['town'],
      addr['postcode'],
    ].where((e) => e != null && e.toString().isNotEmpty).toList();

    return parts.isNotEmpty
        ? parts.join(', ')
        : data['display_name'] ?? 'Unknown location';
  }

  Future<void> _detectAndSaveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _toast('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _toast('Location permission denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
          '?format=json&lat=${position.latitude}&lon=${position.longitude}'
          '&zoom=18&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'legal_case_manager'},
    );

    if (response.statusCode != 200) {
      _toast('Failed to fetch address');
      return;
    }

    final data = json.decode(response.body);
    final address = _parseOSMAddress(data);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.lawyerId)
        .update({
      'officeLat': position.latitude,
      'officeLng': position.longitude,
      'officeAddress': address,
    });

    if (!mounted) return;

    setState(() {
      officeLat = position.latitude;
      officeLng = position.longitude;
      officeAddress = address;
    });

    _toast('Office location saved');
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.lawyerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'Lawyer';
            final specialization = data['specialization'] ?? '';
            final experience = data['experience'] ?? 0;
            final cases = data['cases'] ?? 0;
            final rating = data['rating'] ?? 0.0;
            final about = data['about'] ?? 'No description available';

            officeLat = data['officeLat'];
            officeLng = data['officeLng'];
            officeAddress = data['officeAddress'];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const DashboardHeader(),
                const SizedBox(height: 16),

                /// PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('$specialization Lawyer',
                          style: const TextStyle(fontSize: 12)),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statChip('$cases+', 'Cases'),
                          _statChip('$experience+', 'Experience'),
                          _statChip(rating.toString(), 'Rating'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (currentUserId == widget.lawyerId)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            officeAddress == null
                                ? 'Add Office Location'
                                : 'Update Office Location',
                          ),
                          onPressed: _detectAndSaveLocation,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('About'),
                Text(about),

                if (officeLat != null && officeLng != null) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Direction'),
                  GestureDetector(
                    onTap: () =>
                        _openGoogleMaps(officeLat!, officeLng!),
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    officeAddress ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.directions,
                                    color: Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue,
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }




  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
