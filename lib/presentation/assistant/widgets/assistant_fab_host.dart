import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/router/app_router.dart';
import '../../qibla/qibla_hub_navigator_key.dart';
import '../../qibla/qibla_hub_page.dart';
import '../../qibla/qibla_shell_swipe_provider.dart';
import '../../onboarding/app_tour/app_tour_anchor.dart';
import '../../onboarding/app_tour/app_tour_controller.dart';
import '../../onboarding/app_tour/app_tour_keys.dart';
import '../assistant_entry.dart';
import 'assistant_fab_physics.dart';
import 'assistant_home_bubble.dart';

const String _kFabNx = 'assistant_fab_nx_v2';
const String _kFabNy = 'assistant_fab_ny_v2';
const String _kFabPlaced = 'assistant_fab_placed_v2';

const double _kIdleOpacity = 0.46;
const double _kDragOpacity = 1.0;
const Size _kBubbleFallback = Size(120, 42);

bool _qiblaHubTopIsDuel() {
  final nav = qiblaHubNavigatorKey.currentState;
  if (nav == null) return false;
  String? name;
  nav.popUntil((route) {
    name = route.settings.name;
    return true;
  });
  return name == QiblaHubRoutes.hilalDuel;
}

bool assistantFabHiddenFor({
  required String path,
  required bool duelActive,
}) {
  if (duelActive) return true;
  if (path == AppRoutes.hilalDuel ||
      path.startsWith('${AppRoutes.hilalDuel}/')) {
    return true;
  }
  if (path == AppRoutes.assistant) return true;
  if (path == AppRoutes.inspire ||
      path.startsWith('${AppRoutes.inspire}/')) {
    return true;
  }
  if (path == AppRoutes.onboarding ||
      path.startsWith('${AppRoutes.onboarding}/') ||
      path == AppRoutes.appPrepare) {
    return true;
  }
  return false;
}

/// Kabuk ve kabuk-dışı sayfalarda tek asistan katmanı.
class AssistantFabHost extends ConsumerStatefulWidget {
  const AssistantFabHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AssistantFabHost> createState() => _AssistantFabHostState();
}

