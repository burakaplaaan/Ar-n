// Ana sayfa — günlük namaz hadisi / âyet / sözü (Arapça + Türkçe veya sadece Türkçe söz), animasyonlu kart.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/content/daily_namaz_wisdom.dart';

class DailyNamazWisdomCard extends ConsumerWidget {
  const DailyNamazWisdomCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = dailyNamazWisdomFor(DateTime.now());
    return _DailyNamazWisdomBody(entry: entry);
  }
}

class _DailyNamazWisdomBody extends StatelessWidget {
  const _DailyNamazWisdomBody({required this.entry});

  final DailyNamazWisdom entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fallbackText = l10n.dailyNamazWisdomFallback;
    final onLight = Theme.of(context).brightness == Brightness.light;
    final warmBrown = onLight
        ? const Color(0xFF8B5E3C)
        : const Color(0xFFC59B6D);
    final warmBrownSoft = onLight
        ? const Color(0xFFC9A27A)
        : const Color(0xFF8A6545);
    final titleC = onLight
        ? AppColors.emeraldDark
        : Colors.white.withValues(alpha: 0.92);
    final secondaryC = onLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.42);
    final bodyC = onLight
        ? AppColors.emeraldDark.withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.82);

    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: onLight
                ? Colors.white.withValues(alpha: 0.92)
                : AppColors.homeCardSurface.withValues(alpha: 0.72),
            border: Border.all(
              color: Color.lerp(
                AppColors.accentNeonGreen,
                warmBrown,
                0.3,
              )!.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: warmBrownSoft.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      warmBrownSoft.withValues(alpha: 0.0),
                      warmBrown.withValues(alpha: 0.5),
                      warmBrownSoft.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: 0.7853981633974483,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: warmBrown.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            l10n.homeDailyReminderTitle,
                            style: TextStyle(
                              color: titleC,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        height: 1.5,
                        width: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              warmBrown.withValues(alpha: 0.55),
                              warmBrownSoft.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (entry.source != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.source!,
                        style: TextStyle(
                          color: secondaryC,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 18,
                          color: warmBrown.withValues(alpha: 0.52),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.turkish.trim().isEmpty
                                ? fallbackText
                                : entry.turkish,
                            textAlign: TextAlign.start,
                            style:
                                TextStyle(
                                  fontFamily: AppTextStyles.primaryFontFamily,
                                  fontSize: 12,
                                  height: 1.34,
                                  fontWeight: FontWeight.w500,
                                  color: bodyC,
                                  letterSpacing: -0.05,
                                ).copyWith(
                                  fontFamilyFallback: const <String>[
                                    'Roboto',
                                    'Noto Sans',
                                    'sans-serif',
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
