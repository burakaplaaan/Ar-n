import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspiration_card_model.dart';

/// Izgara hücresinin ekran koordinatındaki dikdörtgeni (viewer Hero-benzeri kapanış).
Rect? inspirationTileOriginRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  if (rect.width < 8 || rect.height < 8) return null;
  return rect;
}

/// Keşfet ızgarası — tüm hücreler aynı en-boy; görsel `BoxFit.cover` + ortala (dosya kırpılmaz).
class InspirationGridTile extends StatelessWidget {
  const InspirationGridTile({
    super.key,
    required this.card,
    required this.onTap,
  });

  final InspirationCardModel card;
  final ValueChanged<Rect?> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(inspirationTileOriginRect(context)),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Thumb(card: card),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.card});

  final InspirationCardModel card;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    // 3 kolonlu grid; fiziksel piksel cinsinden hücre genişliği.
    final cellPx = (screenW / 3 * dpr).ceil();
    return Image.asset(
      card.resolvedImageAssetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheWidth: cellPx,
      errorBuilder: (_, __, ___) => _Fallback(card: card),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.card});

  final InspirationCardModel card;

  @override
  Widget build(BuildContext context) {
    if (card.useLightTextOnImage ?? true) {
      return Container(
        color: const Color(0xFF121814),
        alignment: Alignment.center,
        child: Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
          size: 28,
        ),
      );
    }
    return Container(
      color: AppColors.creamDark.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(
        Icons.format_quote_rounded,
        color: AppColors.emeraldDark.withValues(alpha: 0.35),
        size: 28,
      ),
    );
  }
}
