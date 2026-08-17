// Admin panel — namaz vakit test kaydırması + anlık bildirim testleri.

import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/services/admin_dev_prefs.dart';
import '../../data/services/admob_service.dart';
import '../../data/services/app_local_notification_scheduler.dart';
import '../../data/services/arin_local_notifications_plugin.dart';
import '../../data/services/location_service.dart';
import '../../data/services/prayer_notification_scheduler.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/prayer_time_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

/// [ArinShell] alt barı için alt boşluk.
double _shellBodyBottomInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom + 80;
}

class AdminDevTab extends ConsumerStatefulWidget {
  const AdminDevTab({super.key});

  @override
  ConsumerState<AdminDevTab> createState() => _AdminDevTabState();
}

class _AdminDevTabState extends ConsumerState<AdminDevTab> {
  late double _offsetSlider;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      final prefs = ref.read(sharedPreferencesProvider);
      _offsetSlider = AdminDevPrefs.prayerOffsetMinutes(prefs).toDouble();
    }
  }

  Future<void> _saveOffsetAndReschedule() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(sharedPreferencesProvider);
    await AdminDevPrefs.setPrayerOffsetMinutes(prefs, _offsetSlider.round());
    ref.invalidate(prayerTimesProvider);
    await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
      prefs: prefs,
      aladhan: ref.read(aladhanServiceProvider),
      location: ref.read(locationServiceProvider),
      force: true,
    );
    if (!mounted) return;
    showArinTopToast(context, l10n.adminDevOffsetSavedAndRescheduled);
  }

  Future<void> _resetOffset() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(sharedPreferencesProvider);
    await AdminDevPrefs.setPrayerOffsetMinutes(prefs, 0);
    setState(() => _offsetSlider = 0);
    ref.invalidate(prayerTimesProvider);
    await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
      prefs: prefs,
      aladhan: ref.read(aladhanServiceProvider),
      location: ref.read(locationServiceProvider),
      force: true,
    );
    if (!mounted) return;
    showArinTopToast(context, l10n.adminDevOffsetReset);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = _shellBodyBottomInset(context);
    final label = _offsetSlider == 0
        ? l10n.adminDevOffsetDisabled
        : _offsetSlider < 0
        ? l10n.adminDevOffsetForwardMinutes((-_offsetSlider).round())
        : l10n.adminDevOffsetBackwardMinutes(_offsetSlider.round());

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 8),
      children: [
        Card(
          color: const Color(0xFF0F2419),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu sekme içerik yönetimi değil, teknik test alanıdır. Offset sadece bu cihazı etkiler; Crashlytics ve fatal crash butonları gerçek test sinyali üretir.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _DiagnosticsCard(),
        const SizedBox(height: 20),
        Text(
          l10n.adminDevPrayerOffsetTitle,
          style: TextStyle(
            color: AppColors.creamBase.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminDevPrayerOffsetSubtitle,
          style: const TextStyle(
            color: AppColors.textOnDarkMuted,
            height: 1.35,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          min: AdminDevPrefs.minOffsetMinutes.toDouble(),
          max: AdminDevPrefs.maxOffsetMinutes.toDouble(),
          divisions: 360,
          value: _offsetSlider.clamp(
            AdminDevPrefs.minOffsetMinutes.toDouble(),
            AdminDevPrefs.maxOffsetMinutes.toDouble(),
          ),
          onChanged: (v) => setState(() => _offsetSlider = v),
        ),
        Row(
          children: [
            TextButton(
              onPressed: _resetOffset,
              child: Text(l10n.adminDevResetAction),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saveOffsetAndReschedule,
              child: Text(l10n.adminDevSaveAndRescheduleAction),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l10n.adminDevNotificationTestsTitle,
          style: TextStyle(
            color: AppColors.creamBase.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminDevNotificationTestsSubtitle,
          style: const TextStyle(
            color: AppColors.textOnDarkMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () async {
            final prefs = ref.read(sharedPreferencesProvider);
            final err =
                await PrayerNotificationScheduler.showImmediateTestPrayerNotification(
                  prefs,
                );
            if (!mounted) return;
            showArinTopToast(context, err ?? l10n.adminDevPrayerNotificationSent);
          },
          child: Text(l10n.adminDevPrayerNotificationNowAction),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () async {
            final err =
                await AppLocalNotificationScheduler.showImmediateTestAppNotification();
            if (!mounted) return;
            showArinTopToast(context, err ?? l10n.adminDevAppNotificationSent);
          },
          child: Text(l10n.adminDevAppNotificationNowAction),
        ),
        const SizedBox(height: 28),
        Text(
          'AdMob Ad Inspector',
          style: TextStyle(
            color: AppColors.creamBase.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mediation doğrulama: Unity Ads (Bidding) / Meta Audience Network single ad source. Onboarding bitmiş ve SDK init olmuş olmalı.',
          style: TextStyle(
            color: AppColors.textOnDarkMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () async {
            showArinTopToast(context, 'Ad Inspector açılıyor…');
            final err = await AdMobService.openAdInspector();
            if (!mounted) return;
            if (err != null) {
              showArinTopToast(context, err);
            }
          },
          child: const Text('Ad Inspector aç'),
        ),
        const SizedBox(height: 28),
        Card(
          color: Colors.redAccent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aşağıdaki Crashlytics işlemleri production gözlemleme araçlarına test verisi gönderir. Fatal crash uygulamayı bilerek kapatır.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.adminDevCrashlyticsTestTitle,
          style: TextStyle(
            color: AppColors.creamBase.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          kDebugMode
              ? l10n.adminDevCrashlyticsDebugHint
              : l10n.adminDevCrashlyticsReleaseHint,
          style: const TextStyle(
            color: AppColors.textOnDarkMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () async {
            if (!isFirebaseReady) {
              showArinTopToast(context, l10n.adminFirebaseNotReady);
              return;
            }
            try {
              await FirebaseCrashlytics.instance.recordError(
                StateError('ARIN admin test non-fatal'),
                StackTrace.current,
                reason: 'Admin Dev tab — test non-fatal',
                fatal: false,
              );
              if (!mounted) return;
              showArinTopToast(context, l10n.adminDevCrashlyticsNonFatalSent);
            } catch (e) {
              if (!mounted) return;
              showArinTopToast(context, l10n.adminErrorWithReason(e.toString()));
            }
          },
          child: Text(l10n.adminDevSendNonFatalTestAction),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          icon: const Icon(Icons.warning_amber_rounded),
          label: Text(l10n.adminDevCrashNowFatalAction),
          onPressed: () async {
            final proceed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.adminDevCrashDialogTitle),
                content: Text(l10n.adminDevCrashDialogBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.adminDevCrashAction),
                  ),
                ],
              ),
            );
            if (proceed != true) return;
            if (!isFirebaseReady) {
              showArinTopToast(context, l10n.adminFirebaseNotReady);
              return;
            }
            // crash() native tarafı çağırıp uygulamayı sonlandırır.
            FirebaseCrashlytics.instance.crash();
          },
        ),
      ],
    );
  }
}

/// Tanılama kartı: platform / build modu / uid / pending bildirim sayısı.
/// Admin hatası bildirdiğinde bu kart sayesinde "hangi cihaz, hangi mod,
/// kaç pending alarm var" hızlıca teyit edilir. Pending sayısı sadece
/// isteğe bağlı yenilenir (native read biraz pahalı, pasif izlemek zararsız).
class _DiagnosticsCard extends StatefulWidget {
  const _DiagnosticsCard();

  @override
  State<_DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<_DiagnosticsCard> {
  int? _pending;
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final list = await arinLocalNotificationsPlugin
          .pendingNotificationRequests();
      if (mounted) setState(() => _pending = list.length);
    } catch (_) {
      if (mounted) setState(() => _pending = -1);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildMode(AppLocalizations l10n) {
    if (kReleaseMode) return l10n.adminDevBuildModeRelease;
    if (kProfileMode) return l10n.adminDevBuildModeProfile;
    return l10n.adminDevBuildModeDebug;
  }

  String _platform(AppLocalizations l10n) {
    if (kIsWeb) return l10n.adminDevPlatformWeb;
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return l10n.adminDevPlatformUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: AppColors.accentNeonGreen.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.adminDiagnosticsTitle,
                style: TextStyle(
                  color: AppColors.creamBase.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.adminRefreshAction,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: ArinLoader(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: _loading ? null : _refresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DiagnosticRow(
            label: l10n.adminDevPlatformLabel,
            value: _platform(l10n),
          ),
          _DiagnosticRow(
            label: l10n.adminDevBuildLabel,
            value: _buildMode(l10n),
          ),
          _DiagnosticRow(
            label: l10n.adminDevUidLabel,
            value: uid == null ? '—' : '${uid.substring(0, 8)}…',
          ),
          _DiagnosticRow(
            label: l10n.adminDevPendingNotificationLabel,
            value: _pending == null
                ? l10n.adminDevTapToRefresh
                : _pending == -1
                ? l10n.adminDiagnosticsError
                : '$_pending',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
