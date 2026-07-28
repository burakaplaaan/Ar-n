import '../../core/router/app_router.dart';
import 'qibla_hub_navigator_key.dart';

/// Görünür Kıble araç yığınındaki en üst rotayı tek adım geri alır.
///
/// Shell sistem geri tuşunu kendisi yakaladığı için nested Navigator'a
/// otomatik dispatch yapılamaz. Sistem geri ve kenar kaydırma aynı helper'ı
/// kullanarak modal → araç → dashboard sırasını korur.
bool dispatchQiblaHubBack({
  required String currentPath,
  bool isQiblaVisible = false,
  Object? result,
}) {
  final onQiblaStack = currentPath == AppRoutes.qibla || isQiblaVisible;
  if (!onQiblaStack) return false;

  final navigator = qiblaHubNavigatorKey.currentState;
  if (navigator == null || !navigator.canPop()) return false;
  navigator.pop(result);
  return true;
}
