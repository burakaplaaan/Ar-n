import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ad_gate_service.dart';
import '../../data/services/session_ad_prompt.dart';
import '../shared/widgets/arin_loader.dart';

/// Geçiş animasyonu bitmeden ağır aracı mount etmez.
/// Reklam varsa örtünün altında biter; panel kayarken donmaz.
class QiblaToolOpeningGate extends ConsumerStatefulWidget {
  const QiblaToolOpeningGate({
    super.key,
    required this.child,
    this.adPlacement,
  });

  final Widget child;
  final AdGatePlacement? adPlacement;

  @override
  ConsumerState<QiblaToolOpeningGate> createState() =>
      _QiblaToolOpeningGateState();
}

class _QiblaToolOpeningGateState extends ConsumerState<QiblaToolOpeningGate> {
  bool _ready = false;
  bool _started = false;
  bool _awaitingAd = false;
  bool _aborted = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeListener;
  Completer<void>? _routeDone;

  @override
  void dispose() {
    _aborted = true;
    _detachRouteListener();
    final pending = _routeDone;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
    super.dispose();
  }

  void _detachRouteListener() {
    final animation = _routeAnimation;
    final listener = _routeListener;
    if (animation != null && listener != null) {
      animation.removeStatusListener(listener);
    }
    _routeAnimation = null;
    _routeListener = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      await _waitUntilRouteSettled();
      if (!mounted || _aborted) return;
      final placement = widget.adPlacement;
      if (placement != null) {
        setState(() => _awaitingAd = true);
        await SessionAdPrompt.maybeShow(ref: ref, placement: placement);
      }
    } finally {
      if (mounted && !_aborted) {
        setState(() {
          _awaitingAd = false;
          _ready = true;
        });
      }
    }
  }

  Future<void> _waitUntilRouteSettled() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _aborted) return;
    var animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      return;
    }
    if (animation.status == AnimationStatus.dismissed &&
        !animation.isAnimating) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _aborted) return;
      animation = ModalRoute.of(context)?.animation;
      if (animation == null ||
          animation.status == AnimationStatus.completed ||
          (animation.status == AnimationStatus.dismissed &&
              !animation.isAnimating)) {
        return;
      }
    }
    if (animation.status == AnimationStatus.completed) return;
    if (animation.status == AnimationStatus.reverse ||
        animation.status == AnimationStatus.dismissed) {
      _aborted = true;
      return;
    }
    final done = Completer<void>();
    _routeDone = done;
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.reverse ||
          status == AnimationStatus.dismissed) {
        _aborted = true;
        _detachRouteListener();
        if (!done.isCompleted) done.complete();
        return;
      }
      if (status != AnimationStatus.completed) return;
      _detachRouteListener();
      if (!done.isCompleted) done.complete();
    }

    _routeAnimation = animation;
    _routeListener = listener;
    animation.addStatusListener(listener);
    if (animation.status == AnimationStatus.completed) {
      _detachRouteListener();
      return;
    }
    if (animation.status == AnimationStatus.reverse ||
        animation.status == AnimationStatus.dismissed) {
      _aborted = true;
      _detachRouteListener();
      return;
    }
    await done.future;
    if (mounted && !_aborted) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    if (_awaitingAd) {
      return const _OpeningLoader();
    }
    return const _OpeningShade();
  }
}

class _OpeningShade extends StatelessWidget {
  const _OpeningShade();

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ColoredBox(
      color: light ? const Color(0xFFF3F6F2) : const Color(0xFF0A1210),
    );
  }
}

class _OpeningLoader extends StatelessWidget {
  const _OpeningLoader();

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ColoredBox(
      color: light ? const Color(0xFFF3F6F2) : const Color(0xFF0A1210),
      child: const SafeArea(child: Center(child: ArinLoader())),
    );
  }
}
