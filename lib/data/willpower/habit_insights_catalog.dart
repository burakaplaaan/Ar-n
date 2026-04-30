// Alışkanlık / bırakma konularına göre İslami + sağlık içerikleri (JSON).

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/willpower_templates.dart';
import '../../core/willpower/recovery_progress.dart';
import '../../data/models/habit_model.dart';

class HabitInsightCardData {
  const HabitInsightCardData({
    required this.kind,
    required this.title,
    required this.body,
    this.reference,
  });

  final String kind;
  final String title;
  final String body;
  final String? reference;

  bool get isIslamic => kind == 'islamic';
  bool get isMedical => kind == 'medical';
}

class HabitInsightBundle {
  const HabitInsightBundle({
    required this.sectionTitle,
    required this.cards,
    this.contextSubtitle,
  });

  final String sectionTitle;
  final List<HabitInsightCardData> cards;
  final String? contextSubtitle;
}

class HabitInsightsCatalog {
  HabitInsightsCatalog._(this._bundles);

  final Map<String, HabitInsightBundle> _bundles;

  HabitInsightBundle bundleFor(String key, {required bool quitContext}) {
    final fallback = quitContext ? 'default_bad' : 'default_good';
    return _bundles[key] ?? _bundles[fallback] ?? _bundles.values.first;
  }

  /// Ağ yok / asset hatası — senkron yedek.
  static HabitInsightsCatalog embeddedSync() =>
      HabitInsightsCatalog._(_embedded());

  static Future<HabitInsightsCatalog> load() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/willpower/habit_insights.json');
      final j = json.decode(raw) as Map<String, dynamic>;
      final map = <String, HabitInsightBundle>{};
      final bundles = j['bundles'] as Map<String, dynamic>? ?? {};
      for (final e in bundles.entries) {
        map[e.key] = _parseBundle(e.value as Map<String, dynamic>);
      }
      if (map.isEmpty) return HabitInsightsCatalog._(_embedded());
      return HabitInsightsCatalog._(map);
    } catch (_) {
      return HabitInsightsCatalog._(_embedded());
    }
  }

  static HabitInsightBundle _parseBundle(Map<String, dynamic> j) {
    final title = j['sectionTitle'] as String? ?? 'İki bakış';
    final cards = (j['cards'] as List<dynamic>? ?? []).map((c) {
      final m = c as Map<String, dynamic>;
      return HabitInsightCardData(
        kind: m['kind'] as String? ?? 'islamic',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        reference: m['reference'] as String?,
      );
    }).toList();
    return HabitInsightBundle(sectionTitle: title, cards: cards);
  }

  static Map<String, HabitInsightBundle> _embedded() {
    HabitInsightBundle mini(String title, List<Map<String, String>> cards) {
      return _parseBundle({
        'sectionTitle': title,
        'cards': cards,
      });
    }

    return {
      'default_good': mini('İki bakış', [
        {
          'kind': 'islamic',
          'title': 'Devamlılık',
          'body':
              'Allah en çok devamlı olunan ameli sever. İyi alışkanlıklar küçük adımlarla büyür.',
        },
        {
          'kind': 'medical',
          'title': 'Rutin',
          'body':
              'Düzenli tekrar davranışı otomatikleştirir; stres yönetimine katkı sağlayabilir.',
        },
      ]),
      'default_bad': mini('İki bakış', [
        {
          'kind': 'islamic',
          'title': 'Sabır',
          'body': 'Bırakmak sabır ister; her temiz gün bir zaferdir.',
        },
        {
          'kind': 'medical',
          'title': 'Süreç',
          'body':
              'Bırakırken dalgalanmalar normaldir; gerektiğinde uzman desteği düşün.',
        },
      ]),
      'quran_daily': mini('Kur’an · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Tilavet',
          'body': 'Kalpler ancak Allah’ı anmakla huzur bulur.',
          'reference': 'Ra’d 13:28 — meal anlamı',
        },
        {
          'kind': 'medical',
          'title': 'Odak',
          'body': 'Sessiz okuma nefes ve dikkat için kısa bir mola sunabilir.',
        },
      ]),
      'quit_smoking': mini('Sigara · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Emanet',
          'body': 'Bedenine zarar verenden kaçınmak emanete saygıdır.',
        },
        {
          'kind': 'medical',
          'title': 'İyileşme',
          'body': 'Bıraktıkça kalp ve solunum sistemi iyileşme eğilimindedir.',
        },
      ]),
      'quit_screen': mini('Ekran · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Vakit',
          'body':
              'Asr ile hatırlanır: zaman sermayedir; boşa harcamaktan sakınmak erdemdir.',
        },
        {
          'kind': 'medical',
          'title': 'Dikkat',
          'body':
              'Ekran molaları uyku ve odak için destekleyici olabilir; sınır koymak yorgunluğu azaltır.',
        },
      ]),
      'quit_alcohol': mini('Alkol · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Haramdan sakınma',
          'body': 'İçkiden uzak durmak kalbi ve aklı korumaya yardım eder.',
        },
        {
          'kind': 'medical',
          'title': 'Beden',
          'body':
              'Alkolü bıraktıkça karaciğer ve uyku düzeni birçok kişide toparlanma eğilimindedir.',
        },
      ]),
      'quit_substance': mini('Madde · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Şifa ve sebep',
          'body':
              'Şifa Allah’tandır; tedavi ve güvenilir destek de kulluğun parçasıdır.',
        },
        {
          'kind': 'medical',
          'title': 'Destek',
          'body':
              'Madde bağımlılığında uzman yardımı çoğu zaman gereklidir; yalnız mücadele zorunlu değildir.',
        },
      ]),
      'quit_zina': mini('İffet · iki bakış', [
        {
          'kind': 'islamic',
          'title': 'Mahremiyet',
          'body': 'Gözü ve kalbi korumak iffet yolunda temel adımlardandır.',
        },
        {
          'kind': 'medical',
          'title': 'Sınır',
          'body':
              'Tetikleyicileri azaltmak ve sınır koymak ruh hali istikrarını destekleyebilir.',
        },
      ]),
      'custom_good': mini('', [
        {
          'kind': 'islamic',
          'title': 'Niyet',
          'body':
              'Hayırlı alışkanlığı Allah rızası için sürdürmek bereket katar.',
        },
        {
          'kind': 'medical',
          'title': 'Uyku-uyanıklık',
          'body': 'Sabit saatler enerji ve odak için destekleyici olabilir.',
        },
      ]),
      'custom_bad': mini('', [
        {
          'kind': 'islamic',
          'title': 'Tövbe',
          'body': 'Kötü alışkanlıktan yüz çevirmek yenilenmenin parçasıdır.',
        },
        {
          'kind': 'medical',
          'title': 'Bağımlılık',
          'body':
              'Ödül sistemi etkilenir; geri dönüşler olabilir, destek faydalıdır.',
        },
      ]),
    };
  }
}

