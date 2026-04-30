part of 'admin_content_page.dart';

Widget _buildAdminInspireTab({
  required BuildContext context,
  required double bottomInset,
  required bool inspireLoading,
  required String? inspireError,
  required List<_InspireFormRow> inspireRows,
  required Map<String, dynamic>? inspireDoc,
  required List<int> imageIndices,
  required VoidCallback onAddCard,
  required VoidCallback onRefreshFromServer,
  required Future<void> Function() onPullToRefresh,
  required ValueChanged<int> onDuplicateAt,
  required ValueChanged<int> onShuffleAt,
  required Future<void> Function(int index, String textPreview) onDeleteAt,
  required void Function(int index, InspirationContentKind kind) onKindChanged,
  required void Function(int index, bool on) onMainFeedChanged,
  required VoidCallback onSaveAll,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (inspireLoading && inspireRows.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (inspireError != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            inspireError,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          l10n.adminInspireHint(
            imageIndices.isEmpty ? 1 : imageIndices.length,
          ),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: inspireLoading ? null : onAddCard,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.adminInspireAddNewCard),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: l10n.adminRefreshFromFirestore,
              onPressed: inspireLoading ? null : onRefreshFromServer,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          l10n.adminInspireVersionCards(
            inspireDoc?['version'] ?? '—',
            inspireRows.length,
          ),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
      ),
      Expanded(
        child: inspireRows.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminInspireNoCardsYet,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: inspireLoading ? null : onAddCard,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.adminInspireAddFirstCard),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: onPullToRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: inspireRows.length,
                  itemBuilder: (context, i) {
                    final row = inspireRows[i];
                    final needsTr = row.tr.text.trim().isEmpty;
                    return Card(
                      color: const Color(0xFF0F2419),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: needsTr
                            ? BorderSide(
                                color: Colors.amber.withValues(alpha: 0.55),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.adminInspireCardLabel(i + 1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (needsTr) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n.adminInspireEmptyTextBadge,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.withValues(alpha: 0.95),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                IconButton(
                                  tooltip: l10n.adminInspireDuplicateTooltip,
                                  icon: const Icon(Icons.copy_rounded),
                                  onPressed:
                                      inspireLoading ? null : () => onDuplicateAt(i),
                                ),
                                IconButton(
                                  tooltip: l10n.adminInspireShuffleDesignTooltip,
                                  icon: const Icon(Icons.shuffle),
                                  onPressed:
                                      inspireLoading ? null : () => onShuffleAt(i),
                                ),
                                IconButton(
                                  tooltip: l10n.settingsDeleteAction,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: inspireLoading
                                      ? null
                                      : () {
                                          final txt = row.tr.text.trim();
                                          onDeleteAt(
                                            i,
                                            txt.isEmpty
                                                ? l10n.adminInspireEmptyTextPreview(i)
                                                : txt,
                                          );
                                        },
                                ),
                              ],
                            ),
                            Text(
                              l10n.adminInspireImageNumberLabel(
                                row.design['imageIndex'],
                              ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<InspirationContentKind>(
                              initialValue: row.contentKind,
                              decoration: InputDecoration(
                                labelText: l10n.adminInspireContentKindLabel,
                                filled: true,
                                fillColor: const Color(0xFF0A1A12),
                                border: const OutlineInputBorder(),
                              ),
                              dropdownColor: const Color(0xFF0F2419),
                              items: [
                                DropdownMenuItem(
                                  value: InspirationContentKind.quote,
                                  child: Text(l10n.adminInspireContentKindQuote),
                                ),
                                DropdownMenuItem(
                                  value: InspirationContentKind.verse,
                                  child: Text(l10n.adminInspireContentKindVerse),
                                ),
                                DropdownMenuItem(
                                  value: InspirationContentKind.hadith,
                                  child: Text(l10n.adminInspireContentKindHadith),
                                ),
                              ],
                              onChanged: inspireLoading
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      onKindChanged(i, v);
                                    },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.adminInspireShowInMainFeedTitle),
                              subtitle: Text(
                                l10n.adminInspireShowInMainFeedSubtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                ),
                              ),
                              value: row.showInMainFeed,
                              onChanged: inspireLoading
                                  ? null
                                  : (on) => onMainFeedChanged(i, on),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.tr,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: l10n.adminInspireTurkishTextLabel,
                                filled: true,
                                fillColor: const Color(0xFF0A1A12),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.ar,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: l10n.adminOptionalArabicLabel,
                                filled: true,
                                fillColor: const Color(0xFF0A1A12),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.source,
                              decoration: InputDecoration(
                                labelText: l10n.adminOptionalSourceLabel,
                                filled: true,
                                fillColor: const Color(0xFF0A1A12),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.verseRef,
                              decoration: InputDecoration(
                                labelText: l10n.adminOptionalVerseRefLabel,
                                filled: true,
                                fillColor: const Color(0xFF0A1A12),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: FilledButton(
          onPressed: inspireLoading ? null : onSaveAll,
          child: Text(l10n.adminInspireSaveAllChanges),
        ),
      ),
    ],
  );
}
