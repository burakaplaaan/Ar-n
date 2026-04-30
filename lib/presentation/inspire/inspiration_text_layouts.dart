// 20 yerleşim × 2 ton (açık / koyu metin). `layoutIndex` 0–19.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/inspiration_card_model.dart';

class _Pal {
  const _Pal({
    required this.primary,
    required this.secondary,
    required this.source,
    required this.quote,
    required this.capsuleBg,
    this.shadows,
    this.arabicShadows,
    required this.divider,
  });

  final Color primary;
  final Color secondary;
  final Color source;
  final Color quote;
  final Color capsuleBg;
  final List<Shadow>? shadows;
  final List<Shadow>? arabicShadows;
  final Color divider;
}

_Pal _palette(bool lightTextOnImage) {
  if (lightTextOnImage) {
    return _Pal(
      primary: Colors.white,
      secondary: Colors.white.withValues(alpha: 0.92),
      source: Colors.white.withValues(alpha: 0.68),
      quote: Colors.white.withValues(alpha: 0.38),
      shadows: const [
        Shadow(
          blurRadius: 18,
          offset: Offset(0, 2),
          color: Color(0x88000000),
        ),
      ],
      arabicShadows: const [
        Shadow(
          blurRadius: 14,
          offset: Offset(0, 1),
          color: Color(0x77000000),
        ),
      ],
      divider: Colors.white.withValues(alpha: 0.35),
      capsuleBg: Colors.black.withValues(alpha: 0.22),
    );
  }
  return _Pal(
    primary: const Color(0xFF0F2A22),
    secondary: AppColors.emeraldDark,
    source: AppColors.textSecondary,
    quote: AppColors.textMuted,
    shadows: const [
      Shadow(
        blurRadius: 12,
        offset: Offset(0, 1),
        color: Color(0x33FFFFFF),
      ),
    ],
    arabicShadows: null,
    divider: AppColors.emeraldDark.withValues(alpha: 0.35),
    capsuleBg: Colors.white.withValues(alpha: 0.45),
  );
}

TextStyle _tr(
  _Pal p, {
  double size = 22,
  FontWeight weight = FontWeight.w500,
  double height = 1.42,
}) {
  return GoogleFonts.playfairDisplay(
    color: p.primary,
    fontSize: size,
    fontWeight: weight,
    height: height,
    shadows: p.shadows,
  );
}

TextStyle _ar(_Pal p, {double size = 20, FontWeight w = FontWeight.w500}) {
  return GoogleFonts.amiri(
    color: p.secondary,
    fontSize: size,
    fontWeight: w,
    height: 1.5,
    shadows: p.arabicShadows ?? p.shadows,
  );
}

TextStyle _src(_Pal p) => GoogleFonts.lora(
      color: p.source,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.35,
      fontStyle: FontStyle.italic,
      shadows: p.shadows,
    );

Widget _arabicIfAny(InspirationCardModel card, _Pal p, {double size = 19}) {
  final a = card.ar;
  if (a == null) return const SizedBox.shrink();
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Text(
      a,
      textAlign: TextAlign.center,
      style: _ar(p, size: size),
    ),
  );
}

/// Metin katmanı (görsel / gradient üstü).
Widget buildInspirationTextOverlay({
  required BuildContext context,
  required InspirationCardModel card,
}) {
  final light = card.useLightTextOnImage ?? true;
  final p = _palette(light);
  final li = card.safeLayoutIndex;
  final tr = card.tr;
  final src = card.source;

  switch (li) {
    case 0:
      return _layoutCenterClassic(card, p, tr, src);
    case 1:
      return _layoutTopSourceCapsule(card, p, tr, src);
    case 2:
      return _layoutBottomAnchored(card, p, tr, src);
    case 3:
      return _layoutArabicAboveTurkish(card, p, tr, src);
    case 4:
      return _layoutLeftBar(card, p, tr, src);
    case 5:
      return _layoutRightQuote(card, p, tr, src);
    case 6:
      return _layoutTightSerifBlock(card, p, tr, src);
    case 7:
      return _layoutOrnamentalDivider(card, p, tr, src);
    case 8:
      return _layoutUpperMinimal(card, p, tr, src);
    case 9:
      return _layoutSourceHeader(card, p, tr, src);
    case 10:
      return _layoutDoubleRuleFrame(card, p, tr, src);
    case 11:
      return _layoutTurkishThenArabic(card, p, tr, src);
    case 12:
      return _layoutIlhamBadge(card, p, tr, src);
    case 13:
      return _layoutInsetGlassCard(card, p, tr, src);
    case 14:
      return _layoutDiamondRow(card, p, tr, src);
    case 15:
      return _layoutSplitWeightLine(card, p, tr, src);
    case 16:
      return _layoutSideOpeningQuote(card, p, tr, src);
    case 17:
      return _layoutNestedFrame(card, p, tr, src);
    case 18:
      return _layoutStarRow(card, p, tr, src);
    case 19:
      return _layoutCornerBrackets(card, p, tr, src);
    default:
      return _layoutCenterClassic(card, p, tr, src);
  }
}

