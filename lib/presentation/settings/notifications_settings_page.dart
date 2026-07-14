// Ayarlar → Bildirimler: merkezi hatırlatıcı paneli (namaz detayı ayrı rota).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/models/prayer_times_model.dart';
import '../../data/services/app_local_notification_scheduler.dart';
import '../../data/services/app_notification_channel_prefs.dart';
import '../../data/services/arin_local_notifications_plugin.dart';
import '../../data/services/background_location_task.dart';
import '../../data/services/fcm_token_service.dart';
import '../../data/services/local_notification_permission_gate.dart';
import '../../data/services/location_service.dart';
import '../../data/services/prayer_reminder_prefs.dart';
import '../../data/services/prayer_service_resolver.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/quotes_providers.dart';
import '../shared/widgets/arin_clock_time_sheet.dart';
import 'widgets/permission_gate_card.dart';

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<NotificationsSettingsPage>
    with WidgetsBindingObserver {
  NotificationPermissionSnapshot? _snapshot;
  int _pendingCount = 0;
  bool _loading = true;
  late bool _backgroundLocationEnabled;
  bool _backgroundLocationBusy = false;
  bool _syncBroadcastAfterSettingsReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final loc = ref.read(locationServiceProvider);
    _backgroundLocationEnabled =
        loc.locationUpdatePref == LocationUpdatePref.alwaysUpdate;
    _refreshDiagnostics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final shouldSync = _syncBroadcastAfterSettingsReturn;
      _syncBroadcastAfterSettingsReturn = false;
      _refreshAfterResume(shouldSync: shouldSync);
    }
  }

  Future<void> _refreshAfterResume({required bool shouldSync}) async {
    if (shouldSync) {
      await FcmTokenService.syncBroadcastSubscriptionIfAuthorized();
    }
    await _refreshDiagnostics();
  }

  /// Üç iznin durumunu + AlarmManager kuyruk sayısını aynı turda toplar.
  /// Kuyruk sayısı > 0 ve çalmıyorsa suçlu %99 pil optimizasyonu veya OEM.
  Future<void> _refreshDiagnostics() async {
    final snap = await readNotificationPermissionSnapshot(
      arinLocalNotificationsPlugin,
    );
    final pending = await AppLocalNotificationScheduler.pendingScheduleCount();
    if (mounted) {
      setState(() {
        _snapshot = snap;
        _pendingCount = pending;
        _loading = false;
      });
    }
  }

  Future<void> _openOsSettings() async {
    HapticFeedback.selectionClick();
    _syncBroadcastAfterSettingsReturn = true;
    final opened = await openAppSettings();
    if (!opened) {
      _syncBroadcastAfterSettingsReturn = false;
      if (mounted) await _refreshDiagnostics();
    }
  }

  Future<void> _requestExactAlarm() async {
    HapticFeedback.selectionClick();
    await requestLocalNotificationRuntimePermissions(
      arinLocalNotificationsPlugin,
    );
    await FcmTokenService.syncBroadcastSubscriptionIfAuthorized();
    if (mounted) await _refreshDiagnostics();
  }

  Future<void> _requestBatteryExemption() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationsBatteryRationaleTitle),
        content: Text(l10n.notificationsBatteryRationaleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.notificationsBatteryRationaleCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.notificationsBatteryRationaleConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await requestIgnoreBatteryOptimizations();
    if (mounted) await _refreshDiagnostics();
  }

  /// Google Play "Arka Planda Konum" politikası — sistem izin penceresinden
  /// ÖNCE, uygulama içinde ayrı bir "prominent disclosure" gösterilmesini
  /// zorunlu kılıyor. Kullanıcı bu ekranda "Devam Et" demeden sistem izni
  /// hiç istenmez.
  Future<bool> _confirmBackgroundLocationDisclosure() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.backgroundLocationDisclosureTitle),
        content: Text(l10n.backgroundLocationDisclosureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.backgroundLocationDisclosureDecline),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.backgroundLocationDisclosureAccept),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// "Arka planda otomatik güncelle" anahtarı. Açılırken önce yukarıdaki
  /// disclosure gösterilir, kullanıcı onaylarsa Android 10+'ta "Her Zaman
  /// İzin Ver" konum izni istenir (yalnızca ön plan izni yeterli değil —
  /// WorkManager/BGTaskScheduler görevleri uygulama kapalıyken çalışır).
  /// İzin verilmezse tercih `ask`'e geri döner ve kullanıcı bilgilendirilir.
  Future<void> _onToggleBackgroundLocation(bool enable) async {
    if (_backgroundLocationBusy) return;
    setState(() => _backgroundLocationBusy = true);
    final loc = ref.read(locationServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    try {
      if (enable) {
        final agreed = await _confirmBackgroundLocationDisclosure();
        if (!agreed) {
          if (!mounted) return;
          setState(() => _backgroundLocationEnabled = false);
          return;
        }
        if (!mounted) return;
        var status = await Permission.locationAlways.status;
        if (!status.isGranted) {
          status = await Permission.locationAlways.request();
        }
        if (!status.isGranted) {
          if (!mounted) return;
          setState(() => _backgroundLocationEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsBackgroundLocationPermissionDenied),
            ),
          );
          return;
        }
        await loc.setLocationUpdatePref(LocationUpdatePref.alwaysUpdate);
        await BackgroundLocationTask.syncSchedule(loc);
        if (!mounted) return;
        setState(() => _backgroundLocationEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBackgroundLocationEnabledMessage)),
        );
      } else {
        await loc.setLocationUpdatePref(LocationUpdatePref.ask);
        await BackgroundLocationTask.syncSchedule(loc);
        if (!mounted) return;
        setState(() => _backgroundLocationEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBackgroundLocationDisabledMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _backgroundLocationBusy = false);
    }
  }

  String _notificationLabel() {
    final l10n = AppLocalizations.of(context)!;
    final s = _snapshot;
    if (_loading || s == null) return l10n.generalLoading;
    switch (s.notifications) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return l10n.notificationsPermissionGranted;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return l10n.notificationsPermissionDenied;
      case PermissionStatus.restricted:
        return l10n.notificationsPermissionLimited;
    }
  }

  static String _formatClock(int minutesFromMidnight) {
    final h = minutesFromMidnight ~/ 60;
    final m = minutesFromMidnight % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Pool sync artık scheduler'ın içinde fire-and-forget; burada pre-sync AWAIT
  /// etmek Firestore offline iken toggle/saat seçimini 30 sn'ye kadar bloke
  /// ediyordu (kullanıcı şikayeti: saati kurdum, bildirim gelmiyor). Senkron
  /// yolda yalnız `rescheduleAll` bırakılır; force ile soğutma by-pass.
  Future<void> _syncAppNotifications(SharedPreferences prefs) async {
    final pools = ref.read(quotePoolsRepositoryProvider);
    final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
    List<PrayerTimesModel>? upcomingDays;
    try {
      final resolver = ref.read(prayerServiceResolverProvider);
      final list = await resolver.fetchUpcomingDays(days: 7);
      if (list.isNotEmpty) upcomingDays = list;
    } catch (e) {
      debugPrint('_syncAppNotifications upcoming fetch failed: $e');
    }
    await AppLocalNotificationScheduler.rescheduleAll(
      prefs,
      pools: pools,
      prayerTimes: (upcomingDays != null && upcomingDays.isNotEmpty) ? upcomingDays.first : prayerTimes,
      upcomingDays: upcomingDays,
      force: true,
    );
  }

  /// Önce prefs diske yazılır ve UI hemen güncellenir; ardından bildirim yeniden
  /// planlanır. Sync ağ/Firestore gecikmesinde anahtarın takılı kalmasını önler.
  Future<void> _applyPrefsAndSync(
    SharedPreferences prefs,
    Future<void> Function() savePrefs,
  ) async {
    await savePrefs();
    if (mounted) setState(() {});
    try {
      await _syncAppNotifications(prefs);
    } catch (e, st) {
      debugPrint('Ntf sync failed: $e\n$st');
    }
    if (mounted) {
      await _refreshDiagnostics();
    }
  }

  Future<void> _pickZikirTime(SharedPreferences prefs) async {
    if (!mounted) return;
    final initial = AppNotificationChannelPrefs.zikirQuoteMinutesFromMidnight(
      prefs,
    );
    final picked = await showArinClockTimeSheet(
      context,
      initialMinutesFromMidnight: initial,
      title: AppLocalizations.of(context)!.notificationsZikirTimePickerTitle,
      subtitle: AppLocalizations.of(context)!.notificationsZikirTimePickerSubtitle,
    );
    if (picked == null || !mounted) return;
    await _applyPrefsAndSync(
      prefs,
      () => AppNotificationChannelPrefs.setZikirQuoteMinutesFromMidnight(
        prefs,
        picked,
      ),
    );
    HapticFeedback.selectionClick();
  }

  /// Seçilen saat bugün için geçtiyse bir sonraki tetik yarındır; kullanıcılar
  /// "saati kurdum bildirim gelmiyor" derken çoğu zaman bu durumdadır. Canlı
  /// olarak bir sonraki çalma zamanını saniye/dakika/saat farkıyla gösterir.
  String _nextZikirFireText(int minutesFromMidnight) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final h = minutesFromMidnight ~/ 60;
    final m = minutesFromMidnight % 60;
    var when = DateTime(now.year, now.month, now.day, h, m);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    final diff = when.difference(now);
    final clock =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    final sameDay =
        when.year == now.year && when.month == now.month && when.day == now.day;
    final dayLabel = sameDay
        ? l10n.notificationsNextReminderToday
        : l10n.notificationsNextReminderTomorrow;
    String humanGap() {
      if (diff.inMinutes < 1) return l10n.notificationsNextReminderUnderMinute;
      if (diff.inHours < 1) return l10n.notificationsNextReminderMinutes(diff.inMinutes);
      final hh = diff.inHours;
      final mm = diff.inMinutes % 60;
      if (mm == 0) return l10n.notificationsNextReminderHoursOnly(hh);
      return l10n.notificationsNextReminderHoursMinutes(hh, mm);
    }

    return l10n.notificationsNextReminderLine(dayLabel, clock, humanGap());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(sharedPreferencesProvider);
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;

    final prayerOn = PrayerReminderPrefs.isEnabled(prefs);
    final dailyOn = AppNotificationChannelPrefs.arinmaDailyEnabled(prefs);
    final zikirOn = AppNotificationChannelPrefs.zikirQuoteEnabled(prefs);
    final zikirClock = _formatClock(
      AppNotificationChannelPrefs.zikirQuoteMinutesFromMidnight(prefs),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          const Positioned.fill(child: _NotificationsAmbientLayer()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: onDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor.withValues(alpha: 0.88),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.notificationsHubTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn(duration: 280.ms, curve: Curves.easeOut),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroHeader(
                          onDark: onDark,
                          titleColor: titleColor,
                          muted: muted,
                          headline: l10n.notificationsHubHeadline,
                          subhead: l10n.notificationsHubSubhead,
                        )
                        .animate()
                        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 480.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 22),
                    _SectionLabel(
                      text: l10n.notificationsSectionGeneral,
                      color: muted,
                    ).animate().fadeIn(delay: 40.ms),
                    const SizedBox(height: 10),
                    _NtfGlassCard(
                          onDark: onDark,
                          child: PermissionGateCard(
                            onDark: onDark,
                            snapshot: _snapshot,
                            loading: _loading,
                            pendingCount: _pendingCount,
                            notificationLabel: _notificationLabel(),
                            onOpenOsSettings: _openOsSettings,
                            onRequestExactAlarm: _requestExactAlarm,
                            onRequestBattery: _requestBatteryExemption,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 60.ms)
                        .slideX(
                          begin: 0.02,
                          end: 0,
                          delay: 60.ms,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 26),
                    _SectionLabel(
                      text: l10n.notificationsSectionPrayer,
                      color: muted,
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 10),
                    _NtfNavTile(
                      onDark: onDark,
                      icon: Icons.mosque_outlined,
                      title: l10n.notificationsPrayerRowTitle,
                      subtitle: prayerOn
                          ? l10n.notificationsPrayerOnSubtitle
                          : l10n.notificationsPrayerOffSubtitle,
                      delayMs: 100,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRoutes.settingsNotificationsPrayer);
                      },
                    ),
                    const SizedBox(height: 12),
                    _NtfGlassCard(
                          onDark: onDark,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _NtfSwitchRow(
                                  onDark: onDark,
                                  title: l10n.settingsBackgroundLocationTitle,
                                  subtitle:
                                      l10n.settingsBackgroundLocationSubtitle,
                                  value: _backgroundLocationEnabled,
                                  onChanged: _backgroundLocationBusy
                                      ? (_) {}
                                      : (v) => _onToggleBackgroundLocation(v),
                                ),
                              ),
                              if (_backgroundLocationBusy) ...[
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 110.ms)
                        .slideX(
                          begin: 0.02,
                          end: 0,
                          delay: 110.ms,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 26),
                    _SectionLabel(
                      text: l10n.notificationsSectionArinma,
                      color: muted,
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 10),
                    _NtfGlassCard(
                          onDark: onDark,
                          child: Column(
                            children: [
                              _NtfSwitchRow(
                                onDark: onDark,
                                title: l10n.notificationsArinmaDailyTitle,
                                subtitle:
                                    l10n.notificationsArinmaDailySubtitle,
                                value: dailyOn,
                                onChanged: (v) async {
                                  HapticFeedback.selectionClick();
                                  await _applyPrefsAndSync(
                                    prefs,
                                    () =>
                                        AppNotificationChannelPrefs.setArinmaDailyEnabled(
                                          prefs,
                                          v,
                                        ),
                                  );
                                },
                              ),
                              const Divider(height: 22),
                              _NtfSwitchRow(
                                onDark: onDark,
                                title: l10n.notificationsMilestoneTitle,
                                subtitle:
                                    l10n.notificationsMilestoneSubtitle,
                                value:
                                    AppNotificationChannelPrefs.milestoneEnabled(
                                      prefs,
                                    ),
                                onChanged: (v) async {
                                  HapticFeedback.selectionClick();
                                  await _applyPrefsAndSync(
                                    prefs,
                                    () =>
                                        AppNotificationChannelPrefs.setMilestoneEnabled(
                                          prefs,
                                          v,
                                        ),
                                  );
                                },
                              ),
                              const Divider(height: 22),
                              _NtfSwitchRow(
                                onDark: onDark,
                                title: l10n.notificationsTaskTitle,
                                subtitle: l10n.notificationsTaskSubtitle,
                                value:
                                    AppNotificationChannelPrefs.taskReminderEnabled(
                                      prefs,
                                    ),
                                onChanged: (v) async {
                                  HapticFeedback.selectionClick();
                                  await _applyPrefsAndSync(
                                    prefs,
                                    () =>
                                        AppNotificationChannelPrefs.setTaskReminderEnabled(
                                          prefs,
                                          v,
                                        ),
                                  );
                                },
                              ),
                              const Divider(height: 22),
                              _NtfSwitchRow(
                                onDark: onDark,
                                title: l10n.notificationsZikirTitle,
                                subtitle: l10n.notificationsZikirSubtitle,
                                value: zikirOn,
                                onChanged: (v) async {
                                  HapticFeedback.selectionClick();
                                  await _applyPrefsAndSync(
                                    prefs,
                                    () =>
                                        AppNotificationChannelPrefs.setZikirQuoteEnabled(
                                          prefs,
                                          v,
                                        ),
                                  );
                                },
                              ),
                              if (zikirOn) ...[
                                const Divider(height: 22),
                                InkWell(
                                  onTap: () => _pickZikirTime(prefs),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.self_improvement_rounded,
                                          size: 20,
                                          color: onDark
                                              ? AppColors.accentNeonGreen
                                              : AppColors.emeraldMid,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.notificationsZikirTimeLabel,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: onDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.85,
                                                    )
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          zikirClock,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: onDark
                                                ? AppColors.accentNeonGreen
                                                : AppColors.emeraldDark,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: onDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.3,
                                                )
                                              : AppColors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 30,
                                    right: 4,
                                    top: 2,
                                  ),
                                  child: Text(
                                    _nextZikirFireText(
                                      AppNotificationChannelPrefs.zikirQuoteMinutesFromMidnight(
                                        prefs,
                                      ),
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: onDark
                                          ? Colors.white.withValues(alpha: 0.55)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 140.ms)
                        .slideX(
                          begin: 0.02,
                          end: 0,
                          delay: 140.ms,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.notificationsHealthDisclaimer,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: muted.withValues(alpha: 0.92),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onDark,
    required this.titleColor,
    required this.muted,
    required this.headline,
    required this.subhead,
  });

  final bool onDark;
  final Color titleColor;
  final Color muted;
  final String headline;
  final String subhead;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentNeonGreen.withValues(
                  alpha: onDark ? 0.35 : 0.5,
                ),
                AppColors.emeraldMid.withValues(alpha: onDark ? 0.2 : 0.35),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: onDark ? 0.12 : 0.35),
            ),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: onDark ? AppColors.creamBase : Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.15,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subhead,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _NtfGlassCard extends StatelessWidget {
  const _NtfGlassCard({required this.onDark, required this.child});

  final bool onDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.55);
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.72);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: fill,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: onDark ? 0.22 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NtfNavTile extends StatelessWidget {
  const _NtfNavTile({
    required this.onDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delayMs,
    required this.onTap,
  });

  final bool onDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final int delayMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.55);
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.72);

    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: fill,
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: onDark ? 0.2 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onDark
                          ? AppColors.accentNeonGreen.withValues(alpha: 0.15)
                          : AppColors.emeraldDark.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      icon,
                      color: onDark
                          ? AppColors.accentNeonGreen
                          : AppColors.emeraldDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: onDark
                                ? Colors.white
                                : AppColors.emeraldDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: onDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delayMs),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.03,
          end: 0,
          delay: Duration(milliseconds: delayMs),
          duration: 440.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _NtfSwitchRow extends StatelessWidget {
  const _NtfSwitchRow({
    required this.onDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final bool onDark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onDark ? Colors.white : AppColors.emeraldDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: onDark
                      ? AppColors.textOnDarkMuted
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentNeonGreen;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.emeraldMid.withValues(alpha: 0.55);
            }
            return null;
          }),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// _PermissionGateCard + _gateChip Faz 2'de ayrı bir dosyaya taşındı:
//   lib/presentation/settings/widgets/permission_gate_card.dart
// Monolit dosyayı ~200 satır hafifletti. Yeni widget public
// `PermissionGateCard` olarak import ediliyor (yukarıda).
// ──────────────────────────────────────────────────────────────────────

class _NotificationsAmbientLayer extends StatelessWidget {
  const _NotificationsAmbientLayer();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0.25, -0.42),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (light ? AppColors.emeraldMid : AppColors.accentPurple)
                        .withValues(alpha: light ? 0.07 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Transform.translate(
              offset: const Offset(-40, -40),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentNeonGreen.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
