import 'package:flutter/material.dart';

import '../../../data/services/admin_notification_diagnostics_log.dart';
import '../../../l10n/app_localizations.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

bool _isSkipLikeOutcome(String outcome) {
  return outcome == 'cooldown_skip' ||
      outcome == 'pending_guard_skip' ||
      outcome == 'disabled' ||
      outcome == 'skip_invalid_payload';
}

Color _outcomeColor(String outcome) {
  if (outcome == 'ok') return Colors.greenAccent;
  if (outcome == 'error') return Colors.redAccent;
  if (_isSkipLikeOutcome(outcome)) return Colors.lightBlueAccent;
  return Colors.white70;
}

IconData _outcomeIcon(String outcome) {
  if (outcome == 'ok') return Icons.check_circle_outline;
  if (outcome == 'error') return Icons.error_outline_rounded;
  if (_isSkipLikeOutcome(outcome)) return Icons.info_outline_rounded;
  return Icons.help_outline_rounded;
}

Widget _diagnosticPill({
  required Color color,
  required String label,
  IconData icon = Icons.circle,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.95),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

({Color color, String label, String detail}) _diagnosticHealth({
  required bool prayerOn,
  required bool appDaily,
  required bool appMilestone,
  required bool appTask,
  required bool appZikir,
  required int pendingCount,
  required List<NotificationDiagnosticsEntry> logs,
}) {
  final last = logs.isEmpty ? null : logs.first;
  if (last?.outcome == 'error') {
    return (
      color: Colors.redAccent,
      label: 'Hata',
      detail:
          'Son bildirim olayı hata döndürmüş: ${last!.source} · ${last.action}',
    );
  }
  final anyChannelOn =
      prayerOn || appDaily || appMilestone || appTask || appZikir;
  if (!anyChannelOn) {
    return (
      color: Colors.amber,
      label: 'Kapalı',
      detail:
          'Tüm bildirim kanalları kapalı görünüyor; pending sayısı düşük olabilir.',
    );
  }
  if (pendingCount <= 0) {
    return (
      color: Colors.amber,
      label: 'Kontrol et',
      detail: 'Bildirim kanalı açık ama cihazda bekleyen planlama görünmüyor.',
    );
  }
  if (last != null && _isSkipLikeOutcome(last.outcome)) {
    return (
      color: Colors.lightBlueAccent,
      label: 'Atlandı',
      detail: 'Son olay bilinçli skip: ${last.source} · ${last.action}.',
    );
  }
  return (
    color: Colors.greenAccent,
    label: 'Sağlıklı',
    detail: 'Kanallar açık, pending bildirim var ve son hata görünmüyor.',
  );
}

Widget _channelTile(String label, bool enabled) {
  final color = enabled ? Colors.greenAccent : Colors.white54;
  return Chip(
    avatar: Icon(
      enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
      color: color,
      size: 16,
    ),
    label: Text(label),
    backgroundColor: color.withValues(alpha: enabled ? 0.14 : 0.08),
    side: BorderSide(color: color.withValues(alpha: 0.35)),
  );
}

String _outcomeLabel(AppLocalizations l10n, String outcome) {
  switch (outcome) {
    case 'ok':
      return l10n.adminDiagnosticsOutcomeOk;
    case 'error':
      return l10n.adminDiagnosticsOutcomeError;
    case 'cooldown_skip':
      return l10n.adminDiagnosticsOutcomeCooldownSkip;
    case 'pending_guard_skip':
      return l10n.adminDiagnosticsOutcomePendingGuardSkip;
    case 'disabled':
      return l10n.adminDiagnosticsOutcomeDisabled;
    case 'skip_invalid_payload':
      return l10n.adminDiagnosticsOutcomeInvalidPayloadSkip;
    default:
      return l10n.adminDiagnosticsOutcomeUnknown(outcome);
  }
}

class AdminDiagnosticsTab extends StatelessWidget {
  const AdminDiagnosticsTab({
    super.key,
    required this.bottomInset,
    required this.prayerOn,
    required this.appDaily,
    required this.appMilestone,
    required this.appTask,
    required this.appZikir,
    required this.pendingCount,
    required this.loading,
    required this.logs,
    required this.onRefresh,
    required this.onExport,
    required this.onClear,
    required this.formatTime,
  });

  final double bottomInset;
  final bool prayerOn;
  final bool appDaily;
  final bool appMilestone;
  final bool appTask;
  final bool appZikir;
  final int pendingCount;
  final bool loading;
  final List<NotificationDiagnosticsEntry> logs;
  final VoidCallback onRefresh;
  final VoidCallback onExport;
  final VoidCallback onClear;
  final String Function(String iso) formatTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final health = _diagnosticHealth(
      prayerOn: prayerOn,
      appDaily: appDaily,
      appMilestone: appMilestone,
      appTask: appTask,
      appZikir: appZikir,
      pendingCount: pendingCount,
      logs: logs,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.adminDiagnosticsHint,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Card(
              color: const Color(0xFF0F2419),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bildirim sağlık durumu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _diagnosticPill(
                          color: health.color,
                          label: health.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      health.detail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _channelTile('Namaz', prayerOn),
                        _channelTile('Günlük', appDaily),
                        _channelTile('Milestone', appMilestone),
                        _channelTile('Görev', appTask),
                        _channelTile('Zikir', appZikir),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.adminDiagnosticsStatusSummaryTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminDiagnosticsPrayerStatus(
                        prayerOn
                            ? l10n.adminDiagnosticsEnabled
                            : l10n.adminDiagnosticsDisabled,
                      ),
                    ),
                    Text(
                      l10n.adminDiagnosticsDailyStatus(
                        appDaily
                            ? l10n.adminDiagnosticsEnabled
                            : l10n.adminDiagnosticsDisabled,
                      ),
                    ),
                    Text(
                      l10n.adminDiagnosticsMilestoneStatus(
                        appMilestone
                            ? l10n.adminDiagnosticsEnabled
                            : l10n.adminDiagnosticsDisabled,
                      ),
                    ),
                    Text(
                      l10n.adminDiagnosticsTaskStatus(
                        appTask
                            ? l10n.adminDiagnosticsEnabled
                            : l10n.adminDiagnosticsDisabled,
                      ),
                    ),
                    Text(
                      l10n.adminDiagnosticsZikirStatus(
                        appZikir
                            ? l10n.adminDiagnosticsEnabled
                            : l10n.adminDiagnosticsDisabled,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.adminDiagnosticsPendingQueue(pendingCount)),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: loading ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: ArinLoader(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(l10n.adminRefreshAction),
                ),
                OutlinedButton.icon(
                  onPressed: loading || logs.isEmpty ? null : onExport,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l10n.adminDiagnosticsExportLog),
                ),
                OutlinedButton.icon(
                  onPressed: loading || logs.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.adminDiagnosticsClearLog),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.adminDiagnosticsRecentEvents(logs.length),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(top: 8),
          sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
        if (logs.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: const Color(0xFF0F2419),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.adminDiagnosticsNoLogsHint,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
            sliver: SliverList.builder(
              itemCount: logs.length,
              itemBuilder: (context, i) {
                final entry = logs[i];
                final outcomeColor = _outcomeColor(entry.outcome);
                final outcomeIcon = _outcomeIcon(entry.outcome);
                return Card(
                  color: const Color(0xFF0F2419),
                  child: ListTile(
                    dense: true,
                    leading: Icon(outcomeIcon, color: outcomeColor),
                    title: Text('${entry.source} · ${entry.action}'),
                    subtitle: Text(
                      '${formatTime(entry.atIso)}\n${entry.detailsText()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      _outcomeLabel(l10n, entry.outcome),
                      style: TextStyle(
                        color: outcomeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
