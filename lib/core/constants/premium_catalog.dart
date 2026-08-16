import 'revenuecat_ids.dart';

/// iOS StoreKit ile aynı resmi TRY fiyatları.
/// Android'de mağaza fiyatı gelene kadar gösterim için kullanılır;
/// satın alma her zaman Play/RevenueCat ürününe bağlı kalır.
abstract final class PremiumCatalog {
  static const double monthlyTry = 99.99;
  static const double yearlyTry = 499.99;
  static const double lifetimeTry = 1299.99;
  static const String currencyCode = 'TRY';

  /// Google Play base plan kimlikleri (ürün:basePlan).
  static const String androidMonthlyBasePlanId = 'p1m';
  static const String androidYearlyBasePlanId = 'p1y';

  static double? tryPriceFor(String productId) {
    final base = baseId(productId);
    return switch (base) {
      RevenueCatIds.monthlyProductId => monthlyTry,
      RevenueCatIds.yearlyProductId => yearlyTry,
      RevenueCatIds.lifetimeProductId => lifetimeTry,
      _ => null,
    };
  }

  static List<String> storeQueryIds(String productId, {required bool android}) {
    final base = baseId(productId);
    if (!android) return [base];
    if (base == RevenueCatIds.monthlyProductId) {
      return [base, '$base:$androidMonthlyBasePlanId'];
    }
    if (base == RevenueCatIds.yearlyProductId) {
      return [base, '$base:$androidYearlyBasePlanId'];
    }
    return [base];
  }

  static String baseId(String productId) =>
      RevenueCatIds.baseProductId(productId);

  /// Play / App Store girişi. Lansman SKU fiyatına asla dokunulmaz.
  static const List<PremiumStoreListing> storeListings = [
    PremiumStoreListing(
      productId: RevenueCatIds.monthlyProductId,
      kind: PremiumStoreProductKind.subscriptionMonthly,
      tryPrice: monthlyTry,
      sellToNewCustomers: true,
      keepForExistingRenewals: true,
      changeExistingPrice: false,
      freeTrialDays: 0,
    ),
    PremiumStoreListing(
      productId: RevenueCatIds.yearlyProductId,
      kind: PremiumStoreProductKind.subscriptionYearly,
      tryPrice: yearlyTry,
      sellToNewCustomers: true,
      keepForExistingRenewals: true,
      changeExistingPrice: false,
      freeTrialDays: 3,
    ),
    PremiumStoreListing(
      productId: RevenueCatIds.lifetimeProductId,
      kind: PremiumStoreProductKind.oneTime,
      tryPrice: lifetimeTry,
      sellToNewCustomers: true,
      keepForExistingRenewals: false,
      changeExistingPrice: false,
      freeTrialDays: 0,
    ),
    PremiumStoreListing(
      productId: RevenueCatIds.legacyMonthlyProductId,
      kind: PremiumStoreProductKind.subscriptionMonthly,
      tryPrice: null,
      sellToNewCustomers: false,
      keepForExistingRenewals: true,
      changeExistingPrice: false,
      freeTrialDays: 0,
    ),
    PremiumStoreListing(
      productId: RevenueCatIds.legacyYearlyProductId,
      kind: PremiumStoreProductKind.subscriptionYearly,
      tryPrice: null,
      sellToNewCustomers: false,
      keepForExistingRenewals: true,
      changeExistingPrice: false,
      freeTrialDays: 0,
    ),
  ];
}

enum PremiumStoreProductKind {
  subscriptionMonthly,
  subscriptionYearly,
  oneTime,
}

class PremiumStoreListing {
  const PremiumStoreListing({
    required this.productId,
    required this.kind,
    required this.tryPrice,
    required this.sellToNewCustomers,
    required this.keepForExistingRenewals,
    required this.changeExistingPrice,
    required this.freeTrialDays,
  });

  final String productId;
  final PremiumStoreProductKind kind;
  final double? tryPrice;
  final bool sellToNewCustomers;
  final bool keepForExistingRenewals;
  final bool changeExistingPrice;
  final int freeTrialDays;
}
