class StorePriceInfo {
  const StorePriceInfo({
    required this.productId,
    required this.priceString,
    required this.price,
    required this.currencyCode,
  });

  final String productId;
  final String priceString;
  final double price;
  final String currencyCode;

  String get monthlyEquivalentString {
    if (price <= 0) return '';
    final monthly = price / 12;
    final code = currencyCode.toUpperCase();
    if (code == 'TRY' || code == 'TL') {
      return '${_formatTry(monthly)} ₺';
    }
    return '${monthly.toStringAsFixed(2)} $code';
  }

  static String _formatTry(double value) {
    final rounded = (value * 100).round() / 100;
    final whole = rounded.truncate();
    final cents = ((rounded - whole) * 100).round();
    final wholeText = whole.toString();
    if (cents == 0) return wholeText;
    return '$wholeText,${cents.toString().padLeft(2, '0')}';
  }
}
