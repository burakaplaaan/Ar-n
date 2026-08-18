// home_widget: Android/iOS ortak anahtarlar ve provider güncellemesi.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileLock, FileMode, Platform, RandomAccessFile;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/willpower_templates.dart';
import '../models/esma_ul_husna.dart';
import '../models/prayer_times_model.dart';
import '../repositories/habit_repository.dart';
import '../repositories/salat_log_repository.dart';
import 'arin_lock_notification_service.dart';
import 'global_widget_lock_service.dart';
import 'location_service.dart';
import 'prayer_today_board.dart';
import 'prayer_widget_snapshot.dart';

abstract final class ArinWidgetKeys {
  static const quoteText = 'arin_quote_text';
  static const quoteSource = 'arin_quote_source';
  static const quoteScheduleJson = 'arin_quote_schedule_json';
  static const localeCode = 'arin_widget_locale';

  static const prayerLocation = 'arin_prayer_location';
  static const prayerNextName = 'arin_prayer_next_name';
  static const prayerCountdown = 'arin_prayer_countdown';
  static const prayerNextEpochMs = 'arin_prayer_next_epoch_ms';
  static const prayerScheduleJson = 'arin_prayer_schedule_json';
  static const prayerTodayJson = 'arin_prayer_today_json';
  static const prayerNextClock = 'arin_prayer_next_clock';
  static const esmaArabic = 'arin_esma_arabic';
  static const esmaTurkish = 'arin_esma_turkish';
  static const esmaIndex = 'arin_esma_index';
  static const esmaScheduleJson = 'arin_esma_schedule_json';

  static const trackingEnabled = 'arin_tracking_enabled';
  static const trackingTitle = 'arin_tracking_title';
  static const trackingValue = 'arin_tracking_value';
  static const trackingNote = 'arin_tracking_note';
  static const trackingQuotesJson = 'arin_tracking_quotes_json';
  static const trackingMode = 'arin_tracking_mode';
  static const trackingStartEpochMs = 'arin_tracking_start_epoch_ms';
  static const trackingDayPrefix = 'arin_tracking_day_prefix';

  // Zikirmatik widget. `zikirCount` kümülatif toplam = TEK paylaşılan otorite;
  // hem uygulama hem native +1 butonu bu değeri okuyup yazar. round/tur/target
  // yalnızca gösterim + uygulamada kaldığın yerden devam için taşınır.
  static const zikirEnabled = 'arin_zikir_enabled';
  static const zikirPhrase = 'arin_zikir_phrase';
  static const zikirCount = 'arin_zikir_count';
  static const zikirRound = 'arin_zikir_round';
  static const zikirTur = 'arin_zikir_tur';
  static const zikirTarget = 'arin_zikir_target';

  static const widgetGateQuoteLocked = 'arin_widget_gate_quote_locked';
  static const widgetGatePrayerLocked = 'arin_widget_gate_prayer_locked';
  static const widgetGateComboLocked = 'arin_widget_gate_combo_locked';
  static const widgetGateTrackingLocked = 'arin_widget_gate_tracking_locked';
  static const widgetGateZikirLocked = 'arin_widget_gate_zikir_locked';
  static const widgetGatePremium = 'arin_widget_gate_premium';
  static const widgetGateLockNote = 'arin_widget_gate_lock_note';
  static const widgetGateGlobalLocked = 'arin_widget_gate_global_locked';
  static const widgetGateGlobalRevision = 'arin_widget_gate_global_revision';
  static const widgetGateUnlockHours = 'arin_widget_gate_unlock_hours';
  static const themeId = 'arin_widget_theme_id';
  static const lockTextStyle = 'arin_widget_lock_text';
}

abstract final class ArinWidgetSync {
  static const _forcedWidgetLocale = 'tr';
  static final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');
  static Future<bool>? _appGroupFuture;
  static Future<void> _nativeGateMutationTail = Future<void>.value();

  /// Uygulama açılışında (deferred startup) bir kez çağrılır. AppGroup
  /// hazırlığı paralelde başlasın ki widget yazımı sırasında bekletme
  /// olmasın.
  static void primeAppGroup() {
    if (kIsWeb || !Platform.isIOS) return;
    unawaited(_ensureAppGroupReady());
  }

