class CourtDisplayBoardItem {
  const CourtDisplayBoardItem({
    required this.courtKey,
    required this.courtName,
    required this.courtType,
    required this.sourceUrl,
    required this.displayNumber,
    this.caseNumber,
    this.caseOrder,
    this.caseTiming,
    this.caseStatus,
    this.updatedAt,
  });

  final String courtKey;
  final String courtName;
  final String courtType;
  final String sourceUrl;
  final String displayNumber;
  final String? caseNumber;
  final String? caseOrder;
  final String? caseTiming;
  final String? caseStatus;
  final DateTime? updatedAt;

  bool get hasDisplayNumber {
    final value = displayNumber.trim().toUpperCase();
    if (value.isEmpty) return false;
    if (value == 'NA' || value == '*' || value == 'X') return false;
    return true;
  }

  factory CourtDisplayBoardItem.fromJson(Map<String, dynamic> json, {required String fallbackUrl}) {
    DateTime? parsedUpdatedAt;
    final rawUpdated = json['updatedAt'];
    if (rawUpdated is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdated);
    }

    return CourtDisplayBoardItem(
      courtKey: (json['courtKey'] ?? 'unknown').toString(),
      courtName: (json['courtName'] ?? 'Unknown Court').toString(),
      courtType: (json['courtType'] ?? 'Court').toString(),
      sourceUrl: (json['sourceUrl'] ?? fallbackUrl).toString(),
      displayNumber: (json['displayNumber'] ?? '').toString(),
      caseNumber: json['caseNumber']?.toString(),
      caseOrder: json['caseOrder']?.toString(),
      caseTiming: json['caseTiming']?.toString(),
      caseStatus: json['caseStatus']?.toString(),
      updatedAt: parsedUpdatedAt,
    );
  }
}
