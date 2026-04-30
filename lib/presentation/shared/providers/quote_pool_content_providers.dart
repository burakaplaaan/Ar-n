// Havuz senkronu + yüzey içerik provider'ları.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/quote_pool_ids.dart';
import '../../../core/providers/app_locale_provider.dart';
import '../../../data/content/daily_namaz_wisdom.dart';
import '../../../data/quote_pools/quote_pool_parsers.dart';
import '../../qibla/healing_frequencies/healing_daily_comfort_entries.dart';
import 'quotes_providers.dart';

/// Ana sayfa namaz sözü kartı.
final homeNamazWisdomProvider = FutureProvider<DailyNamazWisdom>((ref) async {
  final r = ref.watch(quotePoolsRepositoryProvider);
  final localeCode = ref.watch(appLocaleProvider).languageCode;
  await r.ensureSyncedToday(QuotePoolIds.homeNamazWisdom);
  return dailyNamazWisdomForDateWithPool(r, DateTime.now(), localeCode);
});

/// Zikir bilgisi günlük metni (havuz boşsa boş döner — UI AppStrings yedekler).
final zikirDailyReflectionProvider = FutureProvider<String>((ref) async {
  final r = ref.watch(quotePoolsRepositoryProvider);
  final localeCode = ref.watch(appLocaleProvider).languageCode;
  await r.ensureSyncedToday(QuotePoolIds.zikirDailyReflections);
  final t = zikirReflectionTextForDay(r, DateTime.now(), localeCode);
  return t;
});

/// İyileştirici frekanslar teselli kartı.
final healingComfortEntryProvider = FutureProvider<HealingComfortEntry>((
  ref,
) async {
  final r = ref.watch(quotePoolsRepositoryProvider);
  await r.ensureSyncedToday(QuotePoolIds.healingComfort);
  return HealingDailyComfort.forLocalTodayWithPool(r);
});
