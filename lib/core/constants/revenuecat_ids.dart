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
  /// Play Console / App Store Connect'te tanımlı ürün ID'leri.
  /// RevenueCat Dashboard → Products'a da eklenmeli.
  static const String monthlyProductId = 'arin_premium_monthly_launch';
  static const String yearlyProductId = 'arin_premium_yearly_launch';

  // ─── Support / Tip Product IDs ───────────────────────────────────────────
  /// Tek seferlik destek ürünleri (Non-Consumable).
  static const String smallSupportProductId = 'arin_support_tip';
  static const String mediumSupportProductId = 'arin_support_medium';
  static const String largeSupportProductId = 'arin_support_large';
}