  /// Dışarıdan `HomeWidget.updateWidget` çağıracak başka yerler (hesap sil
  /// sonrası widget purge gibi) kullansın diye public sabitler.
  static const androidQuoteProviderClass =
      'com.arin.arin.ArinQuoteWidgetProvider';
  static const androidPrayerProviderClass =
      'com.arin.arin.ArinPrayerWidgetProvider';
  static const androidComboProviderClass =
      'com.arin.arin.ArinComboWidgetProvider';
  static const androidTrackingProviderClass =
      'com.arin.arin.ArinTrackingWidgetProvider';
  static const androidZikirProviderClass =
      'com.arin.arin.ArinZikirWidgetProvider';
  static const androidEsmaProviderClass =
      'com.arin.arin.ArinEsmaWidgetProvider';
  static const iOSQuoteWidgetName = 'ArinQuoteWidget';
  static const iOSPrayerWidgetName = 'ArinPrayerWidget';
  static const iOSComboWidgetName = 'ArinComboWidget';
  static const iOSTrackingWidgetName = 'ArinTrackingWidget';
  static const iOSZikirWidgetName = 'ArinZikirWidget';
  static const iOSEsmaWidgetName = 'ArinEsmaWidget';

  static const _androidQuote = androidQuoteProviderClass;
  static const _androidPrayer = androidPrayerProviderClass;
  static const _androidCombo = androidComboProviderClass;
  static const _androidTracking = androidTrackingProviderClass;
  static const _androidZikir = androidZikirProviderClass;
  static const _androidEsma = androidEsmaProviderClass;

  static String _widgetQuotePreferredLineBreaks(String t) => t;

