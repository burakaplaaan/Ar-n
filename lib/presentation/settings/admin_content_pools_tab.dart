part of 'admin_content_page.dart';

String _localizedPoolLabel(AppLocalizations l10n, String poolId) {
  switch (poolId) {
    case QuotePoolIds.homeNamazWisdom:
      return l10n.adminPoolLabelHomeNamazWisdom;
    case QuotePoolIds.personalizedQuotes:
      return l10n.adminPoolLabelPersonalizedQuotes;
    case QuotePoolIds.widgetQuote:
      return l10n.adminPoolLabelWidgetQuote;
    case QuotePoolIds.zikirDailyReflections:
      return l10n.adminPoolLabelZikirDailyReflections;
    case QuotePoolIds.healingComfort:
      return l10n.adminPoolLabelHealingComfort;
    case QuotePoolIds.hubGelisimIslamic:
      return l10n.adminPoolLabelHubGelisimIslamic;
    case QuotePoolIds.hubGelisimMedical:
      return l10n.adminPoolLabelHubGelisimMedical;
    case QuotePoolIds.hubArinmaIslamic:
      return l10n.adminPoolLabelHubArinmaIslamic;
    case QuotePoolIds.hubArinmaMedical:
      return l10n.adminPoolLabelHubArinmaMedical;
    case QuotePoolIds.notificationArinmaBodies:
      return l10n.adminPoolLabelNotificationArinmaBodies;
    default:
      return poolId;
  }
}

Widget _buildAdminPoolsTab({
  required BuildContext context,
  required double bottomInset,
  required List<Map<String, dynamic>> allItems,
  required List<Map<String, dynamic>> items,
  required List<int> itemIndices,
  required String poolId,
  required Map<String, dynamic>? poolDoc,
  required String? poolError,
  required String poolSearch,
  required bool poolLoading,
  required bool seedingAll,
  required bool canSeedMissingPools,
  required bool canResetAllPools,
  required ValueChanged<String> onPoolChanged,
  required VoidCallback onSeedDefaults,
  required VoidCallback onExportCurrentPool,
  required VoidCallback onImportPoolBackup,
  required VoidCallback onSeedAllMergeOnly,
  required VoidCallback onSeedAllReset,
  required ValueChanged<String> onSearchChanged,
  required VoidCallback onClearSearch,
  required VoidCallback onAddItem,
  required ValueChanged<int> onEditItem,
  required Future<void> Function(int realIndex, String preview) onDeleteItem,
}) {
  final l10n = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
        child: Text(
          l10n.adminPoolsHint,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: DropdownButtonFormField<String>(
          initialValue: poolId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.adminPoolsDropdownLabel(allItems.length),
            filled: true,
            fillColor: const Color(0xFF0F2419),
          ),
          dropdownColor: const Color(0xFF0F2419),
          selectedItemBuilder: (context) => QuotePoolIds.all
              .map(
                (id) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _localizedPoolLabel(l10n, id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          items: QuotePoolIds.all
              .map(
                (id) => DropdownMenuItem(
                  value: id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localizedPoolLabel(l10n, id),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        id,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onPoolChanged(v);
          },
        ),
      ),
      if (poolError != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            poolError,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white70,
              title: Text(
                l10n.adminAdvancedActionsTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: poolLoading ? null : onSeedDefaults,
                      child: Text(l10n.adminSeedSelectedPoolDefaults),
                    ),
                    OutlinedButton.icon(
                      onPressed: (poolLoading || seedingAll || poolDoc == null)
                          ? null
                          : onExportCurrentPool,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentNeonGreen,
                        side: BorderSide(
                          color: AppColors.accentNeonGreen.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(l10n.adminBackupCurrentPoolJson),
                    ),
                    OutlinedButton.icon(
                      onPressed: poolLoading || seedingAll
                          ? null
                          : onImportPoolBackup,
                      icon: const Icon(Icons.upload_file_rounded, size: 20),
                      label: Text(l10n.adminRestoreFromBackup),
                    ),
                    if (canSeedMissingPools)
                      FilledButton.tonalIcon(
                        onPressed: (poolLoading || seedingAll)
                            ? null
                            : onSeedAllMergeOnly,
                        icon: const Icon(Icons.merge_rounded, size: 18),
                        label: Text(l10n.adminAddMissingRecords),
                      ),
                    if (canResetAllPools)
                      FilledButton.tonal(
                        onPressed: (poolLoading || seedingAll)
                            ? null
                            : onSeedAllReset,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.18,
                          ),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: seedingAll
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(l10n.adminWritingInProgress),
                                ],
                              )
                            : Text(l10n.adminResetCompletely),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminVersionLabel(poolDoc?['version'] ?? '—'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.adminSearchInPoolHint(allItems.length),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: poolSearch.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: onClearSearch,
                        ),
                  filled: true,
                  fillColor: const Color(0xFF0F2419),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: poolLoading ? null : onAddItem,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.adminAddAction),
            ),
          ],
        ),
      ),
      if (poolSearch.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.adminSearchResultsCount(items.length),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ),
        ),
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    poolSearch.isEmpty
                        ? l10n.adminPoolEmptyHint
                        : l10n.adminSearchNoResults,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottomInset),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final m = items[i];
                  final realIndex = itemIndices[i];
                  final tTitle = m['title']?.toString().trim();
                  final preview = (tTitle != null && tTitle.isNotEmpty)
                      ? tTitle
                      : (m['turkish']?.toString() ??
                            m['text']?.toString() ??
                            '$m');
                  return Card(
                    color: const Color(0xFF0F2419),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentNeonGreen.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          '${realIndex + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accentNeonGreen.withValues(
                              alpha: 0.85,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        l10n.adminTapToEdit,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.52),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.adminEditTooltip,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: poolLoading
                                ? null
                                : () => onEditItem(realIndex),
                          ),
                          IconButton(
                            tooltip: l10n.settingsDeleteAction,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: poolLoading
                                ? null
                                : () => onDeleteItem(realIndex, preview),
                          ),
                        ],
                      ),
                      onTap: poolLoading ? null : () => onEditItem(realIndex),
                    ),
                  );
                },
              ),
      ),
    ],
  );
}
