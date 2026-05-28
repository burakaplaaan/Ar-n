import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/premium_entitlement.dart';
import '../../../data/repositories/premium_entitlement_repository.dart';
import '../../../data/services/purchase_service.dart';
import 'auth_providers.dart';

final premiumEntitlementRepositoryProvider =
    Provider<PremiumEntitlementRepository>((ref) {
  return PremiumEntitlementRepository();
});

/// Premium durumu maliyet için stream ile dinlenmez.
/// Auth değişince tek seferlik sunucu-öncelikli okuma yapar; manuel yenileme
/// gerektiğinde bu provider invalidate edilir.
final premiumEntitlementProvider =
    FutureProvider<PremiumEntitlement>((ref) async {
  final authAsync = ref.watch(authUserProvider);
  final user = authAsync.asData?.value ??
      (authAsync.isLoading ? await ref.watch(authUserProvider.future) : null);
  if (user == null) {
    // Firebase oturumu yokken de RevenueCat local restore/purchase sonucu
    // cihazda aktif olabilir; UI false-negative göstermesin.
    final local = await PurchaseService().getLocalPremiumEntitlement();
    return local ?? PremiumEntitlement.inactive;
  }
  return ref.read(premiumEntitlementRepositoryProvider).loadForCurrentUser();
});

final isPremiumProvider = Provider<bool>((ref) {
  final entitlement = ref.watch(premiumEntitlementProvider);
  return entitlement.asData?.value.isActive ?? false;
});
