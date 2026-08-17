// lib/presentation/onboarding/app_tour/app_tour_keys.dart
// Spotlight turunun hedef widget bağlamları.
// GlobalKey kullanılmaz: aynı hedef iki host'ta olunca layout donması olmasın.

import 'package:flutter/widgets.dart';

enum AppTourTargetId {
  homeHeader,
  homeWisdom,
  homeNamaz,
  homePrayerTimes,
  navTools,
  qiblaAi,
  qiblaCompass,
  qiblaZikir,
  qiblaHilal,
  qiblaPrayerCircle,
  qiblaHealing,
  qiblaBreathing,
  navWillpower,
  willpowerTabs,
  willpowerBreathing,
  willpowerAdd,
  navExplore,
  inspireSearch,
  inspireFilter,
  navSettings,
  settingsNotifications,
  settingsWidgets,
  settingsLanguage,
  assistantFab,
}

abstract final class AppTourKeys {
  static final Map<AppTourTargetId, List<BuildContext>> _contexts = {};

  static void register(AppTourTargetId id, BuildContext context) {
    final stack = _contexts.putIfAbsent(id, () => <BuildContext>[]);
    if (!stack.contains(context)) {
      stack.add(context);
    }
  }

  static void unregister(AppTourTargetId id, BuildContext context) {
    final stack = _contexts[id];
    if (stack == null) return;
    stack.remove(context);
    if (stack.isEmpty) {
      _contexts.remove(id);
    }
  }

  static BuildContext? contextOf(AppTourTargetId id) {
    final stack = _contexts[id];
    if (stack == null || stack.isEmpty) return null;
    for (var i = stack.length - 1; i >= 0; i--) {
      final ctx = stack[i];
      if (ctx.mounted) return ctx;
    }
    return null;
  }

  static Rect? measure(AppTourTargetId id) {
    final ctx = contextOf(id);
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    if (!offset.dx.isFinite || !offset.dy.isFinite) return null;
    if (box.size.width <= 0 || box.size.height <= 0) return null;
    return offset & box.size;
  }

  static Rect? measureOnScreen(AppTourTargetId id, Size screen) {
    final rect = measure(id);
    if (rect == null) return null;
    if (!isSettledOnScreen(rect, screen)) return null;
    return rect;
  }

  static bool isSettledOnScreen(Rect rect, Size screen) {
    if (screen.width <= 0 || screen.height <= 0) return false;
    if (rect.width <= 0 || rect.height <= 0) return false;
    final viewport = Offset.zero & screen;
    final visible = rect.intersect(viewport);
    if (visible.isEmpty) return false;
    final area = rect.width * rect.height;
    final visibleArea = visible.width * visible.height;
    if (area <= 0 || visibleArea / area < 0.92) return false;
    return viewport.contains(rect.center);
  }
}
