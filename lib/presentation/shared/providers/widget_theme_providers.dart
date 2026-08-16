import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/widget_theme.dart';
import '../../../data/services/widget_theme_service.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import 'premium_providers.dart';

final widgetThemeServiceProvider = Provider<WidgetThemeService>((ref) {
  return WidgetThemeService(ref.watch(sharedPreferencesProvider));
});

final effectiveWidgetThemeProvider = Provider<ArinWidgetTheme>((ref) {
  final service = ref.watch(widgetThemeServiceProvider);
  return service.effectiveTheme(isPremium: ref.watch(isPremiumProvider));
});
