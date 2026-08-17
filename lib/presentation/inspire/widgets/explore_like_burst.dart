import 'dart:math';

import 'package:flutter/material.dart';

const kExploreLikeRed = Color(0xFFFF2D55);

Offset exploreLikeFlightPoint({
  required Offset start,
  required Offset end,
  required double t,
}) {
  final travel = Curves.easeInCubic.transform(
    ((t - 0.26) / 0.74).clamp(0.0, 1.0),
  );
  final lift = (start.dy - end.dy).abs().clamp(36.0, 88.0);
  final control = Offset((start.dx + end.dx) / 2, min(start.dy, end.dy) - lift);
  final u = 1 - travel;
  return Offset(
    start.dx * u * u + control.dx * 2 * u * travel + end.dx * travel * travel,
    start.dy * u * u + control.dy * 2 * u * travel + end.dy * travel * travel,
  );
}

double exploreLikeFlightScale(double t) {
  if (t < 0.26) {
    final p = Curves.easeOutBack.transform(t / 0.26);
    return 0.28 + 0.86 * p;
  }
  final p = Curves.easeIn.transform(((t - 0.26) / 0.74).clamp(0.0, 1.0));
  return 1.14 - 0.82 * p;
}

double exploreLikeFlightOpacity(double t) {
  if (t <= 0) return 1;
  if (t >= 1) return 0;
  if (t < 0.68) return 1;
  return (1 - ((t - 0.68) / 0.32)).clamp(0.0, 1.0);
}

/// Çift tık kalpleri: dokunulan yerde pop, beğeni ikonuna uçuş, orada kaybolma.
class ExploreLikeBurstLayer extends StatefulWidget {
  const ExploreLikeBurstLayer({super.key});

  @override
  State<ExploreLikeBurstLayer> createState() => ExploreLikeBurstLayerState();
}

class ExploreLikeBurstLayerState extends State<ExploreLikeBurstLayer>
    with TickerProviderStateMixin {
  final List<_BurstHeart> _hearts = <_BurstHeart>[];

  void spawn({
    required Offset start,
    required Offset end,
    VoidCallback? onArrived,
  }) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    final heart = _BurstHeart(
      controller: controller,
      start: start,
      end: end,
      rotation: (Random().nextDouble() - 0.5) * 0.5,
    );
    var arrived = false;
    void tick() {
      if (heart.disposed) return;
      if (!arrived && controller.value >= 0.78) {
        arrived = true;
        onArrived?.call();
      }
    }

    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed || heart.disposed) return;
      heart.disposed = true;
      controller
        ..removeListener(tick)
        ..removeStatusListener(onStatus)
        ..dispose();
      if (!mounted) return;
      setState(() => _hearts.remove(heart));
    }

    controller
      ..addListener(tick)
      ..addStatusListener(onStatus);
    setState(() => _hearts.add(heart));
    controller.forward();
  }

  void clear() {
    for (final heart in _hearts) {
      heart.disposed = true;
      heart.controller.dispose();
    }
    _hearts.clear();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hearts.isEmpty) return const SizedBox.expand();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final heart in _hearts)
            AnimatedBuilder(
              animation: heart.controller,
              builder: (context, _) {
                final t = heart.controller.value;
                final pos = exploreLikeFlightPoint(
                  start: heart.start,
                  end: heart.end,
                  t: t,
                );
                final scale = exploreLikeFlightScale(t);
                final opacity = exploreLikeFlightOpacity(t);
                return Positioned(
                  left: pos.dx - 44,
                  top: pos.dy - 44,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: heart.rotation * (1 - t * 0.35),
                      child: Transform.scale(
                        scale: scale,
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 92,
                              color: Color(0x66FFFFFF),
                            ),
                            Icon(
                              Icons.favorite_rounded,
                              size: 88,
                              color: kExploreLikeRed,
                              shadows: [
                                Shadow(
                                  blurRadius: 16,
                                  offset: Offset(0, 2),
                                  color: Color(0x66000000),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BurstHeart {
  _BurstHeart({
    required this.controller,
    required this.start,
    required this.end,
    required this.rotation,
  });

  final AnimationController controller;
  final Offset start;
  final Offset end;
  final double rotation;
  bool disposed = false;
}
