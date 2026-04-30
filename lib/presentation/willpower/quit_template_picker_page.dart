// Arınma — gelişim paneli ile uyumlu koyu tema, üçgen motif, kırmızı vurgu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';

const Color _kQuitAccent = Color(0xFFFF5252);
const Color _kSaveOutline = Color(0xFFFFC107);

class QuitTemplatePickerPage extends ConsumerStatefulWidget {
  const QuitTemplatePickerPage({super.key});

  @override
  ConsumerState<QuitTemplatePickerPage> createState() =>
      _QuitTemplatePickerPageState();
}

class _QuitTemplatePickerPageState
    extends ConsumerState<QuitTemplatePickerPage> {
  int? _selected;
  bool _saving = false;

  void _setSel(int i) => setState(() => _selected = i);

  static String? _templateIdForIndex(int index) {
    switch (index) {
      case 0:
        return WillpowerTemplates.quitScreen;
      case 1:
        return WillpowerTemplates.quitSmoking;
      case 2:
        return WillpowerTemplates.quitAlcohol;
      case 3:
        return WillpowerTemplates.quitSubstance;
      case 4:
        return WillpowerTemplates.quitZina;
      default:
        return null;
    }
  }

  void _toastTemplateExists(String templateId) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(habitRepositoryProvider);
    final existing = repo.findActiveByTemplateId(templateId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quitPickerTemplateAlreadyExists),
        behavior: SnackBarBehavior.floating,
        action: existing != null
            ? SnackBarAction(
                label: WillpowerTemplates.isFullQuitProgram(templateId)
                    ? l10n.quitPickerOpenAction
                    : l10n.quitPickerGoToListAction,
                onPressed: () {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.pop();
                  if (WillpowerTemplates.isFullQuitProgram(templateId)) {
                    if (existing.onboardingCompleted) {
                      context.push(AppRoutes.willQuitHome(existing.id));
                    } else {
                      context.push(AppRoutes.willQuitOnboarding(existing.id));
                    }
                  } else {
                    context.go(AppRoutes.habitsArinmaTab);
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context)!;
    final sel = _selected;
    if (sel == null || _saving) return;
    final repo = ref.read(habitRepositoryProvider);

    final checkId = _templateIdForIndex(sel);
    if (checkId != null && repo.hasActiveTemplate(checkId)) {
      _toastTemplateExists(checkId);
      return;
    }

    setState(() => _saving = true);

    try {
      final notifier = ref.read(habitSummaryProvider.notifier);
      switch (sel) {
        case 0:
          final h0 = await notifier.createFromTemplate(
            templateId: WillpowerTemplates.quitScreen,
            title: l10n.quitPickerTemplateScreenTitle,
            type: HabitType.bad,
            emoji: '📱',
            onboardingCompleted: false,
          );
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.willQuitOnboarding(h0.id));
          }
          break;
        case 1:
          final h = await notifier.createFromTemplate(
            templateId: WillpowerTemplates.quitSmoking,
            title: l10n.quitPickerTemplateSmokingTitle,
            type: HabitType.bad,
            emoji: '🚭',
            onboardingCompleted: false,
          );
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.willQuitOnboarding(h.id));
          }
          break;
        case 2:
          final h2 = await notifier.createFromTemplate(
            templateId: WillpowerTemplates.quitAlcohol,
            title: l10n.quitPickerTemplateAlcoholTitle,
            type: HabitType.bad,
            emoji: '🍷',
            onboardingCompleted: false,
          );
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.willQuitOnboarding(h2.id));
          }
          break;
        case 3:
          final h3 = await notifier.createFromTemplate(
            templateId: WillpowerTemplates.quitSubstance,
            title: l10n.quitPickerTemplateSubstanceTitle,
            type: HabitType.bad,
            emoji: '💊',
            onboardingCompleted: false,
          );
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.willQuitOnboarding(h3.id));
          }
          break;
        case 4:
          final h4 = await notifier.createFromTemplate(
            templateId: WillpowerTemplates.quitZina,
            title: l10n.quitPickerTemplateZinaTitle,
            type: HabitType.bad,
            emoji: '🛡️',
            onboardingCompleted: false,
          );
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.willQuitOnboarding(h4.id));
          }
          break;
        case 5:
          if (mounted) {
            ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
            context.pop();
            context.push(AppRoutes.addHabit, extra: HabitType.bad);
          }
          break;
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(habitRepositoryProvider);
    bool hasT(String id) => repo.hasActiveTemplate(id);
    final selTid = _selected != null ? _templateIdForIndex(_selected!) : null;
    final saveBlocked =
        selTid != null &&
        hasT(selTid); // seçili şablon zaten varsa Kaydet kapalı
    final canSave = _selected != null && !_saving && !saveBlocked;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ArinmaBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () {
                                ref
                                        .read(
                                          willpowerHubReturnToArinmaProvider
                                              .notifier,
                                        )
                                        .state =
                                    true;
                                popOrGoWillpowerHub(context);
                              },
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.shellOnCanvasPrimary(context),
                          size: 18,
                        ),
                        label: Text(
                          l10n.closeAction,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.shellOnCanvasPrimary(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.willpowerHubTabQuit,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.shellOnCanvasPrimary(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: canSave ? _onSave : null,
                        style: TextButton.styleFrom(
                          side: BorderSide(
                            color: canSave
                                ? _kSaveOutline
                                : _kSaveOutline.withValues(alpha: 0.28),
                            width: 1.35,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kSaveOutline.withValues(alpha: 0.9),
                                ),
                              )
                            : Text(
                                l10n.saveAction,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: canSave
                                      ? _kSaveOutline
                                      : AppColors.shellOnCanvasTertiary(
                                          context,
                                        ).withValues(alpha: 0.5),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: _QuitTriangleTrio(accent: _kQuitAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.quitPickerHeaderTitle,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.shellOnCanvasPrimary(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.quitPickerHeaderSubtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.shellOnCanvasSecondary(
                                      context,
                                    ),
                                    height: 1.45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, c) {
                          final fullW = c.maxWidth;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ArinmaWeaveTripleRow(
                                width: fullW,
                                slots: [
                                  _ArinmaTriSlot(
                                    title: l10n.quitPickerScreenLabel,
                                    subtitle: l10n.quitPickerScreenSubtitle,
                                    icon: Icons.smartphone_rounded,
                                    selected: _selected == 0,
                                    locked: hasT(WillpowerTemplates.quitScreen),
                                    onTap: () {
                                      if (hasT(WillpowerTemplates.quitScreen)) {
                                        _toastTemplateExists(
                                          WillpowerTemplates.quitScreen,
                                        );
                                        return;
                                      }
                                      _setSel(0);
                                    },
                                  ),
                                  _ArinmaTriSlot(
                                    title: l10n.quitPickerSmokingLabel,
                                    subtitle: l10n.quitPickerDefaultSubtitle,
                                    icon: Icons.smoke_free_rounded,
                                    selected: _selected == 1,
                                    locked: hasT(
                                      WillpowerTemplates.quitSmoking,
                                    ),
                                    onTap: () {
                                      if (hasT(
                                        WillpowerTemplates.quitSmoking,
                                      )) {
                                        _toastTemplateExists(
                                          WillpowerTemplates.quitSmoking,
                                        );
                                        return;
                                      }
                                      _setSel(1);
                                    },
                                  ),
                                  _ArinmaTriSlot(
                                    title: l10n.quitPickerAlcoholLabel,
                                    subtitle: l10n.quitPickerDefaultSubtitle,
                                    icon: Icons.local_bar_rounded,
                                    selected: _selected == 2,
                                    locked: hasT(
                                      WillpowerTemplates.quitAlcohol,
                                    ),
                                    onTap: () {
                                      if (hasT(
                                        WillpowerTemplates.quitAlcohol,
                                      )) {
                                        _toastTemplateExists(
                                          WillpowerTemplates.quitAlcohol,
                                        );
                                        return;
                                      }
                                      _setSel(2);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              _ArinmaWeaveTripleRow(
                                width: fullW,
                                slots: [
                                  _ArinmaTriSlot(
                                    title: l10n.quitPickerSubstanceLabel,
                                    subtitle: l10n.quitPickerSubstanceSubtitle,
                                    icon: Icons.medication_outlined,
                                    selected: _selected == 3,
                                    locked: hasT(
                                      WillpowerTemplates.quitSubstance,
                                    ),
                                    onTap: () {
                                      if (hasT(
                                        WillpowerTemplates.quitSubstance,
                                      )) {
                                        _toastTemplateExists(
                                          WillpowerTemplates.quitSubstance,
                                        );
                                        return;
                                      }
                                      _setSel(3);
                                    },
                                  ),
                                  _ArinmaTriSlot(
                                    title: l10n.quitPickerZinaLabel,
                                    subtitle: l10n.quitPickerDefaultSubtitle,
                                    icon: Icons.shield_outlined,
                                    selected: _selected == 4,
                                    locked: hasT(WillpowerTemplates.quitZina),
                                    onTap: () {
                                      if (hasT(WillpowerTemplates.quitZina)) {
                                        _toastTemplateExists(
                                          WillpowerTemplates.quitZina,
                                        );
                                        return;
                                      }
                                      _setSel(4);
                                    },
                                  ),
                                  null,
                                ],
                                hideTrailingEmptyTriangle: true,
                              ),
                              const SizedBox(height: 16),
                              _ArinmaSpecialCompactButton(
                                selected: _selected == 5,
                                onTap: () => _setSel(5),
                              ),
                            ],
                          );
                        },
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

class _ArinmaBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: light
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.creamMist,
                      AppColors.creamBase,
                      AppColors.creamShellDeep,
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                )
              : const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF060308),
                      Color(0xFF100818),
                      Color(0xFF08050A),
                    ],
                    stops: [0.0, 0.52, 1.0],
                  ),
                ),
        ),
        Positioned(
          top: -72,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kQuitAccent.withValues(alpha: light ? 0.05 : 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFF6A1B9A,
              ).withValues(alpha: light ? 0.045 : 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuitTriangleTrio extends StatelessWidget {
  const _QuitTriangleTrio({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniUpTri(color: accent.withValues(alpha: 0.35)),
        const SizedBox(width: 5),
        _MiniUpTri(color: accent.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        _MiniUpTri(color: accent.withValues(alpha: 0.88)),
      ],
    );
  }
}

class _MiniUpTri extends StatelessWidget {
  const _MiniUpTri({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(9, 10),
      painter: _MiniUpTriPainter(color: color),
    );
  }
}

class _MiniUpTriPainter extends CustomPainter {
  _MiniUpTriPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiniUpTriPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Satır başına ▲▼▲ örü (ortak kenarlı tek şerit) ───

class _ArinmaTriSlot {
  const _ArinmaTriSlot({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;
}

/// Sol ▲, orta ▼, sağ ▲ — alt kenar düz, üst iki tepe.
class _ArinmaWeaveGeom {
  _ArinmaWeaveGeom(Size size) : w = size.width, h = size.height;

  final double w;
  final double h;

  /// Sol yukarı: taban [0,h]–[w/2,h], tepe [w/4,0].
  Path get leftPath => Path()
    ..moveTo(0, h)
    ..lineTo(w / 2, h)
    ..lineTo(w / 4, 0)
    ..close();

  /// Orta aşağı: üst taban [w/4,0]–[3w/4,0], uç [w/2,h].
  Path get midPath => Path()
    ..moveTo(w / 4, 0)
    ..lineTo(3 * w / 4, 0)
    ..lineTo(w / 2, h)
    ..close();

  /// Sağ yukarı: taban [w/2,h]–[w,h], tepe [3w/4,0].
  Path get rightPath => Path()
    ..moveTo(w / 2, h)
    ..lineTo(w, h)
    ..lineTo(3 * w / 4, 0)
    ..close();

  Path get outerPath => Path()
    ..moveTo(0, h)
    ..lineTo(w, h)
    ..lineTo(3 * w / 4, 0)
    ..lineTo(w / 4, 0)
    ..close();

  Path get outerPathWithoutRight => Path()
    ..moveTo(0, h)
    ..lineTo(w / 2, h)
    ..lineTo(3 * w / 4, 0)
    ..lineTo(w / 4, 0)
    ..close();
}

class _ArinmaWeaveClipper extends CustomClipper<Path> {
  const _ArinmaWeaveClipper(this.index);
  final int index;

  @override
  Path getClip(Size size) {
    final g = _ArinmaWeaveGeom(size);
    switch (index) {
      case 0:
        return g.leftPath;
      case 1:
        return g.midPath;
      default:
        return g.rightPath;
    }
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArinmaWeavePainter extends CustomPainter {
  _ArinmaWeavePainter({
    required this.leftOn,
    required this.midOn,
    required this.rightOn,
    required this.leftDead,
    required this.midDead,
    required this.rightDead,
    required this.leftLocked,
    required this.midLocked,
    required this.rightLocked,
    required this.accent,
    required this.lightShell,
    this.hideRightTriangle = false,
  });

  final bool leftOn;
  final bool midOn;
  final bool rightOn;
  final bool leftDead;
  final bool midDead;
  final bool rightDead;
  final bool leftLocked;
  final bool midLocked;
  final bool rightLocked;
  final Color accent;
  final bool lightShell;
  final bool hideRightTriangle;

  Color _fill(bool on, bool dead, bool locked) {
    if (lightShell) {
      if (dead) return Colors.black.withValues(alpha: 0.04);
      if (locked) return Colors.black.withValues(alpha: 0.035);
      if (on) return accent.withValues(alpha: 0.2);
      return Colors.white.withValues(alpha: 0.72);
    }
    if (dead) return Colors.white.withValues(alpha: 0.028);
    if (locked) return Colors.white.withValues(alpha: 0.02);
    if (on) return accent.withValues(alpha: 0.24);
    return Colors.white.withValues(alpha: 0.052);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _ArinmaWeaveGeom(size);

    canvas.drawPath(
      g.leftPath,
      Paint()..color = _fill(leftOn, leftDead, leftLocked),
    );
    canvas.drawPath(
      g.midPath,
      Paint()..color = _fill(midOn, midDead, midLocked),
    );
    if (!hideRightTriangle) {
      canvas.drawPath(
        g.rightPath,
        Paint()..color = _fill(rightOn, rightDead, rightLocked),
      );
    }

    final seam = Paint()
      ..color = lightShell
          ? Colors.black.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width / 4, 0),
      Offset(size.width / 2, size.height),
      seam,
    );
    if (!hideRightTriangle) {
      canvas.drawLine(
        Offset(3 * size.width / 4, 0),
        Offset(size.width / 2, size.height),
        seam,
      );
    }

    final anySel = leftOn || midOn || rightOn;
    final borderCol = anySel
        ? accent.withValues(alpha: lightShell ? 0.48 : 0.55)
        : (lightShell
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.12));
    canvas.drawPath(
      hideRightTriangle ? g.outerPathWithoutRight : g.outerPath,
      Paint()
        ..color = borderCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = anySel ? 1.5 : 1.1
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArinmaWeavePainter oldDelegate) =>
      oldDelegate.leftOn != leftOn ||
      oldDelegate.midOn != midOn ||
      oldDelegate.rightOn != rightOn ||
      oldDelegate.leftDead != leftDead ||
      oldDelegate.midDead != midDead ||
      oldDelegate.rightDead != rightDead ||
      oldDelegate.leftLocked != leftLocked ||
      oldDelegate.midLocked != midLocked ||
      oldDelegate.rightLocked != rightLocked ||
      oldDelegate.accent != accent ||
      oldDelegate.lightShell != lightShell ||
      oldDelegate.hideRightTriangle != hideRightTriangle;
}

class _ArinmaWeaveTripleRow extends StatelessWidget {
  const _ArinmaWeaveTripleRow({
    required this.width,
    required this.slots,
    this.hideTrailingEmptyTriangle = false,
  });

  final double width;
  final List<_ArinmaTriSlot?> slots;
  final bool hideTrailingEmptyTriangle;

  static double weaveHeight(double w) => w * 0.44;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == 3);
    final h = weaveHeight(width);
    final light = ArinShellBackground.isLight(context);

    final s0 = slots[0];
    final s1 = slots[1];
    final s2 = slots[2];
    final compactTwo = hideTrailingEmptyTriangle && s2 == null;
    if (compactTwo) {
      return _buildCompactTwoRow(context, s0, s1, h, light);
    }
    final paintWidth = compactTwo ? width * 0.75 : width;

    Widget hitLayer(int i, _ArinmaTriSlot? s, Alignment iconAlign) {
      return ClipPath(
        clipper: _ArinmaWeaveClipper(i),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: s?.onTap,
            splashColor: _kQuitAccent.withValues(alpha: 0.18),
            highlightColor: _kQuitAccent.withValues(alpha: 0.06),
            child: SizedBox(
              width: paintWidth,
              height: h,
              child: s == null
                  ? const SizedBox.expand()
                  : Align(
                      alignment: iconAlign,
                      child: Icon(
                        s.icon,
                        size: 30,
                        color: s.locked
                            ? (light
                                  ? AppColors.textMuted.withValues(alpha: 0.65)
                                  : AppColors.creamBase.withValues(alpha: 0.32))
                            : s.selected
                            ? (light ? Colors.white : AppColors.creamBase)
                            : (light
                                  ? AppColors.emeraldDark.withValues(
                                      alpha: 0.82,
                                    )
                                  : AppColors.creamBase.withValues(
                                      alpha: 0.72,
                                    )),
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: paintWidth,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(paintWidth, h),
                painter: _ArinmaWeavePainter(
                  leftOn: s0?.selected ?? false,
                  midOn: s1?.selected ?? false,
                  rightOn: s2?.selected ?? false,
                  leftDead: s0 == null,
                  midDead: s1 == null,
                  rightDead: s2 == null,
                  leftLocked: s0?.locked ?? false,
                  midLocked: s1?.locked ?? false,
                  rightLocked: s2?.locked ?? false,
                  accent: _kQuitAccent,
                  lightShell: light,
                  hideRightTriangle: compactTwo,
                ),
              ),
              hitLayer(0, s0, const Alignment(-0.42, 0.38)),
              hitLayer(1, s1, const Alignment(0, -0.28)),
              if (!compactTwo) hitLayer(2, s2, const Alignment(0.42, 0.38)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: compactTwo
              ? [
                  Expanded(child: _weaveLabel(context, slots[0])),
                  Expanded(child: _weaveLabel(context, slots[1])),
                ]
              : [
                  Expanded(child: _weaveLabel(context, slots[0])),
                  Expanded(child: _weaveLabel(context, slots[1])),
                  Expanded(child: _weaveLabel(context, slots[2])),
                ],
        ),
      ],
    );
  }

  Widget _buildCompactTwoRow(
    BuildContext context,
    _ArinmaTriSlot? left,
    _ArinmaTriSlot? right,
    double h,
    bool light,
  ) {
    final rowW = width * 0.94;
    final triW = (rowW - 14) / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: rowW,
          child: Row(
            children: [
              _ArinmaSingleTriangle(
                width: triW,
                height: h,
                slot: left,
                light: light,
              ),
              const SizedBox(width: 14),
              _ArinmaSingleTriangle(
                width: triW,
                height: h,
                slot: right,
                light: light,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: rowW,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _weaveLabel(context, left)),
              const SizedBox(width: 14),
              Expanded(child: _weaveLabel(context, right)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _weaveLabel(BuildContext context, _ArinmaTriSlot? s) {
    final l10n = AppLocalizations.of(context)!;
    if (s == null) {
      return const SizedBox(height: 48);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.shellOnCanvasPrimary(context),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s.locked ? l10n.quitPickerAlreadyAdded : s.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            color: s.locked
                ? _kQuitAccent.withValues(alpha: 0.75)
                : AppColors.shellOnCanvasSecondary(context),
            height: 1.2,
            fontSize: 10,
            fontWeight: s.locked ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ArinmaSingleTriangle extends StatelessWidget {
  const _ArinmaSingleTriangle({
    required this.width,
    required this.height,
    required this.slot,
    required this.light,
  });

  final double width;
  final double height;
  final _ArinmaTriSlot? slot;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final s = slot;
    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: const _UpTriangleClipper(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: s?.onTap,
            splashColor: _kQuitAccent.withValues(alpha: 0.18),
            highlightColor: _kQuitAccent.withValues(alpha: 0.06),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: light ? 0.72 : 0.06),
                    Colors.white.withValues(alpha: light ? 0.55 : 0.035),
                  ],
                ),
                border: Border.all(
                  color: s?.selected == true
                      ? _kQuitAccent.withValues(alpha: light ? 0.52 : 0.62)
                      : (light
                            ? Colors.black.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.14)),
                  width: s?.selected == true ? 1.45 : 1.05,
                ),
              ),
              child: Center(
                child: s == null
                    ? const SizedBox.shrink()
                    : Icon(
                        s.icon,
                        size: 30,
                        color: s.locked
                            ? (light
                                  ? AppColors.textMuted.withValues(alpha: 0.65)
                                  : AppColors.creamBase.withValues(alpha: 0.32))
                            : s.selected
                            ? (light ? Colors.white : AppColors.creamBase)
                            : (light
                                  ? AppColors.emeraldDark.withValues(
                                      alpha: 0.82,
                                    )
                                  : AppColors.creamBase.withValues(
                                      alpha: 0.72,
                                    )),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpTriangleClipper extends CustomClipper<Path> {
  const _UpTriangleClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Arınma ekranı için dışarıda duran küçük "Özel ekle" butonu.
class _ArinmaSpecialCompactButton extends StatelessWidget {
  const _ArinmaSpecialCompactButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.quitPickerAddCustomTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.shellOnCanvasPrimary(context),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.quitPickerAddCustomSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.shellOnCanvasSecondary(context),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.creamBase,
            side: BorderSide(
              color: _kQuitAccent.withValues(alpha: selected ? 0.9 : 0.45),
              width: selected ? 1.45 : 1.05,
            ),
            backgroundColor: selected
                ? _kQuitAccent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
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
                color: _kQuitAccent.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.selectAction,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
