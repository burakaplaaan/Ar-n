import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ads/admob_ids.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/product_metric_features.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/admob_service.dart';
import '../../data/services/global_widget_lock_service.dart';
import '../../data/services/product_metrics_service.dart';
import '../../data/services/widget_access_service.dart';
import '../../data/services/widget_metrics_service.dart';
import '../shared/providers/admob_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/widget_access_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

class WidgetUnlockPage extends ConsumerStatefulWidget {
  const WidgetUnlockPage({required this.kind, super.key});

  final ArinWidgetAccessKind kind;

  @override
  ConsumerState<WidgetUnlockPage> createState() => _WidgetUnlockPageState();
}

class _WidgetUnlockPageState extends ConsumerState<WidgetUnlockPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Kullanıcı bu ekranda büyük olasılıkla "Reklam izle"ye basacak; ödüllü
    // reklamı şimdiden arka planda ısıt ki tıklandığında ANINDA açılsın.
    // Yalnızca premium OLMAYAN kullanıcı için: bu sayfa normalde sadece
    // premium olmayanlara açılır, ama native `lock=1` derin bağlantısı
    // premium/trial uyumsuzluğunda premium kullanıcıyı da buraya
    // getirebildiğinden, boşa reklam isteği üretmemek için entitlement'ı
    // doğruladıktan sonra ısıtıyoruz.
    _maybeWarmRewarded();
    _refreshUnlockConfig();
  }

  Future<void> _refreshUnlockConfig() async {
    await GlobalWidgetLockService.applyIfDue(
      ref.read(sharedPreferencesProvider),
      force: true,
    );
    if (mounted) setState(() {});
  }

  Future<void> _maybeWarmRewarded() async {
    try {
      final entitlement = await ref.read(premiumEntitlementProvider.future);
      if (!mounted) return;
      AdMobService.setRewardedPreloadEligible(!entitlement.isActive);
      if (entitlement.isActive) return;
      AdMobService.preloadRewarded();
    } catch (_) {
      // Entitlement okunamadı: belirsizken reklam ısıtmayı atla (fail-safe).
      AdMobService.setRewardedPreloadEligible(false);
    }
  }

  String _kindTitle(AppLocalizations l10n) => switch (widget.kind) {
    ArinWidgetAccessKind.quote => l10n.widgetUnlockQuoteTitle,
    ArinWidgetAccessKind.prayer => l10n.widgetUnlockPrayerTitle,
    ArinWidgetAccessKind.combo => l10n.widgetUnlockComboTitle,
    ArinWidgetAccessKind.tracking => l10n.widgetUnlockTrackingTitle,
    ArinWidgetAccessKind.zikir => l10n.widgetUnlockZikirTitle,
  };

  Future<void> _watchAd(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final kindTitle = _kindTitle(l10n);
    setState(() => _busy = true);
    try {
      bool premiumActive;
      try {
        premiumActive = (await ref.read(
          premiumEntitlementProvider.future,
        )).isActive;
      } catch (_) {
        if (context.mounted) {
          await _showAdUnavailableDialog(context, title: kindTitle);
        }
        return;
      }
      if (!context.mounted) return;
      AdMobService.setRewardedPreloadEligible(!premiumActive);
      if (premiumActive) {
        context.pop();
        return;
      }

      while (context.mounted) {
        final prepared = await _prepareRewardedWithFeedback(context);
        if (!context.mounted) return;
        if (!prepared) {
          final retry = await _showAdUnavailableDialog(
            context,
            title: kindTitle,
          );
          if (!context.mounted || !retry) return;
          continue;
        }

        // Reklam teklifinde gösterilen süre ile ödül kaydında kullanılan süreyi
        // mümkün olduğunca aynı tutmak için sunucu ayarını gösterimden hemen
        // önce yenile. Push kaçırılmış olsa bile kullanıcı güncel teklifi görür.
        await GlobalWidgetLockService.applyIfDue(
          ref.read(sharedPreferencesProvider),
          force: true,
        );
        if (!context.mounted) return;
        setState(() {});
        final result = await ref
            .read(adMobServiceProvider)
            .showRewardedDetailed(ArinAdUnit.rewardedUnlock);
        if (!context.mounted) return;
        if (result == RewardedAdResult.rewarded) break;
        // Kullanıcı reklamı erken kapattıysa bu bir yükleme hatası değildir.
        if (result == RewardedAdResult.notRewarded) return;
        final retry = await _showAdUnavailableDialog(
          context,
          title: kindTitle,
        );
        if (!context.mounted || !retry) return;
      }

      final service = ref.read(widgetAccessServiceProvider);
      await service.recordRewardedUnlock(widget.kind);
      final premium = await ref.read(premiumEntitlementProvider.future);
      final states = await service.syncAll(isPremium: premium.isActive);
      await WidgetMetricsService.recordRewardedUnlock(widget.kind);
      unawaited(ProductMetricsService.adWatch(ProductMetricFeatures.widget));
      final prefs = await SharedPreferences.getInstance();
      await WidgetMetricsService.reconcile(
        prefs: prefs,
        accessService: service,
        states: states,
        isPremium: premium.isActive,
      );
      if (!context.mounted) return;

      showArinTopToast(
        context,
        l10n.widgetUnlockSuccessTitle(
              kindTitle,
              GlobalWidgetLockService.unlockHours(
                ref.read(sharedPreferencesProvider),
              ),
            ),
        duration: const Duration(seconds: 4),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _prepareRewardedWithFeedback(BuildContext context) async {
    final adMob = ref.read(adMobServiceProvider);
    if (adMob.isRewardedReady) return true;
    return await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (_) => _RewardedPreparingDialog(
            prepare: adMob.prepareRewarded,
            message: AppLocalizations.of(context)!.widgetUnlockAdPreparing,
          ),
        ) ??
        false;
  }

  /// iOS'ta bir diyalog kapanır kapanmaz yenisini açmak bazen sessizce
  /// başarısız oluyor; bir frame + kısa settle beklenir.
  Future<void> _awaitDialogRouteSettle() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 32));
  }

  Future<bool> _showAdUnavailableDialog(
    BuildContext context, {
    required String title,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await _awaitDialogRouteSettle();
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          builder: (dialogContext) => _WidgetUnlockAdUnavailableDialog(
            title: title,
            message: l10n.widgetUnlockAdLoadFailed,
            laterLabel: l10n.widgetUnlockAdLaterButton,
            retryLabel: l10n.widgetUnlockAdRetryButton,
          ),
        ) ??
        false;
  }

  Future<void> _goPremium(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await context.push(AppRoutes.premium);
      if (!context.mounted) return;
      final entitlement = await ref.read(premiumEntitlementProvider.future);
      if (entitlement.isActive) {
        final service = ref.read(widgetAccessServiceProvider);
        final states = await service.syncAll(isPremium: true);
        final prefs = await SharedPreferences.getInstance();
        await WidgetMetricsService.reconcile(
          prefs: prefs,
          accessService: service,
          states: states,
          isPremium: true,
        );
        if (!context.mounted) return;
        showArinTopToast(
          context,
          l10n.widgetUnlockPremiumSuccess,
          duration: const Duration(seconds: 4),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unlockHours = GlobalWidgetLockService.unlockHours(
      ref.read(sharedPreferencesProvider),
    );
    final kindTitle = _kindTitle(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3D30), Color(0xFF071815)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 4,
                child: IconButton(
                  onPressed: _busy ? null : () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔒', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        kindTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.widgetUnlockDescription(unlockHours),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : () => _watchAd(context),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: ArinLoader(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_circle_outline_rounded),
                          label: Text(l10n.widgetUnlockAdButton(unlockHours)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emeraldLight,
                            foregroundColor: const Color(0xFF071815),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _goPremium(context),
                          icon: const Icon(Icons.star_rounded),
                          label: Text(l10n.widgetUnlockPremiumButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9BE7C3),
                            side: const BorderSide(
                              color: Color(0xFF9BE7C3),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _busy ? null : () => context.pop(),
                        child: Text(
                          l10n.widgetUnlockCancelButton,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetUnlockAdUnavailableDialog extends StatelessWidget {
  const _WidgetUnlockAdUnavailableDialog({
    required this.title,
    required this.message,
    required this.laterLabel,
    required this.retryLabel,
  });

  final String title;
  final String message;
  final String laterLabel;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    // Unlock sayfası koyu yeşil; sistem teması açık olsa bile diyalog her
    // platformda (özellikle iOS) aynı, okunaklı Material popup olarak kalsın.
    const surface = Color(0xFF1C2E28);
    const onSurface = Colors.white;
    const accent = AppColors.emeraldLight;

    return AlertDialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: const TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.88),
          fontSize: 14.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          child: Text(
            laterLabel,
            style: const TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: const Color(0xFF071815),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(retryLabel),
        ),
      ],
    );
  }
}

class _RewardedPreparingDialog extends StatefulWidget {
  const _RewardedPreparingDialog({
    required this.prepare,
    required this.message,
  });

  final Future<bool> Function() prepare;
  final String message;

  @override
  State<_RewardedPreparingDialog> createState() =>
      _RewardedPreparingDialogState();
}

class _RewardedPreparingDialogState extends State<_RewardedPreparingDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final ready = await widget.prepare();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1C2E28);
    const onSurface = Colors.white;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: ArinLoader(
                strokeWidth: 2.5,
                color: AppColors.emeraldLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.9),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
