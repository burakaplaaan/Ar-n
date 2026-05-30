// Sigara bırakma — haftalık şerit, metrik çubukları, zarif aksiyonlar, ilham kartları.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/willpower/willpower_content_loader.dart';

/// Haftalık tik şeridi (Pzt–Paz).
class QuitSmokingWeeklyStrip extends StatelessWidget {
  const QuitSmokingWeeklyStrip({
    super.key,
    required this.flags,
    this.compact = false,
    this.accent = const Color(0xFFE53935),
  });

  final List<bool> flags;
  final bool compact;
  final Color accent;

  static const _letters = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    final done = flags.where((e) => e).length;
    final h = compact ? 4.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.weeklyView,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context)!.daysDoneSummary(done.toString()),
              style: AppTextStyles.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final ok = i < flags.length && flags[i];
            final size = compact ? 30.0 : 36.0;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ok
                        ? accent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: ok
                          ? accent.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.12),
                      width: ok ? 2 : 1,
                    ),
                  ),
                  child: ok
                      ? Icon(Icons.check_rounded,
                          color: accent, size: compact ? 16 : 20)
                      : null,
                ),
                SizedBox(height: compact ? 3 : 5),
                Text(
                  _letters[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnDarkMuted,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class QuitMetricBarTile extends StatelessWidget {
  const QuitMetricBarTile({
    super.key,
    required this.icon,
    required this.label,
    required this.percent,
    this.delayMs = 0,
    this.iconColor,
    this.barColor,
  });

  final IconData icon;
  final String label;
  final double percent;
  final int delayMs;
  final Color? iconColor;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.creamBase.withValues(alpha: 0.55);
    final c = barColor ?? AppColors.emeraldMid.withValues(alpha: 0.85);
    final v = (percent / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(icon, size: 19, color: ic),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.creamBase,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${percent.clamp(0, 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnDarkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: v),
              duration: Duration(milliseconds: 900 + delayMs),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 10,
                        width: constraints.maxWidth,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: val.clamp(0.0, 1.0),
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        c.withValues(alpha: 0.5),
                                        c,
                                        c.withValues(alpha: 0.9),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// İki yan yana zarif düğme (üçgen arka plan yok).
class QuitDualActionRow extends StatelessWidget {
  const QuitDualActionRow({
    super.key,
    required this.leftLabel,
    required this.leftIcon,
    required this.onLeft,
    required this.rightLabel,
    required this.rightIcon,
    required this.onRight,
  });

  final String leftLabel;
  final IconData leftIcon;
  final VoidCallback onLeft;
  final String rightLabel;
  final IconData rightIcon;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ElegantOutlineButton(
          label: leftLabel,
          icon: leftIcon,
          onTap: onLeft,
        )),
        const SizedBox(width: 12),
        Expanded(child: _ElegantOutlineButton(
          label: rightLabel,
          icon: rightIcon,
          onTap: onRight,
        )),
      ],
    );
  }
}

class _ElegantOutlineButton extends StatelessWidget {
  const _ElegantOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.creamBase.withValues(alpha: 0.88)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.creamBase,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hub / Arınma — nefes egzersizi girişi (sade akış çizgileri).
class ArinmaBreathingOrbButton extends StatelessWidget {
  const ArinmaBreathingOrbButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.creamBase.withValues(alpha: 0.42);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.creamBase.withValues(alpha: 0.2),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emeraldMid.withValues(alpha: 0.1),
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(36, 36),
              painter: _BreathFlowLinesPainter(lineColor: line),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üç yumuşak eğri — nefes / hava akışı (minimal).
class _BreathFlowLinesPainter extends CustomPainter {
  _BreathFlowLinesPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    void wave(double yFactor, double amp, double phase) {
      final path = Path();
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = t * w;
        final mid = h * yFactor;
        final y = mid + math.sin(t * math.pi * 2 + phase) * amp;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    wave(0.38, h * 0.07, 0);
    wave(0.52, h * 0.09, 0.65);
    wave(0.66, h * 0.06, 1.2);
  }

  @override
  bool shouldRepaint(covariant _BreathFlowLinesPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class QuitWisdomCarousel extends StatelessWidget {
  const QuitWisdomCarousel({super.key, required this.items});

  static const _gold = Color(0xFFC9A962);

  final List<QuitWisdomItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.inspirationAndAwareness,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.creamBase.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.shortBreaksForTruth,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textOnDarkMuted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final it = items[i];
              final isSacred =
                  it.kind == 'ayet' || it.kind == 'sünnet';
              return Container(
                width: 268,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.035),
                  border: Border.all(
                    color: isSacred
                        ? _gold.withValues(alpha: 0.35)
                        : AppColors.emeraldMid.withValues(alpha: 0.28),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.kind.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _gold.withValues(alpha: isSacred ? 0.85 : 0.5),
                        letterSpacing: 1.1,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        it.body,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.creamBase.withValues(alpha: 0.9),
                          height: 1.42,
                          fontStyle: isSacred ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      it.source,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

