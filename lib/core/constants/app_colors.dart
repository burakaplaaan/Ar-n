// lib/core/constants/app_colors.dart
// Uygulamanın tüm renk sabitlerini tanımlar.
// Renk paleti: Koyu Zümrüt Yeşili, açık tema (muted krem) ve Antrasit.
//
// ─── TASARIM SÜRÜMÜ ─────────────────────────────────────────────────────
// v3 "Hub Match" AKTİF. Shell gradient'i alışkanlık takibi hub'ının
// (`_HubBackground`) arka planıyla bire bir aynı: topLeft→bottomRight
// koyu zümrüt-siyah 3 durak + sağ üst yumuşak zümrüt daire + sol alt
// yumuşak üçgen watermark. Her sekme aynı görsel dili konuşur.
//
// Eskiye dönüş:
//   • v2 "Eucalyptus Night"  → bu dosyadaki "ESKİ v2:" hex'lerini aktif et,
//     v3 değerlerini yoruma al. arin_shell_background.dart içinde de
//     "v2 GRADIENT" bloğunu aç.
//   • v1 ilk sürüm            → "ESKİ v1:" hex'lerini aktif et.
//
// Tüm uygulama bu sabitleri kullanır; başka dosyada renk düzeltmek
// gerekmez.
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// ARIN uygulamasının merkezi renk paleti.
/// Tüm widget'lar bu sınıftaki sabitleri kullanmalıdır.
abstract final class AppColors {
  // ─── Zümrüt Yeşili Ailesi ───────────────────────────────────────────
  /// Ana marka rengi — koyu zümrüt
  static const Color emeraldDark = Color(0xFF1B4D3E);

  /// Orta ton zümrüt — kart border, actif ikon
  static const Color emeraldMid = Color(0xFF2D7A5F);

  /// Açık zümrüt — hafif vurgu, ripple
  static const Color emeraldLight = Color(0xFF4CAF87);

  /// Temel zümrüt yeşili
  static const Color emeraldBase = Color(0xFF235A47);

  /// Çok açık zümrüt — chip arka plan, ısı haritası tonu-1
  static const Color emeraldFaint = Color(0xFFB2DFCE);

  // ─── Açık tema (sıcak krem / kağıt — beyaz hissi azaltılmış) ─
  /// Ana zemin tonu (gradient orta)
  static const Color creamBase = Color(0xFFDAD4C9);

  /// Kart / yüzey — zeminden hafif ayrılan sıcak kağıt
  static const Color creamSurface = Color(0xFFE8E4DC);

  /// Bölücü / kenar
  static const Color creamDark = Color(0xFFC5BFB0);

  /// Shell gradient üstü
  static const Color creamMist = Color(0xFFE3DFD4);

  /// Shell gradient altı
  static const Color creamShellDeep = Color(0xFFCEC8BC);

  // ─── Antrasit / Karanlık Tonlar ─────────────────────────────────────
  /// Premium Deep Navy/Anthracite Background
  static const Color backgroundNavy = Color(0xFF0B0D14);

  /// Ana sayfa — üst gradient (v3: alışkanlık hub'ının sol-üst zümrüt-siyahı).
  /// ESKİ v2: 0xFF153C2D (Eucalyptus Night — çok doygun/açık geldi)
  /// ESKİ v1: 0xFF0F2419 (orman yeşili)
  static const Color homeGradientTop = Color(0xFF030806);

  /// Ana sayfa — gradient orta durak (v3: hub merkez yumuşak zümrüt).
  /// ESKİ v2: 0xFF0D271E
  static const Color homeGradientMid = Color(0xFF0A1610);

  /// Ana sayfa — alt gradient (v3: hub'ın sağ-alt siyah-yeşili).
  /// ESKİ v2: 0xFF081511 (koyu yeşil, kontrast düşüktü)
  /// ESKİ v1: 0xFF030806 (saf siyah)
  static const Color homeGradientBottom = Color(0xFF050A07);

  /// Alt bar — zemin ile kontrast için hafif yeşil-siyah (v3: zeminden görünür
  /// ayrılsın diye v2 değerinde tutulur). İstenirse 0xFF060F0A'ya çekilerek
  /// zemine daha da yakınlaştırılabilir.
  /// ESKİ v1: 0xFF050C08
  static const Color shellBarBg = Color(0xFF0A1812);

