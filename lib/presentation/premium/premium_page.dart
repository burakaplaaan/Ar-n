import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/premium_providers.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  static const monthlyProductId = 'arin_premium_monthly_launch';
  static const yearlyProductId = 'arin_premium_yearly_launch';

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  String? _busyProductId;

  Future<void> _startPurchase(String productId) async {
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) {
      final signedIn = await _showSignInSheet();
      if (signedIn != true || !mounted) return;
    }

    setState(() => _busyProductId = productId);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ürün hazırlanıyor: $productId. Mağaza ürünleri açılınca '
            'gerçek satın alma akışı burada başlayacak.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<bool?> _showSignInSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var authBusy = false;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? const Color(0xFF08130E) : AppColors.creamSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> signIn(_PremiumAuth provider) async {
            if (authBusy) return;
            setSheetState(() => authBusy = true);
            final ok = await _signInForPremium(provider: provider);
            if (ctx.mounted && ok) {
              Navigator.pop(ctx, true);
              return;
            }
            if (ctx.mounted) {
              setSheetState(() => authBusy = false);
            }
          }

          return _PremiumSignInSheet(
            authBusy: authBusy,
            appleAvailable: ref.read(authServiceProvider).appleSignInAvailable,
            onGoogle: () => signIn(_PremiumAuth.google),
            onApple: () => signIn(_PremiumAuth.apple),
          );
        },
      ),
    );
  }

  Future<bool> _signInForPremium({required _PremiumAuth provider}) async {
    try {
      final service = ref.read(authServiceProvider);
      switch (provider) {
        case _PremiumAuth.google:
          await service.signInWithGoogle();
          break;
        case _PremiumAuth.apple:
          await service.signInWithApple();
          break;
      }
      if (!mounted) return false;
      ref.invalidate(premiumEntitlementProvider);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş tamamlanamadı: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumAsync = ref.watch(premiumEntitlementProvider);
    final isPremium = premiumAsync.asData?.value.isActive ?? false;
    final signedIn = ref.watch(authUserProvider).asData?.value != null;

    final titleTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleTextColor = isDark
        ? Colors.white.withValues(alpha: 0.74)
        : AppColors.textSecondary;
    final footerTextColor = isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.textMuted;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundNavy : AppColors.creamMist,
      body: Stack(
        children: [
          const _PremiumBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                  return;
                                }
                                context.go(AppRoutes.home);
                              },
                              icon: const Icon(Icons.close_rounded),
                              color: isDark ? Colors.white : AppColors.emeraldDark,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(premiumEntitlementProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Satın alımlar yenilendi.'),
                                  ),
                                );
                              },
                              child: const Text('Geri yükle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _LaunchBadge(),
                        const SizedBox(height: 18),
                        Text(
                          isPremium ? 'ARIN Premium aktif' : 'ARIN Premium',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleTextColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPremium
                              ? 'Reklamsız ve kilitsiz deneyimin açık.'
                              : 'Reklamsız, kesintisiz ve kilitsiz manevi rutin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtitleTextColor,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _CountdownLikeNotice(),
                        const SizedBox(height: 22),
                        const _PremiumBenefits(),
                        const SizedBox(height: 22),
                        if (!isPremium && !signedIn) ...[
                          const _SignInRequiredNotice(),
                          const SizedBox(height: 14),
                        ],
                        _PlanCard(
                          title: 'Yıllık Premium',
                          badge: 'EN AVANTAJLI',
                          oldPrice: '₺1.559,88',
                          price: '₺599,99 / yıl',
                          subline: 'Ayda sadece ₺49,99',
                          productId: PremiumPage.yearlyProductId,
                          highlighted: true,
                          enabled: !isPremium,
                          busy: _busyProductId == PremiumPage.yearlyProductId,
                          onPressed: () =>
                              _startPurchase(PremiumPage.yearlyProductId),
                        ),
                        const SizedBox(height: 12),
                        _PlanCard(
                          title: 'Aylık Premium',
                          oldPrice: '₺129,99',
                          price: '₺59,99 / ay',
                          subline: 'Lansman fiyatıyla başla',
                          productId: PremiumPage.monthlyProductId,
                          highlighted: false,
                          enabled: !isPremium,
                          busy: _busyProductId == PremiumPage.monthlyProductId,
                          onPressed: () =>
                              _startPurchase(PremiumPage.monthlyProductId),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Lansman fiyatları sınırlı süre geçerlidir. '
                          'Abonelik mağaza hesabın üzerinden yönetilir ve '
                          'istediğin zaman iptal edilebilir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: footerTextColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF020604),
                      Color(0xFF0C1F17),
                      Color(0xFF050806),
                    ]
                  : [
                      AppColors.creamMist,
                      AppColors.creamBase,
                      AppColors.creamShellDeep,
                    ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -90,
          right: -80,
          child: _Glow(
            color: AppColors.goldAccent.withValues(
              alpha: isDark ? 0.28 : 0.18,
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -110,
          child: _Glow(
            color: AppColors.emeraldMid.withValues(
              alpha: isDark ? 0.2 : 0.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _LaunchBadge extends StatelessWidget {
  const _LaunchBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.58),
          ),
        ),
        child: const Text(
          'LANSMANA ÖZEL',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.9,
          ),
        ),
      ),
    );
  }
}

