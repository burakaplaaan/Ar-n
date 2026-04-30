// Günlük dönen MANEVİ / SAĞLIK kart havuzları — Firestore `quote_pools/hub_*` + asset yedek.

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/quote_pool_ids.dart';
import '../repositories/quote_pools_repository.dart';
import 'habit_insights_catalog.dart';

/// Gelişim ve Arınma için ayrı islamic/medical listeleri.
class InsightQuotePools {
  const InsightQuotePools({
    required this.gelisimIslamic,
    required this.gelisimMedical,
    required this.arinmaIslamic,
    required this.arinmaMedical,
  });

  final List<HabitInsightCardData> gelisimIslamic;
  final List<HabitInsightCardData> gelisimMedical;
  final List<HabitInsightCardData> arinmaIslamic;
  final List<HabitInsightCardData> arinmaMedical;

  bool get isUsable =>
      gelisimIslamic.isNotEmpty &&
      gelisimMedical.isNotEmpty &&
      arinmaIslamic.isNotEmpty &&
      arinmaMedical.isNotEmpty;

  List<HabitInsightCardData> dailyPair(
    String bundleKey,
    DateTime localDate, {
    required bool quitTab,
  }) {
    final islamic = quitTab ? arinmaIslamic : gelisimIslamic;
    final medical = quitTab ? arinmaMedical : gelisimMedical;
    final salt = '${localDate.year}-${localDate.month}-${localDate.day}';
    final i = _stableHash('$bundleKey|islamic|$salt').abs() % islamic.length;
    final m = _stableHash('$bundleKey|medical|$salt').abs() % medical.length;
    return [islamic[i], medical[m]];
  }

