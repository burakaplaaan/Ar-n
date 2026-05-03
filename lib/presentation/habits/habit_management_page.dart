// Rutin atölyesi — gelişim: Namaz / Kaza takibi (▲▼), özel rutin.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/localization/locale_text.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../kaza/kaza_tracking_provider.dart';
import '../shared/providers/habit_providers.dart';

class HabitManagementPage extends ConsumerStatefulWidget {
  const HabitManagementPage({super.key});

  @override
  ConsumerState<HabitManagementPage> createState() =>
      _HabitManagementPageState();
}

class _HabitManagementPageState extends ConsumerState<HabitManagementPage> {
  /// 0 Namaz, 1 Kaza takibi, 2 Özel rutin
  int? _selected;

  void _setSelection(int i) => setState(() => _selected = i);

  Future<void> _onSave(BuildContext context) async {
    final sel = _selected;
    if (sel == null) return;

    if (sel == 0) {
      final summary = ref.read(habitSummaryProvider);
      HabitModel? salatHabit;
      for (final e in summary) {
        if (e.habit.templateId == WillpowerTemplates.salatDaily &&
            !e.habit.isArchived) {
          salatHabit = e.habit;
          break;
        }
      }
      final h = salatHabit ??
          await ref.read(habitSummaryProvider.notifier).createFromTemplate(
                templateId: WillpowerTemplates.salatDaily,
                title: trEnAr(
                  context,
                  tr: 'Günlük namaz',
                  en: 'Daily prayers',
                  ar: 'الصلوات اليومية',
                ),
                type: HabitType.good,
                emoji: '🕌',
                onboardingCompleted: false,
              );
      if (!context.mounted) return;
      context.push(
        AppRoutes.willNamaz(h.id, fromGelisimSetup: true),
      );
      return;
    }

    if (sel == 1) {
      await ref.read(kazaTrackingProvider.notifier).enableGelisimHubCard();
      if (context.mounted) {
        context.push(AppRoutes.kazaCalculator);
      }
      return;
    }

    await context.push(AppRoutes.addHabit, extra: HabitType.good);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _selected != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MgmtBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.creamBase.withValues(alpha: 0.88),
                          size: 18,
                        ),
                        label: Text(
                          l10n.surveyBack,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          trEnAr(
                            context,
                            tr: 'Rutin atölyesi',
                            en: 'Routine workshop',
                            ar: 'ورشة الروتين',
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: canSave ? () => _onSave(context) : null,
                        child: Text(
                          l10n.surveyNext,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: canSave
                                ? AppColors.accentNeonGreen
                                : AppColors.textOnDarkMuted
                                    .withValues(alpha: 0.45),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text(
                        trEnAr(
                          context,
                          tr: 'Gelişim seç',
                          en: 'Choose growth',
                          ar: 'اختر التطوير',
                        ),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trEnAr(
                          context,
                          tr: 'Namaz veya kaza takibini işaretle; özel bir gelişim için alttaki alanı kullan.',
                          en: 'Pick prayer or makeup tracking; use the section below for a custom growth routine.',
                          ar: 'اختر تتبع الصلاة أو القضاء؛ واستخدم القسم أدناه لروتين تطوير مخصص.',
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(child: SizedBox()),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.willpowerHubKazaTrackingTitle,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.creamBase,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      trEnAr(
                                        context,
                                        tr: 'Sayım ve telafi',
                                        en: 'Counting and compensation',
                                        ar: 'العدّ والتدارك',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textOnDarkMuted,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _InterlockingTrianglePair(
                            namazSelected: _selected == 0,
                            kazaSelected: _selected == 1,
                            onNamaz: () => _setSelection(0),
                            onKaza: () => _setSelection(1),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      trEnAr(
                                        context,
                                        tr: 'Namaz',
                                        en: 'Prayer',
                                        ar: 'الصلاة',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.creamBase,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      trEnAr(
                                        context,
                                        tr: 'Vakit ve huşû',
                                        en: 'Time and khushu',
                                        ar: 'الوقت والخشوع',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textOnDarkMuted,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SpecialRoutineCompactButton(
                        selected: _selected == 2,
                        onTap: () => _setSelection(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MgmtBackground extends StatelessWidget {
  const _MgmtBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF030806),
                Color(0xFF0A1610),
                Color(0xFF050A07),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -50,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emeraldMid.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sol ▲ + sağ ▼; taban uzunlukları eşit (2w/3), alanlar eşit (ortak kenar: tepe → sağ alt köşe).
class _InterlockingTriangleGeometry {
  _InterlockingTriangleGeometry(Size size)
      : w = size.width,
        h = size.height,
        apexLeft = Offset(size.width / 3, 0),
        bottomMid = Offset(size.width * 2 / 3, size.height),
        bottomLeft = Offset(0, size.height),
        topRight = Offset(size.width, 0);

  final double w;
  final double h;
  final Offset apexLeft;
  final Offset bottomMid;
  final Offset bottomLeft;
  final Offset topRight;

  /// Sol üçgen: taban altta, tepe yukarı.
  Path get leftPath => Path()
    ..moveTo(bottomLeft.dx, bottomLeft.dy)
    ..lineTo(bottomMid.dx, bottomMid.dy)
    ..lineTo(apexLeft.dx, apexLeft.dy)
    ..close();

  /// Sağ üçgen: taban üstte, tepe aşağı.
  Path get rightPath => Path()
    ..moveTo(apexLeft.dx, apexLeft.dy)
    ..lineTo(topRight.dx, topRight.dy)
    ..lineTo(bottomMid.dx, bottomMid.dy)
    ..close();

  /// Dış çerçeve (paralelkenar).
  Path get outerPath => Path()
    ..moveTo(bottomLeft.dx, bottomLeft.dy)
    ..lineTo(bottomMid.dx, bottomMid.dy)
    ..lineTo(topRight.dx, topRight.dy)
    ..lineTo(apexLeft.dx, apexLeft.dy)
    ..close();
}

class _InterlockingPairPainter extends CustomPainter {
  _InterlockingPairPainter({
    required this.namazSelected,
    required this.kazaSelected,
    required this.accent,
  });

  final bool namazSelected;
  final bool kazaSelected;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _InterlockingTriangleGeometry(size);

    Paint fillFor(bool selected) {
      if (selected) {
        return Paint()..color = accent.withValues(alpha: 0.24);
      }
      return Paint()..color = Colors.white.withValues(alpha: 0.052);
    }

    canvas.drawPath(g.leftPath, fillFor(namazSelected));
    canvas.drawPath(g.rightPath, fillFor(kazaSelected));

    final seam = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(g.apexLeft, g.bottomMid, seam);

    final borderCol = namazSelected || kazaSelected
        ? accent.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.12);
    final border = Paint()
      ..color = borderCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = namazSelected || kazaSelected ? 1.5 : 1.1;
    canvas.drawPath(g.outerPath, border);
  }

  @override
  bool shouldRepaint(covariant _InterlockingPairPainter oldDelegate) =>
      oldDelegate.namazSelected != namazSelected ||
      oldDelegate.kazaSelected != kazaSelected ||
      oldDelegate.accent != accent;
}

class _LeftTriClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      _InterlockingTriangleGeometry(size).leftPath;

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RightTriClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      _InterlockingTriangleGeometry(size).rightPath;

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _InterlockingTrianglePair extends StatelessWidget {
  const _InterlockingTrianglePair({
    required this.namazSelected,
    required this.kazaSelected,
    required this.onNamaz,
    required this.onKaza,
  });

  final bool namazSelected;
  final bool kazaSelected;
  final VoidCallback onNamaz;
  final VoidCallback onKaza;

  static const _accent = AppColors.accentNeonGreen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 0.58;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _InterlockingPairPainter(
                  namazSelected: namazSelected,
                  kazaSelected: kazaSelected,
                  accent: _accent,
                ),
              ),
              ClipPath(
                clipper: _RightTriClipper(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onKaza,
                    splashColor: _accent.withValues(alpha: 0.2),
                    highlightColor: _accent.withValues(alpha: 0.08),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Align(
                        alignment: const Alignment(1 / 3, -1 / 3),
                        child: Icon(
                          Icons.pending_actions_rounded,
                          size: 38,
                          color: kazaSelected
                              ? AppColors.creamBase
                              : AppColors.creamBase.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ClipPath(
                clipper: _LeftTriClipper(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNamaz,
                    splashColor: _accent.withValues(alpha: 0.2),
                    highlightColor: _accent.withValues(alpha: 0.08),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Align(
                        alignment: const Alignment(-1 / 3, 1 / 3),
                        child: Icon(
                          Icons.mosque_outlined,
                          size: 38,
                          color: namazSelected
                              ? AppColors.creamBase
                              : AppColors.creamBase.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Küçük standart düğme — özel rutin seçimi (Namaz/Kaza üçgenleri aynı kalır).
class _SpecialRoutineCompactButton extends StatelessWidget {
  const _SpecialRoutineCompactButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const _accent = AppColors.accentNeonGreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          trEnAr(
            context,
            tr: 'Özel rutin',
            en: 'Custom routine',
            ar: 'روتين مخصص',
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            trEnAr(
              context,
              tr: 'Başlık, emoji ve hatırlatmayı sen belirle.',
              en: 'Choose your own title, emoji and reminder.',
              ar: 'حدد العنوان والرمز التفاعلي والتذكير بنفسك.',
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.creamBase,
              side: BorderSide(
                color: _accent.withValues(alpha: selected ? 0.88 : 0.42),
                width: selected ? 1.45 : 1.05,
              ),
              backgroundColor: selected
                  ? _accent.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.045),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: _accent.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 6),
                Text(
                  trEnAr(
                    context,
                    tr: 'Seç',
                    en: 'Select',
                    ar: 'اختر',
                  ),
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 60.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.05,
          duration: 500.ms,
          delay: 60.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

