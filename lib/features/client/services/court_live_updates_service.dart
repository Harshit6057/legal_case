import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/court_display_board_item.dart';
import '../models/court_live_update.dart';

class OfficialCourtSource {
  const OfficialCourtSource({
    required this.courtKey,
    required this.courtName,
    required this.courtType,
    required this.displayBoardUrl,
    this.fallbackUrls = const <String>[],
    this.statusUrl,
    this.notes,
  });

  final String courtKey;
  final String courtName;
  final String courtType;
  final String displayBoardUrl;
  final List<String> fallbackUrls;
  final String? statusUrl;
  final String? notes;
}

class CourtLiveUpdatesService {
  CourtLiveUpdatesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<OfficialCourtSource> _officialSources = [
    OfficialCourtSource(
      courtKey: 'sci',
      courtName: 'Supreme Court of India',
      courtType: 'Supreme Court',
      displayBoardUrl: 'https://cdb.sci.gov.in/',
      statusUrl: 'https://services.ecourts.gov.in/',
      notes: 'Official display board page, generally refreshes frequently.',
    ),
    OfficialCourtSource(
      courtKey: 'delhi_hc',
      courtName: 'Delhi High Court',
      courtType: 'High Court',
      displayBoardUrl: 'https://delhihighcourt.nic.in/app/physical-display-board',
      statusUrl: 'https://hcservices.ecourts.gov.in/',
    ),
    OfficialCourtSource(
      courtKey: 'bombay_hc',
      courtName: 'Bombay High Court',
      courtType: 'High Court',
      displayBoardUrl: 'https://bombayhighcourt.nic.in/displayboard.php',
      fallbackUrls: [
        'http://bombayhighcourt.nic.in/displayboard.php',
      ],
      statusUrl: 'https://hcservices.ecourts.gov.in/',
    ),
    OfficialCourtSource(
      courtKey: 'ph_hc',
      courtName: 'Punjab and Haryana High Court',
      courtType: 'High Court',
      displayBoardUrl: 'https://new.phhc.gov.in/display-board',
      statusUrl: 'https://hcservices.ecourts.gov.in/',
      notes: 'Use Display Board entry from official menu when available.',
    ),
  ];

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  List<OfficialCourtSource> getOfficialCourtSources() => _officialSources;

  Stream<List<CourtLiveUpdate>> streamClientCourtUpdates(String clientId) {
    return _firestore
        .collection('booking_requests')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final updates = snapshot.docs
          .map(CourtLiveUpdate.fromBookingRequestDoc)
          .toList();

      updates.sort((a, b) {
        final aTime = a.lastUpdatedAt;
        final bTime = b.lastUpdatedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return updates;
    });
  }

