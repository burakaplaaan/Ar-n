// Günlük beş vakit — üçgen tikler; hub ve namaz ekranında ortak.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/services/arin_widget_sync.dart';
import '../../shared/providers/habit_providers.dart';
import '../../shared/providers/prayer_time_providers.dart';
import '../salat_providers.dart';

class _UpTrianglePainter extends CustomPainter {
  _UpTrianglePainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UpTrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}

class SalatPrayerRow extends ConsumerWidget {
  const SalatPrayerRow({
    super.key,
    required this.habitId,
    this.compact = false,
    this.day,
    this.firstPrayerLabelOverride,
  });

  final String habitId;
  final bool compact;

  /// Varsayılan: bugün.
  final DateTime? day;

  /// İlk vakit (imsak) etiketini bu satıra özel değiştirmek için.
  final String? firstPrayerLabelOverride;

  String _defaultFirstPrayerLabel(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('tr')) return 'Sabah';
    if (code.startsWith('ar')) return 'الفجر';
    return 'Fajr';
  }

  DateTime _fallbackStorageDay(DateTime now) {
    final cal = DateTime(now.year, now.month, now.day);
    // Vakitler yüklenemediyse gece yarısı-imsak arası için eski davranışa
    // yakın kal: yatsı → sabah aralığını önceki salat gününe yaz. 08:00
    // muhafazakâr eşik; gerçek sabah sınırı kışın 06:00'ı aşabildiği için
    // vakitler sonradan yüklenince tiklerin "kaybolmuş" görünmesini azaltır.
    if (now.hour < 8) return cal.subtract(const Duration(days: 1));
    return cal;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prayerLabels = <String>[
      firstPrayerLabelOverride ?? _defaultFirstPrayerLabel(context),
      l10n.prayerNameDhuhr,
      l10n.prayerNameAsr,
      l10n.prayerNameMaghrib,
      l10n.prayerNameIsha,
    ];
    final onLight = ArinShellBackground.isLight(context);
    final now = DateTime.now();
    final salat = ref.watch(salatLogRepositoryProvider);
    final habitRepo = ref.read(habitRepositoryProvider);
    final prayerAsync = ref.watch(prayerTimesProvider);

    /// Takvimde belirli gün: o gün. Canlı satır: imsak günü (gece yatsı dahil).
    final DateTime storageDay = day != null
        ? DateTime(day!.year, day!.month, day!.day)
        : prayerAsync.maybeWhen(
            data: (pt) => pt.salatTickCalendarDay(now),
            orElse: () => _fallbackStorageDay(now),
          );

    final prayers = salat.getPrayers(habitId, storageDay);

    final triSize = compact ? 12.0 : 20.0;

    // Vakit penceresi kısıtı kaldırıldı: kullanıcı dilediği vakti (gün içinde
    // önce ya da sonra) serbestçe işaretleyip kaldırabilir. Vakit servisi
    // yüklenemezse de üçgenler kilitlenmez.

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final done = prayers[i];

        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await salat.setPrayer(
                  habitId,
                  storageDay,
                  i,
                  !done,
                  habitRepo,
                );
                ref.read(habitSummaryProvider.notifier).refresh();
                unawaited(ArinWidgetSync.refreshPrayerTodayMarks());
              },
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: compact ? 34 : 48,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: compact ? 4 : 10,
                    horizontal: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: Size(triSize, triSize * 1.05),
                        painter: _UpTrianglePainter(
                          color: done
                              ? (onLight
                                  ? AppColors.accentGreenOnLight
                                  : AppColors.accentNeonGreen)
                              : (onLight
                                  ? AppColors.emeraldDark.withValues(
                                      alpha: 0.38,
                                    )
                                  : AppColors.creamBase.withValues(
                                      alpha: 0.28,
                                    )),
                          filled: done,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 6),
                      Text(
                        prayerLabels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: (compact
                                ? AppTextStyles.labelSmall
                                : AppTextStyles.bodySmall)
                            .copyWith(
                          color: done
                              ? (onLight
                                  ? AppColors.accentGreenOnLight
                                  : AppColors.accentNeonGreen)
                                  .withValues(alpha: 0.95)
                              : (onLight
                                  ? AppColors.textSecondary.withValues(
                                      alpha: 1.0,
                                    )
                                  : AppColors.textOnDarkMuted.withValues(
                                      alpha: 1.0,
                                    )),
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 8 : 11,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Son [dayCount] gün için gün — tamamlanan/5 metni (takvim şeridi).
class SalatRecentDaysStrip extends ConsumerWidget {
  const SalatRecentDaysStrip({
    super.key,
    required this.habitId,
    this.dayCount = 21,
  });

  final String habitId;
  final int dayCount;

  static const _weekdayLettersTr = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
  static const _weekdayLettersEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayLettersAr = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    final letters = code.startsWith('ar')
        ? _weekdayLettersAr
        : (code.startsWith('en') ? _weekdayLettersEn : _weekdayLettersTr);
    final salat = ref.watch(salatLogRepositoryProvider);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: dayCount - 1));

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: dayCount,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final d = start.add(Duration(days: index));
          final n = salat.countDone(habitId, d);
          final isToday = d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
          final letter = letters[d.weekday - 1];

          return Container(
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isToday
                  ? AppColors.accentNeonGreen.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isToday
                    ? AppColors.accentNeonGreen.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$n/5',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: n == 5
                        ? AppColors.accentNeonGreen
                        : AppColors.creamBase.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
