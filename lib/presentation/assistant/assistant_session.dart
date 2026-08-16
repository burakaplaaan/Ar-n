import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../qibla/qibla_hub_navigator_key.dart';
import '../qibla/qibla_hub_page.dart';
import 'assistant_models.dart';

/// Asistan sayfası kapanınca sohbet kaybolmasın diye oturum burada durur.
class AssistantSession {
  final List<AssistantChatTurn> turns = [];
  bool sending = false;
  int? remainingToday;
  String? banner;
  int seq = 0;
  int? streamingId;
  final Set<int> revealed = <int>{};
}

final assistantSessionProvider = Provider<AssistantSession>((ref) {
  return AssistantSession();
});

/// Asistandan açılan araç adı (`zikir`, `widgets`…). Sekme değişince temizlenir.
final assistantReturnToolProvider = StateProvider<String?>((ref) => null);

void markAssistantReturnPending(WidgetRef ref, String tool) {
  ref.read(assistantReturnToolProvider.notifier).state = tool;
}

void clearAssistantReturnPending(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(assistantReturnToolProvider) != null) {
    container.read(assistantReturnToolProvider.notifier).state = null;
  }
}

String? _qiblaHubTopName() {
  final nav = qiblaHubNavigatorKey.currentState;
  if (nav == null) return null;
  String? name;
  nav.popUntil((route) {
    name = route.settings.name;
    return true;
  });
  return name;
}

bool assistantReturnStillOnTool({
  required String tool,
  required String path,
  String? qiblaTop,
}) {
  switch (tool) {
    case 'zikir':
      return qiblaTop == QiblaHubRoutes.zikir;
    case 'healing':
      return qiblaTop == QiblaHubRoutes.healing;
    case 'qibla':
      return path == AppRoutes.qibla &&
          (qiblaTop == null || qiblaTop == QiblaHubRoutes.dashboard);
    case 'widgets':
      return path == AppRoutes.settingsWidgets;
    case 'notifications':
      return path == AppRoutes.settingsNotifications;
    case 'breathing':
      return path.contains('/habits/will/breathing');
    case 'prayer_circle':
      return path == AppRoutes.prayerCircle ||
          qiblaTop == QiblaHubRoutes.prayerCircle;
    case 'hilal_duel':
      return path == AppRoutes.hilalDuel ||
          qiblaTop == QiblaHubRoutes.hilalDuel;
    case 'kaza':
      return path.startsWith(AppRoutes.kazaTracker) ||
          path.startsWith('/habits/kaza');
    case 'namaz':
      return path.contains('/habits/will/namaz');
    case 'premium':
      return path == AppRoutes.premium;
    default:
      return false;
  }
}

/// Açık araç hâlâ asistanın gönderdiği yerse sohbete döner.
bool popToAssistantIfNeeded(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final tool = container.read(assistantReturnToolProvider);
  if (tool == null || tool.isEmpty) return false;

  var path = '';
  try {
    path = GoRouterState.of(context).uri.path;
  } catch (_) {}
  final top = _qiblaHubTopName();
  if (!assistantReturnStillOnTool(tool: tool, path: path, qiblaTop: top)) {
    container.read(assistantReturnToolProvider.notifier).state = null;
    return false;
  }

  container.read(assistantReturnToolProvider.notifier).state = null;
  final hub = qiblaHubNavigatorKey.currentState;
  if (hub != null) {
    hub.popUntil((route) => route.isFirst);
  }
  final router = GoRouter.maybeOf(context);
  if (router == null) return false;
  router.go(AppRoutes.assistant);
  return true;
}
