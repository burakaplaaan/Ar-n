import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

const Locale kLocaleTr = Locale('tr');
const Locale kLocaleEn = Locale('en');
const Locale kLocaleAr = Locale('ar');

const List<Locale> kSupportedAppLocales = <Locale>[
  kLocaleTr,
  kLocaleEn,
  kLocaleAr,
];

const String _kLocalePrefKey = 'arin_app_locale';
const String _kLocaleTagTr = 'tr';
const String _kLocaleTagEn = 'en';
const String _kLocaleTagAr = 'ar';

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier(this._ref) : super(_loadInitialLocale(_ref));

  final Ref _ref;

  static Locale _loadInitialLocale(Ref ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kLocalePrefKey);
    return _localeFromTag(raw);
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = _normalizeLocale(locale);
    final previous = state;
    state = normalized;
    final prefs = _ref.read(sharedPreferencesProvider);
    final ok = await prefs.setString(_kLocalePrefKey, _localeToTag(normalized));
    if (!ok) {
      // Runtime dil değişimi başarısız kalıcı yazılsa bile anlık UI tutarlı kalsın.
      state = previous;
    }
  }

  static Locale _normalizeLocale(Locale locale) {
    for (final supported in kSupportedAppLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return kLocaleTr;
  }

  static Locale _localeFromTag(String? tag) {
    final normalized = (tag ?? '').trim().toLowerCase();
    if (normalized.startsWith(_kLocaleTagEn)) return kLocaleEn;
    if (normalized.startsWith(_kLocaleTagAr)) return kLocaleAr;
    return kLocaleTr;
  }

  static String _localeToTag(Locale locale) {
    if (locale.languageCode == kLocaleEn.languageCode) return _kLocaleTagEn;
    if (locale.languageCode == kLocaleAr.languageCode) return _kLocaleTagAr;
    return _kLocaleTagTr;
  }
}

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>(
  (ref) => AppLocaleNotifier(ref),
);
