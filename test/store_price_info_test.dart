import 'package:arin/data/models/store_price_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yıllık TRY fiyatını aya böler', () {
    const info = StorePriceInfo(
      productId: 'arin_premium_yearly',
      priceString: '₺499.99',
      price: 499.99,
      currencyCode: 'TRY',
    );
    expect(info.monthlyEquivalentString, '41,67 ₺');
  });
}
