// Vakitler veya tercihler değişince yerel bildirimleri yeniden planlar;
// Home Widget namaz verisini günc tutar (periyodik + provider dinleme).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_locale_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/arin_widget_sync.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_notification_scheduler.dart';
import '../providers/prayer_time_providers.dart';

/// Ana kabukta tutulmalı (yalnızca HomePage değil); aksi halde widget donuk kalır.
class PrayerScheduleListener extends ConsumerStatefulWidget {
  const PrayerScheduleListener({super.key});

  @override
  ConsumerState<PrayerScheduleListener> createState() =>
      _PrayerScheduleListenerState();
}

class _PrayerScheduleListenerState
    extends ConsumerState<PrayerScheduleListener> {
  Timer? _widgetPushTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushPrayerWidgetIfReady();
    });
    // Uygulama açıkken SharedPreferences + epoch ile uyumlu kalsın (pil: 30 sn).
    _widgetPushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pushPrayerWidgetIfReady();
    });
  }

  @override
  void dispose() {
    _widgetPushTimer?.cancel();
    super.dispose();
  }

  void _pushPrayerWidgetIfReady() {
    final next = ref.read(prayerTimesProvider);
    final localeCode = ref.read(appLocaleProvider).languageCode;
    next.whenData((pt) {
      unawaited(
        ArinWidgetSync.refreshPrayer(
          model: pt,
          location: ref.read(locationServiceProvider),
          localeCode: localeCode,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PrayerTimesModel>>(prayerTimesProvider, (_, next) {
      next.whenData((pt) {
        final prefs = ref.read(sharedPreferencesProvider);
        unawaited(
          PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
            prefs: prefs,
            aladhan: ref.read(aladhanServiceProvider),
            location: ref.read(locationServiceProvider),
          ),
        );
        ArinWidgetSync.refreshPrayer(
          model: pt,
          location: ref.read(locationServiceProvider),
          localeCode: ref.read(appLocaleProvider).languageCode,
        );
      });
    });
    return const SizedBox.shrink();
  }
}
