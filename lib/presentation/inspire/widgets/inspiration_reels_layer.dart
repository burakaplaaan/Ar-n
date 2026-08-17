// Reels: Arapça (varsa) → Türkçe → çizgi → sure referansı (âyet).
// Açık görseller: nötr koyu gri/siyah dolgu + çok hafif beyaz kontur (kahve/terracotta yok).
// Font listesi: reels_typography.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/explore_occasion_message.dart';
import '../../../data/models/inspiration_card_model.dart';
import '../../../data/models/inspiration_content_kind.dart';
import '../inspiration_engagement_provider.dart';
import '../inspiration_like_count.dart';
import '../inspiration_like_totals_provider.dart';

// ── Okunurluk: ince kontur, abartısız ─────────────────────────────────────

/// Koyu metin (açık fotoğraf): tek sıra yumuşak beyaz dış hat.
List<Shadow> _reelsDarkOnLightReadable() {
  const c = Color(0xA8FFFFFF);
  const ring = <Offset>[
    Offset(-1, 0),
    Offset(1, 0),
    Offset(0, -1),
    Offset(0, 1),
    Offset(-1, -1),
    Offset(-1, 1),
    Offset(1, -1),
    Offset(1, 1),
  ];
  return [
    for (final o in ring) Shadow(offset: o, color: c, blurRadius: 0),
    const Shadow(blurRadius: 4, offset: Offset(0, 1), color: Color(0x22000000)),
  ];
}

/// Açık metin (koyu fotoğraf): ince siyah kontur + hafif gölge.
List<Shadow> _reelsLightOnDarkReadable() {
  const c = Color(0x72000000);
  const ring = <Offset>[
    Offset(-1, 0),
    Offset(1, 0),
    Offset(0, -1),
    Offset(0, 1),
    Offset(-1, -1),
    Offset(-1, 1),
    Offset(1, -1),
    Offset(1, 1),
  ];
  return [
    for (final o in ring) Shadow(offset: o, color: c, blurRadius: 0),
    const Shadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x66000000)),
  ];
}

bool _reelsUsesLeftColumn(int styleIdx) => styleIdx == 3 || styleIdx == 11;

/// Türkçe büyük harf satırı (10: ikinci blok Montserrat CAPS).
bool _isReelsAllCapsLine(String line) {
  final trimmed = line.trim();
  if (trimmed.length < 6) return false;
  var hasLetter = false;
  for (final rune in trimmed.runes) {
    final c = String.fromCharCode(rune);
    if (RegExp(r'[a-zçğıöşüA-ZÇĞİÖŞÜ]').hasMatch(c)) {
      hasLetter = true;
      if (RegExp(r'[a-zçğıöşü]').hasMatch(c)) return false;
    }
  }
  return hasLetter;
}

List<TextSpan> _reelsStyle13GoldSpans(
  String line,
  TextStyle baseWhite,
  Color gold,
) {
  final re = RegExp(r'\{\{g:(.+?)\}\}');
  final spans = <TextSpan>[];
  var start = 0;
  for (final m in re.allMatches(line)) {
    if (m.start > start) {
      spans.add(
        TextSpan(text: line.substring(start, m.start), style: baseWhite),
      );
    }
    spans.add(
      TextSpan(
        text: m.group(1) ?? '',
        style: baseWhite.copyWith(color: gold),
      ),
    );
    start = m.end;
  }
  if (start < line.length) {
    spans.add(TextSpan(text: line.substring(start), style: baseWhite));
  }
  if (spans.isEmpty) {
    return [TextSpan(text: line, style: baseWhite)];
  }
  return spans;
}

/// Sadece metin / Arapça / çizgi (paylaşım için [RepaintBoundary] içine konur).
class InspirationReelsQuoteBlock extends StatelessWidget {
  const InspirationReelsQuoteBlock({
    super.key,
    required this.card,
    required this.useLightTextOnImage,
    this.textAnchor = Alignment.center,
    this.scrollEnabled = true,
  });

  final InspirationCardModel card;
  final bool useLightTextOnImage;
  final Alignment textAnchor;
  final bool scrollEnabled;

