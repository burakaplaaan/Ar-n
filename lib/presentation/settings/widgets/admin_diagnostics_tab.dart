import 'package:flutter/material.dart';

import '../../../data/services/admin_notification_diagnostics_log.dart';
import '../../../l10n/app_localizations.dart';

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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                    leading: Icon(
                      outcomeIcon,
                      color: outcomeColor,
                    ),
                    title: Text('${entry.source} · ${entry.action}'),
                    subtitle: Text(
                      '${formatTime(entry.atIso)}\n${entry.detailsText()}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
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