  /// Söz widget verisi + yalnızca söz provider güncellemesi.
  static Future<void> pushQuote({
    required String text,
    required String source,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      var t = _widgetQuotePreferredLineBreaks(text.trim());
      final s = source;
      await HomeWidget.saveWidgetData<String>(ArinWidgetKeys.quoteText, t);
      await HomeWidget.saveWidgetData<String>(ArinWidgetKeys.quoteSource, s);
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await _writeEsma(DateTime.now());
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: 'ArinQuoteWidget',
      );
      await _updateEsmaWidget();
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuote: $e\n$st');
    }
  }

  /// Admin override: mevcut zaman çizelgesini geçici olarak devre dışı bırakır
  /// ve widget'a tek bir mesaj basar. Override kapanınca havuz schedule'ı tekrar
  /// yazılmalıdır.
  static Future<void> pushQuoteOverride({
    required String text,
    required String source,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteScheduleJson,
        '',
      );
      await pushQuote(text: text, source: source, localeCode: localeCode);
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuoteOverride: $e\n$st');
    }
  }

  /// Söz widget'ı için 3 günlük yerel zaman çizelgesi. Native widget bu JSON'u
  /// okuyup uygulama açılmadan slot değişimlerinde kendini günceller.
  static Future<void> pushQuoteSchedule({
    required List<({DateTime startsAt, String text, String source})> entries,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb || entries.isEmpty) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final sorted = entries.toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final now = DateTime.now();
      final current = _currentQuoteEntry(sorted, now) ?? sorted.first;
      final schedule = <String, Object?>{
        'version': 1,
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'entries': sorted
            .map(
              (e) => <String, Object?>{
                'epochMs': e.startsAt.millisecondsSinceEpoch,
                'text': _widgetQuotePreferredLineBreaks(e.text.trim()),
                'source': e.source.trim(),
              },
            )
            .toList(growable: false),
      };

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteScheduleJson,
        jsonEncode(schedule),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteText,
        _widgetQuotePreferredLineBreaks(current.text.trim()),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteSource,
        current.source.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuoteSchedule: $e\n$st');
    }
  }

  /// Gelişim/Arınma takip widget'ı: tek seçili takip, kısa sayaç ve motivasyon.
  static Future<void> pushTracking({
    required String title,
    required String value,
    required String note,
    required String quotesJson,
    String mode = 'static',
    int? startEpochMs,
    String dayPrefix = '',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingEnabled,
        '1',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingTitle,
        title.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingValue,
        value.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingNote,
        note.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingQuotesJson,
        quotesJson,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingMode,
        mode,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingStartEpochMs,
        startEpochMs == null ? '' : '$startEpochMs',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingDayPrefix,
        dayPrefix.trim(),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushTracking: $e\n$st');
    }
  }

  static Future<void> clearTracking() async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      for (final k in const <String>[
        ArinWidgetKeys.trackingEnabled,
        ArinWidgetKeys.trackingTitle,
        ArinWidgetKeys.trackingValue,
        ArinWidgetKeys.trackingNote,
        ArinWidgetKeys.trackingQuotesJson,
        ArinWidgetKeys.trackingMode,
        ArinWidgetKeys.trackingStartEpochMs,
        ArinWidgetKeys.trackingDayPrefix,
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.clearTracking: $e\n$st');
    }
  }

  /// Zikirmatik widget'ı: aktif oturumu (zikir + sayaç) widget'a yansıtır.
  /// `count` kümülatif toplam (paylaşılan otorite); round/tur/target gösterim
  /// ve uygulamada kaldığın yerden devam için taşınır.
  static Future<void> pushZikir({
    required String phrase,
    required int count,
    required int round,
    required int tur,
    required int target,
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      await HomeWidget.saveWidgetData<String>(ArinWidgetKeys.zikirEnabled, '1');
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.zikirPhrase,
        phrase.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.zikirCount,
        '${count < 0 ? 0 : count}',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.zikirRound,
        '${round < 0 ? 0 : round}',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.zikirTur,
        '${tur < 1 ? 1 : tur}',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.zikirTarget,
        '${target < 1 ? 1 : target}',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidZikir,
        iOSName: iOSZikirWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushZikir: $e\n$st');
    }
  }

  static Future<void> clearZikir() async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      for (final k in const <String>[
        ArinWidgetKeys.zikirEnabled,
        ArinWidgetKeys.zikirPhrase,
        ArinWidgetKeys.zikirCount,
        ArinWidgetKeys.zikirRound,
        ArinWidgetKeys.zikirTur,
        ArinWidgetKeys.zikirTarget,
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidZikir,
        iOSName: iOSZikirWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.clearZikir: $e\n$st');
    }
  }

  static Future<void> pushWidgetGateStates({
    required Map<String, bool> lockedByKind,
    required Map<String, DateTime?> trialUntilByKind,
    required Map<String, DateTime?> unlockUntilByKind,
    required Map<String, DateTime?> unlockStartedAtByKind,
    required bool isPremium,
    required bool globalLocked,
    required int globalLockRevision,
    required int unlockHours,
    String lockNote = '',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final stateCurrent = await _serializedNativeGateMutation(() async {
        final globalStateCurrent =
            await _saveGlobalLockOverrideIfCurrentUnlocked(
              locked: globalLocked,
              revision: globalLockRevision,
              lockNote: lockNote,
              unlockHours: unlockHours,
            );
        if (!globalStateCurrent) return false;

        Future<void> saveLocked(String key, String kind) {
          return HomeWidget.saveWidgetData<String>(
            key,
            lockedByKind[kind] == true ? '1' : '0',
          );
        }

        await saveLocked(ArinWidgetKeys.widgetGateQuoteLocked, 'quote');
        await saveLocked(ArinWidgetKeys.widgetGatePrayerLocked, 'prayer');
        await saveLocked(ArinWidgetKeys.widgetGateComboLocked, 'combo');
        await saveLocked(ArinWidgetKeys.widgetGateTrackingLocked, 'tracking');
        await saveLocked(ArinWidgetKeys.widgetGateZikirLocked, 'zikir');
        await HomeWidget.saveWidgetData<String>(
          ArinWidgetKeys.widgetGatePremium,
          isPremium ? '1' : '0',
        );
        await HomeWidget.saveWidgetData<String>(
          ArinWidgetKeys.widgetGateLockNote,
          globalLocked ? lockNote.trim() : '',
        );
        for (final kind in const <String>[
          'quote',
          'prayer',
          'combo',
          'tracking',
          'zikir',
        ]) {
          await HomeWidget.saveWidgetData<String>(
            'arin_widget_gate_${kind}_trial_until_ms',
            '${trialUntilByKind[kind]?.millisecondsSinceEpoch ?? 0}',
          );
          await HomeWidget.saveWidgetData<String>(
            'arin_widget_gate_${kind}_unlock_until_ms',
            '${unlockUntilByKind[kind]?.millisecondsSinceEpoch ?? 0}',
          );
          await HomeWidget.saveWidgetData<String>(
            'arin_widget_gate_${kind}_unlock_started_at_ms',
            '${unlockStartedAtByKind[kind]?.millisecondsSinceEpoch ?? 0}',
          );
        }
        await _saveGlobalLockRevision(globalLockRevision);
        return true;
      });
      if (!stateCurrent) return;
      await _updateAllWidgets();
      // Kilit ekranı bildirimleri ana ekran widget'larıyla aynı reklam/deneme
      // kapısını paylaşır (bkz. `ArinLockNotifications.kt`); reklam izlenince
      // veya premium alınınca bildirimin de anında normale dönmesi için
      // native tarafı burada da tetikle — aksi halde kullanıcı uygulamayı
      // kapatıp açana kadar "kilitli" görünmeye devam ederdi.
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushWidgetGateStates: $e\n$st');
    }
  }

  /// Sessiz FCM mesajından gelen global override'ı sürüm sırasını koruyarak
  /// uygular. Premium istisnası native provider'larda değerlendirilir.
  ///
  /// Aynı revision tekrar uygulanabilir: önceki denemede veri yazılıp provider
  /// refresh'i yarıda kaldıysa tekrar teslim edilen FCM mesajı iyileştirir.
  static Future<void> applyGlobalLockOverride({
    required bool locked,
    required int revision,
    required String lockNote,
    required int unlockHours,
  }) async {
    if (kIsWeb || revision <= 0) return;
    if (!await _ensureAppGroupReady()) return;

    final applied = await _saveGlobalLockOverrideIfCurrent(
      locked: locked,
      revision: revision,
      lockNote: lockNote,
      unlockHours: unlockHours,
    );
    if (!applied) return;
    await _updateAllWidgets();
    unawaited(ArinLockNotificationService.syncAll());
  }

  /// Background FCM isolate'ının yazdığı native/App Group durumunu foreground
  /// Flutter isolate'ına taşımak için okunabilir snapshot döndürür.
  static Future<
    ({
      bool locked,
      int revision,
      String note,
      int unlockHours,
      Map<String, int> unlockStartedAtMsByKind,
      Map<String, int> unlockUntilMsByKind,
    })?
  >
  readGlobalLockOverride() async {
    if (kIsWeb || !await _ensureAppGroupReady()) return null;
    return _serializedNativeGateMutation(() async {
      final revisionRaw = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.widgetGateGlobalRevision,
      );
      final revision = int.tryParse(revisionRaw ?? '') ?? 0;
      if (revision <= 0) return null;
      final lockedRaw = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.widgetGateGlobalLocked,
      );
      final note = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.widgetGateLockNote,
      );
      final unlockHoursRaw = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.widgetGateUnlockHours,
      );
      final parsedUnlockHours = int.tryParse(unlockHoursRaw ?? '');
      final unlockHours =
          GlobalWidgetLockService.isValidUnlockHours(parsedUnlockHours)
          ? parsedUnlockHours!
          : GlobalWidgetLockService.defaultUnlockHours;
      final unlockStartedAtMsByKind = <String, int>{};
      final unlockUntilMsByKind = <String, int>{};
      for (final kind in const <String>[
        'quote',
        'prayer',
        'combo',
        'tracking',
        'zikir',
      ]) {
        final startedAtRaw = await HomeWidget.getWidgetData<String>(
          'arin_widget_gate_${kind}_unlock_started_at_ms',
        );
        final untilRaw = await HomeWidget.getWidgetData<String>(
          'arin_widget_gate_${kind}_unlock_until_ms',
        );
        unlockStartedAtMsByKind[kind] = int.tryParse(startedAtRaw ?? '') ?? 0;
        unlockUntilMsByKind[kind] = int.tryParse(untilRaw ?? '') ?? 0;
      }
      return (
        locked: lockedRaw == '1',
        revision: revision,
        note: note ?? '',
        unlockHours: unlockHours,
        unlockStartedAtMsByKind: unlockStartedAtMsByKind,
        unlockUntilMsByKind: unlockUntilMsByKind,
      );
    });
  }

  static Future<bool> _saveGlobalLockOverrideIfCurrent({
    required bool locked,
    required int revision,
    required String lockNote,
    required int unlockHours,
  }) async {
    return _serializedNativeGateMutation(() async {
      final applied = await _saveGlobalLockOverrideIfCurrentUnlocked(
        locked: locked,
        revision: revision,
        lockNote: lockNote,
        unlockHours: unlockHours,
      );
      if (!applied) return false;
      await _saveGlobalLockRevision(revision);
      return true;
    });
  }

  /// Çağıran `_serializedNativeGateMutation` kilidini tutmalıdır. Revision bu
  /// işlemde yazılmaz; tüm ilişkili native anahtarlar tamamlandıktan sonra
  /// commit işareti olarak en son yazılır.
  static Future<bool> _saveGlobalLockOverrideIfCurrentUnlocked({
    required bool locked,
    required int revision,
    required String lockNote,
    required int unlockHours,
  }) async {
    final currentRaw = await HomeWidget.getWidgetData<String>(
      ArinWidgetKeys.widgetGateGlobalRevision,
    );
    final currentRevision = int.tryParse(currentRaw ?? '') ?? 0;
    if (revision < currentRevision ||
        (revision <= 0 && currentRevision > 0) ||
        unlockHours < 1 ||
        unlockHours > 72) {
      return false;
    }

    final previousHoursRaw = await HomeWidget.getWidgetData<String>(
      ArinWidgetKeys.widgetGateUnlockHours,
    );
    // Saat anahtarı yoksa kayıt eski sürümden kalmıştır; o dönem 24 saatti.
    final previousHours =
        int.tryParse(previousHoursRaw ?? '') ??
        GlobalWidgetLockService.legacyUnlockHours;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final kind in const <String>[
      'quote',
      'prayer',
      'combo',
      'tracking',
      'zikir',
    ]) {
      final startedAtKey = 'arin_widget_gate_${kind}_unlock_started_at_ms';
      final untilKey = 'arin_widget_gate_${kind}_unlock_until_ms';
      final startedAtRaw = await HomeWidget.getWidgetData<String>(startedAtKey);
      final untilRaw = await HomeWidget.getWidgetData<String>(untilKey);
      final previousUntil = int.tryParse(untilRaw ?? '') ?? 0;
      if (previousUntil > 0 && previousUntil <= nowMs) {
        continue;
      }
      var startedAt = int.tryParse(startedAtRaw ?? '') ?? 0;
      if (startedAt <= 0 && previousUntil > 0) {
        startedAt =
            previousUntil - Duration(hours: previousHours).inMilliseconds;
        await HomeWidget.saveWidgetData<String>(startedAtKey, '$startedAt');
      }
      if (startedAt > 0) {
        await HomeWidget.saveWidgetData<String>(
          untilKey,
          '${startedAt + Duration(hours: unlockHours).inMilliseconds}',
        );
      }
    }
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.widgetGateUnlockHours,
      '$unlockHours',
    );
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.widgetGateGlobalLocked,
      locked ? '1' : '0',
    );
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.widgetGateLockNote,
      locked ? lockNote.trim() : '',
    );
    return true;
  }

  static Future<void> _saveGlobalLockRevision(int revision) async {
    if (revision > 0) {
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.widgetGateGlobalRevision,
        '$revision',
      );
    }
  }

  /// Background ve foreground FCM isolate'ları aynı HomeWidget/App Group
  /// deposuna yazabilir. Dart kuyruğu aynı isolate'ı, OS dosya kilidi ise
  /// isolate'lar arası read-check-write bölümünü sıralar.
  static Future<T> _serializedNativeGateMutation<T>(
    Future<T> Function() action,
  ) async {
    final previous = _nativeGateMutationTail;
    final release = Completer<void>();
    _nativeGateMutationTail = release.future;
    await previous;

    RandomAccessFile? lockFile;
    try {
      final support = await getApplicationSupportDirectory();
      lockFile = await File(
        '${support.path}${Platform.pathSeparator}.arin_widget_gate.lock',
      ).open(mode: FileMode.append);
      // Foreground ve background FCM isolate'ları çakıştığında yeni revision
      // düşürülmemeli; kilit boşalana kadar bekleyip ardından revision kontrolü
      // aynı critical section içinde yeniden yapılır.
      await lockFile.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      if (lockFile != null) {
        try {
          await lockFile.unlock();
        } catch (_) {}
        await lockFile.close();
      }
      release.complete();
    }
  }

  static Future<void> refreshAllWidgets() => _updateAllWidgets();

  static Future<void> _updateAllWidgets() async {
    await Future.wait([
      HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      ),
      HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      ),
      HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      ),
      HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      ),
      HomeWidget.updateWidget(
        qualifiedAndroidName: _androidZikir,
        iOSName: iOSZikirWidgetName,
      ),
    ]);
  }

  static ({DateTime startsAt, String text, String source})? _currentQuoteEntry(
    List<({DateTime startsAt, String text, String source})> entries,
    DateTime now,
  ) {
    ({DateTime startsAt, String text, String source})? current;
    for (final e in entries) {
      if (e.startsAt.isAfter(now)) break;
      current = e;
    }
    return current;
  }

  static Future<void> refreshPrayer({
    required PrayerTimesModel model,
    required LocationService location,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final now = DateTime.now();
      final loc = formatWidgetLocationLabel(
        location.savedCity,
        location.savedCountry,
        localeCode: _forcedWidgetLocale,
      );
      final safeLocationLine = _widgetSafeLocationLine(
        primary: loc,
        fallback: model.city,
      );
      final snap = PrayerWidgetSnapshot.fromModel(
        model: model,
        now: now,
        locationLine: safeLocationLine,
        localeCode: _forcedWidgetLocale,
      );

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerLocation,
        snap.locationLine,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerScheduleJson,
        '',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextName,
        snap.nextName,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerCountdown,
        snap.countdownLabel,
      );

      final nextEpoch = now.add(snap.remaining).millisecondsSinceEpoch;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextEpochMs,
        '$nextEpoch',
      );
      await _writeTodayAndEsma(
        models: [model],
        now: now,
        nextAt: now.add(snap.remaining),
      );

      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: 'ArinPrayerWidget',
      );
      await _updateEsmaWidget();
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.refreshPrayer: $e\n$st');
    }
  }

  /// Namaz widget'ı için çok günlük yerel plan. Uygulama kapalıyken native
  /// taraf sıradaki vakti bu listeden seçer; şehir değişiminde bu plan ezilir.
  static Future<void> refreshPrayerSchedule({
    required List<PrayerTimesModel> models,
    required LocationService location,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb || models.isEmpty) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final now = DateTime.now();
      final loc = formatWidgetLocationLabel(
        location.savedCity,
        location.savedCountry,
        localeCode: _forcedWidgetLocale,
      );
      final safeLocationLine = _widgetSafeLocationLine(
        primary: loc,
        fallback: models.first.city,
      );
      final events = _prayerScheduleEvents(models);
      if (events.isEmpty) {
        await refreshPrayer(
          model: models.first,
          location: location,
          localeCode: localeCode,
        );
        return;
      }

      final next = events.firstWhere(
        (e) => e.at.isAfter(now),
        orElse: () => events.last,
      );
      final remaining = next.at.difference(now);
      final schedule = <String, Object?>{
        'version': 1,
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'location': safeLocationLine,
        'city': location.savedCity,
        'country': location.savedCountry,
        'entries': events
            .map(
              (e) => <String, Object?>{
                'epochMs': e.at.millisecondsSinceEpoch,
                'name': e.name,
              },
            )
            .toList(growable: false),
      };

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerScheduleJson,
        jsonEncode(schedule),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerLocation,
        safeLocationLine,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextName,
        next.name,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerCountdown,
        _formatHms(remaining.isNegative ? Duration.zero : remaining),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextEpochMs,
        '${next.at.millisecondsSinceEpoch}',
      );
      await _writeTodayAndEsma(
        models: models,
        now: now,
        nextAt: next.at,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
      await _updateEsmaWidget();
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.refreshPrayerSchedule: $e\n$st');
    }
  }

  static List<({String name, DateTime at})> _prayerScheduleEvents(
    List<PrayerTimesModel> models,
  ) {
    final out = <({String name, DateTime at})>[];
    for (final model in models) {
      final day = _parseIsoDate(model.date);
      if (day == null) continue;
      void add(String name, String hhmm) {
        final at = _at(day, hhmm);
        if (at != null) out.add((name: name, at: at));
      }

      add('İmsak', model.fajr);
      // Güneşe kadar kullanıcı hâlâ sabah namazı penceresinde olsun.
      add('Güneş', model.sunrise);
      add('Öğle', model.dhuhr);
      add('İkindi', model.asr);
      add('Akşam', model.maghrib);
      add('Yatsı', model.isha);
    }
    final last = models.isEmpty ? null : models.last;
    final lastDay = last == null ? null : _parseIsoDate(last.date);
    if (last != null && lastDay != null) {
      final nextFajr = _at(lastDay.add(const Duration(days: 1)), last.fajr);
      if (nextFajr != null) out.add((name: 'İmsak', at: nextFajr));
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  static DateTime? _parseIsoDate(String ymd) {
    final p = ymd.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime? _at(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  static String _formatHms(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static List<bool> _todaySalatDone(DateTime day) {
    try {
      final habit = HabitRepository().findActiveByTemplateId(
        WillpowerTemplates.salatDaily,
      );
      if (habit == null) {
        return List<bool>.filled(5, false);
      }
      return SalatLogRepository().getPrayers(habit.id, day);
    } catch (_) {
      return List<bool>.filled(5, false);
    }
  }

  static Map<String, Object?> _todayBoard({
    required List<PrayerTimesModel> models,
    required DateTime now,
    required DateTime nextAt,
  }) {
    final tickDay = PrayerTodayBoard.salatBoardDay(models: models, now: now);
    return PrayerTodayBoard.build(
      models: models,
      now: now,
      nextAt: nextAt,
      done: _todaySalatDone(tickDay),
      tickDay: tickDay,
    );
  }

  static Future<void> _writeTodayAndEsma({
    required List<PrayerTimesModel> models,
    required DateTime now,
    required DateTime nextAt,
  }) async {
    final board = _todayBoard(models: models, now: now, nextAt: nextAt);
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.prayerTodayJson,
      jsonEncode(board),
    );
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.prayerNextClock,
      board['nextClock'] as String? ?? '',
    );
    await _writeEsma(now);
  }

  static Future<void> _writeEsma(DateTime now) async {
    final today = EsmaUlHusna.forDay(now);
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.esmaArabic,
      today.arabic,
    );
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.esmaTurkish,
      today.turkish,
    );
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.esmaIndex,
      '${today.index}',
    );
    final start = DateTime(now.year, now.month, now.day);
    final entries = List<Map<String, Object?>>.generate(16, (i) {
      final day = start.add(Duration(days: i));
      final name = EsmaUlHusna.forDay(day);
      return {
        'day': PrayerTodayBoard.ymd(day),
        'arabic': name.arabic,
        'turkish': name.turkish,
        'index': name.index,
      };
    });
    await HomeWidget.saveWidgetData<String>(
      ArinWidgetKeys.esmaScheduleJson,
      jsonEncode({'entries': entries}),
    );
  }

  static Future<void> _updateEsmaWidget() async {
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _androidEsma,
      iOSName: iOSEsmaWidgetName,
    );
  }

  /// Namaz tiklenince sadece günlük tahta güncellenir.
  static Future<void> refreshPrayerTodayMarks() async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final raw = await HomeWidget.getWidgetData<String>(
        ArinWidgetKeys.prayerTodayJson,
      );
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, Object?>.from(decoded);
      final now = DateTime.now();
      var imsakClock = '';
      final slotsProbe = map['slots'];
      if (slotsProbe is List && slotsProbe.isNotEmpty) {
        final first = slotsProbe.first;
        if (first is Map) {
          imsakClock = '${first['time'] ?? ''}';
        }
      }
      final tickDay = imsakClock.isEmpty
          ? DateTime(now.year, now.month, now.day)
          : PrayerTodayBoard.salatBoardDayFromClock(
              now: now,
              imsakClock: imsakClock,
            );
      final done = _todaySalatDone(tickDay);
      map['day'] = PrayerTodayBoard.ymd(tickDay);
      final slotsRaw = map['slots'];
      if (slotsRaw is List) {
        final slots = <Map<String, Object?>>[];
        for (var i = 0; i < slotsRaw.length && i < 5; i++) {
          final slot = slotsRaw[i];
          if (slot is! Map) continue;
          final next = Map<String, Object?>.from(slot);
          next['done'] = done[i];
          slots.add(next);
        }
        map['slots'] = slots;
      }
      map['doneCount'] = done.where((e) => e).length;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerTodayJson,
        jsonEncode(map),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.refreshPrayerTodayMarks: $e\n$st');
    }
  }

  static String _widgetSafeLocationLine({
    required String primary,
    required String fallback,
  }) {
    final first = primary.trim();
    if (first.isNotEmpty && !_arabicChars.hasMatch(first)) return first;
    final second = fallback.trim();
    if (second.isNotEmpty && !_arabicChars.hasMatch(second)) return second;
    return '';
  }

  /// Hesap silme / çıkış akışında widget verilerini sıfırlar. home_widget
  /// plugin'i Android'de widget provider başına ayrı bir SharedPreferences
  /// deposu, iOS'ta ise App Group UserDefaults suite'i kullanır — bu yüzden
  /// Flutter tarafındaki [SharedPreferences.clear] bu verileri silmez.
  /// Tüm bilinen anahtarlara boş değer yazıp widget provider'lara refresh
  /// sinyali gönderiyoruz; widget layout'ları "kurulum bekliyor" görünümüne
  /// güvenle düşsün.
  static Future<void> clearAll() async {
    if (kIsWeb) return;
    try {
      // clearAll oturum kapanışı / hesap silme akışından geliyor; burada
      // bir kerelik bekleyebiliriz çünkü ana açılış path'inde değil.
      if (!await _ensureAppGroupReady()) return;
      // Global lock kullanıcı hesabına değil uygulama kurulumuna aittir.
      // widgetGateGlobalLocked/revision bilerek temizlenmez; aksi halde çıkış
      // yapmak acil global kilidi yerel olarak aşabilirdi.
      for (final k in const <String>[
        ArinWidgetKeys.quoteText,
        ArinWidgetKeys.quoteSource,
        ArinWidgetKeys.quoteScheduleJson,
        ArinWidgetKeys.localeCode,
        ArinWidgetKeys.prayerLocation,
        ArinWidgetKeys.prayerNextName,
        ArinWidgetKeys.prayerCountdown,
        ArinWidgetKeys.prayerNextEpochMs,
        ArinWidgetKeys.prayerScheduleJson,
        ArinWidgetKeys.prayerTodayJson,
        ArinWidgetKeys.prayerNextClock,
        ArinWidgetKeys.esmaArabic,
        ArinWidgetKeys.esmaTurkish,
        ArinWidgetKeys.esmaIndex,
        ArinWidgetKeys.esmaScheduleJson,
        ArinWidgetKeys.trackingEnabled,
        ArinWidgetKeys.trackingTitle,
        ArinWidgetKeys.trackingValue,
        ArinWidgetKeys.trackingNote,
        ArinWidgetKeys.trackingQuotesJson,
        ArinWidgetKeys.trackingMode,
        ArinWidgetKeys.trackingStartEpochMs,
        ArinWidgetKeys.trackingDayPrefix,
        ArinWidgetKeys.zikirEnabled,
        ArinWidgetKeys.zikirPhrase,
        ArinWidgetKeys.zikirCount,
        ArinWidgetKeys.zikirRound,
        ArinWidgetKeys.zikirTur,
        ArinWidgetKeys.zikirTarget,
        ArinWidgetKeys.widgetGateQuoteLocked,
        ArinWidgetKeys.widgetGatePrayerLocked,
        ArinWidgetKeys.widgetGateComboLocked,
        ArinWidgetKeys.widgetGateTrackingLocked,
        ArinWidgetKeys.widgetGateZikirLocked,
        ArinWidgetKeys.widgetGatePremium,
        ArinWidgetKeys.widgetGateLockNote,
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      for (final kind in const [
        'quote',
        'prayer',
        'combo',
        'tracking',
        'zikir',
      ]) {
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_first_use_ms_$kind',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_last_render_ms_$kind',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_home_last_render_ms_$kind',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_lock_notif_first_use_ms_$kind',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_lock_notif_last_show_ms_$kind',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_gate_${kind}_trial_until_ms',
          '',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_gate_${kind}_unlock_until_ms',
          '',
        );
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidZikir,
        iOSName: iOSZikirWidgetName,
      );
      await _updateEsmaWidget();
      unawaited(ArinLockNotificationService.syncAll());
    } catch (e, st) {
      debugPrint('ArinWidgetSync.clearAll: $e\n$st');
    }
  }

  /// Senkron, bekleme yapmayan kontrol: AppGroup hazırsa true döner ve
  /// widget yazımına izin verir; hazır değilse hazırlama future'ını
  /// arka planda başlatır ama caller'ı bloklamaz (false döner).
  ///
  /// Bu sayede pool sync (ana açılış path'i) AppGroup için 2 saniye
  /// beklemez; widget bir sonraki başarı turunda güncellenir.
  static Future<bool> _ensureAppGroupReady() {
    if (kIsWeb || !Platform.isIOS) return Future<bool>.value(true);
    final existing = _appGroupFuture;
    if (existing != null) return existing;

    final future = HomeWidget.setAppGroupId('group.com.arin.arin')
        .timeout(const Duration(seconds: 4))
        .then((_) {
          return true;
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('ArinWidgetSync.setAppGroupId: $e\n$st');
          return false;
        });
    _appGroupFuture = future;
    future.then((ok) {
      if (!ok) _appGroupFuture = null;
    });
    return future;
  }
}