  @override
  Widget build(BuildContext context) {
    final lightOnImage = useLightTextOnImage;
    final lines = card.tr.split('\n');
    final emphasis = card.safeEmphasisTailLines;
    final styleIdx = card.safeReelsStyle;

    final baseTr = lightOnImage
        ? Colors.white.withValues(alpha: 0.96)
        : const Color(0xFF121212);
    final emphColor = lightOnImage
        ? const Color(0xFFFFE082)
        : const Color(0xFFB8944A);
    final arabicColor =
        card.contentKind == InspirationContentKind.hadith && lightOnImage
        ? const Color(0xFFFFD700)
        : (lightOnImage ? const Color(0xFFE8C547) : const Color(0xFF1E1E1E));
    final lineColors = lightOnImage
        ? [
            Colors.transparent,
            const Color(0xFFE8C547).withValues(alpha: 0.9),
            const Color(0xFFFFD54F).withValues(alpha: 0.85),
            const Color(0xFFE8C547).withValues(alpha: 0.9),
            Colors.transparent,
          ]
        : [
            Colors.transparent,
            const Color(0xFF757575).withValues(alpha: 0.55),
            const Color(0xFF424242),
            const Color(0xFF757575).withValues(alpha: 0.55),
            Colors.transparent,
          ];

    final startEmph = emphasis > 0
        ? (lines.length - emphasis).clamp(0, lines.length)
        : lines.length;
    final lineWidgets = _mainLines(
      lines: lines,
      styleIdx: styleIdx,
      lightOnImage: lightOnImage,
      baseColor: baseTr,
      emphColor: emphColor,
      startEmphIndex: startEmph,
    );

    final verseRefColorResolved = styleIdx == 10
        ? (lightOnImage ? const Color(0xFFDFC88A) : const Color(0xFF6B5420))
        : (lightOnImage
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF424242));

    final occasion = exploreOccasionMessage(DateTime.now());
    final arText = card.ar;
    final verseRef = card.verseReference;