Widget _layoutCenterClassic(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('“', style: _tr(p, size: 42, weight: FontWeight.w200).copyWith(color: p.quote)),
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 23)),
        Text('”', style: _tr(p, size: 42, weight: FontWeight.w200).copyWith(color: p.quote)),
        if (card.ar != null) ...[
          const SizedBox(height: 18),
          _arabicIfAny(card, p, size: 20),
        ],
        if (src != null) ...[
          const SizedBox(height: 20),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutTopSourceCapsule(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (src != null)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.divider),
                color: p.capsuleBg,
              ),
              child: Text(src, textAlign: TextAlign.center, style: _src(p)),
            ),
          ),
        if (src != null) const SizedBox(height: 28),
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 21),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Center(
            child: Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 24)),
          ),
        ),
      ],
    ),
  );
}

Widget _layoutBottomAnchored(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (card.ar != null) ...[
          _arabicIfAny(card, p),
          const SizedBox(height: 14),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 22)),
        if (src != null) ...[
          const SizedBox(height: 16),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutArabicAboveTurkish(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 26),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 22),
          const SizedBox(height: 22),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 21)),
        if (src != null) ...[
          const SizedBox(height: 18),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutLeftBar(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 40, 28, 40),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.primary.withValues(alpha: 0.25),
                p.primary,
                p.primary.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.ar != null) ...[
                _arabicIfAny(card, p, size: 18),
                const SizedBox(height: 12),
              ],
              Text(tr, textAlign: TextAlign.left, style: _tr(p, size: 20)),
              if (src != null) ...[
                const SizedBox(height: 14),
                Text(src, style: _src(p)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _layoutRightQuote(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(32, 48, 20, 48),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('❞',
            style: GoogleFonts.playfairDisplay(
              fontSize: 56,
              color: p.quote,
              shadows: p.shadows,
            )),
        const SizedBox(height: 8),
        if (card.ar != null) ...[
          SizedBox(
            width: double.infinity,
            child: _arabicIfAny(card, p),
          ),
          const SizedBox(height: 12),
        ],
        Text(tr, textAlign: TextAlign.right, style: _tr(p, size: 21)),
        if (src != null) ...[
          const SizedBox(height: 16),
          Text(src, textAlign: TextAlign.right, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutTightSerifBlock(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              color: p.primary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.55,
              letterSpacing: 0.2,
              shadows: p.shadows,
            ),
          ),
          if (card.ar != null) ...[
            const SizedBox(height: 20),
            _arabicIfAny(card, p, size: 19),
          ],
          if (src != null) ...[
            const SizedBox(height: 18),
            Text(src, textAlign: TextAlign.center, style: _src(p)),
          ],
        ],
      ),
    ),
  );
}

Widget _layoutOrnamentalDivider(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: p.divider, thickness: 0.8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.auto_awesome, size: 18, color: p.quote),
            ),
            Expanded(child: Divider(color: p.divider, thickness: 0.8)),
          ],
        ),
        const SizedBox(height: 24),
        if (card.ar != null) ...[
          _arabicIfAny(card, p),
          const SizedBox(height: 16),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 22)),
        if (src != null) ...[
          const SizedBox(height: 20),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutUpperMinimal(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(28, 64, 28, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr,
          textAlign: TextAlign.left,
          style: _tr(p, size: 19, weight: FontWeight.w400),
        ),
        const Spacer(),
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 18),
          const SizedBox(height: 12),
        ],
        if (src != null) Text(src, style: _src(p)),
      ],
    ),
  );
}

Widget _layoutSourceHeader(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 52, 24, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (src != null)
          Text(
            src.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              color: p.quote,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              shadows: p.shadows,
            ),
          ),
        if (src != null) const SizedBox(height: 32),
        const Spacer(),
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 22),
          const SizedBox(height: 20),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 25)),
        const Spacer(),
      ],
    ),
  );
}

// ─── Yerleşim 10–19 ─────────────────────────────────────────────────────

