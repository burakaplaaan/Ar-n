// lib/core/router/app_router_refresh.dart
// GoRouter redirect'inin prefs / oturum değişince yeniden çalışması için.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [notifyAuthOrOnboarding] ile GoRouter yeniden yönlendirme yapar.
class AppRouterRefresh extends ChangeNotifier {
  void notifyAuthOrOnboarding() => notifyListeners();
}

final appRouterRefreshProvider =
    ChangeNotifierProvider<AppRouterRefresh>((ref) {
  return AppRouterRefresh();
});
