// Keşfet Reels — kullanılan Google Fonts kaydı (Türkçe + Arapça).
// Yeni font eklerken: `inspiration_reels_layer.dart` içindeki `reelsStyle` /
// Arapça slot eşlemesini ve `safeReelsStyle` üst sınırını güncelle.

/// Türkçe satırlar — `reelsStyle` → GoogleFonts.*
/// 0 Playfair · 1 Inter · 2 EB Garamond · 3 Playfair sola · 4 Playfair kalın ·
/// 5 Roboto Condensed · 6 Lora · 7 Cormorant Garamond · 8 Quicksand ·
/// 9 Cabin Sketch (tebeşir) · 10 Bodoni + Montserrat (şiirsel başlık + CAPS) ·
/// 11 Great Vibes + Lora (üst el yazısı, alt serife tan) ·
/// 12 Satisfy + Lora + Playfair italic (üç katman) ·
/// 13 Playfair italic + `{{g:kelime}}` ile altın vurgu
abstract final class ReelsTurkishFonts {
  static const playfairDisplay = 'Playfair Display';
  static const inter = 'Inter';
  static const ebGaramond = 'EB Garamond';
  static const robotoCondensed = 'Roboto Condensed';
  static const lora = 'Lora';
  static const cormorantGaramond = 'Cormorant Garamond';
  static const quicksand = 'Quicksand';
  static const cabinSketch = 'Cabin Sketch';
  static const bodoniModa = 'Bodoni Moda';
  static const montserrat = 'Montserrat';
  static const greatVibes = 'Great Vibes';
  static const satisfy = 'Satisfy';
}

/// Arapça — `imageIndex % 3` ile dönüşümlü.
abstract final class ReelsArabicFonts {
  static const amiri = 'Amiri';
  static const scheherazadeNew = 'Scheherazade New';
  static const notoNaskhArabic = 'Noto Naskh Arabic';
}
