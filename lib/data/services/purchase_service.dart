// lib/data/services/purchase_service.dart
//
// RevenueCat üzerinden abonelik yönetimi.
// Tüm platform farkları bu katmanda gizlenir; UI sadece bu servisi çağırır.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/analytics/meta_app_events.dart';
import '../../core/constants/revenuecat_ids.dart';
import '../../l10n/app_localizations.dart';
import '../models/premium_entitlement.dart';
import '../models/purchase_result.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final purchaseServiceProvider = Provider<PurchaseService>(
  (_) => PurchaseService(),
);

// ─── Service ─────────────────────────────────────────────────────────────────

class PurchaseService {
  // ── Init ──────────────────────────────────────────────────────────────────

  /// Purchases.configure() tamamlandığında true olur.
  /// Uygulama açılışında deferred startup'ta async olarak başlatıldığı için
  /// getLocalPremiumEntitlement() bu flag'i kontrol ederek RC hazır olana kadar bekler.
  static bool _isConfigured = false;
  static Future<void>? _configureFuture;
  
  /// Global callback for customer info updates (e.g. to invalidate provider)
  static void Function()? onCustomerInfoUpdated;

  /// Ana app bootstrap sırasında bir kez çağrılır.
  /// Firebase Auth ile oturum açık olan kullanıcı ID'si verilirse
  /// RevenueCat o ID ile ilişkilendirir (webhook'ta Firestore'a yazılır).
  static Future<void> initialize({String? firebaseUid}) async {
    if (!_isSupportedPlatform) return;
    if (_isConfigured) {
      if (firebaseUid != null && firebaseUid.isNotEmpty) {
        await _safeCall(() => Purchases.logIn(firebaseUid));
      }
      return;
    }
    if (_configureFuture != null) {
      try {
        await _configureFuture;
      } catch (e) {
        debugPrint('[PurchaseService] initialize wait error: $e');
      }
      if (firebaseUid != null && firebaseUid.isNotEmpty && _isConfigured) {
        await _safeCall(() => Purchases.logIn(firebaseUid));
      }
      return;
    }

    _configureFuture = () async {
      final apiKey = Platform.isAndroid
          ? RevenueCatIds.androidApiKey
          : RevenueCatIds.iosApiKey;

      await Purchases.setLogLevel(
        kReleaseMode ? LogLevel.error : LogLevel.debug,
      );

      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      Purchases.addCustomerInfoUpdateListener((_) {
        // App lifecycle boyunca (arka planda / anlık push ile) gelen abonelik değişikliklerini
        // dinleyip Premium state'i tazele.
        onCustomerInfoUpdated?.call();
      });
      _isConfigured = true;
    }();
    try {
      await _configureFuture;
    } catch (e) {
      _isConfigured = false;
      debugPrint('[PurchaseService] initialize error: $e');
    } finally {
      _configureFuture = null;
    }

    if (firebaseUid != null && firebaseUid.isNotEmpty && _isConfigured) {
      await _safeCall(() => Purchases.logIn(firebaseUid));
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// RevenueCat'in aktif teklifini çeker.
  /// Dönen liste: [aylık Package, yıllık Package] (boş gelebilir).
  Future<List<Package>> fetchPackages() async {
    if (!_isSupportedPlatform) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('[PurchaseService] fetchPackages error: $e');
      return [];
    }
  }

  /// Verilen abonelik ürün ID'leri için mağazadan gerçek fiyat stringlerini çeker.
  /// Sadece Android'de anlamlıdır; RC hazır değilse max 2 sn bekler.
  /// Dönen map: { productId: priceString }. Bulunamayan ID'ler map'te yer almaz.
  Future<Map<String, String>> fetchProductPriceStrings(
    List<String> productIds,
    {ProductCategory productCategory = ProductCategory.subscription}
  ) async {
    if (!_isSupportedPlatform) return {};
    final ready = await _waitUntilConfigured();
    if (!ready) return {};
    try {
      final products = await Purchases.getProducts(
        productIds,
        productCategory: productCategory,
      );
      return {for (final p in products) p.identifier: p.priceString};
    } catch (e) {
      debugPrint('[PurchaseService] fetchProductPriceStrings error: $e');
      return {};
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  /// Verilen productId için abonelik satın alma başlatır.
  /// Kullanıcı iptal ederse [PurchaseOutcome.cancelled] döner.
  Future<PurchaseOutcome> purchase(String productId, {AppLocalizations? l10n}) async {
    if (!_isSupportedPlatform) {
      return PurchaseOutcome.error(l10n?.purchaseErrorNotSupported ?? 'Bu platformda satın alma desteklenmiyor.');
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected('Not ready') ?? 'Satın alma servisi henüz hazır değil. Lütfen birkaç saniye sonra tekrar deneyin.');
    }

    // Offerings yerine doğrudan getProducts kullanılıyor.
    // Varsayılan ProductCategory.subscription, abonelik ürünleri getirir.
    // Billing client bağlantısı için 3 deneme × 2 sn retry.
    StoreProduct? product;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final products = await Purchases.getProducts([productId]);
        debugPrint(
          '[PurchaseService] purchase getProducts($productId) attempt ${attempt + 1} → ${products.length} ürün',
        );
        if (products.isNotEmpty) {
          product = products.first;
          break;
        }
      } catch (e) {
        debugPrint(
          '[PurchaseService] purchase getProducts($productId) attempt ${attempt + 1} error: $e',
        );
      }
      if (attempt < 2) await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (product == null) {
      return PurchaseOutcome.error(l10n?.purchaseErrorNotFound ?? 'Ürün bulunamadı. İnternet bağlantınızı kontrol edin.');
    }

    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      var active = _hasPremium(result.customerInfo);
      if (!active) {
        // Entitlement webhook/edge cache gecikebilir. Hemen "başarısız" demek
        // yanlış, ama aktiflik doğrulanmadan "başarılı" demek de yanıltıcı.
        for (var attempt = 0; attempt < 3 && !active; attempt++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          final refreshed = await Purchases.getCustomerInfo();
          active = _hasPremium(refreshed);
        }
      }
      if (!active) {
        // Ödeme alındıktan sonra entitlement geç düşebilir (webhook/cache gecikmesi).
        // UI tarafı premiumConfirmed kontrolü yaptığı için başarı döndürüp akışı
        // "beklemede" mesajıyla yönetmek, yanlış hata/tekrar ödeme riskini azaltır.
        debugPrint(
          '[PurchaseService] purchase completed but entitlement not active yet; returning success.',
        );
      }
      _logMetaSubscription(product, result.customerInfo);
      return const PurchaseOutcome.success();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.error(l10n != null ? _errorMessage(code, l10n) : 'Hata: ${code.name}');
    } catch (e) {
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected(e.toString()) ?? 'Beklenmedik hata: $e');
    }
  }

  // ── Support / Tip Purchase ────────────────────────────────────────────────

  /// Tek seferlik destek ürünü satın alır (Non-Consumable).
  /// Abonelikten farklı olarak doğrudan [productId] ile product fetch eder.
  Future<PurchaseOutcome> purchaseSupportProduct(String productId, {AppLocalizations? l10n}) async {
    if (!_isSupportedPlatform) {
      return PurchaseOutcome.error(l10n?.purchaseErrorNotSupported ?? 'Bu platformda satın alma desteklenmiyor.');
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected('Not ready') ?? 'Destek satın alma servisi henüz hazır değil. Lütfen tekrar deneyin.');
    }
    try {
      // Billing client bağlantısı configure'dan hemen sonra hazır olmayabilir.
      // 3 deneme, aralarında 2'şer saniye bekleme.
      // INAPP (tek seferlik) ürünler için ProductCategory.nonSubscription
      // şart; varsayılan subscription'dır ve INAPP ürünleri görmez.
      List<StoreProduct> products = [];
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          products = await Purchases.getProducts(
            [productId],
            productCategory: ProductCategory.nonSubscription,
          );
          debugPrint(
            '[PurchaseService] getProducts($productId) attempt ${attempt + 1} → ${products.length} ürün',
          );
        } catch (e) {
          debugPrint(
            '[PurchaseService] getProducts($productId) attempt ${attempt + 1} error: $e',
          );
        }
        if (products.isNotEmpty) break;
        if (attempt < 2) await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (products.isEmpty) {
        return PurchaseOutcome.error(l10n?.purchaseErrorNotFound ?? 'Ürün bulunamadı [ID: $productId]. Mağaza tarafında ürün aktif olmayabilir veya bağlantı sorunu olabilir.');
      }
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
      final baseId = _baseProductId(productId);
      var purchased = result.customerInfo.nonSubscriptionTransactions.any(
        (t) => _baseProductId(t.productIdentifier) == baseId,
      );
      if (!purchased) {
        // Non-subscription transaction listesi RC tarafında anlık gecikebilir.
        for (var attempt = 0; attempt < 3 && !purchased; attempt++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          final refreshed = await Purchases.getCustomerInfo();
          purchased = refreshed.nonSubscriptionTransactions.any(
            (t) => _baseProductId(t.productIdentifier) == baseId,
          );
        }
      }
      if (!purchased) {
        debugPrint(
          '[PurchaseService] support purchase verification still pending for $productId; returning success to prevent duplicate charges.',
        );
      }
      _logMetaPurchase(products.first, result.customerInfo);
      return const PurchaseOutcome.success();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[PurchaseService] PlatformException: ${e.message} | code: ${code.name}');
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.error(l10n != null ? _errorMessage(code, l10n) : 'Hata: ${code.name}');
    } catch (e) {
      debugPrint('[PurchaseService] Unexpected error: $e');
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected(e.toString()) ?? 'Hata: $e');
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Önceki satın alımları geri yükler.
  Future<PurchaseOutcome> restorePurchases({AppLocalizations? l10n}) async {
    if (!_isSupportedPlatform) {
      return PurchaseOutcome.error(l10n?.purchaseErrorNotSupported ?? 'Bu platformda desteklenmiyor.');
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected('Not ready') ?? 'Satın alma servisi henüz hazır değil. Lütfen birkaç saniye sonra tekrar deneyin.');
    }
    try {
      final info = await Purchases.restorePurchases();
      return _hasPremium(info)
          ? const PurchaseOutcome.success()
          : const PurchaseOutcome.notFound();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return PurchaseOutcome.error(l10n != null ? _errorMessage(code, l10n) : 'Ağ hatası veya beklenmedik sorun.');
    } catch (e) {
      return PurchaseOutcome.error(l10n?.purchaseErrorUnexpected(e.toString()) ?? 'Beklenmedik hata: $e');
    }
  }

  // ── Customer info ─────────────────────────────────────────────────────────

  /// Cihaz üzerindeki anlık premium durumunu döner (Firestore'dan bağımsız).
  Future<bool> isPremiumLocally() async {
    if (!_isSupportedPlatform) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return _hasPremium(info);
    } catch (_) {
      return false;
    }
  }

  /// Cihaz üzerindeki anlık premium durumunu productId ile birlikte döner.
  /// Uygulama yeniden başlatıldığında RC henüz configure edilmemiş olabilir;
  /// bu durumda max 2 sn RC'nin hazır olmasını bekler, sonra Firestore fallback'e düşer.
  Future<PremiumEntitlement?> getLocalPremiumEntitlement({
    String? expectedFirebaseUid,
  }) async {
    if (!_isSupportedPlatform) return null;
    // RC configure edilmeden getCustomerInfo() çağrısı exception fırlatır.
    // App restart'ta deferred startup tamamlanmadan burada olunabilir; 2 sn bekle.
    for (var i = 0; i < 2 && !_isConfigured; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!_isConfigured) return null;
    try {
      final appUserId = await Purchases.appUserID;
      final info = await Purchases.getCustomerInfo();
      if (expectedFirebaseUid != null && expectedFirebaseUid.isNotEmpty) {
        final rcUserId = appUserId.trim();
        // Anonim RC kullanıcısı veya UID uyuşmazlığı varsa fallback iptal
        if (rcUserId.isEmpty || 
            rcUserId.startsWith('\$RCAnonymousID:') || 
            rcUserId != expectedFirebaseUid) {
          debugPrint(
            '[PurchaseService] local entitlement ignored due to RC identity mismatch. '
            'expected=$expectedFirebaseUid rc=$rcUserId',
          );
          return null;
        }
      }
      final entitlement =
          info.entitlements.active[RevenueCatIds.premiumEntitlement];
      if (entitlement != null && entitlement.isActive) {
        return PremiumEntitlement(
          active: true,
          productId: entitlement.productIdentifier,
          source: 'revenuecat_local',
          expiresAt: entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── User Identity ─────────────────────────────────────────────────────────

  /// Oturum açıldığında çağrılır; RevenueCat cihaz ID'sini Firebase UID ile eşler.
  static Future<void> loginUser(String firebaseUid) async {
    if (!_isSupportedPlatform) return;
    await initialize();
    if (!_isConfigured) {
      throw StateError('RevenueCat başlatılamadı (login).');
    }
    try {
      await Purchases.logIn(firebaseUid);
    } catch (e) {
      debugPrint('[PurchaseService] loginUser error: $e');
      throw StateError('RevenueCat kullanıcı eşleme hatası.');
    }
  }

  /// Oturum kapandığında çağrılır; RevenueCat anonim ID'ye döner.
  static Future<void> logoutUser() async {
    if (!_isSupportedPlatform) return;
    if (!_isConfigured && _configureFuture == null) {
      await initialize();
    } else if (!_isConfigured && _configureFuture != null) {
      try {
        await _configureFuture;
      } catch (e) {
        debugPrint('[PurchaseService] logout wait error: $e');
      }
    }
    if (!_isConfigured) {
      throw StateError('RevenueCat başlatılamadı (logout).');
    }
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[PurchaseService] logoutUser error: $e');
      throw StateError('RevenueCat oturumu kapatılamadı.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String _baseProductId(String productId) {
    final idx = productId.indexOf(':');
    if (idx <= 0) return productId;
    return productId.substring(0, idx);
  }

  bool _hasPremium(CustomerInfo info) {
    return info.entitlements.active
        .containsKey(RevenueCatIds.premiumEntitlement);
  }

  String _errorMessage(PurchasesErrorCode code, AppLocalizations l10n) {
    return switch (code) {
      PurchasesErrorCode.networkError => l10n.purchaseErrorUnexpected('Network error'),
      PurchasesErrorCode.receiptAlreadyInUseError => l10n.purchaseErrorUnexpected(
        'Receipt already in use',
      ),
      PurchasesErrorCode.invalidAppUserIdError => l10n.purchaseErrorUnexpected(
        'Invalid app user id',
      ),
      PurchasesErrorCode.paymentPendingError => l10n.purchaseErrorUnexpected(
        'Payment pending',
      ),
      _ => l10n.purchaseErrorUnexpected(code.name),
    };
  }

  static Future<void> _safeCall(Future<dynamic> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[PurchaseService] _safeCall error: $e');
    }
  }

  Future<bool> _waitUntilConfigured() async {
    if (_isConfigured) return true;
    for (var i = 0; i < 3; i++) {
      if (_isConfigured) return true;
      if (_configureFuture != null) {
        try {
          await _configureFuture;
        } catch (e) {
          debugPrint('[PurchaseService] configure wait error: $e');
          _isConfigured = false;
          return false;
        }
      } else {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return _isConfigured;
  }

  void _logMetaSubscription(StoreProduct product, CustomerInfo info) {
    final orderId = info.originalAppUserId.isNotEmpty
        ? '${info.originalAppUserId}_${product.identifier}_${DateTime.now().millisecondsSinceEpoch}'
        : '${product.identifier}_${DateTime.now().millisecondsSinceEpoch}';
    unawaited(
      MetaAppEvents.logSubscribe(
        price: product.price,
        currency: product.currencyCode,
        orderId: orderId,
      ),
    );
    unawaited(
      MetaAppEvents.logPurchase(
        amount: product.price,
        currency: product.currencyCode,
        orderId: orderId,
        parameters: {'fb_content_id': product.identifier},
      ),
    );
  }

  void _logMetaPurchase(StoreProduct product, CustomerInfo info) {
    final orderId = info.originalAppUserId.isNotEmpty
        ? '${info.originalAppUserId}_${product.identifier}_${DateTime.now().millisecondsSinceEpoch}'
        : '${product.identifier}_${DateTime.now().millisecondsSinceEpoch}';
    unawaited(
      MetaAppEvents.logPurchase(
        amount: product.price,
        currency: product.currencyCode,
        orderId: orderId,
        parameters: {'fb_content_id': product.identifier},
      ),
    );
  }
}