class _CountdownLikeNotice extends StatelessWidget {
  const _CountdownLikeNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamSurface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.creamDark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppColors.goldAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu fiyat sınırlı süre geçerli. Lansman bitmeden premiumu '
              'en avantajlı fiyatla aç.',
              style: TextStyle(
                color: textColor,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefits extends StatelessWidget {
  const _PremiumBenefits();

  static const _items = [
    (Icons.block_rounded, 'Reklamsız kullanım'),
    (Icons.widgets_rounded, 'Widget kilidi yok'),
    (Icons.explore_rounded, 'Keşfet akışı kesintisiz'),
    (Icons.notifications_active_rounded, '2. ezan alarmı açık'),
    (Icons.spa_rounded, 'Zikir, pusula ve frekanslarda reklam yok'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.textPrimary;

    return Column(
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.$1,
                    color: isDark
                        ? AppColors.accentNeonGreen
                        : AppColors.accentGreenOnLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SignInRequiredNotice extends StatelessWidget {
  const _SignInRequiredNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentNeonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: isDark
                ? AppColors.accentNeonGreen
                : AppColors.accentGreenOnLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fiyatları inceleyebilirsin. Satın almadan önce premiumu '
              'hesabına bağlamak için Google veya Apple ile giriş isteyeceğiz.',
              style: TextStyle(
                color: textColor,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PremiumAuth { google, apple }

class _PremiumSignInSheet extends StatelessWidget {
  const _PremiumSignInSheet({
    required this.authBusy,
    required this.appleAvailable,
    required this.onGoogle,
    required this.onApple,
  });

  final bool authBusy;
  final bool appleAvailable;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final appleButtonColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final appleBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : AppColors.creamDark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: AppColors.goldAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Premium için hesabını bağla',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Satın aldığın premium cihaz değiştirince kaybolmasın diye '
              'önce hesabına bağlanır. Fiyatları görmek için giriş gerekmez.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, height: 1.35),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: authBusy ? null : onGoogle,
              icon: authBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata_rounded),
              label: const Text('Google ile devam et'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentNeonGreen,
                foregroundColor: const Color(0xFF07110B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (appleAvailable) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: authBusy ? null : onApple,
                icon: const Icon(Icons.apple_rounded),
                label: const Text('Apple ile devam et'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appleButtonColor,
                  side: BorderSide(color: appleBorderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: authBusy ? null : () => Navigator.pop(context, false),
              child: const Text('Şimdilik vazgeç'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.oldPrice,
    required this.price,
    required this.subline,
    required this.productId,
    required this.highlighted,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.badge,
  });

  final String title;
  final String oldPrice;
  final String price;
  final String subline;
  final String productId;
  final bool highlighted;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final oldPriceColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textMuted;
    final priceTextColor = isDark ? Colors.white : AppColors.textPrimary;

    final borderColor = highlighted
        ? AppColors.goldAccent
        : (isDark
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.creamDark);
    final containerColor = highlighted
        ? AppColors.goldAccent.withValues(alpha: 0.12)
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.creamSurface.withValues(alpha: 0.85));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: highlighted ? 1.4 : 1),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFF241900),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            oldPrice,
            style: TextStyle(
              color: oldPriceColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.lineThrough,
              decorationColor: oldPriceColor,
              decorationThickness: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              color: priceTextColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subline,
            style: TextStyle(
              color: highlighted
                  ? AppColors.goldAccent
                  : (isDark
                        ? AppColors.accentNeonGreen
                        : AppColors.accentGreenOnLight),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled && !busy ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: highlighted
                    ? AppColors.goldAccent
                    : AppColors.accentNeonGreen,
                foregroundColor: const Color(0xFF07110B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      enabled ? 'Lansman Fiyatıyla Başla' : 'Premium aktif',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
