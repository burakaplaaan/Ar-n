import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shared_preferences_provider.dart';

const _salatTrackingVisibleOnHomeKey = 'salat_tracking_visible_on_home';

final salatTrackingVisibleOnHomeProvider =
    NotifierProvider<SalatTrackingVisibilityNotifier, bool>(
  SalatTrackingVisibilityNotifier.new,
);

class SalatTrackingVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_salatTrackingVisibleOnHomeKey) ?? false;
  }

  Future<void> enableFromGelisim() async {
    if (state) return;
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_salatTrackingVisibleOnHomeKey, true);
  }
}
