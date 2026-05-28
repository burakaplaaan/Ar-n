import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ads/admob_ids.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/services/widget_access_service.dart';
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

  Future<void> _watchAd() async {
    setState(() => _busy = true);
    try {
      final ok = await ref
          .read(adMobServiceProvider)
          .showRewarded(ArinAdUnit.rewardedUnlock);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reklam şu an yüklenemedi, daha sonra tekrar dene.'),
          ),
        );
        return;
      }
      final service = ref.read(widgetAccessServiceProvider);
      await service.recordRewardedUnlock(widget.kind);
      final premium = ref.read(premiumEntitlementProvider).asData?.value;
      await service.syncAll(isPremium: premium?.isActive == true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.kind.title} 24 saat açıldı! 🎉'),
          duration: const Duration(seconds: 4),
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goPremium() async {
    setState(() => _busy = true);
    try {
      await context.push(AppRoutes.premium);
      if (!mounted) return;
      final entitlement = await ref.read(premiumEntitlementProvider.future);
      if (entitlement.isActive) {
        final service = ref.read(widgetAccessServiceProvider);
        await service.syncAll(isPremium: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium aktif! Tüm widgetlar açıldı. 🎉'),
            duration: Duration(seconds: 4),
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
                        child: const Text(
                          '🔒',
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.kind.title,
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
                        'Bu widgetı 24 saat açmak için kısa bir reklam izleyebilirsin. '
                        'Kalıcı erişim için Premium\'a geç.',
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
                          onPressed: _busy ? null : _watchAd,
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
                          label: const Text('Reklam izle — 24 saat aç'),
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
                          onPressed: _busy ? null : _goPremium,
                          icon: const Icon(Icons.star_rounded),
                          label: const Text('Premium\'a geç'),
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
                          'Şimdi değil',
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
