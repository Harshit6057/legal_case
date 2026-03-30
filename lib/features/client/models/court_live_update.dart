import 'package:cloud_firestore/cloud_firestore.dart';

class CourtLiveUpdate {
  const CourtLiveUpdate({
    required this.caseId,
    required this.caseNumber,
    required this.caseTitle,
    required this.courtName,
    required this.courtType,
    required this.hasDisplayBoard,
    this.hearingTime,
    this.queueNumber,
    this.caseOrder,
    this.reportability,
    this.nextScheduledAt,
    this.lastUpdatedAt,
    this.boardText,
    this.sourceUrl,
  });

  final String caseId;
  final String caseNumber;
  final String caseTitle;
  final String courtName;
  final String courtType;
  final bool hasDisplayBoard;
  final DateTime? hearingTime;
  final int? queueNumber;
  final int? caseOrder;
  final String? reportability;
  final DateTime? nextScheduledAt;
  final DateTime? lastUpdatedAt;
  final String? boardText;
  final String? sourceUrl;

  bool get isDistrictCourt => courtType.toLowerCase() == 'district court';

  bool get isReportable => (reportability ?? '').toLowerCase() == 'reportable';

  bool get isUnreportable => (reportability ?? '').toLowerCase() == 'unreportable';

  static CourtLiveUpdate fromBookingRequestDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final caseNumberRaw = (data['caseNumber'] ?? '').toString().trim();
    final caseTitleRaw = (data['caseTitle'] ?? '').toString().trim();
    final courtTypeRaw = (data['courtType'] ?? '').toString().trim();

    return CourtLiveUpdate(
      caseId: doc.id,
      caseNumber: caseNumberRaw.isEmpty
          ? doc.id.substring(0, doc.id.length >= 8 ? 8 : doc.id.length).toUpperCase()
          : caseNumberRaw,
      caseTitle: caseTitleRaw.isEmpty ? 'Untitled Case' : caseTitleRaw,
      courtName: (data['courtName'] ?? 'Court not assigned').toString(),
      courtType: courtTypeRaw.isEmpty ? 'District Court' : courtTypeRaw,
      hasDisplayBoard: data['hasDisplayBoard'] == true,
      hearingTime: parseDate(data['hearingTime']),
      queueNumber: parseInt(data['queueNumber']),
      caseOrder: parseInt(data['caseOrder']),
      reportability: (data['reportability'] ?? '').toString().trim().isEmpty
          ? null
          : (data['reportability'] as String).trim(),
      nextScheduledAt: parseDate(data['scheduledDate']),
      lastUpdatedAt: parseDate(data['courtLastUpdatedAt'] ?? data['updatedAt']),
      boardText: (data['boardText'] ?? '').toString().trim().isEmpty
          ? null
          : (data['boardText'] as String).trim(),
      sourceUrl: (data['courtSourceUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (data['courtSourceUrl'] as String).trim(),
    );
  }
}
