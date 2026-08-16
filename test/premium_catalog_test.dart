import 'package:arin/core/constants/premium_catalog.dart';
import 'package:arin/core/constants/revenuecat_ids.dart';
import 'package:arin/data/models/store_price_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS ile aynı TRY katalog fiyatlarını tutar', () {
    expect(PremiumCatalog.tryPriceFor(RevenueCatIds.monthlyProductId), 99.99);
    expect(PremiumCatalog.tryPriceFor(RevenueCatIds.yearlyProductId), 499.99);
    expect(PremiumCatalog.tryPriceFor(RevenueCatIds.lifetimeProductId), 1299.99);
  });

  test('Android abonelik sorgusuna base plan ekler', () {
    expect(
      PremiumCatalog.storeQueryIds(
        RevenueCatIds.monthlyProductId,
        android: true,
      ),
      [RevenueCatIds.monthlyProductId, 'arin_premium_monthly:p1m'],
    );
    expect(
      PremiumCatalog.storeQueryIds(
        RevenueCatIds.yearlyProductId,
        android: true,
      ),
      [RevenueCatIds.yearlyProductId, 'arin_premium_yearly:p1y'],
    );
    expect(
      PremiumCatalog.storeQueryIds(
        RevenueCatIds.lifetimeProductId,
        android: true,
      ),
      [RevenueCatIds.lifetimeProductId],
    );
  });

  test('iOS sorgusunda base plan eklemez', () {
    expect(
      PremiumCatalog.storeQueryIds(
        RevenueCatIds.yearlyProductId,
        android: false,
      ),
      [RevenueCatIds.yearlyProductId],
    );
  });

  test('lansman SKU satılmaz, yeni SKU satılır', () {
    expect(RevenueCatIds.isLegacyProductId('arin_premium_monthly_launch'), true);
    expect(RevenueCatIds.isLegacyProductId('arin_premium_yearly_launch:p1y'), true);
    expect(RevenueCatIds.canPurchaseInApp(RevenueCatIds.legacyMonthlyProductId), false);
    expect(RevenueCatIds.canPurchaseInApp(RevenueCatIds.monthlyProductId), true);
    expect(RevenueCatIds.canPurchaseInApp(RevenueCatIds.lifetimeProductId), true);
  });

  test('mağaza listesinde lansman fiyatı değiştirilmez', () {
    final legacy = PremiumCatalog.storeListings.where(
      (item) => RevenueCatIds.isLegacyProductId(item.productId),
    );
    expect(legacy.length, 2);
    for (final item in legacy) {
      expect(item.sellToNewCustomers, isFalse);
      expect(item.keepForExistingRenewals, isTrue);
      expect(item.changeExistingPrice, isFalse);
      expect(item.tryPrice, isNull);
    }
    final sellable = PremiumCatalog.storeListings.where(
      (item) => item.sellToNewCustomers,
    );
    expect(
      sellable.map((item) => item.productId),
      [
        RevenueCatIds.monthlyProductId,
        RevenueCatIds.yearlyProductId,
        RevenueCatIds.lifetimeProductId,
      ],
    );
    expect(
      sellable.map((item) => item.tryPrice),
      [99.99, 499.99, 1299.99],
    );
  });

  test('katalog fallback TRY fiyatını biçimler', () {
    expect(
      StorePriceInfo.catalogFallback(RevenueCatIds.monthlyProductId).priceString,
      '99,99 ₺',
    );
    expect(
      StorePriceInfo.catalogFallback(RevenueCatIds.yearlyProductId).priceString,
      '499,99 ₺',
    );
    expect(
      StorePriceInfo.catalogFallback(RevenueCatIds.lifetimeProductId).priceString,
      '1.299,99 ₺',
    );
  });
}
