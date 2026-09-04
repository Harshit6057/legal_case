import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:legal_case_manager/features/client/models/court_display_board_item.dart';
import 'package:legal_case_manager/features/client/services/court_live_updates_service.dart';

class CourtsDisplayBoardScreen extends StatefulWidget {
  const CourtsDisplayBoardScreen({super.key});

  @override
  State<CourtsDisplayBoardScreen> createState() => _CourtsDisplayBoardScreenState();
}

class _CourtsDisplayBoardScreenState extends State<CourtsDisplayBoardScreen> {
  final CourtLiveUpdatesService _service = CourtLiveUpdatesService();
  Timer? _timer;

  bool _isLoading = true;
  List<CourtDisplayBoardItem> _items = const <CourtDisplayBoardItem>[];
  String _selectedCourtKey = 'all';

  @override
  void initState() {
    super.initState();
    _loadBoards();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadBoards(showLoader: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoards({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }

    final items = await _service.fetchOfficialDisplayBoards(
      courtKey: _selectedCourtKey == 'all' ? null : _selectedCourtKey,
    );

    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final sources = _service.getOfficialCourtSources();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Courts Display Numbers'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBoards,
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This page shows official Supreme/High Court display boards. Auto-sync runs every 30 seconds.',
                      style: TextStyle(color: Color(0xFF0C4A6E), fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCourtKey,
                      decoration: InputDecoration(
                        labelText: 'Select Court Display Board',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Official Courts')),
                        ...sources.map(
                          (source) => DropdownMenuItem(
                            value: source.courtKey,
                            child: Text(source.courtName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedCourtKey = value);
                        _loadBoards();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _linkChip('eCourts Services', 'https://services.ecourts.gov.in/'),
                        _linkChip('HC Services', 'https://hcservices.ecourts.gov.in/'),
                        ...sources.map((source) => _linkChip(source.courtName, source.displayBoardUrl)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            kIsWeb
                                ? 'No court display-number data found on web. Add a CORS-safe proxy using .env key COURT_BOARD_PROXY_URL and configure Firestore collection court_board_sources.'
                                : 'No court display-number data found. Configure court source URLs in Firestore collection court_board_sources.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBoards,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final updatedText = item.updatedAt == null
                                ? 'Updated: NA'
                                : 'Updated: ${dateFormat.format(item.updatedAt!.toLocal())}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.courtName} • ${item.courtType}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _pill('Display #', item.displayNumber),
                                      _pill('Case No', item.caseNumber ?? 'NA'),
                                      _pill('Case Order', item.caseOrder ?? 'NA'),
                                      _pill('Timing', item.caseTiming ?? 'NA'),
                                      _pill('Status', item.caseStatus ?? 'Live'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          updatedText,
                                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _openSource(item.sourceUrl),
                                        child: const Text('Open Source'),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _linkChip(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: () => _openSource(url),
        labelStyle: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}
