import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

const String kThemeModePrefKey = 'arin_app_theme_mode';
const String _kThemeTagLight = 'light';
const String _kThemeTagDark = 'dark';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(_loadInitial(_ref));

  final Ref _ref;

  static ThemeMode _loadInitial(Ref ref) {
    final raw = ref.read(sharedPreferencesProvider).getString(kThemeModePrefKey);
    return raw == _kThemeTagLight ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final normalized = mode == ThemeMode.light
        ? ThemeMode.light
        : ThemeMode.dark;
    final previous = state;
    state = normalized;
    final ok = await _ref
        .read(sharedPreferencesProvider)
        .setString(kThemeModePrefKey, _tagFor(normalized));
    if (!ok) {
      state = previous;
    }
  }

  static String _tagFor(ThemeMode mode) =>
      mode == ThemeMode.light ? _kThemeTagLight : _kThemeTagDark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);
