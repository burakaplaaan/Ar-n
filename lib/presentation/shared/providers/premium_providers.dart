import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/premium_entitlement.dart';
import '../../../data/repositories/premium_entitlement_repository.dart';
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
    return PremiumEntitlement.inactive;
  }
  return ref.read(premiumEntitlementRepositoryProvider).loadForCurrentUser();
});

enum PremiumAccessState { loading, free, premium }

final premiumAccessStateProvider = Provider<PremiumAccessState>((ref) {
  final entitlement = ref.watch(premiumEntitlementProvider);
  return entitlement.when(
    data: (v) => v.isActive ? PremiumAccessState.premium : PremiumAccessState.free,
    // Entitlement okunamadığında kullanıcıyı "free" saymak yanlış reklam/gate
    // gösterebilir; hata durumunu loading gibi ele alıp fail-open davran.
    error: (_, __) => PremiumAccessState.loading,
    loading: () => PremiumAccessState.loading,
  );
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumAccessStateProvider) == PremiumAccessState.premium;
});
