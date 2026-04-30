// Havuz öğelerini yüzey modellerine dönüştürür.

import '../../core/constants/quote_pool_ids.dart';
import '../content/arin_ntf_messages.dart';
import '../content/daily_namaz_wisdom.dart';
import '../repositories/quote_pools_repository.dart';
import 'localized_pool_fields.dart';

String _kindFallbackForLocale(String localeCode) {
  switch (normalizeLocaleCode(localeCode)) {
    case 'en':
      return 'Quote';
    case 'ar':
      return 'مقولة';
    default:
      return 'Söz';
  }
}

DailyNamazWisdom? dailyNamazFromItemMap(
  Map<String, dynamic> m, {
  required String localeCode,
}) {
  final localizedText = localizedPoolField(
    m,
    baseKey: 'text',
    localeCode: localeCode,
    legacyKeys: const <String>['turkish', 'body'],
  );
  if (localizedText == null || localizedText.isEmpty) return null;
  final localizedKind =
      localizedPoolField(
        m,
        baseKey: 'kind',
        localeCode: localeCode,
        legacyKeys: const <String>['kind'],
      ) ??
      _kindFallbackForLocale(localeCode);
  final localizedSource = localizedPoolField(
    m,
    baseKey: 'source',
    localeCode: localeCode,
    legacyKeys: const <String>['source', 'title', 'reference', 'ref', 'surah'],
  );
  final arabicText =
      localizedPoolField(
        m,
        baseKey: 'arabic',
        localeCode: localeCode,
        legacyKeys: const <String>['arabic'],
      ) ??
      '';
  return DailyNamazWisdom(
    arabic: arabicText,
    turkish: localizedText,
    kind: localizedKind,
    source: localizedSource,
  );
}

/// Günlük indeks için havuz (varsa) veya yerel liste.
DailyNamazWisdom dailyNamazWisdomForDateWithPool(
  QuotePoolsRepository r,
  DateTime nowLocal,
  String localeCode,
) {
  final items = r.itemsFromCache(QuotePoolIds.homeNamazWisdom);
  if (items.isEmpty) {
    return dailyNamazWisdomFor(nowLocal);
  }
  final parsed = <DailyNamazWisdom>[];
  for (final m in items) {
    final w = dailyNamazFromItemMap(m, localeCode: localeCode);
    if (w != null) parsed.add(w);
  }
  if (parsed.isEmpty) {
    return dailyNamazWisdomFor(nowLocal);
  }
  final idx = dailyNamazWisdomIndex(nowLocal) % parsed.length;
  return parsed[idx];
}

DailyNamazWisdom dailyNamazWisdomForNotificationWithPool(
  QuotePoolsRepository r,
  DateTime nowLocal,
  String localeCode,
) {
  final items = r.itemsFromCache(QuotePoolIds.homeNamazWisdom);
  if (items.isEmpty) {
    return dailyNamazWisdomForNotification(nowLocal);
  }
  final parsed = <DailyNamazWisdom>[];
  for (final m in items) {
    final w = dailyNamazFromItemMap(m, localeCode: localeCode);
    if (w != null) parsed.add(w);
  }
  if (parsed.isEmpty) {
    return dailyNamazWisdomForNotification(nowLocal);
  }
  final n = parsed.length;
  final d = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  return parsed[(days + (n ~/ 2)) % n];
}

String zikirReflectionTextForDay(
  QuotePoolsRepository r,
  DateTime nowLocal,
  String localeCode,
) {
  final items = r.itemsFromCache(QuotePoolIds.zikirDailyReflections);
  if (items.isEmpty) return '';
  final d = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final origin = DateTime(2020, 1, 1);
  final idx = d.difference(origin).inDays.abs() % items.length;
  final m = items[idx];
  return localizedPoolField(
        m,
        baseKey: 'text',
        localeCode: localeCode,
        legacyKeys: const <String>['text', 'body'],
      ) ??
      '';
}

String arinmaNotificationBodyWithPool(
  QuotePoolsRepository r,
  DateTime dayLocal,
  String localeCode,
) {
  final items = r.itemsFromCache(QuotePoolIds.notificationArinmaBodies);
  if (items.isEmpty) {
    return arinmaNotificationBodyForDay(dayLocal);
  }
  final d = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  final i = days % items.length;
  final m = items[i < 0 ? i + items.length : i];
  final s =
      localizedPoolField(
        m,
        baseKey: 'text',
        localeCode: localeCode,
        legacyKeys: const <String>['text', 'body'],
      ) ??
      '';
  if (s.trim().isEmpty) {
    return arinmaNotificationBodyForDay(dayLocal);
  }
  return s;
}
