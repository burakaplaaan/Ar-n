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
import '../../shared/widgets/arin_shell_layout.dart';
import '../assistant_entry.dart';
import 'assistant_home_bubble.dart';

const String _kFabNx = 'assistant_fab_nx_v1';
const String _kFabNy = 'assistant_fab_ny_v1';
const String _kFabPlaced = 'assistant_fab_placed_v1';

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

class _AssistantFabHostState extends ConsumerState<AssistantFabHost> {
  Offset? _offset;
  bool _dragging = false;
  Size? _lastScreen;
  Size _bubbleSize = _kBubbleFallback;
  final GlobalKey _bubbleKey = GlobalKey();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Size get _size => _bubbleSize;

  Offset _defaultOffset(Size screen, EdgeInsets safe) {
    final bottomReserve = ArinShellLayout.bottomContentPadding(
      context,
    ).clamp(safe.bottom + 8, screen.height * 0.45);
    return Offset(
      screen.width - safe.right - 16 - _size.width,
      screen.height - bottomReserve - _size.height,
    );
  }

  Offset _clampTo(Offset raw, Size screen, EdgeInsets safe) {
    final bottomReserve = ArinShellLayout.bottomContentPadding(
      context,
    ).clamp(safe.bottom + 8, screen.height * 0.45);
    final minX = safe.left + 8;
    final maxX = (screen.width - safe.right - _size.width - 8).clamp(
      minX,
      screen.width,
    );
    final minY = safe.top + 8;
    final maxY = (screen.height - bottomReserve - _size.height).clamp(
      minY,
      screen.height,
    );
    return Offset(raw.dx.clamp(minX, maxX), raw.dy.clamp(minY, maxY));
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

  Offset _restoreOrDefault(Size screen, EdgeInsets safe) {
    if (_prefs.getBool(_kFabPlaced) == true) {
      final nx = _prefs.getDouble(_kFabNx);
      final ny = _prefs.getDouble(_kFabNy);
      if (nx != null && ny != null) {
        return _clampTo(
          Offset(nx * screen.width, ny * screen.height),
          screen,
          safe,
        );
      }
    }
    return _clampTo(_defaultOffset(screen, safe), screen, safe);
  }

  void _persist(Offset offset, Size screen) {
    if (screen.width <= 0 || screen.height <= 0) return;
    _prefs
      ..setBool(_kFabPlaced, true)
      ..setDouble(_kFabNx, (offset.dx / screen.width).clamp(0.0, 1.0))
      ..setDouble(_kFabNy, (offset.dy / screen.height).clamp(0.0, 1.0));
  }

  void _ensureOffset(Size screen, EdgeInsets safe) {
    final rotated = _lastScreen != null &&
        (_lastScreen!.width != screen.width ||
            _lastScreen!.height != screen.height);
    _lastScreen = screen;
    if (_offset == null || rotated) {
      _offset = _restoreOrDefault(screen, safe);
    } else {
      _offset = _clampTo(_offset!, screen, safe);
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
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    _ensureOffset(screen, mq.padding);
    final offset = _offset ?? Offset.zero;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureBubble();
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_dragging &&
            (notification is ScrollUpdateNotification ||
                notification is OverscrollNotification)) {
          setState(() => _dragging = false);
        }
        return false;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (!hidden)
            Positioned(
              left: offset.dx,
              top: offset.dy,
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
                    setState(() => _dragging = true);
                  },
                  onPanUpdate: (details) {
                    final next = _clampTo(
                      (_offset ?? offset) + details.delta,
                      screen,
                      mq.padding,
                    );
                    setState(() => _offset = next);
                  },
                  onPanEnd: (_) {
                    _persist(_offset ?? offset, screen);
                    setState(() => _dragging = false);
                  },
                  onPanCancel: () {
                    setState(() => _dragging = false);
                  },
                  child: AppTourAnchor(
                    id: AppTourTargetId.assistantFab,
                    child: AssistantHomeBubble(key: _bubbleKey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
