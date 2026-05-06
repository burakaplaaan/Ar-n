part of 'admin_content_page.dart';

Widget _buildAdminInspireTab({
  required BuildContext context,
  required double bottomInset,
  required bool inspireLoading,
  required String? inspireError,
  required int allRowCount,
  required List<_InspireFormRow> inspireRows,
  required List<int> rowIndices,
  required Map<String, dynamic>? inspireDoc,
  required InspirationContentKind selectedKind,
  required String inspireSearch,
  required TextEditingController inspireSearchController,
  required Duration publishDelay,
  required DateTime? lastSavedAt,
  required List<int> imageIndices,
  required ValueChanged<InspirationContentKind> onKindFilterChanged,
  required ValueChanged<String> onSearchChanged,
  required VoidCallback onClearSearch,
  required VoidCallback onDraftChanged,
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
  if (inspireLoading && allRowCount == 0) {
    return const Center(child: CircularProgressIndicator());
  }
  final quality = _inspireQualityWarnings(inspireRows);
  final unsaved = inspireRows.where((row) => row.hasUnsavedChanges).length;
  final mainFeedCount = inspireRows.where((row) => row.showInMainFeed).length;
  final status = _inspireOverallStatus(
    rows: inspireRows,
    lastSavedAt: lastSavedAt,
    publishDelay: publishDelay,
    qualityWarningCount: quality.length,
  );

  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    behavior: HitTestBehavior.translucent,
    child: Column(
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
                Expanded(
                  child: DropdownButtonFormField<InspirationContentKind>(
                    initialValue: selectedKind,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.adminInspireContentKindLabel,
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
                            if (v != null) onKindFilterChanged(v);
                          },
                  ),
                ),
                const SizedBox(width: 8),
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
            child: TextField(
              controller: inspireSearchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Bu keşfet bölümünde ara ($allRowCount kart)',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: inspireSearch.isEmpty
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
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.adminInspireVersionCards(
                inspireDoc?['version'] ?? '—',
                allRowCount,
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          _buildInspireAdminSummaryCard(
            status: status,
            selectedKind: selectedKind,
            visibleCount: inspireRows.length,
            allRowCount: allRowCount,
            mainFeedCount: mainFeedCount,
            unsavedCount: unsaved,
            qualityWarnings: quality,
            lastSavedAt: lastSavedAt,
            publishDelay: publishDelay,
          ),
      Expanded(
        child: inspireRows.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: inspireRows.length,
                  itemBuilder: (context, i) {
                    final row = inspireRows[i];
                    final realIndex = rowIndices[i];
                    final needsTr = row.tr.text.trim().isEmpty;
                    final status = _inspirePublishStatus(
                      row: row,
                      lastSavedAt: lastSavedAt,
                      publishDelay: publishDelay,
                    );
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
                                  l10n.adminInspireCardLabel(realIndex + 1),
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
                                      color: Colors.amber.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n.adminInspireEmptyTextBadge,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.withValues(
                                          alpha: 0.95,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                _InspireStatusPill(status: status),
                                const Spacer(),
                                IconButton(
                                  tooltip: l10n.adminInspireDuplicateTooltip,
                                  icon: const Icon(Icons.copy_rounded),
                                  onPressed: inspireLoading
                                      ? null
                                      : () => onDuplicateAt(realIndex),
                                ),
                                IconButton(
                                  tooltip:
                                      l10n.adminInspireShuffleDesignTooltip,
                                  icon: const Icon(Icons.shuffle),
                                  onPressed: inspireLoading
                                      ? null
                                      : () => onShuffleAt(realIndex),
                                ),
                                IconButton(
                                  tooltip: l10n.settingsDeleteAction,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: inspireLoading
                                      ? null
                                      : () {
                                          final txt = row.tr.text.trim();
                                          onDeleteAt(
                                            realIndex,
                                            txt.isEmpty
                                                ? l10n.adminInspireEmptyTextPreview(
                                                    realIndex,
                                                  )
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
                                  child: Text(
                                    l10n.adminInspireContentKindQuote,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: InspirationContentKind.verse,
                                  child: Text(
                                    l10n.adminInspireContentKindVerse,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: InspirationContentKind.hadith,
                                  child: Text(
                                    l10n.adminInspireContentKindHadith,
                                  ),
                                ),
                              ],
                              onChanged: inspireLoading
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      onKindChanged(realIndex, v);
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
                                  : (on) => onMainFeedChanged(realIndex, on),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.tr,
                              minLines: 3,
                              maxLines: 12,
                              keyboardType: TextInputType.multiline,
                              onChanged: (_) => onDraftChanged(),
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
                              minLines: 2,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              onChanged: (_) => onDraftChanged(),
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
                              minLines: 2,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              onChanged: (_) => onDraftChanged(),
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
                              minLines: 2,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              onChanged: (_) => onDraftChanged(),
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
      SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: inspireLoading ? null : onSaveAll,
          child: Text(l10n.adminInspireSaveAllChanges),
        ),
      ),
    ],
    ),
  );
}

enum _InspirePublishStatus { draft, propagating, live }

({Color color, String label, String detail}) _inspireOverallStatus({
  required List<_InspireFormRow> rows,
  required DateTime? lastSavedAt,
  required Duration publishDelay,
  required int qualityWarningCount,
}) {
  final unsaved = rows.any((row) => row.hasUnsavedChanges);
  if (unsaved) {
    return (
      color: Colors.redAccent,
      label: 'Kaydedilmedi',
      detail: 'Bu görünümde kaydedilmemiş değişiklik var.',
    );
  }
  if (qualityWarningCount > 0) {
    return (
      color: Colors.amber,
      label: 'Kontrol et',
      detail: 'Kartlarda yayın öncesi kontrol edilmesi gereken alanlar var.',
    );
  }
  if (lastSavedAt != null) {
    final liveAt = lastSavedAt.add(publishDelay);
    if (liveAt.isAfter(DateTime.now())) {
      return (
        color: Colors.amber,
        label: 'Yayılıyor',
        detail:
            'Keşfet kataloğu 16 saate kadar cache kullanır. Tahmini canlı: ${_shortDateTime(liveAt)}.',
      );
    }
  }
  return (
    color: AppColors.accentNeonGreen,
    label: 'Yayında',
    detail:
        'Cache süresi geçmiş görünüyor; yeni açan kullanıcılar güncel içeriği alır.',
  );
}

List<String> _inspireQualityWarnings(List<_InspireFormRow> rows) {
  final warnings = <String>[];
  var emptyText = 0;
  var missingReligiousReference = 0;
  var longText = 0;
  final seen = <String>{};
  var duplicates = 0;
  for (final row in rows) {
    final tr = row.tr.text.trim();
    if (tr.isEmpty) emptyText++;
    if (tr.length > 420) longText++;
    if ((row.contentKind == InspirationContentKind.verse ||
            row.contentKind == InspirationContentKind.hadith) &&
        row.source.text.trim().isEmpty &&
        row.verseRef.text.trim().isEmpty) {
      missingReligiousReference++;
    }
    final key = '${row.contentKind.wireName}|${tr.toLowerCase()}';
    if (tr.isNotEmpty && !seen.add(key)) duplicates++;
  }
  if (emptyText > 0) warnings.add('$emptyText kartta Türkçe metin boş.');
  if (missingReligiousReference > 0) {
    warnings.add(
      '$missingReligiousReference âyet/hadis kartında kaynak veya referans eksik.',
    );
  }
  if (longText > 0) {
    warnings.add('$longText kart uzun; görselde taşma yapabilir.');
  }
  if (duplicates > 0) warnings.add('$duplicates olası tekrar kart var.');
  return warnings;
}

Widget _buildInspireAdminSummaryCard({
  required ({Color color, String label, String detail}) status,
  required InspirationContentKind selectedKind,
  required int visibleCount,
  required int allRowCount,
  required int mainFeedCount,
  required int unsavedCount,
  required List<String> qualityWarnings,
  required DateTime? lastSavedAt,
  required Duration publishDelay,
}) {
  final liveAt = lastSavedAt?.add(publishDelay);
  final now = DateTime.now();
  final eta = liveAt == null
      ? 'Son kayıt zamanı yok.'
      : liveAt.isAfter(now)
      ? 'Kalan süre: ${_durationText(liveAt.difference(now))}'
      : 'Yayın cache süresi geçmiş.';
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
    child: Card(
      color: const Color(0xFF0F2419),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Keşfet yayın durumu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _adminStatusPill(color: status.color, label: status.label),
              ],
            ),
            const SizedBox(height: 4),
            Text(status.detail),
            const SizedBox(height: 4),
            Text(
              '$eta · Görünüm: ${selectedKind.wireName} ($visibleCount/$allRowCount) · Ana akış: $mainFeedCount · Kaydedilmemiş: $unsavedCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 11.5,
              ),
            ),
            if (qualityWarnings.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...qualityWarnings
                  .take(1)
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (qualityWarnings.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${qualityWarnings.length - 1} ek uyarı',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

_InspirePublishStatus _inspirePublishStatus({
  required _InspireFormRow row,
  required DateTime? lastSavedAt,
  required Duration publishDelay,
}) {
  if (row.hasUnsavedChanges) return _InspirePublishStatus.draft;
  if (lastSavedAt == null) return _InspirePublishStatus.live;
  final elapsed = DateTime.now().difference(lastSavedAt);
  if (elapsed < publishDelay) return _InspirePublishStatus.propagating;
  return _InspirePublishStatus.live;
}

class _InspireStatusPill extends StatelessWidget {
  const _InspireStatusPill({required this.status});

  final _InspirePublishStatus status;

  @override
  Widget build(BuildContext context) {
    final (:color, :label) = switch (status) {
      _InspirePublishStatus.draft => (
        color: Colors.amber,
        label: 'Kaydedilmedi',
      ),
      _InspirePublishStatus.propagating => (
        color: Colors.deepOrangeAccent,
        label: 'Yayılıyor',
      ),
      _InspirePublishStatus.live => (
        color: AppColors.accentNeonGreen,
        label: 'Yayında',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