  /// Cam kart / vurgu kenarı (neon zümrüt — koyu shell üzeri)
  static const Color accentNeonGreen = Color(0xFF4ADE80);

  /// Açık krem zemin üzeri vurgu (neon yerine doygun zümrüt-yeşil)
  static const Color accentGreenOnLight = Color(0xFF2F8F68);

  /// Orta FAB gradient üstü
  static const Color accentGlowGreen = Color(0xFF22C55E);
  
  /// Premium Card Surface (Cam Efekti için zemin)
  static const Color cardSurface = Color(0xFF151822);

  /// Ana sayfa kartları — hafif yeşil cam.
  /// v3: zemin koyulaştığı için kart yüzeyini v2 (0xFF142A22) gibi yukarı
  /// bırakmak kartları zeminden daha da ayrıştırıyor → koruyoruz.
  /// ESKİ v1: 0xFF0C1610 (zemin çok koyuyken kart belirgin değildi)
  static const Color homeCardSurface = Color(0xFF142A22);
  
  /// Glow için Premium Accent Mor/Mavi
  static const Color accentPurple = Color(0xFF5E5CE6);
  
  /// Gold / Amber Vurgu
  static const Color goldAccent = Color(0xFFFFD700);

  // ─── Süsleme / Ornament (sıcak "kahve rengi" altın-bronz) ────────────
  /// Koyu shell üzeri kart süslemesi — köşe motifleri ve ince çerçeve.
  /// Sıcak mat altın-bronz; neon yeşil ile birlikte premium "kahve rengi
  /// detay" hissini verir.
  static const Color ornamentGold = Color(0xFFB88E47);

  /// Açık (krem) tema üzeri süsleme — krem zeminde okunması için daha koyu
  /// bronz ton.
  static const Color ornamentGoldDeep = Color(0xFF9D7438);

  /// İyileştirici Frekanslar — teal vurgu (mock)
  static const Color healingTeal = Color(0xFF26C6DA);

  /// İyileştirici Frekanslar — ambiyans slider / uyku vurgusu
  static const Color healingOrange = Color(0xFFFF9500);

  /// Derin arka plan — eski dark mode
  static const Color anthraciteDark = Color(0xFF1A1F1C);

  /// Orta antrasit — dark mode kart yüzeyi
  static const Color anthraciteMid = Color(0xFF242B26);

  /// Açık antrasit — dark mode bölücü
  static const Color anthraciteLight = Color(0xFF3A4A3E);

  // ─── Metin Renkleri ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1F1C);
  static const Color textSecondary = Color(0xFF4A5A4E);
  static const Color textMuted = Color(0xFF8A9E8F);
  static const Color textOnDark = Color(0xFFF5F0E8);
  static const Color textOnDarkMuted = Color(0xFFB2C4B6);

  // ─── Glassmorphism Katmanları ────────────────────────────────────────
  /// Cam yüzeyi — beyaz saydamlık
  static const Color glassWhite = Color(0x1AFFFFFF);

  /// Cam kenarlığı
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Cam gölgesi
  static const Color glassShadow = Color(0x26000000);

  // ─── Isı Haritası Tonları (skor 1-10) ───────────────────────────────
  /// Renk fonksiyonu: skor 0→10 arasında zümrüt tonu üretir
  static Color heatmapColor(int score) {
    if (score <= 0) return creamDark;
    final t = (score.clamp(1, 10) / 10.0);
    return Color.lerp(emeraldFaint, emeraldDark, t) ?? emeraldFaint;
  }

  // ─── Fonksiyonel Renkler ────────────────────────────────────────────
  static const Color success = Color(0xFF2D7A5F);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF2C6E84);

  // ─── Açık / koyu shell üzeri metin (hub, ana sayfa gradient vb.) ─────

  static bool _isLightShell(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  /// Açık gradient üzerinde başlık; koyu temada açık metin.
  static Color shellOnCanvasPrimary(BuildContext context) =>
      _isLightShell(context) ? emeraldDark : textOnDark;

  /// İkincil paragraf / alt başlık.
  static Color shellOnCanvasSecondary(BuildContext context) =>
      _isLightShell(context) ? textSecondary : textOnDarkMuted;

  /// Daha sakin üçüncül metin (CTA altı vb.).
  static Color shellOnCanvasTertiary(BuildContext context) =>
      _isLightShell(context)
          ? const Color(0xFF5D6E64)
          : creamBase.withValues(alpha: 0.72);
}
