import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/willpower_templates.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../shared/providers/habit_providers.dart';

const _salatTrackingVisibleOnHomeKey =
    WillpowerTemplates.salatVisibleOnHomePrefKey;

final salatTrackingVisibleOnHomeProvider =
    NotifierProvider<SalatTrackingVisibilityNotifier, bool>(
      SalatTrackingVisibilityNotifier.new,
    );

class SalatTrackingVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.containsKey(_salatTrackingVisibleOnHomeKey)) {
      return prefs.getBool(_salatTrackingVisibleOnHomeKey) ?? true;
    }
    final habitRepo = ref.read(habitRepositoryProvider);
    final habit = habitRepo.findActiveByTemplateId(
      WillpowerTemplates.salatDaily,
    );
    final ready =
        habit != null &&
        habit.onboardingCompleted &&
        habit.commitmentText.trim().isNotEmpty;
    Future.microtask(() async {
      await prefs.setBool(_salatTrackingVisibleOnHomeKey, ready);
    });
    return ready;
  }

  Future<void> enableFromGelisim() async {
    if (state) return;
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_salatTrackingVisibleOnHomeKey, true);
  }

  Future<void> disable() async {
    if (!state) return;
    state = false;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_salatTrackingVisibleOnHomeKey, false);
  }
}
