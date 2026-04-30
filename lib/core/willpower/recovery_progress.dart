// Tahmini iyileşme göstergeleri (tıbbi teşhis değildir). Motivasyon amaçlı.
// Süreler: erken hızlı artış + uzun kuyruk; kaynaklara uygun özet ölçekler.

abstract final class RecoveryProgress {
  static double _piecewisePercent(int elapsedDays, List<(int day, double pct)> pts) {
    if (elapsedDays < 0) return 0;
    if (pts.isEmpty) return 0;
    if (elapsedDays >= pts.last.$1) return 100;
    for (var i = 0; i < pts.length - 1; i++) {
      final d0 = pts[i].$1;
      final p0 = pts[i].$2;
      final d1 = pts[i + 1].$1;
      final p1 = pts[i + 1].$2;
      if (elapsedDays <= d1) {
        final span = (d1 - d0).clamp(1, 999999);
        final t = (elapsedDays - d0) / span;
        return (p0 + t * (p1 - p0)).clamp(0.0, 100.0);
      }
    }
    return 100;
  }

  /// Solunum / akciğer — erken temizlik hızlı; tam asimptot ~8 yıl (kanser riski vb. ölçekleri).
  static double smokingLungPercent(int elapsedDays) => _piecewisePercent(elapsedDays, const [
        (0, 0),
        (3, 5),
        (14, 14),
        (30, 28),
        (90, 48),
        (180, 62),
        (365, 76),
        (730, 90),
        (2920, 100),
      ]);

  /// Kalp-damar — ilk yıl belirgin; ~3 yılda hedefe yaklaşım.
  static double smokingHeartPercent(int elapsedDays) => _piecewisePercent(elapsedDays, const [
        (0, 0),
        (1, 2),
        (30, 22),
        (90, 42),
        (180, 55),
        (365, 70),
        (730, 88),
        (1095, 100),
      ]);

  /// Diş / ağız estetiği — leke ve diş eti iyileşmesi ~1 yıl göstergesi.
  static double smokingTeethPercent(int elapsedDays) => _piecewisePercent(elapsedDays, const [
        (0, 0),
        (7, 12),
        (30, 35),
        (90, 62),
        (180, 80),
        (365, 100),
      ]);

  /// Koku ve tat — ilk haftalar hızlı toparlanma; tam olgunluk ~5 yıl (subjektif üst sınır).
  static double smokingSmellTastePercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (2, 15),
        (7, 35),
        (14, 48),
        (30, 58),
        (90, 72),
        (365, 88),
        (730, 94),
        (1825, 100),
      ]);

  static String medicalDisclaimerTr() =>
      'Tahmini iyileşme göstergesidir; tıbbi teşhis veya tedavi yerine geçmez.';

  // ─── Ekran / dijital sınır (motivasyon; tıbbi iddia yok) ─────────────
  static double screenFocusPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (3, 12),
        (7, 22),
        (14, 32),
        (30, 48),
        (60, 62),
        (90, 72),
        (180, 85),
        (365, 100),
      ]);

  static double screenSleepRhythmPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (5, 10),
        (14, 24),
        (30, 42),
        (60, 58),
        (90, 70),
        (180, 82),
        (365, 100),
      ]);

  static double screenAwarenessPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (1, 6),
        (7, 18),
        (21, 35),
        (45, 52),
        (90, 68),
        (180, 82),
        (365, 100),
      ]);

  static double screenInnerCalmPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (7, 8),
        (21, 20),
        (45, 38),
        (90, 55),
        (180, 72),
        (270, 85),
        (365, 100),
      ]);

  // ─── Alkol (motivasyon; tıbbi teşhis değildir) ───────────────────────
  static double alcoholLiverRecoveryPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (7, 8),
        (30, 22),
        (60, 38),
        (90, 50),
        (180, 68),
        (365, 85),
        (730, 100),
      ]);

  static double alcoholSleepStabilityPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (5, 12),
        (14, 28),
        (30, 45),
        (60, 60),
        (90, 72),
        (180, 88),
        (365, 100),
      ]);

  static double alcoholMoodBalancePercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (3, 10),
        (14, 26),
        (30, 42),
        (60, 58),
        (90, 70),
        (180, 85),
        (365, 100),
      ]);

  static double alcoholClarityPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (2, 8),
        (10, 24),
        (30, 45),
        (60, 62),
        (90, 75),
        (180, 90),
        (365, 100),
      ]);

  // ─── Madde (motivasyon + destek çizgisi; tıbbi değildir) ─────────────
  static double substanceBodyStabilizationPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (7, 15),
        (14, 28),
        (30, 45),
        (60, 60),
        (90, 72),
        (180, 85),
        (365, 100),
      ]);

  static double substanceSleepRhythmPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (5, 10),
        (14, 25),
        (30, 42),
        (60, 58),
        (90, 70),
        (180, 85),
        (365, 100),
      ]);

  static double substanceUrgeControlPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (3, 8),
        (14, 22),
        (30, 40),
        (60, 58),
        (90, 72),
        (180, 86),
        (365, 100),
      ]);

  static double substanceSupportPathPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (1, 12),
        (7, 28),
        (14, 40),
        (30, 55),
        (60, 70),
        (90, 82),
        (180, 100),
      ]);

  // ─── Zina / iffet (manevi motivasyon çizgileri) ─────────────────────
  static double zinaDisciplinePercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (3, 10),
        (7, 20),
        (14, 32),
        (30, 48),
        (60, 65),
        (90, 78),
        (180, 92),
        (365, 100),
      ]);

  static double zinaBoundaryStrengthPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (5, 12),
        (14, 28),
        (30, 45),
        (60, 62),
        (90, 75),
        (180, 88),
        (365, 100),
      ]);

  static double zinaHeartCalmPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (7, 10),
        (21, 26),
        (45, 44),
        (90, 62),
        (180, 80),
        (365, 100),
      ]);

  static double zinaTawbaSteadfastPercent(int elapsedDays) =>
      _piecewisePercent(elapsedDays, const [
        (0, 0),
        (1, 8),
        (10, 22),
        (30, 40),
        (60, 58),
        (90, 72),
        (180, 88),
        (365, 100),
      ]);
}
