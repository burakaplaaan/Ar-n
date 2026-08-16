// lib/presentation/onboarding/app_tour/app_tour_overlay.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'app_tour_controller.dart';
import 'app_tour_keys.dart';
import 'app_tour_layout.dart';
import 'app_tour_step.dart';

class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key});

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay> {
  Rect? _hole;
  int _preparedFor = -1;
  bool _advancing = false;

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(appTourControllerProvider);
    final step = tour.step;
    if (!tour.active || step == null) return const SizedBox.shrink();

    if (_preparedFor != tour.stepIndex) {
      _preparedFor = tour.stepIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_prepareTarget(step, tour.stepIndex));
      });
    }

    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final slots = AppTourLayout.slots(
      hole: _hole,
      screen: media.size,
      safeBottom: media.padding.bottom,
    );

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SpotlightPainter(hole: _hole),
              child: const SizedBox.expand(),
            ),
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.transparent),
            ),
            _TooltipCard(
              step: step,
              hole: _hole,
              side: slots.side,
              reservedBottom: slots.tooltipReservedBottom,
              title: step.title(l10n),
              body: step.body(l10n),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: slots.ctaBottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _advancing
                        ? null
                        : () => unawaited(_onSkip()),
                    child: Text(
                      l10n.appTourSkip,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _advancing ? null : () => unawaited(_onNext()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emeraldLight,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.emeraldLight
                            .withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        step.finale ? l10n.appTourLetsStart : l10n.appTourNext,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    HapticFeedback.selectionClick();
    try {
      await ref.read(appTourControllerProvider.notifier).next(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _onSkip() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await ref.read(appTourControllerProvider.notifier).finish(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _prepareTarget(AppTourStep step, int stepIndex) async {
    if (mounted && _preparedFor == stepIndex) {
      setState(() => _hole = null);
    }
    if (step.id == null) return;

    var attempt = 0;
    while (mounted && _preparedFor == stepIndex) {
      if (step.route.isNotEmpty) {
        if (!mounted || _preparedFor != stepIndex) return;
        try {
          final path = GoRouterState.of(context).uri.path;
          if (path != step.route) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            attempt++;
            continue;
          }
        } catch (_) {}
      }

      final key = AppTourKeys.of(step.id!);
      final ctx = key.currentContext;
      if (ctx != null && ctx.mounted && step.scroll) {
        try {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 240),
            alignment: 0.28,
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
      }
      if (!mounted || _preparedFor != stepIndex) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _preparedFor != stepIndex) return;

      final screen = MediaQuery.sizeOf(context);
      final hole = AppTourKeys.measureOnScreen(step.id!, screen);
      if (hole != null) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted || _preparedFor != stepIndex) return;
        final again = AppTourKeys.measureOnScreen(step.id!, screen);
        if (again != null &&
            (again.center - hole.center).distance < 2 &&
            (again.width - hole.width).abs() < 2 &&
            (again.height - hole.height).abs() < 2) {
          setState(() => _hole = again);
          return;
        }
      }
      attempt++;
      await Future<void>.delayed(
        Duration(milliseconds: attempt < 40 ? 80 : 400),
      );
    }
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.hole,
    required this.side,
    required this.reservedBottom,
    required this.title,
    required this.body,
  });

  final AppTourStep step;
  final Rect? hole;
  final AppTourTooltipSide side;
  final double reservedBottom;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final card = _TourCopy(
      title: title,
      body: body,
      emphasize: step.finale,
    );

    if (step.finale || hole == null) {
      return Positioned(
        left: 24,
        right: 24,
        top: media.padding.top + 72,
        bottom: reservedBottom + 8,
        child: Align(alignment: Alignment.center, child: card),
      );
    }

    final padded = hole!.inflate(AppTourLayout.holeInflate);
    if (side == AppTourTooltipSide.below) {
      return Positioned(
        left: 24,
        right: 24,
        top: padded.bottom + 16,
        bottom: reservedBottom + 8,
        child: Align(alignment: Alignment.topCenter, child: card),
      );
    }
    final aboveBottom = [
      reservedBottom + 8,
      media.size.height - padded.top + 16,
    ].reduce((a, b) => a > b ? a : b);
    return Positioned(
      left: 24,
      right: 24,
      top: media.padding.top + 12,
      bottom: aboveBottom,
      child: Align(alignment: Alignment.bottomCenter, child: card),
    );
  }
}

class _TourCopy extends StatelessWidget {
  const _TourCopy({
    required this.title,
    required this.body,
    required this.emphasize,
  });

  final String title;
  final String body;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: (emphasize
                    ? AppTextStyles.headlineLarge
                    : AppTextStyles.titleLarge)
                .copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole});

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      overlay
        ..addRRect(
          RRect.fromRectAndRadius(
            hole!.inflate(AppTourLayout.holeInflate),
            const Radius.circular(AppTourLayout.holeRadius),
          ),
        )
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.74),
    );
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          hole!.inflate(AppTourLayout.holeInflate),
          const Radius.circular(AppTourLayout.holeRadius),
        ),
        Paint()
          ..color = AppColors.accentNeonGreen.withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole;
  }
}
