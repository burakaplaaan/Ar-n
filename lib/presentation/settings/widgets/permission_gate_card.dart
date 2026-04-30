// lib/presentation/settings/widgets/permission_gate_card.dart
//
// Bildirim Ayarları ekranının üstündeki "sağlık çubuğu": 3 iznin + pending
// AlarmManager kuyruk sayısının tek bakışta okunduğu yüzey. Eskiden
// `notifications_settings_page.dart` içinde 1170 satırlık monolitin
// parçasıydı — Faz 2'de bağımsız bir widget'a taşındı.
//
// Saf StatelessWidget; veri + callback'ler parent'tan gelir. Bu sayede
// test edilebilir, yeniden kullanılabilir ve parent ekran ~200 satır
// hafifledi.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/local_notification_permission_gate.dart';

class PermissionGateCard extends StatelessWidget {
  const PermissionGateCard({
    super.key,
    required this.onDark,
    required this.snapshot,
    required this.loading,
    required this.pendingCount,
    required this.notificationLabel,
    required this.chipColor,
    required this.chipFg,
    required this.onOpenOsSettings,
    required this.onRequestExactAlarm,
    required this.onRequestBattery,
  });

  final bool onDark;
  final NotificationPermissionSnapshot? snapshot;
  final bool loading;
  final int pendingCount;
  final String notificationLabel;
  final Color Function(bool ok, bool onDark) chipColor;
  final Color Function(bool ok, bool onDark) chipFg;
  final VoidCallback onOpenOsSettings;
  final VoidCallback onRequestExactAlarm;
  final VoidCallback onRequestBattery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = snapshot;
    final ntfOk = s?.notificationsAllowed ?? false;
    final exactOk = s?.exactAlarmsAllowed ?? false;
    final batteryOk = s?.batteryOptimizationsIgnored ?? false;
    final allGreen = ntfOk && exactOk && batteryOk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          allGreen
              ? l10n.notificationsGateAllGood
              : l10n.notificationsGateMissing,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: onDark
                ? Colors.white.withValues(alpha: 0.82)
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _gateChip(
              l10n.notificationsGateNotification,
              ntfOk,
              label: loading
                  ? l10n.generalLoading
                  : (ntfOk
                        ? notificationLabel
                        : l10n.notificationsPermissionDenied),
            ),
            _gateChip(
              l10n.notificationsGateExactAlarm,
              exactOk,
              label: loading
                  ? l10n.generalLoading
                  : (exactOk
                        ? l10n.notificationsPermissionGranted
                        : l10n.notificationsPermissionDenied),
            ),
            _gateChip(
              l10n.notificationsGateBattery,
              batteryOk,
              label: loading
                  ? l10n.generalLoading
                  : (batteryOk
                        ? l10n.notificationsPermissionGranted
                        : l10n.notificationsPermissionDenied),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${l10n.notificationsDiagnosticsQueuedLabel}: $pendingCount',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: pendingCount > 0
                ? (onDark
                      ? Colors.white.withValues(alpha: 0.78)
                      : AppColors.emeraldDark.withValues(alpha: 0.8))
                : (onDark ? AppColors.goldAccent : AppColors.goldAccent),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenOsSettings,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.78)
                      : AppColors.emeraldDark,
                ),
                label: Text(
                  l10n.notificationsOpenOsSettings,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.82)
                        : AppColors.emeraldDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.emeraldDark.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            if (!exactOk && !loading) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRequestExactAlarm,
                  icon: Icon(
                    Icons.alarm_rounded,
                    size: 18,
                    color: onDark
                        ? AppColors.goldAccent
                        : AppColors.emeraldDark,
                  ),
                  label: Text(
                    l10n.notificationsGateRequestExact,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: onDark
                          ? AppColors.goldAccent
                          : AppColors.emeraldDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
            if (!batteryOk && !loading) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRequestBattery,
                  icon: Icon(
                    Icons.battery_charging_full_rounded,
                    size: 18,
                    color: onDark
                        ? AppColors.goldAccent
                        : AppColors.emeraldDark,
                  ),
                  label: Text(
                    l10n.notificationsGateRequestBattery,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: onDark
                          ? AppColors.goldAccent
                          : AppColors.emeraldDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _gateChip(String axis, bool ok, {required String label}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chipColor(ok, onDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (ok
              ? (onDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.emeraldDark.withValues(alpha: 0.25))
              : (onDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.goldAccent.withValues(alpha: 0.25))),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 13,
              color: chipFg(ok, onDark),
            ),
            const SizedBox(width: 6),
            Text(
              '$axis · $label',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: chipFg(ok, onDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
