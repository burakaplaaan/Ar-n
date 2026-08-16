import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/widget_theme.dart';
import 'arin_widget_sync.dart';

class WidgetThemeService {
  WidgetThemeService(this._prefs);

  final SharedPreferences _prefs;

  static const prefsKey = 'arin_widget_theme_id';
  static const widgetKey = ArinWidgetKeys.themeId;

  String requestedId() => _prefs.getString(prefsKey) ?? ArinWidgetTheme.defaultId;

  ArinWidgetTheme requestedTheme() => ArinWidgetTheme.byId(requestedId());

  ArinWidgetTheme effectiveTheme({required bool isPremium}) {
    return ArinWidgetTheme.byId(
      ArinWidgetTheme.resolveEffectiveId(
        requestedId: requestedId(),
        isPremium: isPremium,
      ),
    );
  }

  Future<void> select({
    required String themeId,
    required bool isPremium,
  }) async {
    final theme = ArinWidgetTheme.byId(themeId);
    if (theme.premiumOnly && !isPremium) {
      throw StateError('premium_required');
    }
    await _prefs.setString(prefsKey, theme.id);
    await syncToWidgets(isPremium: isPremium);
  }

  Future<void> syncToWidgets({required bool isPremium}) async {
    if (kIsWeb) return;
    final effective = effectiveTheme(isPremium: isPremium);
    try {
      await HomeWidget.saveWidgetData<String>(widgetKey, effective.id);
      await ArinWidgetSync.refreshAllWidgets();
    } catch (e) {
      debugPrint('[WidgetThemeService] sync error: $e');
    }
  }
}
