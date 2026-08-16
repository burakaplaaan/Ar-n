import 'package:flutter/widgets.dart';

import 'qibla_hub_navigator_key.dart';

/// `/assistant` gibi PageView’ın söküldüğü bir rotadan `/qibla`’ya geçince
/// iç Navigator birkaç kare gecikebilir. Widget kısayoluyla aynı retry.
Future<bool> pushQiblaHubRoute(String hubRoute) async {
  await WidgetsBinding.instance.endOfFrame;
  var attempts = 0;
  while (attempts < 25) {
    final nav = qiblaHubNavigatorKey.currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      nav.pushNamed(hubRoute);
      return true;
    }
    attempts++;
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  return false;
}
