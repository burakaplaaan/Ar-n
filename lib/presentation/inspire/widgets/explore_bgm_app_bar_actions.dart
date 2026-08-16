import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../explore_bgm_controller.dart';

/// Keşfet SliverAppBar — müzik aç/kapa ve sıradaki parça.
class ExploreBgmAppBarActions extends ConsumerWidget {
  const ExploreBgmAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(exploreBgmNotifierProvider);
    final notifier = ref.read(exploreBgmNotifierProvider.notifier);
    final on = s.userEnabled && s.isPlaying;
    final muted = !s.userEnabled;

    final iconColor = muted
        ? Colors.white.withValues(alpha: 0.48)
        : AppColors.accentNeonGreen.withValues(alpha: 0.92);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: muted ? 'Müziği aç' : 'Müziği kapat',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: const EdgeInsets.all(6),
          onPressed: () => notifier.toggle(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: muted
                ? Icon(
                    Icons.volume_off_rounded,
                    key: const ValueKey('off'),
                    color: iconColor,
                    size: 22,
                  )
                : _PulseScale(
                    key: const ValueKey('on'),
                    active: on,
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
          ),
        ),
        if (on)
          IconButton(
            tooltip: 'Sıradaki parça',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            onPressed: () => notifier.skip(),
            icon: Icon(
              Icons.skip_next_rounded,
              color: AppColors.accentNeonGreen.withValues(alpha: 0.72),
              size: 22,
            ),
          ),
      ],
    );
  }
}

class _PulseScale extends StatefulWidget {
  const _PulseScale({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<_PulseScale> {
  bool _forward = true;

  @override
  void didUpdateWidget(covariant _PulseScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _forward = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Transform.scale(scale: 1.0, child: widget.child);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _forward ? 1.06 : 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      onEnd: () {
        if (!mounted || !widget.active) return;
        setState(() => _forward = !_forward);
      },
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: widget.child,
    );
  }
}
