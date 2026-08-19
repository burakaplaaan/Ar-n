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

  test('binlik ayracı ile TRY biçimler', () {
    expect(StorePriceInfo.formatTry(1299.99), '1.299,99');
    expect(StorePriceInfo.formatTry(99.99), '99,99');
  });

  test('12 aylık toplamı yıllıktan pahalıysa karşılaştırma üretir', () {
    const monthly = StorePriceInfo(
      productId: 'arin_premium_monthly',
      priceString: '99,99 ₺',
      price: 99.99,
      currencyCode: 'TRY',
    );
    const yearly = StorePriceInfo(
      productId: 'arin_premium_yearly',
      priceString: '499,99 ₺',
      price: 499.99,
      currencyCode: 'TRY',
    );
    expect(
      StorePriceInfo.annualizedMonthlyCompare(
        monthly: monthly,
        yearly: yearly,
      ),
      '1.199,88 ₺',
    );
  });

  test('yıllık daha pahalıysa çizgi üretmez', () {
    const monthly = StorePriceInfo(
      productId: 'arin_premium_monthly',
      priceString: '20 ₺',
      price: 20,
      currencyCode: 'TRY',
    );
    const yearly = StorePriceInfo(
      productId: 'arin_premium_yearly',
      priceString: '499,99 ₺',
      price: 499.99,
      currencyCode: 'TRY',
    );
    expect(
      StorePriceInfo.annualizedMonthlyCompare(
        monthly: monthly,
        yearly: yearly,
      ),
      isNull,
    );
  });

  test('USD aylık toplamını dolar işaretiyle biçimler', () {
    const monthly = StorePriceInfo(
      productId: 'arin_premium_monthly',
      priceString: '\$1.99',
      price: 1.99,
      currencyCode: 'USD',
    );
    const yearly = StorePriceInfo(
      productId: 'arin_premium_yearly',
      priceString: '\$9.99',
      price: 9.99,
      currencyCode: 'USD',
    );
    expect(
      StorePriceInfo.annualizedMonthlyCompare(
        monthly: monthly,
        yearly: yearly,
      ),
      '\$23.88',
    );
  });
}
