// Dün / son 7 gün namaz özeti — animasyonlu yorum kartı.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  String _comment(int yesterdayDone, double weekAvg) {
    if (weekAvg >= 4.5 && yesterdayDone >= 4) {
      return 'Son günlerde ritmin çok güçlü; kalbin düzenle hizalanmış görünüyor. Böyle devam.';
    }
    if (yesterdayDone == 5) {
      return 'Dün beş vakit tamam — Rabb’ine yakın bir gün geçirmişsin. Bugün de aynı niyetle devam edebilirsin.';
    }
    if (yesterdayDone == 0) {
      return 'Dün kayıt düşmemiş olabilir veya henüz işaretlenmemiş. Bugün tek bir vakitle bile çizgiyi yeniden çizebilirsin.';
    }
    if (weekAvg < 2.5) {
      return 'Bu hafta ortalama düşük; bu normal — tefekkür ve küçük adımlarla yükselir. Bir vakit fazlası büyük fark yaratır.';
    }
    if (yesterdayDone >= 3) {
      return 'Dün $yesterdayDone/5 vakit işaretli; bugün bir iki vakitle dengeyi tamamlamak mümkün.';
    }
    return 'Geçmiş günler verisi senin için bir ayna: eksik kalan yerlerde merhamet, tamamlananlarda şükür.';
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

    final msg = _comment(yDone, avg7);

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
                'Yansıma',
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
            'Dün · ${_weekdayShort(yesterday)} · $yDone/5  ·  Son 7 gün ort. ${avg7.toStringAsFixed(1)}/5',
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