Widget _layoutDoubleRuleFrame(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 1,
          width: 112,
          color: p.divider,
        ),
        const SizedBox(height: 22),
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 19),
          const SizedBox(height: 16),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 21)),
        const SizedBox(height: 22),
        Container(
          height: 1,
          width: 112,
          color: p.divider,
        ),
        if (src != null) ...[
          const SizedBox(height: 18),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutTurkishThenArabic(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 23)),
        if (card.ar != null) ...[
          const SizedBox(height: 26),
          _arabicIfAny(card, p, size: 21),
        ],
        if (src != null) ...[
          const SizedBox(height: 20),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutIlhamBadge(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.divider, width: 1.1),
            color: p.capsuleBg.withValues(alpha: 0.65),
          ),
          child: Text(
            'İLHAM',
            style: GoogleFonts.lora(
              color: p.quote,
              fontSize: 9,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
              shadows: p.shadows,
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (card.ar != null) ...[
          _arabicIfAny(card, p),
          const SizedBox(height: 14),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 21)),
        if (src != null) ...[
          const SizedBox(height: 18),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutInsetGlassCard(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.divider, width: 1.2),
          color: p.capsuleBg.withValues(alpha: 0.55),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.ar != null) ...[
              _arabicIfAny(card, p, size: 18),
              const SizedBox(height: 14),
            ],
            Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 20)),
            if (src != null) ...[
              const SizedBox(height: 16),
              Text(src, textAlign: TextAlign.center, style: _src(p)),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _layoutDiamondRow(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '◆   ◆   ◆',
          style: GoogleFonts.lora(
            color: p.quote,
            fontSize: 11,
            letterSpacing: 4,
            shadows: p.shadows,
          ),
        ),
        const SizedBox(height: 20),
        if (card.ar != null) ...[
          _arabicIfAny(card, p),
          const SizedBox(height: 16),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 22)),
        if (src != null) ...[
          const SizedBox(height: 18),
          Text(
            '◆   ◆   ◆',
            style: GoogleFonts.lora(
              color: p.quote,
              fontSize: 11,
              letterSpacing: 4,
              shadows: p.shadows,
            ),
          ),
          const SizedBox(height: 14),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutSplitWeightLine(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  if (tr.length <= 2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.ar != null) ...[
            _arabicIfAny(card, p, size: 19),
            const SizedBox(height: 16),
          ],
          Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 20)),
          if (src != null) ...[
            const SizedBox(height: 20),
            Text(src, textAlign: TextAlign.center, style: _src(p)),
          ],
        ],
      ),
    );
  }
  final mid = (tr.length / 2).floor().clamp(1, tr.length - 1);
  final a = tr.substring(0, mid).trim();
  final b = tr.substring(mid).trim();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.ar != null) ...[
          _arabicIfAny(card, p, size: 19),
          const SizedBox(height: 16),
        ],
        Text.rich(
          TextSpan(
            style: _tr(p, size: 20, weight: FontWeight.w400),
            children: [
              TextSpan(
                text: '$a ',
                style: _tr(p, size: 20, weight: FontWeight.w300),
              ),
              TextSpan(
                text: b,
                style: _tr(p, size: 20, weight: FontWeight.w700),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        if (src != null) ...[
          const SizedBox(height: 20),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
      ],
    ),
  );
}

Widget _layoutSideOpeningQuote(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 28, 40),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '“',
            style: GoogleFonts.playfairDisplay(
              fontSize: 72,
              height: 0.85,
              color: p.quote,
              shadows: p.shadows,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.ar != null) ...[
                _arabicIfAny(card, p, size: 17),
                const SizedBox(height: 10),
              ],
              Text(tr, textAlign: TextAlign.left, style: _tr(p, size: 19)),
              if (src != null) ...[
                const SizedBox(height: 14),
                Text(src, style: _src(p)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _layoutNestedFrame(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.divider.withValues(alpha: 0.55)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (card.ar != null) ...[
                _arabicIfAny(card, p, size: 18),
                const SizedBox(height: 12),
              ],
              Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 19)),
              if (src != null) ...[
                const SizedBox(height: 14),
                Text(src, textAlign: TextAlign.center, style: _src(p)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _layoutStarRow(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.star_rounded,
                size: 14,
                color: p.quote.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (card.ar != null) ...[
          _arabicIfAny(card, p),
          const SizedBox(height: 14),
        ],
        Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 21)),
        if (src != null) ...[
          const SizedBox(height: 18),
          Text(src, textAlign: TextAlign.center, style: _src(p)),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.star_rounded,
                size: 14,
                color: p.quote.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _layoutCornerBrackets(
  InspirationCardModel card,
  _Pal p,
  String tr,
  String? src,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            '⌜',
            style: GoogleFonts.lora(
              fontSize: 28,
              color: p.quote,
              shadows: p.shadows,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '⌟',
            style: GoogleFonts.lora(
              fontSize: 28,
              color: p.quote,
              shadows: p.shadows,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (card.ar != null) ...[
                _arabicIfAny(card, p),
                const SizedBox(height: 14),
              ],
              Text(tr, textAlign: TextAlign.center, style: _tr(p, size: 21)),
              if (src != null) ...[
                const SizedBox(height: 16),
                Text(src, textAlign: TextAlign.center, style: _src(p)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
