// lib/data/services/purchase_service.dart
//
// RevenueCat üzerinden abonelik yönetimi.
// Tüm platform farkları bu katmanda gizlenir; UI sadece bu servisi çağırır.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants/revenuecat_ids.dart';
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
  Future<PurchaseOutcome> purchase(String productId) async {
    if (!_isSupportedPlatform) {
      return const PurchaseOutcome.error(
        'Bu platformda satın alma desteklenmiyor.',
      );
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return const PurchaseOutcome.error(
        'Satın alma servisi henüz hazır değil. Lütfen birkaç saniye sonra tekrar deneyin.',
      );
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
      return const PurchaseOutcome.error(
        'Ürün bulunamadı. İnternet bağlantınızı kontrol edin.',
      );
    }

    try {
      final result = await Purchases.purchaseStoreProduct(product);
      var active = _hasPremium(result.customerInfo);
      if (!active) {
        // RevenueCat entitlement aktivasyonu anlık olmayabilir;
        // 2 sn sonra customer info'yu yeniden çek.
        await Future<void>.delayed(const Duration(seconds: 2));
        final refreshed = await Purchases.getCustomerInfo();
        active = _hasPremium(refreshed);
      }
      return active
          ? const PurchaseOutcome.success()
          : const PurchaseOutcome.error(
              'Satın alma tamamlandı ancak premium aktif olmadı.',
            );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.error(_errorMessage(code));
    } catch (e) {
      return PurchaseOutcome.error('Beklenmedik hata: $e');
    }
  }

  // ── Support / Tip Purchase ────────────────────────────────────────────────

  /// Tek seferlik destek ürünü satın alır (Non-Consumable).
  /// Abonelikten farklı olarak doğrudan [productId] ile product fetch eder.
  Future<PurchaseOutcome> purchaseSupportProduct(String productId) async {
    if (!_isSupportedPlatform) {
      return const PurchaseOutcome.error(
        'Bu platformda satın alma desteklenmiyor.',
      );
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return const PurchaseOutcome.error(
        'Destek satın alma servisi henüz hazır değil. Lütfen tekrar deneyin.',
      );
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
        return PurchaseOutcome.error(
          'Ürün bulunamadı [ID: $productId]. '
          'Mağaza tarafında ürün aktif olmayabilir veya bağlantı sorunu olabilir.',
        );
      }
      final result = await Purchases.purchaseStoreProduct(products.first);
      final purchased = result.customerInfo.nonSubscriptionTransactions
          .any((t) => t.productIdentifier == productId);
      return purchased
          ? const PurchaseOutcome.success()
          : const PurchaseOutcome.error(
              'Satın alma tamamlandı ancak doğrulanamadı.',
            );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[PurchaseService] PlatformException: ${e.message} | code: ${code.name}');
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.error('${_errorMessage(code)} [${code.name}]');
    } catch (e) {
      debugPrint('[PurchaseService] Unexpected error: $e');
      return PurchaseOutcome.error('Hata: $e');
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Önceki satın alımları geri yükler.
  Future<PurchaseOutcome> restorePurchases() async {
    if (!_isSupportedPlatform) {
      return const PurchaseOutcome.error('Bu platformda desteklenmiyor.');
    }
    final ready = await _waitUntilConfigured();
    if (!ready) {
      return const PurchaseOutcome.error(
        'Satın alma servisi henüz hazır değil. Lütfen birkaç saniye sonra tekrar deneyin.',
      );
    }
    try {
      final info = await Purchases.restorePurchases();
      return _hasPremium(info)
          ? const PurchaseOutcome.success()
          : const PurchaseOutcome.notFound();
    } on PlatformException catch (e) {
      return PurchaseOutcome.error(
        _errorMessage(PurchasesErrorHelper.getErrorCode(e)),
      );
    } catch (e) {
      return PurchaseOutcome.error('Beklenmedik hata: $e');
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
      final info = await Purchases.getCustomerInfo();
      if (expectedFirebaseUid != null && expectedFirebaseUid.isNotEmpty) {
        final rcUserId = info.originalAppUserId.trim();
        if (rcUserId.isEmpty || rcUserId != expectedFirebaseUid) {
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

  bool _hasPremium(CustomerInfo info) {
    return info.entitlements.active
        .containsKey(RevenueCatIds.premiumEntitlement);
  }

  String _errorMessage(PurchasesErrorCode code) {
    return switch (code) {
      PurchasesErrorCode.networkError =>
        'Ağ hatası. İnternet bağlantınızı kontrol edin.',
      PurchasesErrorCode.receiptAlreadyInUseError =>
        'Bu satın alım başka bir hesaba bağlı.',
      PurchasesErrorCode.invalidAppUserIdError =>
        'Geçersiz kullanıcı. Lütfen tekrar giriş yapın.',
      PurchasesErrorCode.paymentPendingError =>
        'Ödeme onay bekliyor.',
      _ => 'Bir sorun oluştu (${code.name}). Lütfen tekrar deneyin.',
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
}
