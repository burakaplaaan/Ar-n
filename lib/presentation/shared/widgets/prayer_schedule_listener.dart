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
import '../../../data/services/prayer_service_resolver.dart';
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
  bool _widgetPushInFlight = false;
  bool _widgetPushQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushPrayerWidgetIfReady();
    });
    // Native widget uzun planla kendi ilerler; açık kalan oturumda planı
    // seyrekçe uzatmak yeterli.
    _widgetPushTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _pushPrayerWidgetIfReady();
    });
  }

  @override
  void dispose() {
    _widgetPushTimer?.cancel();
    super.dispose();
  }

  void _pushPrayerWidgetIfReady() {
    if (_widgetPushInFlight) return;
    final next = ref.read(prayerTimesProvider);
    final localeCode = ref.read(appLocaleProvider).languageCode;
    next.whenData((pt) {
      unawaited(_pushPrayerWidgetSchedule(seed: pt, localeCode: localeCode));
    });
  }

  Future<void> _pushPrayerWidgetSchedule({
    required PrayerTimesModel seed,
    required String localeCode,
  }) async {
    if (_widgetPushInFlight) {
      _widgetPushQueued = true;
      return;
    }
    _widgetPushInFlight = true;
    final location = ref.read(locationServiceProvider);
    try {
      final resolver = ref.read(prayerServiceResolverProvider);
      final upcoming = await resolver.fetchUpcomingDays(days: 14);
      final models = upcoming.isEmpty ? <PrayerTimesModel>[seed] : upcoming;
      await ArinWidgetSync.refreshPrayerSchedule(
        models: models,
        location: location,
        localeCode: localeCode,
      );
    } catch (_) {
      await ArinWidgetSync.refreshPrayer(
        model: seed,
        location: location,
        localeCode: localeCode,
      );
    } finally {
      _widgetPushInFlight = false;
      if (_widgetPushQueued && mounted) {
        _widgetPushQueued = false;
        _pushPrayerWidgetIfReady();
      }
    }
  }

  Future<void> _reschedulePrayerNotifications() async {
    try {
      await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
        prefs: ref.read(sharedPreferencesProvider),
        aladhan: ref.read(aladhanServiceProvider),
        location: ref.read(locationServiceProvider),
        force: true,
      );
    } catch (e) {
      debugPrint('PrayerScheduleListener notification reschedule skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PrayerTimesModel>>(prayerTimesProvider, (_, next) {
      next.whenData((pt) {
        unawaited(_reschedulePrayerNotifications());
        unawaited(
          _pushPrayerWidgetSchedule(
            seed: pt,
            localeCode: ref.read(appLocaleProvider).languageCode,
          ),
        );
      });
    });
    return const SizedBox.shrink();
  }
}