  Future<void> triggerScraperSync({required String clientId}) async {
    final endpoint = dotenv.env['COURT_SCRAPER_SYNC_URL']?.trim() ?? '';
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint('COURT_SCRAPER_SYNC_URL not configured. Skipping scraper sync trigger.');
      }
      return;
    }

    try {
      final docs = await _firestore
          .collection('booking_requests')
          .where('clientId', isEqualTo: clientId)
          .get();

      final caseIds = docs.docs.map((doc) => doc.id).toList();

      await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'caseIds': caseIds,
          'requestedAt': DateTime.now().toIso8601String(),
          'targetUpdateTime': '18:00',
        }),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to trigger scraper sync: $error');
      }
    }
  }

  Future<List<CourtDisplayBoardItem>> fetchAllCourtsDisplayNumbers() async {
    return fetchOfficialDisplayBoards();
  }

  Future<List<CourtDisplayBoardItem>> fetchOfficialDisplayBoards({String? courtKey}) async {
    final filteredSources = _officialSources
        .where((source) => courtKey == null || source.courtKey == courtKey)
        .toList();

    final allItems = <CourtDisplayBoardItem>[];
    for (final source in filteredSources) {
      final sourceItems = await _scrapeOfficialSource(source);
      if (kDebugMode) {
        debugPrint(
          'Court source ${source.courtKey} parsed ${sourceItems.length} rows',
        );
      }
      allItems.addAll(sourceItems.where((item) => item.hasDisplayNumber));
    }

    // Merge admin-configured Firestore sources so courts added in `court_board_sources`
    // appear in the same all-courts board UI.
    final customItems = await fetchCustomFirestoreCourtSources(courtKey: courtKey);
    allItems.addAll(customItems.where((item) => item.hasDisplayNumber));

    allItems.sort((a, b) {
      final aTime = a.updatedAt;
      final bTime = b.updatedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return allItems;
  }

  Future<List<CourtDisplayBoardItem>> _scrapeOfficialSource(OfficialCourtSource source) async {
    if (source.courtKey == 'delhi_hc') {
      final delhi = await _fetchDelhiHighCourtLiveRows(source);
      if (delhi.isNotEmpty) return delhi;
    }
    if (source.courtKey == 'ph_hc') {
      final phhc = await _fetchPunjabHaryanaHighCourtLiveRows(source);
      if (phhc.isNotEmpty) return phhc;
    }

    try {
      final response = await _httpGetWithFallbacks(
        primaryUrl: source.displayBoardUrl,
        fallbackUrls: source.fallbackUrls,
        headers: {
          ..._defaultHeaders,
          'Referer': source.displayBoardUrl,
        },
      );
      if (response == null) {
        return <CourtDisplayBoardItem>[
          _fallbackItem(source, status: 'Source unreachable'),
        ];
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <CourtDisplayBoardItem>[
          _fallbackItem(source, status: 'Source unavailable (${response.statusCode})'),
        ];
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      final sourceSpecific = _parseOfficialSourceSpecific(
        source: source,
        body: response.body,
      );
      if (sourceSpecific.isNotEmpty) {
        return sourceSpecific;
      }

      if (contentType.contains('application/json') || _looksLikeJson(response.body)) {
        final parsed = _parseJsonBoardPayload(
          response.body,
          sourceUrl: source.displayBoardUrl,
          defaultCourtKey: source.courtKey,
          defaultCourtName: source.courtName,
          defaultCourtType: source.courtType,
          defaultStatus: 'Live',
        );
        return parsed.isNotEmpty ? parsed : <CourtDisplayBoardItem>[_fallbackItem(source)];
      }

      final parsed = _parseHtmlBoardPayload(
        response.body,
        sourceUrl: source.displayBoardUrl,
        courtKey: source.courtKey,
        courtName: source.courtName,
        courtType: source.courtType,
      );

      return parsed.isNotEmpty ? parsed : <CourtDisplayBoardItem>[_fallbackItem(source)];
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed scraping official source ${source.displayBoardUrl}: $error');
      }
      return <CourtDisplayBoardItem>[
        _fallbackItem(source, status: 'Fetch error'),
      ];
    }
  }

  Future<http.Response?> _httpGetWithFallbacks({
    required String primaryUrl,
    required List<String> fallbackUrls,
    Map<String, String>? headers,
    int maxAttemptsPerUrl = 2,
  }) async {
    final urls = <String>[primaryUrl, ...fallbackUrls];
    final proxyBase = dotenv.env['COURT_BOARD_PROXY_URL']?.trim() ?? '';

    for (final url in urls) {
      for (var attempt = 0; attempt < maxAttemptsPerUrl; attempt++) {
        try {
          final response = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 12));
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return response;
          }

          if (kIsWeb) {
            final proxied = await _httpGetViaProxy(proxyBase: proxyBase, targetUrl: url, headers: headers);
            if (proxied != null && proxied.statusCode >= 200 && proxied.statusCode < 300) {
              return proxied;
            }
          }

          if (response.statusCode == 403 || response.statusCode == 429) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            continue;
          }
        } catch (_) {
          if (kIsWeb) {
            final proxied = await _httpGetViaProxy(proxyBase: proxyBase, targetUrl: url, headers: headers);
            if (proxied != null && proxied.statusCode >= 200 && proxied.statusCode < 300) {
              return proxied;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    return null;
  }

  Future<http.Response?> _httpGetViaProxy({
    required String proxyBase,
    required String targetUrl,
    Map<String, String>? headers,
  }) async {
    final fallbackProxyUrl = 'https://r.jina.ai/$targetUrl';
    final candidates = <Uri>[];

    if (proxyBase.isNotEmpty) {
      try {
        final proxyUri = Uri.parse(proxyBase);
        final mergedQuery = <String, String>{
          ...proxyUri.queryParameters,
          'url': targetUrl,
        };
        candidates.add(proxyUri.replace(queryParameters: mergedQuery));
      } catch (_) {
        // ignore malformed custom proxy URL and continue with fallback proxy
      }
    }

    try {
      candidates.add(Uri.parse(fallbackProxyUrl));
    } catch (_) {
      return null;
    }

    for (final uri in candidates) {
      try {
        final response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<List<CourtDisplayBoardItem>> _fetchDelhiHighCourtLiveRows(
    OfficialCourtSource source,
  ) async {
    const url =
        'https://delhihighcourt.nic.in/app/physical-display-board?draw=1&start=0&length=120&search[value]=&search[regex]=false';

    try {
      final response = await _httpGetWithFallbacks(
        primaryUrl: url,
        fallbackUrls: const <String>[],
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json,text/javascript,*/*;q=0.01',
          'Referer': 'https://delhihighcourt.nic.in/app/physical-display-board',
        },
      );

      if (response == null) {
        return const <CourtDisplayBoardItem>[];
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <CourtDisplayBoardItem>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const <CourtDisplayBoardItem>[];
      }

      final rows = (decoded['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final items = <CourtDisplayBoardItem>[];
      for (final row in rows) {
        final itemNo = (row['item'] ?? '').toString().trim();
        final caseNo = (row['case_no'] ?? '').toString().trim();
        final order = (row['disp_court_no'] ?? row['court_no'] ?? '').toString().trim();

        if (itemNo.isEmpty || itemNo == '*' || itemNo.toUpperCase() == 'X') {
          continue;
        }

        final status = (itemNo == '*')
            ? 'Not in session'
            : (itemNo.toUpperCase() == 'X' ? 'Board exhausted' : 'Running');

        items.add(
          CourtDisplayBoardItem(
            courtKey: source.courtKey,
            courtName: source.courtName,
            courtType: source.courtType,
            sourceUrl: source.displayBoardUrl,
            displayNumber: itemNo,
            caseNumber: caseNo.isEmpty ? null : caseNo,
            caseOrder: order.isEmpty ? null : order,
            caseStatus: status,
            updatedAt: DateTime.now(),
          ),
        );
      }

      return items;
    } catch (_) {
      return const <CourtDisplayBoardItem>[];
    }
  }

  Future<List<CourtDisplayBoardItem>> _fetchPunjabHaryanaHighCourtLiveRows(
    OfficialCourtSource source,
  ) async {
    const endpoint =
        'https://livedb9010.phhc.gov.in/display_board/public/getRecords?skip=0&limit=500';

    try {
      final response = await _httpGetWithFallbacks(
        primaryUrl: endpoint,
        fallbackUrls: const <String>[],
        headers: {
          ..._defaultHeaders,
          'Accept': 'application/json,text/plain,*/*',
          'Referer': source.displayBoardUrl,
        },
      );

      if (response == null) {
        return const <CourtDisplayBoardItem>[];
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <CourtDisplayBoardItem>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const <CourtDisplayBoardItem>[];
      }

      final rows = (decoded['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final out = <CourtDisplayBoardItem>[];
      for (final row in rows) {
        final courtNo = (row['court_no'] ?? row['courtNo'] ?? '').toString().trim();
        final srNo = (row['sr_no'] ?? row['srNo'] ?? '').toString().trim();

        if (courtNo.isEmpty) continue;

        out.add(
          CourtDisplayBoardItem(
            courtKey: source.courtKey,
            courtName: source.courtName,
            courtType: source.courtType,
            sourceUrl: source.displayBoardUrl,
            displayNumber: 'C$courtNo',
            caseOrder: srNo.isEmpty ? null : srNo,
            caseStatus: srNo.isEmpty || srNo == '-' ? 'Not in session' : 'Running',
            updatedAt: DateTime.now(),
          ),
        );
      }

      return out;
    } catch (_) {
      return const <CourtDisplayBoardItem>[];
    }
  }

  List<CourtDisplayBoardItem> _parseOfficialSourceSpecific({
    required OfficialCourtSource source,
    required String body,
  }) {
    if (source.courtKey == 'delhi_hc') {
      return _parseDelhiHighCourtBoard(source: source, body: body);
    }
    if (source.courtKey == 'bombay_hc') {
      return _parseBombayHighCourtBoard(source: source, body: body);
    }
    if (source.courtKey == 'sci') {
      return _parseSciBoard(source: source, body: body);
    }
    return const <CourtDisplayBoardItem>[];
  }

  List<CourtDisplayBoardItem> _parseDelhiHighCourtBoard({
    required OfficialCourtSource source,
    required String body,
  }) {
    final rows = <CourtDisplayBoardItem>[];
    final pipeRowRegex = RegExp(
      r'\|\s*(\d+)\s*\|\s*([A-Za-z0-9*]+)\s*\|\s*[^|]*\|\s*([^|]*)\|\s*([^|]*)\|\s*(View Link|NA)\s*\|',
      caseSensitive: false,
    );

    for (final match in pipeRowRegex.allMatches(body)) {
      final order = (match.group(1) ?? '').trim();
      final displayNo = (match.group(2) ?? '').trim();
      final caseNo = (match.group(3) ?? '').trim();
      final action = (match.group(5) ?? '').trim().toLowerCase();

      if (displayNo == '*' || displayNo.isEmpty) continue;

      rows.add(
        CourtDisplayBoardItem(
          courtKey: source.courtKey,
          courtName: source.courtName,
          courtType: source.courtType,
          sourceUrl: source.displayBoardUrl,
          displayNumber: displayNo,
          caseNumber: caseNo.isEmpty ? null : caseNo,
          caseOrder: order,
          caseStatus: action == 'na' ? 'Not in session' : 'Running',
          updatedAt: DateTime.now(),
        ),
      );
    }

    return rows.take(60).toList();
  }

  List<CourtDisplayBoardItem> _parseBombayHighCourtBoard({
    required OfficialCourtSource source,
    required String body,
  }) {
    final rows = <CourtDisplayBoardItem>[];
    final compactText = _stripHtml(body);

    final listingRegex = RegExp(
      r'\b(\d{1,2}[A-Z]?)\s+(\d{1,3})\s+([A-Z][A-Z()\./\-]*\/\d{1,7}\/\d{4})\b',
      caseSensitive: false,
    );

    final calledMap = <String, String>{};
    final calledRegex = RegExp(
      r'CR\.\s*NO\.\s*(\d{1,2}[A-Z]?)\s*([^C]{5,100})',
      caseSensitive: false,
    );
    for (final match in calledRegex.allMatches(compactText)) {
      final courtNo = (match.group(1) ?? '').trim().toUpperCase();
      final message = (match.group(2) ?? '').trim();
      if (courtNo.isNotEmpty && message.isNotEmpty) {
        calledMap[courtNo] = 'Called: $message';
      }
    }

    for (final match in listingRegex.allMatches(compactText)) {
      final courtNo = (match.group(1) ?? '').trim().toUpperCase();
      final serialNo = (match.group(2) ?? '').trim();
      final caseNo = (match.group(3) ?? '').trim();

      if (courtNo.isEmpty || caseNo.isEmpty) continue;

      rows.add(
        CourtDisplayBoardItem(
          courtKey: source.courtKey,
          courtName: source.courtName,
          courtType: source.courtType,
          sourceUrl: source.displayBoardUrl,
          displayNumber: courtNo,
          caseNumber: caseNo,
          caseOrder: serialNo,
          caseStatus: calledMap[courtNo] ?? 'Running',
          updatedAt: DateTime.now(),
        ),
      );
    }

    return rows.take(80).toList();
  }

  List<CourtDisplayBoardItem> _parseSciBoard({
    required OfficialCourtSource source,
    required String body,
  }) {
    final match = RegExp(r'var\s+data\s*=\s*(\{.*?\});', dotAll: true)
        .firstMatch(body);
    if (match == null) {
      return const <CourtDisplayBoardItem>[];
    }

    final jsonText = match.group(1);
    if (jsonText == null || jsonText.isEmpty) {
      return const <CourtDisplayBoardItem>[];
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return const <CourtDisplayBoardItem>[];
      }

      final details = (decoded['listedItemDetails'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final rows = <CourtDisplayBoardItem>[];
      for (final d in details) {
        final courtNameText = _stripHtml((d['court_name'] ?? '').toString()).toUpperCase();
        final regDisplay = _stripHtml((d['registration_number_display'] ?? '').toString());
        final itemNo = _stripHtml((d['item_no'] ?? '').toString());
        final itemStatus = _stripHtml((d['item_status'] ?? '').toString());

        if (courtNameText.isEmpty) continue;

        final caseNo = regDisplay.isEmpty || regDisplay.toLowerCase() == 'not in session'
            ? null
            : regDisplay;

        final status = itemStatus.isNotEmpty
            ? itemStatus
            : (caseNo == null ? 'Not in session' : 'Running');

        rows.add(
          CourtDisplayBoardItem(
            courtKey: source.courtKey,
            courtName: source.courtName,
            courtType: source.courtType,
            sourceUrl: source.displayBoardUrl,
            displayNumber: courtNameText,
            caseNumber: caseNo,
            caseOrder: itemNo.isEmpty ? null : itemNo,
            caseStatus: status,
            updatedAt: DateTime.now(),
          ),
        );
      }

      return rows.where((r) => r.hasDisplayNumber).toList();
    } catch (_) {
      return const <CourtDisplayBoardItem>[];
    }
  }

  CourtDisplayBoardItem _fallbackItem(OfficialCourtSource source, {String? status}) {
    return CourtDisplayBoardItem(
      courtKey: source.courtKey,
      courtName: source.courtName,
      courtType: source.courtType,
      sourceUrl: source.displayBoardUrl,
      displayNumber: 'NA',
      caseStatus: status ?? 'Live board format not parsable in-app',
      updatedAt: DateTime.now(),
    );
  }

  Future<List<CourtDisplayBoardItem>> fetchCustomFirestoreCourtSources({String? courtKey}) async {
    try {
      final query = _firestore
          .collection('court_board_sources')
          .where('enabled', isEqualTo: true)
          .where('hasDisplayBoard', isEqualTo: true);
      final sourcesSnapshot = await query.get();

      final allItems = <CourtDisplayBoardItem>[];
      for (final doc in sourcesSnapshot.docs) {
        final sourceData = doc.data();
        if (courtKey != null && (sourceData['courtKey'] ?? '').toString() != courtKey) {
          continue;
        }
        final sourceItems = await _scrapeCustomSource(sourceData);
        allItems.addAll(sourceItems.where((item) => item.hasDisplayNumber));
      }

      return allItems;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to fetch custom court sources: $error');
      }
      return const <CourtDisplayBoardItem>[];
    }
  }

  Future<List<CourtDisplayBoardItem>> _scrapeCustomSource(Map<String, dynamic> sourceData) async {
    final sourceUrl = (sourceData['sourceUrl'] ?? '').toString().trim();
    if (sourceUrl.isEmpty) return const <CourtDisplayBoardItem>[];

    final courtKey = (sourceData['courtKey'] ?? 'custom').toString();
    final courtName = (sourceData['courtName'] ?? 'Unknown Court').toString();
    final courtType = (sourceData['courtType'] ?? 'Court').toString();

    try {
      final response = await _httpGetWithFallbacks(
        primaryUrl: sourceUrl,
        fallbackUrls: const <String>[],
        headers: _defaultHeaders,
      );
      if (response == null) {
        return const <CourtDisplayBoardItem>[];
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <CourtDisplayBoardItem>[];
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('application/json') || _looksLikeJson(response.body)) {
        return _parseJsonBoardPayload(
          response.body,
          sourceUrl: sourceUrl,
          defaultCourtKey: courtKey,
          defaultCourtName: courtName,
          defaultCourtType: courtType,
          defaultStatus: 'Live',
        );
      }

      return _parseHtmlBoardPayload(
        response.body,
        sourceUrl: sourceUrl,
        courtKey: courtKey,
        courtName: courtName,
        courtType: courtType,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed scraping source $sourceUrl: $error');
      }
      return const <CourtDisplayBoardItem>[];
    }
  }

  bool _looksLikeJson(String body) {
    final text = body.trimLeft();
    return text.startsWith('{') || text.startsWith('[');
  }

  List<CourtDisplayBoardItem> _parseJsonBoardPayload(
    String body, {
    required String sourceUrl,
    required String defaultCourtKey,
    required String defaultCourtName,
    required String defaultCourtType,
    required String defaultStatus,
  }) {
    try {
      final decoded = jsonDecode(body);
      final list = <dynamic>[];

      if (decoded is List) {
        list.addAll(decoded);
      } else if (decoded is Map<String, dynamic>) {
        final candidates = decoded['items'] ?? decoded['cases'] ?? decoded['boards'];
        if (candidates is List) {
          list.addAll(candidates);
        } else {
          list.add(decoded);
        }
      }

      return list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
        final merged = {
          'courtKey': item['courtKey'] ?? defaultCourtKey,
          'courtName': item['courtName'] ?? defaultCourtName,
          'courtType': item['courtType'] ?? defaultCourtType,
          'sourceUrl': item['sourceUrl'] ?? sourceUrl,
          'caseStatus': item['caseStatus'] ?? defaultStatus,
          ...item,
        };
        return CourtDisplayBoardItem.fromJson(merged, fallbackUrl: sourceUrl);
      }).toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('JSON board payload parsing failed: $error');
      }
      return const <CourtDisplayBoardItem>[];
    }
  }

  List<CourtDisplayBoardItem> _parseHtmlBoardPayload(
    String html, {
    required String sourceUrl,
    required String courtKey,
    required String courtName,
    required String courtType,
  }) {
    final rows = RegExp(r'<tr[^>]*>(.*?)</tr>', caseSensitive: false, dotAll: true)
        .allMatches(html)
        .map((match) => match.group(1) ?? '')
        .where((row) => row.trim().isNotEmpty)
        .toList();

    final parsedRows = <CourtDisplayBoardItem>[];

    for (final row in rows) {
      final columns = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', caseSensitive: false, dotAll: true)
          .allMatches(row)
          .map((cell) => _stripHtml(cell.group(1) ?? ''))
          .where((cell) => cell.isNotEmpty)
          .toList();

      if (columns.isEmpty) continue;

      final display = _firstMatching(columns, [
        RegExp(r'^(court\s*no\.?|board\s*no\.?|display\s*no\.?|token\s*no\.?)', caseSensitive: false),
        RegExp(r'^[A-Za-z]*\d+[A-Za-z0-9\-/]*$'),
      ]);

      final caseNo = _firstMatching(columns, [
        RegExp(r'\b(CNR|Case)\b', caseSensitive: false),
        RegExp(r'\d{1,4}[/\-]\d{2,4}'),
      ]);

      final order = _firstMatching(columns, [
        RegExp(r'\border\b|serial', caseSensitive: false),
        RegExp(r'^\d{1,3}$'),
      ]);

      final timing = _firstMatching(columns, [
        RegExp(r'\b\d{1,2}:\d{2}\s*(AM|PM)?\b', caseSensitive: false),
      ]);

      final status = _firstMatching(columns, [
        RegExp(r'\b(running|called|pass\s*over|disposed|adjourned|pending|in\s*progress)\b', caseSensitive: false),
      ]);

      if (display.isEmpty && caseNo.isEmpty && order.isEmpty) continue;

      parsedRows.add(
        CourtDisplayBoardItem(
          courtKey: courtKey,
          courtName: courtName,
          courtType: courtType,
          sourceUrl: sourceUrl,
          displayNumber: display.isEmpty ? 'NA' : display,
          caseNumber: caseNo.isEmpty ? null : caseNo,
          caseOrder: order.isEmpty ? null : order,
          caseTiming: timing.isEmpty ? null : timing,
          caseStatus: status.isEmpty ? 'Live' : status,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (parsedRows.isNotEmpty) {
      return parsedRows.take(40).toList();
    }

    String extract(String pattern) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
      if (match == null) return '';
      final value = (match.groupCount >= 1 ? match.group(1) : null) ?? '';
      return _stripHtml(value);
    }

    final displayNumber = extract(r'(?:display\s*number|board\s*number|token\s*number)\s*[:\-]?\s*([A-Za-z0-9\-/]+)');
    final caseNumber = extract(r'(?:case\s*(?:no|number))\s*[:\-]?\s*([A-Za-z0-9\-/]+)');
    final caseOrder = extract(r'(?:case\s*order|order\s*number|serial\s*number)\s*[:\-]?\s*([A-Za-z0-9\-/]+)');
    final caseTiming = extract(r'(?:timing|time|hearing\s*time)\s*[:\-]?\s*([0-9]{1,2}[:.][0-9]{2}\s*(?:AM|PM)?)');
    final caseStatus = extract(r'(?:status|stage)\s*[:\-]?\s*([A-Za-z\s]+)');

    if (displayNumber.isEmpty && caseNumber.isEmpty) return const <CourtDisplayBoardItem>[];

    return <CourtDisplayBoardItem>[
      CourtDisplayBoardItem(
        courtKey: courtKey,
        courtName: courtName,
        courtType: courtType,
        sourceUrl: sourceUrl,
        displayNumber: displayNumber.isEmpty ? 'NA' : displayNumber,
        caseNumber: caseNumber.isEmpty ? null : caseNumber,
        caseOrder: caseOrder.isEmpty ? null : caseOrder,
        caseTiming: caseTiming.isEmpty ? null : caseTiming,
        caseStatus: caseStatus.isEmpty ? 'Live' : caseStatus,
        updatedAt: DateTime.now(),
      ),
    ];
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _firstMatching(List<String> values, List<RegExp> patterns) {
    for (final value in values) {
      for (final pattern in patterns) {
        if (pattern.hasMatch(value)) return value;
      }
    }
    return '';
  }
}
