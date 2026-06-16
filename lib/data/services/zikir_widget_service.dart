import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'arin_widget_sync.dart';

/// Zikirmatik widget'ı ile uygulama oturumu arasındaki köprü.
///
/// TEK paylaşılan otorite kümülatif sayaç (`arin_zikir_count`)'tir. Hem
/// uygulama (zikir sayfasında her tıkta) hem de native widget'taki "+1" butonu
/// bu değeri okuyup yazar. Uygulama foreground'a döndüğünde widget'ın yazdığı
/// güncel toplam okunur ve oturum (total/round/tur) kaldığı yerden devam
/// edecek şekilde yeniden hesaplanır.
abstract final class ZikirWidgetService {
  /// Aktif oturumu widget'a yansıtır.
  ///
  /// Read-modify-write: widget'taki kümülatif sayaç oturumdan ilerideyse
  /// (kullanıcı arka planda "+1" bastıysa) onu DÜŞÜRMEYİZ — aksi halde
  /// debounce'lı bayat bir yazım widget tıklarını kalıcı olarak silerdi.
  /// Yalnızca [allowDecrease] (oturum sıfırlama) açıkça izin verir.
  static Future<void> pushSession({
    required String phrase,
    required int total,
    required int round,
    required int tur,
    required int target,
    bool allowDecrease = false,
  }) async {
    var effTotal = total;
    var effRound = round;
    var effTur = tur;
    if (!allowDecrease) {
      final widgetTotal = await readWidgetTotal();
      if (widgetTotal != null && widgetTotal > total) {
        final rec = reconcile(
          sessionTotal: total,
          sessionRound: round,
          sessionTur: tur,
          target: target,
          widgetTotal: widgetTotal,
        );
        effTotal = rec.total;
        effRound = rec.round;
        effTur = rec.tur;
      }
    }
    await ArinWidgetSync.pushZikir(
      phrase: phrase,
      count: effTotal,
      round: effRound,
      tur: effTur,
      target: target,
    );
  }

  /// Widget'ın (native +1 butonu) yazdığı kümülatif toplamı okur. Henüz hiç
  /// yazılmamışsa `null` döner.
  static Future<int?> readWidgetTotal() async {
    if (kIsWeb) return null;
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.zikirCount,
      );
      if (raw == null || raw.isEmpty) return null;
      final n = int.tryParse(raw) ?? double.tryParse(raw)?.toInt();
      if (n == null || n < 0) return null;
      return n;
    } catch (e) {
      debugPrint('ZikirWidgetService.readWidgetTotal: $e');
      return null;
    }
  }

  /// Widget toplamı oturum toplamından ileriyse (kullanıcı widget'tan saydı),
  /// round/tur değerlerini tur tamamlamalarını da hesaba katarak ilerletir.
  /// Saf fonksiyon — test edilebilir, yan etkisiz.
  static ({int total, int round, int tur}) reconcile({
    required int sessionTotal,
    required int sessionRound,
    required int sessionTur,
    required int target,
    required int widgetTotal,
  }) {
    if (widgetTotal <= sessionTotal) {
      return (total: sessionTotal, round: sessionRound, tur: sessionTur);
    }
    final delta = widgetTotal - sessionTotal;
    if (target < 1) {
      return (total: widgetTotal, round: sessionRound + delta, tur: sessionTur);
    }
    final combinedRound = sessionRound + delta;
    final tursCompleted = combinedRound ~/ target;
    return (
      total: widgetTotal,
      round: combinedRound % target,
      tur: sessionTur + tursCompleted,
    );
  }
}
