// Bir zikir metnine özel sayaç (toplam / tur içi / tur no / hedef).
class ZikirMatikPhraseSession {
  const ZikirMatikPhraseSession({
    required this.total,
    required this.round,
    required this.tur,
    required this.target,
    this.updatedAtMillis = 0,
  });

  final int total;
  final int round;
  final int tur;
  final int target;
  final int updatedAtMillis;

  static const empty = ZikirMatikPhraseSession(
    total: 0,
    round: 0,
    tur: 1,
    target: 33,
  );

  ZikirMatikPhraseSession copyWith({
    int? total,
    int? round,
    int? tur,
    int? target,
    int? updatedAtMillis,
  }) {
    return ZikirMatikPhraseSession(
      total: total ?? this.total,
      round: round ?? this.round,
      tur: tur ?? this.tur,
      target: target ?? this.target,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'round': round,
        'tur': tur,
        'target': target,
        'updatedAtMillis': updatedAtMillis,
      };

  static ZikirMatikPhraseSession? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final round = (json['round'] as num?)?.toInt() ?? 0;
    final tur = (json['tur'] as num?)?.toInt() ?? 1;
    var target = (json['target'] as num?)?.toInt() ?? 33;
    if (target < 3) target = 33;
    return ZikirMatikPhraseSession(
      total: total.clamp(0, 999999),
      round: round.clamp(0, 999999),
      tur: tur < 1 ? 1 : tur,
      target: target.clamp(3, 9999),
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
