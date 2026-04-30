/// Keşfet yerel görselleri: `assets/inspiration/1.jpg`, `2.jpg`, … (çok sayıda dosya;
/// indeksler manifestten toplanır, `pubspec`’te `assets/inspiration/` klasörü tanımlı olmalı).
abstract final class InspirationAssets {
  static const String folder = 'assets/inspiration';
  static const String extension = 'jpg';

  static String pathForIndex(int imageIndex) =>
      '$folder/$imageIndex.$extension';
}
