import '../../core/constants/premium_catalog.dart';

class StorePriceInfo {
  const StorePriceInfo({
    required this.productId,
    required this.priceString,
    required this.price,
    required this.currencyCode,
  });

  factory StorePriceInfo.catalogFallback(String productId) {
    final price = PremiumCatalog.tryPriceFor(productId);
    if (price == null) {
      throw ArgumentError.value(productId, 'productId', 'Katalog fiyatı yok');
    }
    final base = PremiumCatalog.baseId(productId);
    return StorePriceInfo(
      productId: base,
      priceString: '${formatTry(price)} ₺',
      price: price,
      currencyCode: PremiumCatalog.currencyCode,
    );
  }

  static StorePriceInfo? maybeCatalogFallback(String productId) {
    if (PremiumCatalog.tryPriceFor(productId) == null) return null;
    return StorePriceInfo.catalogFallback(productId);
  }

  final String productId;
  final String priceString;
  final double price;
  final String currencyCode;

  String get monthlyEquivalentString {
    if (price <= 0) return '';
    return formatAmount(price / 12);
  }

  /// 12 ay aylık alınca oluşacak tutar. Yıllık fiyattan yüksekse biçimlenmiş
  /// metin, değilse null (üstü çizili sahte indirim yok).
  static String? annualizedMonthlyCompare({
    required StorePriceInfo? monthly,
    required StorePriceInfo? yearly,
  }) {
    if (monthly == null || yearly == null) return null;
    if (monthly.price <= 0 || yearly.price <= 0) return null;
    final annualized = monthly.price * 12;
    if (annualized <= yearly.price + 0.009) return null;
    return monthly.formatAmount(annualized);
  }

  String formatAmount(double value) {
    final code = currencyCode.toUpperCase();
    if (code == 'TRY' || code == 'TL') {
      return '${formatTry(value)} ₺';
    }
    final sample = priceString.trim();
    if (sample.startsWith(r'$')) {
      return '\$${value.toStringAsFixed(2)}';
    }
    return '${value.toStringAsFixed(2)} $code';
  }

  static String formatTry(double value) {
    final rounded = (value * 100).round() / 100;
    final whole = rounded.truncate();
    final cents = ((rounded - whole) * 100).round();
    final wholeText = _thousands(whole);
    if (cents == 0) return wholeText;
    return '$wholeText,${cents.toString().padLeft(2, '0')}';
  }

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
