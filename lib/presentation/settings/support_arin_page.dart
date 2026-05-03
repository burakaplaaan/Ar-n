import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class SupportArinPage extends StatelessWidget {
  const SupportArinPage({super.key});

  static const smallSupportProductId = 'arin_support_small';
  static const mediumSupportProductId = 'arin_support_medium';
  static const largeSupportProductId = 'arin_support_large';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Arın’a Destek Ol'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: const [
          _HeaderCard(),
          SizedBox(height: 18),
          _SupportCard(
            icon: Icons.local_cafe_rounded,
            title: 'Küçük Destek',
            subtitle: 'Bir kahve desteğiyle geliştirmeye katkı ver.',
            price: '₺49,99',
            productId: smallSupportProductId,
          ),
          SizedBox(height: 12),
          _SupportCard(
            icon: Icons.favorite_rounded,
            title: 'Orta Destek',
            subtitle: 'Yeni içerik ve özelliklerin gelişmesini hızlandır.',
            price: '₺149,99',
            productId: mediumSupportProductId,
            highlighted: true,
          ),
          SizedBox(height: 12),
          _SupportCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Büyük Destek',
            subtitle: 'Arın’ın uzun vadeli gelişimine güçlü katkı ver.',
            price: '₺349,99',
            productId: largeSupportProductId,
          ),
          SizedBox(height: 16),
          Text(
            'Destek paketleri tek seferlik mağaza ürünleri olarak çalışır. '
            'Premium abonelikten ayrıdır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emeraldDark.withValues(alpha: 0.96),
            AppColors.goldAccent.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arın’ın yanında ol',
            style: TextStyle(
              color: Colors.white,
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.4,
            ),
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
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String productId;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.goldAccent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? AppColors.goldAccent.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.12),
        ),
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
            child: Icon(icon, color: AppColors.accentNeonGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ürün hazırlanıyor: $productId. Mağaza ürünü açılınca '
                    'destek satın alma akışına bağlanacak.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  highlighted ? AppColors.goldAccent : AppColors.accentNeonGreen,
              foregroundColor: const Color(0xFF07110B),
            ),
            child: Text(price),
          ),
        ],
      ),
    );
  }
}
