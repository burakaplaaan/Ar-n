// lib/data/models/zikir_matik_tur_log.dart

/// Tamamlanan bir tur (hedef sayıya ulaşıldığında) için otomatik kayıt.
class ZikirMatikTurLog {
  const ZikirMatikTurLog({
    required this.id,
    required this.phrase,
    required this.completedTur,
    required this.target,
    required this.totalCountAtEvent,
    required this.recordedAtMillis,
  });

  final String id;
  final String phrase;
  /// Tamamlanan tur numarası (zikirmatikteki “Tur” etiketi o andaki değer).
  final int completedTur;
  final int target;
  final int totalCountAtEvent;
  final int recordedAtMillis;

  DateTime get recordedAt =>
      DateTime.fromMillisecondsSinceEpoch(recordedAtMillis, isUtc: false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'phrase': phrase,
        'completedTur': completedTur,
        'target': target,
        'totalCountAtEvent': totalCountAtEvent,
        'recordedAtMillis': recordedAtMillis,
      };

  static ZikirMatikTurLog? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = j['id'] as String?;
    final phrase = j['phrase'] as String?;
    if (id == null || phrase == null) return null;
    return ZikirMatikTurLog(
      id: id,
      phrase: phrase,
      completedTur: (j['completedTur'] as num?)?.toInt() ?? 1,
      target: (j['target'] as num?)?.toInt() ?? 33,
      totalCountAtEvent: (j['totalCountAtEvent'] as num?)?.toInt() ?? 0,
      recordedAtMillis: (j['recordedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
