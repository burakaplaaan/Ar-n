// Mushaf ortak parçaları: tezhip şeridi, ışıltı, satırlar, mini oynatıcı.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_surah_catalog.dart';
import '../../shared/widgets/arin_pressable.dart';
import 'quran_style.dart';

class QuranOrnamentBar extends StatelessWidget {
  const QuranOrnamentBar({super.key, required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    final soft = QuranStyle.bronzeSoft(onDark);

    Widget line({required bool toRight}) {
      return Expanded(
        child: Container(
          height: 1.1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
              end: toRight ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                bronze.withValues(alpha: 0),
                bronze.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      );
    }

    Widget diamond({required double size, required double alpha, bool glow = false}) {
      return Transform.rotate(
        angle: QuranStyle.diamondAngle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bronze.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(1.6),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: soft.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          line(toRight: true),
          const SizedBox(width: 10),
          diamond(size: 5, alpha: 0.5),
          const SizedBox(width: 7),
          diamond(size: 8, alpha: 0.88, glow: true),
          const SizedBox(width: 7),
          diamond(size: 5, alpha: 0.5),
          const SizedBox(width: 10),
          line(toRight: false),
        ],
      ),
    );
  }
}

class QuranShimmerBlock extends StatefulWidget {
  const QuranShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    required this.onDark,
    this.radius = 8,
  });

  final double width;
  final double height;
  final bool onDark;
  final double radius;

  @override
  State<QuranShimmerBlock> createState() => _QuranShimmerBlockState();
}

class _QuranShimmerBlockState extends State<QuranShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.onDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.creamDark.withValues(alpha: 0.45);
    final shine = widget.onDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.7);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + _ctrl.value * 2.4, 0),
              end: Alignment(-0.2 + _ctrl.value * 2.4, 0),
              colors: [base, shine, base],
            ),
          ),
        );
      },
    );
  }
}

class QuranAyahSkeleton extends StatelessWidget {
  const QuranAyahSkeleton({super.key, required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: QuranShimmerBlock(
              width: MediaQuery.sizeOf(context).width * 0.78,
              height: 22,
              onDark: onDark,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: QuranShimmerBlock(
              width: MediaQuery.sizeOf(context).width * 0.62,
              height: 22,
              onDark: onDark,
            ),
          ),
          const SizedBox(height: 14),
          QuranShimmerBlock(
            width: MediaQuery.sizeOf(context).width * 0.88,
            height: 12,
            onDark: onDark,
            radius: 6,
          ),
        ],
      ),
    );
  }
}

class QuranSurahTile extends StatelessWidget {
  const QuranSurahTile({
    super.key,
    required this.meta,
    required this.onDark,
    required this.languageCode,
    required this.meccanLabel,
    required this.medinanLabel,
    required this.ayahCountLabel,
    required this.onTap,
  });

  final QuranSurahMeta meta;
  final bool onDark;
  final String languageCode;
  final String meccanLabel;
  final String medinanLabel;
  final String ayahCountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    final title = QuranStyle.title(onDark);
    final local = meta.localizedName(languageCode);
    return ArinPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                QuranStyle.cardFill(onDark),
                QuranStyle.cardFillDeep(onDark),
              ],
            ),
            border: Border.all(color: QuranStyle.border(onDark)),
            boxShadow: [
              BoxShadow(
                color: bronze.withValues(alpha: onDark ? 0.1 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                _SurahIndexBadge(number: meta.number, onDark: onDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: title,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meta.meccan ? meccanLabel : medinanLabel}  ·  $ayahCountLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: QuranStyle.muted(onDark),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    meta.arabic,
                    style: TextStyle(
                      color: bronze.withValues(alpha: 0.95),
                      fontSize: 22,
                      height: 1.15,
                      fontFamily: QuranStyle.arabicFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahIndexBadge extends StatelessWidget {
  const _SurahIndexBadge({required this.number, required this.onDark});

  final int number;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: QuranStyle.diamondAngle,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: bronze.withValues(alpha: 0.7)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bronze.withValues(alpha: onDark ? 0.22 : 0.16),
                    bronze.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              color: QuranStyle.title(onDark),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: AppTextStyles.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class QuranContinueCard extends StatelessWidget {
  const QuranContinueCard({
    super.key,
    required this.onDark,
    required this.title,
    required this.body,
    required this.onOpen,
    required this.onPlay,
  });

  final bool onDark;
  final String title;
  final String body;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: ArinPressable(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? const [Color(0xFF2A2218), Color(0xFF14110D)]
                  : const [Color(0xFFF3E6D4), Color(0xFFE8DCC8)],
            ),
            border: Border.all(color: bronze.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: bronze.withValues(alpha: onDark ? 0.22 : 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: bronze,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: QuranStyle.title(onDark),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                ArinPressable(
                  onTap: onPlay,
                  scale: 0.92,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bronze.withValues(alpha: onDark ? 0.22 : 0.18),
                      border: Border.all(color: bronze.withValues(alpha: 0.7)),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: onDark ? const Color(0xFFF6E7C9) : bronze,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuranMiniPlayer extends StatelessWidget {
  const QuranMiniPlayer({
    super.key,
    required this.onDark,
    required this.surahName,
    required this.ayahLabel,
    required this.playing,
    required this.buffering,
    required this.onPlayPause,
    required this.onOpen,
    required this.onStop,
  });

  final bool onDark;
  final String surahName;
  final String ayahLabel;
  final bool playing;
  final bool buffering;
  final VoidCallback onPlayPause;
  final VoidCallback onOpen;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onDark
                ? [
                    const Color(0xFF1A1610).withValues(alpha: 0.97),
                    const Color(0xFF0C0A08).withValues(alpha: 0.98),
                  ]
                : [
                    AppColors.creamSurface.withValues(alpha: 0.98),
                    AppColors.creamMist,
                  ],
          ),
          border: Border(
            top: BorderSide(color: bronze.withValues(alpha: 0.35)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: onDark ? 0.28 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(
            children: [
              ArinPressable(
                onTap: onPlayPause,
                scale: 0.92,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bronze.withValues(alpha: onDark ? 0.2 : 0.16),
                    border: Border.all(color: bronze.withValues(alpha: 0.65)),
                  ),
                  child: buffering
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: bronze,
                          ),
                        )
                      : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: onDark ? const Color(0xFFF6E7C9) : bronze,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArinPressable(
                  onTap: onOpen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: QuranStyle.title(onDark),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ayahLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: QuranStyle.muted(onDark),
                          fontSize: 12,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onStop,
                icon: Icon(
                  Icons.close_rounded,
                  color: QuranStyle.muted(onDark),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuranBismillahHeader extends StatelessWidget {
  const QuranBismillahHeader({super.key, required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      child: Column(
        children: [
          QuranOrnamentBar(onDark: onDark),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              QuranSurahCatalog.bismillahArabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bronze,
                fontFamily: QuranStyle.arabicFamily,
                fontSize: 26,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
