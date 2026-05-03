// Ana sayfa — günlük namaz hadisi / âyet / sözü (Arapça + Türkçe veya sadece Türkçe söz), animasyonlu kart.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/locale_text.dart';
import '../../../core/theme/arin_shell_background.dart';
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
    final fallbackText = trEnAr(
      context,
      tr: 'Hatırlatıcı metni yüklenemedi. Sayfayı yenilemeyi dene.',
      en: 'Reminder text could not be loaded. Try refreshing the page.',
      ar: 'تعذر تحميل نص التذكير. حاول تحديث الصفحة.',
    );
    final onDark = !ArinShellBackground.isLight(context);
    const accent = AppColors.accentNeonGreen;
    final borderC = accent.withValues(alpha: onDark ? 0.38 : 0.45);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.92) : AppColors.emeraldDark;
    // Okunabilirliği korurken kart görsel ağırlığını biraz azalt.
    final bodyC = onDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.emeraldDark.withValues(alpha: 0.88);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onDark
                ? [
                    AppColors.homeCardSurface.withValues(alpha: 0.88),
                    const Color(0xFF0A120E).withValues(alpha: 0.94),
                  ]
                : [
                    AppColors.creamSurface,
                    AppColors.creamMist.withValues(alpha: 0.95),
                  ],
          ),
          border: Border.all(color: borderC, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: accent.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.homeDailyReminderTitle,
                  style: TextStyle(
                    color: titleC,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (entry.source != null) ...[
              const SizedBox(height: 3),
              Text(
                entry.source!,
                style: TextStyle(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.56)
                      : AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Icon(
              Icons.format_quote_rounded,
              size: 18,
              color: accent.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 4),
            Text(
              entry.turkish.trim().isEmpty
                  ? fallbackText
                  : entry.turkish,
              textAlign: TextAlign.center,
              style: TextStyle(
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
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        )
        .shimmer(
          delay: 450.ms,
          duration: 1.6.seconds,
          color: accent.withValues(alpha: 0.06),
        );
  }
}
