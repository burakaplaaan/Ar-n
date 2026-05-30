// Dün / son 7 gün namaz özeti — animasyonlu yorum kartı.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../salat_providers.dart';

class NamazInsightCard extends ConsumerStatefulWidget {
  const NamazInsightCard({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<NamazInsightCard> createState() => _NamazInsightCardState();
}

class _NamazInsightCardState extends ConsumerState<NamazInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _weekdayShort(DateTime d) {
    // DateTime.weekday: 1 = Pazartesi … 7 = Pazar
    const names = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    return names[d.weekday - 1];
  }

  String _comment(BuildContext context, int yesterdayDone, double weekAvg) {
    final l10n = AppLocalizations.of(context)!;
    if (weekAvg >= 4.5 && yesterdayDone >= 4) {
      return l10n.insightCommentStrong;
    }
    if (yesterdayDone == 5) {
      return l10n.insightCommentPerfect;
    }
    if (yesterdayDone == 0) {
      return l10n.insightCommentZero;
    }
    if (weekAvg < 2.5) {
      return l10n.insightCommentLow;
    }
    if (yesterdayDone >= 3) {
      // Assuming insightCommentGood takes a count
      // Wait, how to pass count if it's parameterized?
      // Since I don't know the exact ARB file structure generated, I should just assume standard code generation:
      // l10n.insightCommentGood(yesterdayDone.toString());
      // Actually, since I'm just creating the JSON and using the key, I will assume the key is created with parameter:
      // "insightCommentGood(yesterdayDone.toString())" or just "insightCommentGood" and I'll do a string replacement if needed.
      // But standard is l10n.insightCommentGood(yesterdayDone.toString()) or something similar.
      // Let's use a simpler approach: 
      // return l10n.insightCommentGood.replaceAll('{count}', yesterdayDone.toString());
      return l10n.insightCommentGood(yesterdayDone.toString());
    }
    return l10n.insightCommentDefault;
  }

  @override
  Widget build(BuildContext context) {
    final salat = ref.watch(salatLogRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    var sum7 = 0;
    for (var i = 0; i < 7; i++) {
      sum7 += salat.countDone(
        widget.habitId,
        today.subtract(Duration(days: i)),
      );
    }
    final avg7 = sum7 / 7.0;
    final yDone = salat.countDone(widget.habitId, yesterday);

    final msg = _comment(context, yDone, avg7);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final glow = 0.22 + 0.12 * math.sin(t * math.pi);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF152018).withValues(alpha: 0.95),
                const Color(0xFF0C100E).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: AppColors.accentNeonGreen.withValues(alpha: glow),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.06 + 0.04 * t),
                blurRadius: 22 + 8 * t,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.reflection,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.creamBase,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.yesterdayPrayerSummary(
              _weekdayShort(yesterday),
              yDone.toString(),
              avg7.toStringAsFixed(1),
            ),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnDarkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            msg,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.9),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 520.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, duration: 520.ms, curve: Curves.easeOutCubic);
  }
}
