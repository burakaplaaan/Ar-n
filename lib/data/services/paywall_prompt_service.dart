import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../presentation/shared/providers/premium_providers.dart';
import 'session_ad_prompt.dart';

/// Oturum boyunca en fazla bir kez "özellik kullandıktan sonra" paywall gösterir.
/// Kilitli premium içeriğe (AI, tema) basınca her zaman açılır.
class PaywallPromptService {
  PaywallPromptService._();

  static bool _shownAfterFeatureThisSession = false;

  @visibleForTesting
  static void resetSessionForTest() {
    _shownAfterFeatureThisSession = false;
  }

  static bool get shownAfterFeatureThisSession =>
      _shownAfterFeatureThisSession;

  /// Kilitli özelliğe dokununca — oturum limiti yok.
  static Future<void> showForLockedFeature(BuildContext context) {
    return _openPremium(context);
  }

  /// Ücretsiz bir özellik kullanıldıktan sonra, oturumda bir kez.
  static Future<void> maybeShowAfterFeatureUse({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    if (_shownAfterFeatureThisSession) return;
    if (!context.mounted) return;
    final access = ref.read(premiumAccessStateProvider);
    if (access == PremiumAccessState.premium) return;
    if (access == PremiumAccessState.loading) return;
    if (SessionAdPrompt.shownRecently()) return;
    _shownAfterFeatureThisSession = true;
    await _openPremium(context);
  }

  static Future<void> _openPremium(BuildContext context) async {
    if (!context.mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == AppRoutes.premium) return;
    await context.push(AppRoutes.premium);
  }
}
