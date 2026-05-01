// Vakit hatırlatıcı — dışta anahtar; süre tekerlek seçici (Tamam / İptal).

import 'dart:async';

import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/services/arin_local_notifications_plugin.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_notification_android_uri.dart';
import '../../../data/services/prayer_notification_scheduler.dart';
import '../../../data/services/prayer_notification_sounds.dart';
import '../../../data/services/prayer_reminder_prefs.dart';
import '../../../data/services/prayer_user_notification_sound_store.dart';
import '../../shared/providers/prayer_time_providers.dart';

part 'namaz_adhan_reminder_sheets.dart';

String _prayerSlotLabel(AppLocalizations l10n, int i) {
  switch (i) {
    case 0:
      return l10n.prayerNameImsak;
    case 1:
      return l10n.prayerNameSunrise;
    case 2:
      return l10n.prayerNameDhuhr;
    case 3:
      return l10n.prayerNameAsr;
    case 4:
      return l10n.prayerNameMaghrib;
    case 5:
      return l10n.prayerNameIsha;
    default:
      return '';
  }
}

Future<void> _rescheduleNotifications(
  WidgetRef ref, {
  bool force = false,
}) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
    prefs: prefs,
    aladhan: ref.read(aladhanServiceProvider),
    location: ref.read(locationServiceProvider),
    force: force,
  );
}

String _minutePickerLabelEarly(AppLocalizations l10n, int m) {
  if (m < 0) return l10n.reminderOff;
  if (m == 0) return l10n.reminderAtExactTime;
  return l10n.reminderMinutesBefore(m);
}

String _minutePickerLabelSecond(AppLocalizations l10n, int m) {
  if (m == 0) return l10n.reminderOff;
  return l10n.reminderMinutesBefore(m);
}

String _reminderCardSubtitle(AppLocalizations l10n) =>
    l10n.reminderCardSubtitle;

String _pairLineForPrayer(
  SharedPreferences prefs,
  int i,
  AppLocalizations l10n,
) {
  final a = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i);
  final b = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(prefs, i);
  final first = a < 0
      ? l10n.reminderFirstOff
      : l10n.reminderFirstValue(_minutePickerLabelEarly(l10n, a));
  if (b <= 0) return l10n.reminderPairSecondOff(first);
  return l10n.reminderPairSecondValue(first, _minutePickerLabelSecond(l10n, b));
}

int _nearestInList(int stored, List<int> list) {
  var best = list.first;
  var bestD = 9999;
  for (final x in list) {
    final d = (x - stored).abs();
    if (d < bestD) {
      bestD = d;
      best = x;
    }
  }
  return best;
}

int _indexForEarly(int m) {
  const list = PrayerReminderPrefs.pickerEarlyValues;
  final v = list.contains(m) ? m : _nearestInList(m, list);
  return list.indexOf(v).clamp(0, list.length - 1);
}

int _indexForSecond(int m) {
  const list = PrayerReminderPrefs.pickerSecondValues;
  final v = list.contains(m) ? m : _nearestInList(m, list);
  return list.indexOf(v).clamp(0, list.length - 1);
}

Future<({int early, int second})?> _openDualReminderSheet(
  BuildContext context, {
  required String prayerTitle,
  required int initialEarly,
  required int initialSecond,
}) {
  return showModalBottomSheet<({int early, int second})>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161B17),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _DualReminderSheet(
      prayerTitle: prayerTitle,
      initialEarlyIndex: _indexForEarly(initialEarly),
      initialSecondIndex: _indexForSecond(initialSecond),
    ),
  );
}

Future<bool?> _openPerPrayerReminderList(
  BuildContext context, {
  required SharedPreferences prefs,
  required WidgetRef ref,
  required bool isEnablingFlow,
  required Future<void> Function() onBildirimSesi,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161B17),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PerPrayerReminderListSheet(
      prefs: prefs,
      isEnablingFlow: isEnablingFlow,
      onReschedule: () => _rescheduleNotifications(ref, force: true),
      onBildirimSesi: onBildirimSesi,
    ),
  );
}

class NamazAdhanReminderCard extends ConsumerStatefulWidget {
  const NamazAdhanReminderCard({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<NamazAdhanReminderCard> createState() =>
      _NamazAdhanReminderCardState();
}

class _NamazAdhanReminderCardState
    extends ConsumerState<NamazAdhanReminderCard> {
  /// null = SharedPreferences değerini kullan (Riverpod prefs nesnesi değişmediği için senkron için gerekli).
  bool? _enabledOverride;

  bool _effectiveEnabled(SharedPreferences prefs) =>
      _enabledOverride ?? PrayerReminderPrefs.isEnabled(prefs);

  Future<void> _turnOff(SharedPreferences prefs) async {
    HapticFeedback.selectionClick();
    await PrayerReminderPrefs.setEnabled(prefs, false);
    await PrayerNotificationScheduler.cancelAllPrayerNotifications();
    if (mounted) setState(() => _enabledOverride = null);
  }

  /// Aç: izin → tekerlek → Tamam’da kaydet. İptal’da kapat.
  Future<void> _turnOnWithPicker(SharedPreferences prefs) async {
    HapticFeedback.selectionClick();
    if (!PrayerNotificationScheduler.supported) return;
    final l10n = AppLocalizations.of(context)!;

    final ok = await PrayerNotificationScheduler.requestPermissions();
    if (!ok) {
      await PrayerReminderPrefs.setEnabled(prefs, false);
      if (mounted) {
        setState(() => _enabledOverride = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.reminderPermissionRequiredMessage,
              style: TextStyle(
                color: AppColors.creamBase.withValues(alpha: 0.92),
              ),
            ),
            backgroundColor: AppColors.anthraciteMid,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);
    if (!mounted) return;
    final confirmed = await _openPerPrayerReminderList(
      context,
      prefs: prefs,
      ref: ref,
      isEnablingFlow: true,
      onBildirimSesi: () => _openPrayerSoundPicker(prefs),
    );

    if (!mounted) return;
    if (confirmed != true) {
      await PrayerReminderPrefs.setEnabled(prefs, false);
      setState(() => _enabledOverride = false);
      return;
    }

    await PrayerReminderPrefs.setEnabled(prefs, true);
    await _rescheduleNotifications(ref, force: true);
    if (mounted) setState(() => _enabledOverride = null);
  }

  Future<void> _openPrayerSoundPicker(SharedPreferences prefs) async {
    if (!PrayerNotificationScheduler.supported) return;
    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);
    if (!mounted) return;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B17),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _PrayerNotificationSoundSheet(
        prefs: prefs,
        onAfterSoundChange: () => _rescheduleNotifications(ref, force: true),
      ),
    );
    if (applied != true || !mounted) return;
    setState(() {});
  }

