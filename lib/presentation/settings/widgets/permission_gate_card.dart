// lib/presentation/settings/widgets/permission_gate_card.dart
//
// Bildirim Ayarları → Genel: üç izin ekseni + kuyruk sayısı tek bakışta.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/local_notification_permission_gate.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

class PermissionGateCard extends StatelessWidget {
  const PermissionGateCard({
    super.key,
    required this.onDark,
    required this.snapshot,
    required this.loading,
    required this.pendingCount,
    required this.notificationLabel,
    required this.onOpenOsSettings,
    required this.onRequestExactAlarm,
    required this.onRequestBattery,
  });

  final bool onDark;
  final NotificationPermissionSnapshot? snapshot;
  final bool loading;
  final int pendingCount;
  final String notificationLabel;
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(
          onDark: onDark,
          allGreen: allGreen,
          loading: loading,
          title: allGreen
              ? l10n.notificationsGateAllGood
              : l10n.notificationsGateMissing,
        ),
        const SizedBox(height: 14),
        _PermissionRow(
          onDark: onDark,
          icon: Icons.notifications_outlined,
          title: l10n.notificationsGateNotification,
          status: loading
              ? l10n.generalLoading
              : (ntfOk
                    ? notificationLabel
                    : l10n.notificationsPermissionDenied),
          ok: ntfOk,
          loading: loading,
          onTap: !loading && !ntfOk ? onOpenOsSettings : null,
        ),
        _rowDivider(onDark),
        _PermissionRow(
          onDark: onDark,
          icon: Icons.alarm_rounded,
          title: l10n.notificationsGateExactAlarm,
          status: loading
              ? l10n.generalLoading
              : (exactOk
                    ? l10n.notificationsPermissionGranted
                    : l10n.notificationsPermissionDenied),
          ok: exactOk,
          loading: loading,
          onTap: !loading && !exactOk ? onRequestExactAlarm : null,
        ),
        _rowDivider(onDark),
        _PermissionRow(
          onDark: onDark,
          icon: Icons.battery_charging_full_rounded,
          title: l10n.notificationsGateBattery,
          status: loading
              ? l10n.generalLoading
              : (batteryOk
                    ? l10n.notificationsPermissionGranted
                    : l10n.notificationsPermissionDenied),
          ok: batteryOk,
          loading: loading,
          onTap: !loading && !batteryOk ? onRequestBattery : null,
        ),
        const SizedBox(height: 14),
        _QueueFootnote(
          onDark: onDark,
          label: l10n.notificationsDiagnosticsQueuedLabel,
          count: pendingCount,
          loading: loading,
        ),
        const SizedBox(height: 12),
        _SettingsLink(
          onDark: onDark,
          label: l10n.notificationsOpenOsSettings,
          onTap: onOpenOsSettings,
        ),
      ],
    );
  }

  Widget _rowDivider(bool onDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: onDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppColors.creamDark.withValues(alpha: 0.45),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.onDark,
    required this.allGreen,
    required this.loading,
    required this.title,
  });

  final bool onDark;
  final bool allGreen;
  final bool loading;
  final String title;

  @override
  Widget build(BuildContext context) {
    final accent = allGreen ? AppColors.accentNeonGreen : AppColors.goldAccent;
    final bg = allGreen
        ? (onDark
              ? AppColors.accentNeonGreen.withValues(alpha: 0.1)
              : AppColors.emeraldFaint.withValues(alpha: 0.55))
        : (onDark
              ? AppColors.goldAccent.withValues(alpha: 0.1)
              : AppColors.goldAccent.withValues(alpha: 0.12));
    final border = accent.withValues(alpha: onDark ? 0.22 : 0.28);
    final fg = onDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.emeraldDark.withValues(alpha: 0.92);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: onDark ? 0.16 : 0.14),
            ),
            child: Icon(
              loading
                  ? Icons.hourglass_empty_rounded
                  : (allGreen
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded),
              size: 17,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.onDark,
    required this.icon,
    required this.title,
    required this.status,
    required this.ok,
    required this.loading,
    this.onTap,
  });

  final bool onDark;
  final IconData icon;
  final String title;
  final String status;
  final bool ok;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ok ? AppColors.accentNeonGreen : AppColors.goldAccent;
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.94)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textMuted;
    final tappable = onTap != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: onDark ? 0.12 : 0.1),
            ),
            child: Icon(icon, size: 18, color: accent.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ok ? muted : accent.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: ArinLoader(
                strokeWidth: 2,
                color: muted.withValues(alpha: 0.7),
              ),
            )
          else
            Icon(
              ok
                  ? Icons.check_circle_rounded
                  : (tappable
                        ? Icons.chevron_right_rounded
                        : Icons.error_outline_rounded),
              size: ok ? 20 : 22,
              color: ok
                  ? AppColors.accentNeonGreen.withValues(alpha: 0.9)
                  : (tappable
                        ? muted.withValues(alpha: 0.55)
                        : AppColors.goldAccent.withValues(alpha: 0.85)),
            ),
        ],
      ),
    );

    if (!tappable) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

class _QueueFootnote extends StatelessWidget {
  const _QueueFootnote({
    required this.onDark,
    required this.label,
    required this.count,
    required this.loading,
  });

  final bool onDark;
  final String label;
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textMuted;
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: muted.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            loading ? '…' : '$label: $count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: muted.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.onDark,
    required this.label,
    required this.onTap,
  });

  final bool onDark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.emeraldDark.withValues(alpha: 0.82);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.emeraldDark.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded, size: 14, color: fg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