typedef HabitInsightCardReplacer = List<HabitInsightCardData>? Function(
  String bundleKey,
  List<HabitInsightCardData> originalCards,
);

List<HabitInsightCardData> _resolveInsightCards(
  String bundleKey,
  List<HabitInsightCardData> base,
  HabitInsightCardReplacer? cardReplacer,
) {
  final r = cardReplacer?.call(bundleKey, base);
  if (r != null && r.length >= 2) {
    return [r[0], r[1]];
  }
  return base;
}

({HabitModel habit, int streak, bool completedToday})? _pickPrimaryInsightItem(
  List<({HabitModel habit, int streak, bool completedToday})> items, {
  required bool quitTab,
}) {
  if (items.isEmpty) return null;
  final ranked = [...items];
  ranked.sort((a, b) {
    int score(({HabitModel habit, int streak, bool completedToday}) e) {
      final habit = e.habit;
      var s = 0;
      if (!e.completedToday) s += 100;
      s += (30 - e.streak).clamp(0, 30);
      if (quitTab && WillpowerTemplates.isFullQuitProgram(habit.templateId)) {
        s += 80;
      }
      if (!quitTab && habit.templateId == WillpowerTemplates.quranDaily) {
        s += 40;
      }
      return s;
    }

    final byScore = score(b) - score(a);
    if (byScore != 0) return byScore;
    final byStreak = a.streak.compareTo(b.streak);
    if (byStreak != 0) return byStreak;
    return b.habit.createdAt.compareTo(a.habit.createdAt);
  });
  return ranked.first;
}

/// Sekme ve öncelikli alışkanlığa göre içerik anahtarı + bağlam alt başlığı.
HabitInsightBundle resolveHabitInsights({
  required HabitInsightsCatalog catalog,
  required bool quitTab,
  required List<({HabitModel habit, int streak, bool completedToday})> items,
  HabitInsightCardReplacer? cardReplacer,
}) {
  final primaryItem = _pickPrimaryInsightItem(items, quitTab: quitTab);
  final primary = primaryItem?.habit;

  late String key;
  if (quitTab) {
    if (primary == null) {
      key = 'default_bad';
    } else if (WillpowerTemplates.isFullQuitProgram(primary.templateId)) {
      key = switch (primary.templateId) {
        WillpowerTemplates.quitSmoking => 'quit_smoking',
        WillpowerTemplates.quitScreen => 'quit_screen',
        WillpowerTemplates.quitAlcohol => 'quit_alcohol',
        WillpowerTemplates.quitSubstance => 'quit_substance',
        WillpowerTemplates.quitZina => 'quit_zina',
        _ => 'custom_bad',
      };
    } else {
      key = 'custom_bad';
    }
  } else {
    if (primary == null) {
      key = 'default_good';
    } else if (primary.templateId == WillpowerTemplates.quranDaily) {
      key = 'quran_daily';
    } else {
      key = 'custom_good';
    }
  }

  final base = catalog.bundleFor(key, quitContext: quitTab);
  final subtitle =
      primary != null ? '“${primary.title}” için özel notlar' : null;

  // Tam Arınma programları: üst başlık/alt başlık yok; yalnızca kartlar.
  if (quitTab &&
      primary != null &&
      WillpowerTemplates.isFullQuitProgram(primary.templateId)) {
    return HabitInsightBundle(
      sectionTitle: '',
      cards: _resolveInsightCards(key, base.cards, cardReplacer),
      contextSubtitle: null,
    );
  }

  // Özel takip (Gelişim / Arınma): "Hedefin · iki bakış" vb. ve üçgen + özel not satırı yok.
  if (key == 'custom_good' || key == 'custom_bad') {
    return HabitInsightBundle(
      sectionTitle: '',
      cards: _resolveInsightCards(key, base.cards, cardReplacer),
      contextSubtitle: null,
    );
  }

  return HabitInsightBundle(
    sectionTitle: base.sectionTitle,
    cards: _resolveInsightCards(key, base.cards, cardReplacer),
    contextSubtitle: subtitle,
  );
}

String medicalFootnote() => RecoveryProgress.medicalDisclaimerTr();
