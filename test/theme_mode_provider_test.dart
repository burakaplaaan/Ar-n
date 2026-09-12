import 'package:arin/core/providers/shared_preferences_provider.dart';
import 'package:arin/core/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('krem tema kaydı yeniden açılışta hatırlanır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(first.dispose);

    expect(first.read(themeModeProvider), ThemeMode.dark);

    await first.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    expect(first.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(kThemeModePrefKey), 'light');

    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(second.read(themeModeProvider), ThemeMode.light);
  });

  test('kayıt yoksa gece teması açılır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}
