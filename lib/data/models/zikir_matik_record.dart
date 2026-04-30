// lib/data/models/zikir_matik_record.dart

class ZikirMatikRecord {
  const ZikirMatikRecord({
    required this.id,
    required this.phrase,
    required this.totalCount,
    required this.tur,
    required this.target,
    required this.savedAtMillis,
  });

  final String id;
  final String phrase;
  final int totalCount;
  final int tur;
  final int target;
  final int savedAtMillis;

  DateTime get savedAt =>
      DateTime.fromMillisecondsSinceEpoch(savedAtMillis, isUtc: false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'phrase': phrase,
        'totalCount': totalCount,
        'tur': tur,
        'target': target,
        'savedAtMillis': savedAtMillis,
      };

  static ZikirMatikRecord? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = j['id'] as String?;
    final phrase = j['phrase'] as String?;
    if (id == null || phrase == null) return null;
    return ZikirMatikRecord(
      id: id,
      phrase: phrase,
      totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
      tur: (j['tur'] as num?)?.toInt() ?? 1,
      target: (j['target'] as num?)?.toInt() ?? 33,
      savedAtMillis: (j['savedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
