import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/router/app_router.dart';
import 'qibla_hub_navigator_key.dart';
import 'qibla_hub_page.dart';

/// Görünür Kıble araç yığınındaki en üst rotayı tek adım geri alır.
///
/// Shell sistem geri tuşunu kendisi yakaladığı için nested Navigator'a
/// otomatik dispatch yapılamaz. Sistem geri ve kenar kaydırma aynı helper'ı
/// kullanarak modal → araç → dashboard sırasını korur.
///
/// Not: [PopScope](canPop: false) iken [NavigatorState.canPop] false döner;
/// yine de yığında araç varsa [Navigator.maybePop] ile sayfa handler'ı
/// (Bilgi Düellosu iptal/forfeit) tetiklenmeli.
bool dispatchQiblaHubBack({
  required String currentPath,
  bool isQiblaVisible = false,
  Object? result,
}) {
  final onQiblaStack = currentPath == AppRoutes.qibla ||
      currentPath.startsWith('${AppRoutes.qibla}/') ||
      currentPath == AppRoutes.hilalDuel ||
      currentPath == AppRoutes.prayerCircle ||
      isQiblaVisible;
  if (!onQiblaStack) return false;

  final navigator = qiblaHubNavigatorKey.currentState;
  if (navigator == null) return false;

  Route<dynamic>? top;
  navigator.popUntil((route) {
    top = route;
    return true;
  });
  if (top == null || top!.isFirst) return false;
  if (top!.settings.name == QiblaHubRoutes.dashboard) return false;

  // Zorla pop etme — PopScope onPopInvoked (iptal/terk) çalışsın.
  unawaited(navigator.maybePop(result));
  return true;
}