    final coreChildren = <Widget>[
      if (arText != null && arText.isNotEmpty) ...[
        _ReelsArabicParagraph(
          text: arText,
          imageIndex: card.imageIndex,
          color: arabicColor,
          lightOnImage: lightOnImage,
          textAlign: _reelsUsesLeftColumn(styleIdx)
              ? TextAlign.start
              : TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
      ...lineWidgets,
      const SizedBox(height: 18),
      _reelsUsesLeftColumn(styleIdx)
          ? Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 1.2,
                width: 132,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: lineColors),
                  boxShadow: lightOnImage
                      ? [
                          BoxShadow(
                            blurRadius: 6,
                            spreadRadius: 0,
                            color: const Color(
                              0xFFE8C547,
                            ).withValues(alpha: 0.28),
                          ),
                        ]
                      : null,
                ),
              ),
            )
          : Center(
              child: Container(
                height: 1.2,
                width: 132,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: lineColors),
                  boxShadow: lightOnImage
                      ? [
                          BoxShadow(
                            blurRadius: 6,
                            spreadRadius: 0,
                            color: const Color(
                              0xFFE8C547,
                            ).withValues(alpha: 0.28),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
      if (occasion != null) ...[
        const SizedBox(height: 12),
        Text(
          occasion,
          textAlign: _reelsUsesLeftColumn(styleIdx)
              ? TextAlign.start
              : TextAlign.center,
          style: GoogleFonts.montserrat(
            color: lightOnImage
                ? const Color(0xFFFFE082)
                : const Color(0xFFB8944A),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            height: 1.25,
            shadows: lightOnImage
                ? _reelsLightOnDarkReadable()
                : _reelsDarkOnLightReadable(),
          ),
        ),
      ],
      if (verseRef != null && verseRef.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          verseRef,
          textAlign: _reelsUsesLeftColumn(styleIdx)
              ? TextAlign.start
              : TextAlign.center,
          style: styleIdx == 10
              ? GoogleFonts.montserrat(
                  color: verseRefColorResolved,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  letterSpacing: 2.0,
                  shadows: lightOnImage
                      ? _reelsLightOnDarkReadable()
                      : _reelsDarkOnLightReadable(),
                )
              : GoogleFonts.inter(
                  color: verseRefColorResolved,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  fontStyle: FontStyle.italic,
                  shadows: lightOnImage
                      ? _reelsLightOnDarkReadable()
                      : _reelsDarkOnLightReadable(),
                ),
        ),
      ],
    ];

    final core = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _reelsUsesLeftColumn(styleIdx)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: coreChildren,
    );

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, c) {
          // Uzun âyet/hadis tamamen kaydırılabilir; görünür alanı daraltmayalım.
          final maxH = c.maxHeight * 0.78;
          final maxW = c.maxWidth - 52;

          return Align(
            alignment: textAnchor,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
              child: SingleChildScrollView(
                physics: scrollEnabled
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _reelsUsesLeftColumn(styleIdx)
                    ? Center(child: core)
                    : core,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sağ aksiyon şeridi (paylaşım görüntüsüne dahil edilmez).
class InspirationReelsActionRail extends ConsumerStatefulWidget {
  const InspirationReelsActionRail({
    super.key,
    required this.card,
    required this.lightOnImage,
    this.onRemixBackground,
    this.onShare,
    this.likeIconKey,
    this.likePulseToken = 0,
  });

  final InspirationCardModel card;
  final bool lightOnImage;
  final VoidCallback? onRemixBackground;
  final void Function(Rect? shareAnchor)? onShare;
  final Key? likeIconKey;
  final int likePulseToken;

  @override
  ConsumerState<InspirationReelsActionRail> createState() =>
      _InspirationReelsActionRailState();
}

class _InspirationReelsActionRailState
    extends ConsumerState<InspirationReelsActionRail> {
  void _prefetchCount(String cardId) {
    final locallyLiked = ref.read(inspirationLikedIdsProvider).contains(cardId);
    unawaited(
      ref.read(inspirationLikeTotalsProvider.notifier).ensureLoaded(
        cardId,
        locallyLiked: locallyLiked,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchCount(widget.card.id);
    });
  }

  @override
  void didUpdateWidget(covariant InspirationReelsActionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _prefetchCount(widget.card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final lightOnImage = widget.lightOnImage;
    final saved = ref.watch(inspirationSavedIdsProvider);
    final liked = ref.watch(inspirationLikedIdsProvider);
    final totals = ref.watch(inspirationLikeTotalsProvider);
    final isSaved = saved.contains(card.id);
    final isLiked = liked.contains(card.id);
    final savedNotifier = ref.read(inspirationSavedIdsProvider.notifier);
    final likedNotifier = ref.read(inspirationLikedIdsProvider.notifier);

    final bookmarkFilled = lightOnImage
        ? Colors.white
        : const Color(0xFF121212);
    final bookmarkIcon = isSaved
        ? Icons.bookmark_rounded
        : Icons.bookmark_border_rounded;
    final bookmarkColor = isSaved
        ? bookmarkFilled
        : Colors.white.withValues(alpha: 0.92);

    final likeIcon = isLiked
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;
    final likeColor = isLiked
        ? const Color(0xFFFF5252)
        : Colors.white.withValues(alpha: 0.92);
    final likeCount = displayedInspirationLikeCount(
      card.id,
      likedByUser: isLiked,
      remoteExtra: totals.extras[card.id] ?? 0,
      remoteExtraLoaded: totals.loadedIds.contains(card.id),
      remoteIncludesUser: totals.remotelyCountedIds.contains(card.id),
    );
    final likeCountLabel = formatInspirationLikeCount(likeCount);

    return Positioned(
      right: 4,
      bottom: 0,
      top: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: lightOnImage
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.28),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReelsActionButton(
                      icon: likeIcon,
                      iconColor: likeColor,
                      iconKey: widget.likeIconKey,
                      pulseToken: widget.likePulseToken,
                      onPressed: () {
                        likedNotifier.toggle(card.id);
                        HapticFeedback.lightImpact();
                      },
                      label: 'Beğen',
                      caption: likeCountLabel,
                    ),
                    const SizedBox(height: 18),
                    _ReelsActionButton(
                      icon: bookmarkIcon,
                      iconColor: bookmarkColor,
                      onPressed: () {
                        savedNotifier.toggle(card.id);
                        HapticFeedback.lightImpact();
                      },
                      label: 'Kaydet',
                    ),
                    const SizedBox(height: 18),
                    _ReelsActionButton(
                      icon: Icons.menu_book_outlined,
                      onPressed: widget.onRemixBackground ?? () {},
                      label: 'Arka planı değiştir',
                    ),
                    const SizedBox(height: 18),
                    Builder(
                      builder: (shareBtnContext) {
                        return _ReelsActionButton(
                          icon: Icons.share_outlined,
                          onPressed: () {
                            Rect? anchor;
                            final box =
                                shareBtnContext.findRenderObject()
                                    as RenderBox?;
                            if (box != null && box.hasSize) {
                              anchor =
                                  box.localToGlobal(Offset.zero) & box.size;
                            }
                            widget.onShare?.call(anchor);
                          },
                          label: 'Paylaş',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InspirationReelsLayer extends StatelessWidget {
  const InspirationReelsLayer({
    super.key,
    required this.card,
    required this.useLightTextOnImage,
    this.textAnchor = Alignment.center,
    this.onRemixBackground,
    this.onShare,
    this.scrollEnabled = true,
  });

  final InspirationCardModel card;
  final bool useLightTextOnImage;
  final Alignment textAnchor;
  final VoidCallback? onRemixBackground;
  final void Function(Rect? shareAnchor)? onShare;
  final bool scrollEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InspirationReelsQuoteBlock(
          card: card,
          useLightTextOnImage: useLightTextOnImage,
          textAnchor: textAnchor,
          scrollEnabled: scrollEnabled,
        ),
        InspirationReelsActionRail(
          card: card,
          lightOnImage: useLightTextOnImage,
          onRemixBackground: onRemixBackground,
          onShare: onShare,
        ),
      ],
    );
  }
}

class _ReelsArabicParagraph extends StatelessWidget {
  const _ReelsArabicParagraph({
    required this.text,
    required this.imageIndex,
    required this.color,
    required this.lightOnImage,
    required this.textAlign,
  });

  final String text;
  final int imageIndex;
  final Color color;
  final bool lightOnImage;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final slot = imageIndex % 3;
    final shadows = lightOnImage
        ? _reelsLightOnDarkReadable()
        : _reelsDarkOnLightReadable();

    final base = TextStyle(
      color: color,
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.55,
      shadows: shadows,
    );

    Widget child;
    switch (slot) {
      case 1:
        child = Text(
          text,
          textAlign: textAlign,
          style: GoogleFonts.scheherazadeNew(textStyle: base),
        );
        break;
      case 2:
        child = Text(
          text,
          textAlign: textAlign,
          style: GoogleFonts.notoNaskhArabic(textStyle: base),
        );
        break;
      default:
        child = Text(
          text,
          textAlign: textAlign,
          style: GoogleFonts.amiri(textStyle: base),
        );
    }

    return Directionality(textDirection: TextDirection.rtl, child: child);
  }
}

List<Widget> _mainLines({
  required List<String> lines,
  required int styleIdx,
  required bool lightOnImage,
  required Color baseColor,
  required Color emphColor,
  required int startEmphIndex,
}) {
  final out = <Widget>[];
  final fs = lines.length > 14 ? 15.0 : (lines.length > 9 ? 16.0 : 17.0);
  var contentIdx = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty) {
      out.add(const SizedBox(height: 6));
      continue;
    }
    final emph = i >= startEmphIndex;
    final color = emph ? emphColor : baseColor;
    out.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: _lineText(
          line,
          styleIdx: styleIdx,
          lineContentIndex: contentIdx,
          color: color,
          baseColor: baseColor,
          emphColor: emphColor,
          lightOnImage: lightOnImage,
          fontSize: fs,
          emph: emph,
        ),
      ),
    );
    contentIdx++;
  }
  return out;
}

Widget _lineText(
  String line, {
  required int styleIdx,
  required int lineContentIndex,
  required Color color,
  required Color baseColor,
  required Color emphColor,
  required bool lightOnImage,
  required double fontSize,
  required bool emph,
}) {
  final align = _reelsUsesLeftColumn(styleIdx)
      ? TextAlign.left
      : TextAlign.center;

  final List<Shadow> shadows = lightOnImage
      ? _reelsLightOnDarkReadable()
      : _reelsDarkOnLightReadable();

  if (styleIdx == 9) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.cabinSketch(
        color: color,
        fontSize: fontSize + 2,
        fontWeight: FontWeight.w700,
        height: 1.32,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 10) {
    final caps = lineContentIndex > 0 && _isReelsAllCapsLine(line);
    if (caps) {
      return Text(
        line,
        textAlign: align,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: fontSize - 0.5,
          fontWeight: FontWeight.w600,
          height: 1.45,
          letterSpacing: 2.4,
          shadows: shadows,
        ),
      );
    }
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.bodoniModa(
        color: color,
        fontSize: lineContentIndex == 0 ? fontSize + 2.5 : fontSize + 0.5,
        fontWeight: lineContentIndex == 0 ? FontWeight.w700 : FontWeight.w500,
        height: 1.32,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 11) {
    final secondaryTan = lightOnImage
        ? const Color(0xFFE9C46A)
        : const Color(0xFF7A5A20);
    if (lineContentIndex == 0) {
      return Text(
        line,
        textAlign: align,
        style: GoogleFonts.greatVibes(
          color: baseColor,
          fontSize: fontSize + 10,
          fontWeight: FontWeight.w400,
          height: 1.25,
          shadows: shadows,
        ),
      );
    }
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.lora(
        color: secondaryTan,
        fontSize: fontSize + 0.5,
        fontWeight: FontWeight.w500,
        height: 1.48,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 12) {
    if (lineContentIndex == 0) {
      return Text(
        line,
        textAlign: align,
        style: GoogleFonts.satisfy(
          color: color,
          fontSize: fontSize + 6,
          fontWeight: FontWeight.w400,
          height: 1.2,
          shadows: shadows,
        ),
      );
    }
    if (lineContentIndex == 1) {
      return Text(
        line,
        textAlign: align,
        style: GoogleFonts.lora(
          color: color,
          fontSize: fontSize + 0.5,
          fontWeight: FontWeight.w400,
          height: 1.45,
          shadows: shadows,
        ),
      );
    }
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.playfairDisplay(
        color: color,
        fontSize: fontSize + 1,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        height: 1.38,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 13) {
    final gold = lightOnImage
        ? const Color(0xFFE9C46A)
        : const Color(0xFFB8944A);
    final baseWhite = GoogleFonts.playfairDisplay(
      color: baseColor,
      fontSize: fontSize + 0.5,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.42,
      shadows: shadows,
    );
    if (line.contains('{{g:')) {
      return Text.rich(
        TextSpan(children: _reelsStyle13GoldSpans(line, baseWhite, gold)),
        textAlign: align,
      );
    }
    return Text(line, textAlign: align, style: baseWhite);
  }

  if (styleIdx == 5) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.robotoCondensed(
        color: color,
        fontSize: fontSize + 1,
        fontWeight: FontWeight.w700,
        height: 1.35,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 1) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.inter(
        color: color,
        fontSize: fontSize,
        fontWeight: lightOnImage ? FontWeight.w600 : FontWeight.w600,
        height: 1.42,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 2) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.ebGaramond(
        color: color,
        fontSize: fontSize + 1,
        fontWeight: lightOnImage ? FontWeight.w600 : FontWeight.w700,
        height: 1.38,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 6) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.lora(
        color: color,
        fontSize: fontSize + 0.5,
        fontWeight: lightOnImage ? FontWeight.w500 : FontWeight.w700,
        height: 1.42,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 7) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.cormorantGaramond(
        color: color,
        fontSize: fontSize + 1,
        fontWeight: lightOnImage ? FontWeight.w600 : FontWeight.w700,
        height: 1.38,
        shadows: shadows,
      ),
    );
  }

  if (styleIdx == 8) {
    return Text(
      line,
      textAlign: align,
      style: GoogleFonts.quicksand(
        color: color,
        fontSize: fontSize,
        fontWeight: lightOnImage ? FontWeight.w600 : FontWeight.w700,
        height: 1.4,
        shadows: shadows,
      ),
    );
  }

  final serifWeight = lightOnImage
      ? (styleIdx == 4 ? FontWeight.w600 : FontWeight.w500)
      : (styleIdx == 4 ? FontWeight.w700 : FontWeight.w600);

  return Text(
    line,
    textAlign: align,
    style: GoogleFonts.playfairDisplay(
      color: color,
      fontSize: fontSize + (styleIdx == 4 ? 0.5 : 0),
      fontWeight: serifWeight,
      height: 1.4,
      shadows: shadows,
    ),
  );
}

class _LikeIconPulse extends StatefulWidget {
  const _LikeIconPulse({
    required this.pulseToken,
    required this.child,
  });

  final int pulseToken;
  final Widget child;

  @override
  State<_LikeIconPulse> createState() => _LikeIconPulseState();
}

class _LikeIconPulseState extends State<_LikeIconPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.28), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _LikeIconPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseToken != oldWidget.pulseToken && widget.pulseToken > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class _ReelsActionButton extends StatelessWidget {
  const _ReelsActionButton({
    required this.icon,
    required this.onPressed,
    required this.label,
    this.iconColor,
    this.caption,
    this.iconKey,
    this.pulseToken = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String label;
  final Color? iconColor;
  final String? caption;
  final Key? iconKey;
  final int pulseToken;

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? Colors.white.withValues(alpha: 0.92);
    final captionText = caption;
    return Semantics(
      button: true,
      label: captionText == null ? label : '$label, $captionText',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: captionText == null
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
          child: Padding(
            padding: captionText == null
                ? const EdgeInsets.all(6)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LikeIconPulse(
                  pulseToken: pulseToken,
                  child: Icon(
                    icon,
                    key: iconKey,
                    size: 30,
                    color: c,
                    shadows: const [
                      Shadow(
                        blurRadius: 10,
                        offset: Offset(0, 1),
                        color: Color(0x99000000),
                      ),
                    ],
                  ),
                ),
                if (captionText != null) ...[
                  const SizedBox(height: 2),
                  ExcludeSemantics(
                    child: Text(
                      captionText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        shadows: const [
                          Shadow(
                            blurRadius: 8,
                            offset: Offset(0, 1),
                            color: Color(0x99000000),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
