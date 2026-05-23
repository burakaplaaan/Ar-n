import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/revenuecat_ids.dart';
import '../../data/models/purchase_result.dart';
import '../../data/services/purchase_service.dart';

class SupportArinPage extends ConsumerStatefulWidget {
  const SupportArinPage({super.key});

  @override
  ConsumerState<SupportArinPage> createState() => _SupportArinPageState();
}

class _SupportArinPageState extends ConsumerState<SupportArinPage> {
  String? _busyProductId;

  Future<void> _startPurchase(String productId) async {
    if (_busyProductId != null) return;
    setState(() => _busyProductId = productId);

    final service = ref.read(purchaseServiceProvider);
    final outcome = await service.purchaseSupportProduct(productId);

    if (!mounted) return;
    setState(() => _busyProductId = null);

    switch (outcome) {
      case PurchaseOutcome _ when outcome.isSuccess:
        _showSuccessDialog();
      case PurchaseOutcome _ when outcome.isCancelled:
        break;
      default:
        final msg = outcome.userMessage;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
          );
        }
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Teşekkürler! 🙏'),
        content: const Text(
          'Desteğin Arın için çok değerli. '
          'Bu katkıyla daha güzel bir deneyim sunmaya devam edeceğiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundNavy : AppColors.creamMist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.emeraldDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text("Arın'a Destek Ol"),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          const _HeaderCard(),
          const SizedBox(height: 18),
          _SupportCard(
            icon: Icons.local_cafe_rounded,
            title: 'Küçük Destek',
            subtitle: 'Bir kahve desteğiyle geliştirmeye katkı ver.',
            price: '₺49,99',
            productId: RevenueCatIds.smallSupportProductId,
            isBusy: _busyProductId == RevenueCatIds.smallSupportProductId,
            anyBusy: _busyProductId != null,
            onTap: () => _startPurchase(RevenueCatIds.smallSupportProductId),
          ),
          const SizedBox(height: 12),
          _SupportCard(
            icon: Icons.favorite_rounded,
            title: 'Orta Destek',
            subtitle: 'Yeni içerik ve özelliklerin gelişmesini hızlandır.',
            price: '₺149,99',
            productId: RevenueCatIds.mediumSupportProductId,
            highlighted: true,
            isBusy: _busyProductId == RevenueCatIds.mediumSupportProductId,
            anyBusy: _busyProductId != null,
            onTap: () => _startPurchase(RevenueCatIds.mediumSupportProductId),
          ),
          const SizedBox(height: 12),
          _SupportCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Büyük Destek',
            subtitle: "Arın'ın uzun vadeli gelişimine güçlü katkı ver.",
            price: '₺349,99',
            productId: RevenueCatIds.largeSupportProductId,
            isBusy: _busyProductId == RevenueCatIds.largeSupportProductId,
            anyBusy: _busyProductId != null,
            onTap: () => _startPurchase(RevenueCatIds.largeSupportProductId),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Text(
                'Destek paketleri tek seferlik mağaza ürünleri olarak çalışır. '
                'Premium abonelikten ayrıdır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                  height: 1.4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : AppColors.textSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.creamDark;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.goldAccent.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.emeraldDark.withValues(alpha: 0.96),
                  AppColors.goldAccent.withValues(alpha: 0.22),
                ]
              : [
                  AppColors.creamSurface,
                  AppColors.emeraldFaint.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Arın'ın yanında ol",
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bağış değil, mağaza kurallarına uygun tek seferlik destek '
            'paketleri. Uygulamanın reklamsız ve premium deneyimini '
            'büyütmemize yardımcı olur.',
            style: TextStyle(color: subtitleColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.productId,
    required this.isBusy,
    required this.anyBusy,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String productId;
  final bool isBusy;
  final bool anyBusy;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.textSecondary;
    final containerColor = highlighted
        ? AppColors.goldAccent.withValues(alpha: 0.12)
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.creamSurface.withValues(alpha: 0.85));
    final borderColor = highlighted
        ? AppColors.goldAccent.withValues(alpha: 0.7)
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.creamDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark
                  ? AppColors.accentNeonGreen
                  : AppColors.accentGreenOnLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, height: 1.28),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: anyBusy ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor:
                  highlighted ? AppColors.goldAccent : AppColors.accentNeonGreen,
              foregroundColor: const Color(0xFF07110B),
              disabledBackgroundColor:
                  (highlighted ? AppColors.goldAccent : AppColors.accentNeonGreen)
                      .withValues(alpha: 0.4),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF07110B),
                    ),
                  )
                : Text(price),
          ),
        ],
      ),
    );
  }
}
