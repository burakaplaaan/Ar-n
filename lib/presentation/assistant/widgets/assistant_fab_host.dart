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
    with SingleTickerProviderStateMixin {
  Offset? _offset;
  bool _dragging = false;
  Size? _lastScreen;
  Size _bubbleSize = _kBubbleFallback;
  final GlobalKey _bubbleKey = GlobalKey();
  late final AnimationController _move;
  Offset _animFrom = Offset.zero;
  Offset _animTo = Offset.zero;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Size get _size => _bubbleSize;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this)
      ..addListener(_onMoveTick)
      ..addStatusListener(_onMoveStatus);
  }

  @override
  void dispose() {
    _move
      ..removeListener(_onMoveTick)
      ..removeStatusListener(_onMoveStatus)
      ..dispose();
    super.dispose();
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
  }

  void _measureBubble() {
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if ((box.size.width - _bubbleSize.width).abs() < 0.5 &&
        (box.size.height - _bubbleSize.height).abs() < 0.5) {
      return;
    }
    setState(() => _bubbleSize = box.size);
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
            children: [
              widget.child,
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: Offstage(
                  offstage: hidden,
                  child: IgnorePointer(
                    ignoring: hidden,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      opacity: _dragging ? _kDragOpacity : _kIdleOpacity,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await openAssistantOrPaywall(
                            context: context,
                            ref: ref,
                          );
                        },
                        onPanStart: (_) {
                          _move.stop();
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
                          child: AssistantHomeBubble(key: _bubbleKey),
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
