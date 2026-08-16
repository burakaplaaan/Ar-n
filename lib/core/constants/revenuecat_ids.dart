// RevenueCat konfigürasyonu — tek kaynak.
//
// API anahtarlarını RevenueCat Dashboard'dan al:
//   app.revenuecat.com → Project: arin → Apps → <platform> → API Key
//
// Entitlement ID'si her iki platformda aynı olmalı.

abstract final class RevenueCatIds {
  // ─── API Keys ────────────────────────────────────────────────────────────
  /// RevenueCat Dashboard → Apps → Google Play → Public API Key
  static const String androidApiKey = 'goog_cjPvOJEaGvUIUXuYNjDtrCecErK';

  /// RevenueCat Dashboard → Apps → App Store → Public API Key
  static const String iosApiKey = 'appl_EXlSidwFRlyxQMjPTKTXgMDaOLE';

  // ─── Entitlement ─────────────────────────────────────────────────────────
  /// RevenueCat Dashboard → Entitlements → identifier
  static const String premiumEntitlement = 'premium';

  // ─── Product IDs ─────────────────────────────────────────────────────────
  /// Yeni fiyatlandırma — iOS StoreKit ve Android Play ile aynı SKU'lar
  /// (aylık 99,99 ₺ / yıllık 499,99 ₺ + 3 gün deneme / ömür boyu 1.299,99 ₺).
  /// Eski lansman SKU'ları satılmaz; mevcut aboneler o fiyattan devam eder.
  static const String monthlyProductId = 'arin_premium_monthly';
  static const String yearlyProductId = 'arin_premium_yearly';
  static const String lifetimeProductId = 'arin_premium_lifetime';

  /// Eski lansman ürünleri — yalnızca sahiplik tespiti için.
  static const String legacyMonthlyProductId = 'arin_premium_monthly_launch';
  static const String legacyYearlyProductId = 'arin_premium_yearly_launch';

  static const List<String> allMonthlyProductIds = [
    monthlyProductId,
    legacyMonthlyProductId,
  ];

  static const List<String> allYearlyProductIds = [
    yearlyProductId,
    legacyYearlyProductId,
  ];

  static const List<String> allLifetimeProductIds = [
    lifetimeProductId,
  ];

  /// Uygulama yalnızca bunları satar. Lansman SKU'ları satışa kapalıdır.
  static const List<String> sellableProductIds = [
    monthlyProductId,
    yearlyProductId,
    lifetimeProductId,
  ];

  static const List<String> legacyProductIds = [
    legacyMonthlyProductId,
    legacyYearlyProductId,
  ];

  static String baseProductId(String productId) {
    final idx = productId.indexOf(':');
    if (idx <= 0) return productId;
    return productId.substring(0, idx);
  }

  static bool isLegacyProductId(String productId) {
    return legacyProductIds.contains(baseProductId(productId));
  }

  static bool isSellableProductId(String productId) {
    return sellableProductIds.contains(baseProductId(productId));
  }

  static bool isSupportProductId(String productId) {
    final base = baseProductId(productId);
    return base == smallSupportProductId ||
        base == mediumSupportProductId ||
        base == largeSupportProductId;
  }

  static bool canPurchaseInApp(String productId) {
    if (isLegacyProductId(productId)) return false;
    return isSellableProductId(productId) || isSupportProductId(productId);
  }

  // ─── Support / Tip Product IDs ───────────────────────────────────────────
  /// Tek seferlik destek ürünleri (Non-Consumable).
  static const String smallSupportProductId = 'arin_support_tip';
  static const String mediumSupportProductId = 'arin_support_medium';
  static const String largeSupportProductId = 'arin_support_large';
}
