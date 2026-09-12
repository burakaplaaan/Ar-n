import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/willpower_templates.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../providers/habit_providers.dart';

enum RitualPulseStrength { tick, day }

/// Namaz tiki veya alışkanlık günü için kısa parıltı + titreşim.
abstract final class RitualPulse {
  static Future<void> show(
    BuildContext context, {
    required RitualPulseStrength strength,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    switch (strength) {
      case RitualPulseStrength.tick:
        await HapticFeedback.lightImpact();
      case RitualPulseStrength.day:
        await HapticFeedback.mediumImpact();
    }
    if (!context.mounted) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RitualPulseLayer(
        strength: strength,
        onFinished: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

Future<void> toggleHabitTodayWithPulse({
  required BuildContext context,
  required WidgetRef ref,
  required String habitId,
  String? templateId,
}) async {
  if (WillpowerTemplates.isFullQuitProgram(templateId)) {
    await ref.read(habitSummaryProvider.notifier).toggleToday(habitId);
    return;
  }
  final before = ref
      .read(habitSummaryProvider)
      .where((item) => item.habit.id == habitId);
  final wasDone = before.isEmpty ? false : before.first.completedToday;
  await ref.read(habitSummaryProvider.notifier).toggleToday(habitId);
  if (!context.mounted) return;
  final after = ref
      .read(habitSummaryProvider)
      .where((item) => item.habit.id == habitId);
  final nowDone = after.isEmpty ? false : after.first.completedToday;
  if (!wasDone && nowDone) {
    await RitualPulse.show(context, strength: RitualPulseStrength.day);
  }
}

class _RitualPulseLayer extends StatefulWidget {
  const _RitualPulseLayer({
    required this.strength,
    required this.onFinished,
  });

  final RitualPulseStrength strength;
  final VoidCallback onFinished;

  @override
  State<_RitualPulseLayer> createState() => _RitualPulseLayerState();
}

class _RitualPulseLayerState extends State<_RitualPulseLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = widget.strength == RitualPulseStrength.day
        ? const Duration(milliseconds: 900)
        : const Duration(milliseconds: 420);
    _controller = AnimationController(vsync: this, duration: duration)
      ..forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final accent = light
        ? AppColors.accentGreenOnLight
        : AppColors.accentNeonGreen;
    final peak = widget.strength == RitualPulseStrength.day ? 0.22 : 0.12;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final fade = t < 0.35
              ? Curves.easeOut.transform(t / 0.35)
              : Curves.easeIn.transform((1 - t) / 0.65);
          return ColoredBox(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.78 + (0.18 * t),
                  colors: [
                    accent.withValues(alpha: peak * fade),
                    accent.withValues(alpha: peak * 0.35 * fade),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
