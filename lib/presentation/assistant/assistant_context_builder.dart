import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/willpower_templates.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/user_profile_providers.dart';
import '../willpower/salat_providers.dart';
import 'assistant_models.dart';

const _prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

AssistantContextSnapshot buildAssistantContext({
  required WidgetRef ref,
  required String locale,
}) {
  final name = ref.read(userProfileProvider).name?.trim();
  final habitRepo = ref.read(habitRepositoryProvider);
  final habits = habitRepo
      .getAll()
      .take(4)
      .map((h) => h.title.trim())
      .where((t) => t.isNotEmpty)
      .join(', ');

  String? nextPrayer;
  String? prayers;
  final times = ref.read(prayerTimesProvider).asData?.value;
  if (times != null) {
    final now = DateTime.now();
    final next = times.nextPrayer(now);
    if (next != null) {
      final mins = next.remaining.inMinutes;
      nextPrayer = next.isUrgentFajr
          ? 'fajr_window;sunrise_in_${mins}m'
          : '${next.name};in_${mins}m';
    }
    final salatHabit = habitRepo.findActiveByTemplateId(
      WillpowerTemplates.salatDaily,
    );
    if (salatHabit != null) {
      final day = times.salatTickCalendarDay(now);
      final ticks = ref
          .read(salatLogRepositoryProvider)
          .getPrayers(salatHabit.id, day);
      prayers = [
        for (var i = 0; i < _prayerKeys.length; i++)
          '${_prayerKeys[i]}:${ticks[i] ? "ok" : "-"}',
      ].join(' ');
    }
  }

  return AssistantContextSnapshot(
    name: name,
    locale: locale,
    nextPrayer: nextPrayer,
    prayers: prayers,
    habits: habits.isEmpty ? null : habits,
  );
}