class _AssistantFabHostState extends ConsumerState<AssistantFabHost>
    with TickerProviderStateMixin {
  Offset? _offset;
  bool _dragging = false;
  bool _hidden = false;
  Size? _lastScreen;
  Size _bubbleSize = _kBubbleFallback;
  final GlobalKey _bubbleKey = GlobalKey();
  late final AnimationController _move;
  late final AnimationController _dock;
  Offset _animFrom = Offset.zero;
  Offset _animTo = Offset.zero;
  Timer? _idleDock;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Size get _size => _bubbleSize;

  bool get _isPeeked => _dock.value > 0.5;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this)
      ..addListener(_onMoveTick)
      ..addStatusListener(_onMoveStatus);
    _dock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDock();
    });
  }

  @override
  void dispose() {
    _idleDock?.cancel();
    _dock.dispose();
    _move
      ..removeListener(_onMoveTick)
      ..removeStatusListener(_onMoveStatus)
      ..dispose();
    super.dispose();
  }

  void _scheduleDock() {
    _idleDock?.cancel();
    if (!mounted || _hidden || _dragging) return;
    _idleDock = Timer(kAssistantFabIdleDockDelay, _beginDock);
  }

  void _beginDock() {
    if (!mounted || _hidden || _dragging) return;
    if (ref.read(appTourControllerProvider).active) return;
    if (_dock.value >= 1) return;
    if (_move.isAnimating) {
      _idleDock = Timer(const Duration(milliseconds: 220), _beginDock);
      return;
    }
    _dock.forward();
  }

  void _expandDock({bool restartIdle = true}) {
    _idleDock?.cancel();
    if (_dock.value > 0 || _dock.status == AnimationStatus.forward) {
      _dock.reverse();
    }
    if (restartIdle) _scheduleDock();
  }

  void _onMoveTick() {
    final t = Curves.easeOutCubic.transform(_move.value);
    setState(() => _offset = Offset.lerp(_animFrom, _animTo, t));
  }

  void _onMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final screen = _lastScreen;
    if (screen == null || _offset == null) return;
    _persist(_offset!, screen);
  }

  AssistantFabBounds _bounds(Size stack) {
    final raw = MediaQueryData.fromView(View.of(context));
    return assistantFabBoundsFor(
      stack: stack,
      bubble: _size,
      viewLeft: raw.viewPadding.left,
      viewTop: raw.viewPadding.top,
      viewRight: raw.viewPadding.right,
      viewBottom: raw.viewPadding.bottom,
      fullScreenHeight: raw.size.height,
    );
  }

  Offset _defaultOffset(Size screen) {
    final b = _bounds(screen);
    return Offset(b.maxX, b.maxY);
  }

  Offset _clampTo(Offset raw, Size screen) {
    return _bounds(screen).clamp(raw);
  }

  Offset _snapTo(Offset raw, Size screen, [Offset velocity = Offset.zero]) {
    return snapAssistantFabToNearestEdge(
      raw,
      _bounds(screen),
      velocity: velocity,
    );
  }

  void _animateTo(Offset target, Size screen, {Offset velocity = Offset.zero}) {
    final from = _offset ?? target;
    if ((from - target).distance < 0.8) {
      _offset = target;
      _persist(target, screen);
      return;
    }
    _animFrom = from;
    _animTo = target;
    final dist = (from - target).distance;
    final flung = velocity.distance >= kAssistantFabFlingThreshold;
    final ms = (flung ? 140 + dist * 0.22 : 200 + dist * 0.38)
        .clamp(flung ? 140.0 : 200.0, flung ? 320.0 : 440.0)
        .round();
    _move
      ..stop()
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _finishDrag(Offset velocity, Size screen) {
    final current = _offset ?? _defaultOffset(screen);
    final settled = settleAssistantFab(
      position: current,
      velocity: velocity,
      bounds: _bounds(screen),
    );
    setState(() => _dragging = false);
    HapticFeedback.selectionClick();
    _animateTo(settled, screen, velocity: velocity);
    _scheduleDock();
  }

  void _measureBubble() {
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if ((box.size.width - _bubbleSize.width).abs() < 0.5 &&
        (box.size.height - _bubbleSize.height).abs() < 0.5) {
      return;
    }
    final oldSize = _bubbleSize;
    final nextSize = box.size;
    final screen = _lastScreen;
    var nextOffset = _offset;
    if (nextOffset != null && screen != null && !_move.isAnimating) {
      nextOffset = _reanchorOnResize(
        position: nextOffset,
        oldSize: oldSize,
        nextSize: nextSize,
        screen: screen,
      );
    }
    setState(() {
      _bubbleSize = nextSize;
      if (nextOffset != null && screen != null) {
        _offset = _clampTo(nextOffset, screen);
      }
    });
  }

  Offset _reanchorOnResize({
    required Offset position,
    required Size oldSize,
    required Size nextSize,
    required Size screen,
  }) {
    final raw = MediaQueryData.fromView(View.of(context));
    final oldBounds = assistantFabBoundsFor(
      stack: screen,
      bubble: oldSize,
      viewLeft: raw.viewPadding.left,
      viewTop: raw.viewPadding.top,
      viewRight: raw.viewPadding.right,
      viewBottom: raw.viewPadding.bottom,
      fullScreenHeight: raw.size.height,
    );
    final onRight = (position.dx - oldBounds.maxX).abs() < 1.5;
    final onBottom = (position.dy - oldBounds.maxY).abs() < 1.5;
    var dx = position.dx;
    var dy = position.dy;
    if (onRight) {
      dx += oldSize.width - nextSize.width;
    }
    if (onBottom) {
      dy += oldSize.height - nextSize.height;
    }
    return Offset(dx, dy);
  }

  Offset _restoreOrDefault(Size screen) {
    if (_prefs.getBool(_kFabPlaced) == true) {
      final nx = _prefs.getDouble(_kFabNx);
      final ny = _prefs.getDouble(_kFabNy);
      if (nx != null && ny != null) {
        return _snapTo(
          Offset(nx * screen.width, ny * screen.height),
          screen,
        );
      }
    }
    return _snapTo(_defaultOffset(screen), screen);
  }

  void _persist(Offset offset, Size screen) {
    if (screen.width <= 0 || screen.height <= 0) return;
    _prefs
      ..setBool(_kFabPlaced, true)
      ..setDouble(_kFabNx, (offset.dx / screen.width).clamp(0.0, 1.0))
      ..setDouble(_kFabNy, (offset.dy / screen.height).clamp(0.0, 1.0));
  }

  void _ensureOffset(Size screen) {
    if (_move.isAnimating) {
      _lastScreen = screen;
      return;
    }
    final rotated = _lastScreen != null &&
        (_lastScreen!.width != screen.width ||
            _lastScreen!.height != screen.height);
    _lastScreen = screen;
    if (_offset == null || rotated) {
      _offset = _restoreOrDefault(screen);
    } else {
      _offset = _clampTo(_offset!, screen);
    }
  }

  @override
  Widget build(BuildContext context) {
    String path = '';
    try {
      path = GoRouterState.of(context).uri.path;
    } catch (_) {
      path = '';
    }
    final duelActive = ref.watch(hilalDuelActiveProvider);
    final nestedDuel = _qiblaHubTopIsDuel();
    if (duelActive &&
        !nestedDuel &&
        path != AppRoutes.hilalDuel &&
        !path.startsWith('${AppRoutes.hilalDuel}/')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!ref.read(hilalDuelActiveProvider)) return;
        if (_qiblaHubTopIsDuel()) return;
        ref.read(hilalDuelActiveProvider.notifier).state = false;
      });
    }
    final hidden = assistantFabHiddenFor(
      path: path,
      duelActive: duelActive || nestedDuel,
    );
    final tourActive = ref.watch(appTourControllerProvider).active;
    if (_hidden != hidden) {
      _hidden = hidden;
      if (hidden) {
        _idleDock?.cancel();
        if (_dock.value > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _dock.value = 0;
          });
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scheduleDock();
        });
      }
    }
    if (tourActive && _dock.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expandDock(restartIdle: false);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureOffset(screen);
        final offset = _offset ?? Offset.zero;
        if (!hidden) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measureBubble();
          });
        }
        final edge = assistantFabEdgeFor(offset, _bounds(screen));
        final peek = assistantFabPeekTranslation(
          edge: edge,
          bubble: _size,
        );
        final dockT = Curves.easeInOutCubic.transform(_dock.value);
        final compact = _dock.value > 0.12 && !_dragging;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_dragging &&
                (notification is ScrollUpdateNotification ||
                    notification is OverscrollNotification)) {
              _finishDrag(Offset.zero, screen);
            }
            return false;
          },
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              widget.child,
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: Offstage(
                  offstage: hidden,
                  child: IgnorePointer(
                    ignoring: hidden,
                    child: Transform.translate(
                      offset: peek * dockT,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: _dragging
                            ? _kDragOpacity
                            : (_dock.value > 0.4 ? 0.82 : _kIdleOpacity),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            if (_isPeeked || _dock.status == AnimationStatus.forward) {
                              HapticFeedback.selectionClick();
                              _expandDock();
                              return;
                            }
                            HapticFeedback.lightImpact();
                            _scheduleDock();
                            await openAssistantOrPaywall(
                              context: context,
                              ref: ref,
                            );
                          },
                          onPanStart: (_) {
                            _move.stop();
                            _expandDock(restartIdle: false);
                            setState(() => _dragging = true);
                          },
                          onPanUpdate: (details) {
                            final next = _clampTo(
                              (_offset ?? offset) + details.delta,
                              screen,
                            );
                            setState(() => _offset = next);
                          },
                          onPanEnd: (details) {
                            _finishDrag(
                              details.velocity.pixelsPerSecond,
                              screen,
                            );
                          },
                          onPanCancel: () {
                            _finishDrag(Offset.zero, screen);
                          },
                          child: AppTourAnchor(
                            id: AppTourTargetId.assistantFab,
                            child: AssistantHomeBubble(
                              key: _bubbleKey,
                              compact: compact,
                            ),
                          ),
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
