import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ads/admob_ids.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/admob_service.dart';
import '../../data/services/global_widget_lock_service.dart';
import '../../data/services/widget_access_service.dart';
import '../../data/services/widget_metrics_service.dart';
import '../shared/providers/admob_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/widget_access_providers.dart';

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
      if (!mounted || entitlement.isActive) return;
      AdMobService.preloadRewarded();
    } catch (_) {
      // Entitlement okunamadı: belirsizken reklam ısıtmayı atla (fail-safe).
    }
  }

  Future<void> _watchAd(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      // Reklam teklifinde gösterilen süre ile ödül kaydında kullanılan süreyi
      // mümkün olduğunca aynı tutmak için sunucu ayarını gösterimden hemen önce
      // yenile. Push kaçırılmış olsa bile kullanıcı güncel teklifi görür.
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
      if (result != RewardedAdResult.rewarded) {
        // Kullanıcı reklamı erken kapattıysa (notRewarded) "yüklenemedi"
        // mesajı yanıltıcı olur; yalnızca gerçek yükleme/gösterim hatasında
        // bilgilendir.
        if (result != RewardedAdResult.notRewarded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.widgetUnlockAdLoadFailed)),
          );
        }
        return;
      }
      final service = ref.read(widgetAccessServiceProvider);
      await service.recordRewardedUnlock(widget.kind);
      final premium = await ref.read(premiumEntitlementProvider.future);
      final states = await service.syncAll(isPremium: premium.isActive);
      await WidgetMetricsService.recordRewardedUnlock(widget.kind);
      final prefs = await SharedPreferences.getInstance();
      await WidgetMetricsService.reconcile(
        prefs: prefs,
        accessService: service,
        states: states,
        isPremium: premium.isActive,
      );
      if (!context.mounted) return;

      final kindTitle = switch (widget.kind) {
        ArinWidgetAccessKind.quote => l10n.widgetUnlockQuoteTitle,
        ArinWidgetAccessKind.prayer => l10n.widgetUnlockPrayerTitle,
        ArinWidgetAccessKind.combo => l10n.widgetUnlockComboTitle,
        ArinWidgetAccessKind.tracking => l10n.widgetUnlockTrackingTitle,
        ArinWidgetAccessKind.zikir => l10n.widgetUnlockZikirTitle,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.widgetUnlockSuccessTitle(
              kindTitle,
              GlobalWidgetLockService.unlockHours(
                ref.read(sharedPreferencesProvider),
              ),
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.widgetUnlockPremiumSuccess),
            duration: const Duration(seconds: 4),
          ),
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
    final kindTitle = switch (widget.kind) {
      ArinWidgetAccessKind.quote => l10n.widgetUnlockQuoteTitle,
      ArinWidgetAccessKind.prayer => l10n.widgetUnlockPrayerTitle,
      ArinWidgetAccessKind.combo => l10n.widgetUnlockComboTitle,
      ArinWidgetAccessKind.tracking => l10n.widgetUnlockTrackingTitle,
      ArinWidgetAccessKind.zikir => l10n.widgetUnlockZikirTitle,
    };

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
                                  child: CircularProgressIndicator(
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