  Future<void> _changeMinutesOnly(SharedPreferences prefs) async {
    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);
    if (!mounted) return;
    await _openPerPrayerReminderList(
      context,
      prefs: prefs,
      ref: ref,
      isEnablingFlow: false,
      onBildirimSesi: () => _openPrayerSoundPicker(prefs),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editPrayerReminderAt(
    BuildContext context,
    SharedPreferences prefs,
    int i,
  ) async {
    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);
    if (!mounted || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final chosen = await _openDualReminderSheet(
      context,
      prayerTitle: _prayerSlotLabel(l10n, i),
      initialEarly: PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i),
      initialSecond: PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
        prefs,
        i,
      ),
    );
    if (chosen == null || !mounted) return;
    await PrayerReminderPrefs.setMinutesBeforeForPrayer(prefs, i, chosen.early);
    await PrayerReminderPrefs.setMinutesBeforeSecondaryForPrayer(
      prefs,
      i,
      chosen.second,
    );
    await _rescheduleNotifications(ref, force: true);
    if (mounted) setState(() {});
  }

  Future<void> _onCompactSwitch(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _enabledOverride = value);
    if (!value) {
      await _turnOff(prefs);
      return;
    }
    await _turnOnWithPicker(prefs);
  }

  Future<void> _onFullSwitch(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _enabledOverride = value);
    if (!value) {
      await _turnOff(prefs);
      return;
    }
    await _turnOnWithPicker(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(sharedPreferencesProvider);
    final displayOn = _effectiveEnabled(prefs);
    final onLight = Theme.of(context).brightness == Brightness.light;
    final accent = onLight
        ? AppColors.accentGreenOnLight
        : AppColors.accentNeonGreen;
    final primaryText = onLight ? AppColors.emeraldDark : AppColors.creamBase;
    final secondaryText = onLight
        ? AppColors.textSecondary
        : AppColors.textOnDarkMuted;
    final subduedIcon = onLight
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.35);
    final tileSurface = onLight
        ? AppColors.creamSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.05);
    final slotSurface = onLight
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.04);
    final borderColor = onLight
        ? AppColors.creamDark.withValues(alpha: 0.75)
        : AppColors.accentNeonGreen.withValues(alpha: 0.18);

    if (widget.compact) {
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: displayOn && PrayerNotificationScheduler.supported
                      ? () => _changeMinutesOnly(prefs)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  splashColor: accent.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: accent.withValues(alpha: 0.88),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.reminderPrayerNotificationTitle,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: primaryText,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                displayOn
                                    ? _reminderCardSubtitle(l10n)
                                    : l10n.reminderCardDisabledHint,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: secondaryText,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (displayOn && PrayerNotificationScheduler.supported)
                IconButton(
                  tooltip: l10n.prayerSoundPickerTitle,
                  onPressed: () => _openPrayerSoundPicker(prefs),
                  icon: Icon(
                    Icons.graphic_eq_rounded,
                    color: accent.withValues(alpha: 0.88),
                    size: 22,
                  ),
                ),
              Switch.adaptive(
                value: displayOn,
                activeThumbColor: accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: PrayerNotificationScheduler.supported
                    ? _onCompactSwitch
                    : null,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic);
    }

    return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: onLight
                ? AppColors.creamSurface.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.045),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      color: accent.withValues(alpha: 0.9),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reminderPrayerNotificationTitle,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (PrayerNotificationScheduler.supported) ...[
                const SizedBox(height: 10),
                Material(
                  color: tileSurface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openPrayerSoundPicker(prefs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: accent.withValues(alpha: 0.88),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.prayerSoundPickerTitle,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subduedIcon),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (!PrayerNotificationScheduler.supported) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.reminderLocalNotificationUnavailable,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reminderSectionTitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (displayOn)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: InkWell(
                              onTap: PrayerNotificationScheduler.supported
                                  ? () => _changeMinutesOnly(prefs)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Text(
                                _reminderCardSubtitle(l10n),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: accent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: accent.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: displayOn,
                    activeThumbColor: accent,
                    onChanged: PrayerNotificationScheduler.supported
                        ? _onFullSwitch
                        : null,
                  ),
                ],
              ),
              if (displayOn && PrayerNotificationScheduler.supported) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.reminderTwoAlertsPerPrayer,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...List.generate(PrayerReminderPrefs.slotCount, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _editPrayerReminderAt(context, prefs, i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: slotSurface,
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _prayerSlotLabel(l10n, i),
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _pairLineForPrayer(prefs, i, l10n),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: subduedIcon,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}