  static int _stableHash(String s) {
    var h = 0;
    for (final u in s.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return h;
  }

  static List<HabitInsightCardData> _parseList(
    List<Map<String, dynamic>> items,
    String kind,
  ) {
    return items.map((m) {
      return HabitInsightCardData(
        kind: kind,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        reference: m['reference'] as String?,
      );
    }).toList();
  }

  /// Asset `insight_quote_pools.json` (iki liste) — yedek.
  static Future<({List<HabitInsightCardData> islamic, List<HabitInsightCardData> medical})>
      _loadAssetTwoLists() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/willpower/insight_quote_pools.json');
      final j = json.decode(raw) as Map<String, dynamic>;
      return (
        islamic: _parseList(
          (j['islamic'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'islamic',
        ),
        medical: _parseList(
          (j['medical'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'medical',
        ),
      );
    } catch (_) {
      final j = json.decode(kInsightHubEmbeddedJson) as Map<String, dynamic>;
      return (
        islamic: _parseList(
          (j['islamic'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'islamic',
        ),
        medical: _parseList(
          (j['medical'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'medical',
        ),
      );
    }
  }

  static Future<InsightQuotePools> loadWithPools(QuotePoolsRepository r) async {
    await Future.wait([
      r.ensureSyncedToday(QuotePoolIds.hubGelisimIslamic),
      r.ensureSyncedToday(QuotePoolIds.hubGelisimMedical),
      r.ensureSyncedToday(QuotePoolIds.hubArinmaIslamic),
      r.ensureSyncedToday(QuotePoolIds.hubArinmaMedical),
    ]);

    final gI = _parseList(r.itemsFromCache(QuotePoolIds.hubGelisimIslamic), 'islamic');
    final gM = _parseList(r.itemsFromCache(QuotePoolIds.hubGelisimMedical), 'medical');
    final aI = _parseList(r.itemsFromCache(QuotePoolIds.hubArinmaIslamic), 'islamic');
    final aM = _parseList(r.itemsFromCache(QuotePoolIds.hubArinmaMedical), 'medical');

    final asset = await _loadAssetTwoLists();
    return InsightQuotePools(
      gelisimIslamic: gI.isNotEmpty ? gI : asset.islamic,
      gelisimMedical: gM.isNotEmpty ? gM : asset.medical,
      arinmaIslamic: aI.isNotEmpty ? aI : asset.islamic,
      arinmaMedical: aM.isNotEmpty ? aM : asset.medical,
    );
  }
}

/// Yerleşik hub kartları (Firestore tohumlama + asset yedek).
const String kInsightHubEmbeddedJson = '''
{
  "islamic": [
    {"title": "Devamlılık", "body": "Allah en çok devamlı olunan ameli sever. Küçük ama sürekli adımlar, hayırlı alışkanlığı kök saldırır.", "reference": "Hadis — devamlılık (meal anlamı)"},
    {"title": "Niyet", "body": "Ameller niyetlere göredir. İyi bir alışkanlığı O’nun rızası için sürdürmek, ona bereket ve manevi derinlik katar.", "reference": "Hadis — niyet (meal anlamı)"},
    {"title": "Sabır", "body": "Sabır, imanın kandilidir. Zorlandığında yavaşlamak değil, doğruda kalmak; Allah’ın yardımı sabredenledir.", "reference": "Bakara 2:153 — meal anlamı"},
    {"title": "Tevekkül", "body": "Sebepleri kullan, sonucu Allah’a bırak. Çaba ile birlikte tevekkül, kalbi hafifletir.", "reference": "Tevbe 9:51 — meal anlamı"},
    {"title": "Şükür", "body": "Az da olsa verilen nimeti görmek, kalbi genişletir. Şükür, yeni hayırlara kapı aralayabilir.", "reference": "İbrahim 14:7 — meal anlamı"},
    {"title": "Tefekkür", "body": "Gökleri ve yeri düşünmek, Allah’ın kudretine yönelmektir. Kısa bir duraklama bile kalbi tazeler.", "reference": "Âl-i İmrân 3:191 — meal anlamı"},
    {"title": "İstiğfar", "body": "İnsan hataya meyillidir; tövbe kapısı açıktır. Kalbi yumuşatan bir tövbe, yeniden başlamaktır.", "reference": "Nûh 71:10-12 — meal anlamı"},
    {"title": "Salâh", "body": "Namaz, mümine vuslattır. Gün içinde vakitlere yaslanmak, düzeni ve iç huzuru besler.", "reference": "Ra’d 13:28 — meal anlamı"},
    {"title": "Kur’an", "body": "Kalpler ancak Allah’ı anmakla mutmain olur. Her gün bir miktar tilavet, ruhu besler.", "reference": "Ra’d 13:28 — meal anlamı"},
    {"title": "Emanet", "body": "Beden bir emanettir; ona iyi bakmak ve zarardan sakınmak kulluğun parçasıdır.", "reference": "A’râf 7:56 — meal anlamı (zarardan sakınma)"}
  ],
  "medical": [
    {"title": "Uyku ve ritim", "body": "Düzenli yatış-kalkış, birçok kişide uyku kalitesini ve gündüz enerjisini destekler."},
    {"title": "Stres tepkisi", "body": "Kronik stres uyku, iştah ve odak üzerinde etkili olabilir; nefes ve molalar faydalı olabilir."},
    {"title": "Alışkanlık döngüsü", "body": "Tekrarlayan davranışlar beyinde yollar oluşturur; yeni rutinler zaman ve tekrar ister."},
    {"title": "Hareket", "body": "Hafif-orta tempolu düzenli hareket, ruh hâli ve uyku için çoğu rehberde önerilir."},
    {"title": "Nefes", "body": "Yavaş ve derin nefes, parasempatik sistemi destekleyerek anlık gerginlikte rahatlama hissi verebilir."},
    {"title": "Ekran süresi", "body": "Gece ekranı uyku hormonunu olumsuz etkileyebilir; yatmadan önce sınır koymak uyku için destek olabilir."},
    {"title": "Sosyal destek", "body": "Güvenilir bir çevreyle paylaşmak, bırakma veya yeni rutin süreçlerinde dayanıklılığı artırabilir."},
    {"title": "Tetikleyiciler", "body": "Ortam ve zamanı fark etmek, istenmeyen alışkanlık döngüsünü kırmaya yardımcı olabilir."},
    {"title": "Bırakma dalgaları", "body": "İstek (craving) dalgalar halinde gelir; çoğu zaman dakikalar içinde zayıflar. Dalga geçene kadar bekle."},
    {"title": "İlerleme", "body": "Küçük kazanımlar birikir; grafik düz çizgi olmak zorunda değildir. Nazik ve sabırlı ol."}
  ]
}
''';
