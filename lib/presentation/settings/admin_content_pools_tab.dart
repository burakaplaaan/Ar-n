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
    case QuotePoolIds.notificationNamazWisdom:
      return l10n.adminPoolLabelNotificationNamazWisdom;
    case QuotePoolIds.notificationDailyNamazReminder:
      return l10n.adminPoolLabelNotificationDailyNamazReminder;
    default:
      return poolId;
  }
}

({String surface, String cadence, String format, Duration delay})
_poolUsageInfo(String poolId) {
  switch (poolId) {
    case QuotePoolIds.homeNamazWisdom:
      return (
        surface:
            'Ana sayfa namaz kartında kullanılır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Türkçe + tür zorunlu; Arapça ve kaynak isteğe bağlıdır.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.personalizedQuotes:
      return (
        surface:
            'Kişiselleştirilmiş söz eşleşmeleri ve bazı widget yedekleri için kullanılır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format:
            'Kısa Türkçe metin, isteğe bağlı Arapça/kaynak ve etiketler uygundur.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.widgetQuote:
      return (
        surface: 'Ana ekran widget sözleri için kullanılır.',
        cadence:
            'Widget havuzu yaklaşık 1 saatte bir kontrol edilir; gösterim slotları 00/06/09/12/15/18/21.',
        format:
            'Kısa metin ve isteğe bağlı kaynak önerilir; uzun metin widgetta kesilebilir.',
        delay: const Duration(hours: 1),
      );
    case QuotePoolIds.zikirDailyReflections:
      return (
        surface: 'Namaz vakti/zikir yansıması kartlarında kullanılır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Tek, kısa ve doğrudan metin beklenir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.healingComfort:
      return (
        surface:
            'İyileşme frekansları ve teselli akışındaki günlük rahatlatıcı içerikte kullanılır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Türkçe + Arapça + referans zorunlu tutulur.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.hubGelisimIslamic:
      return (
        surface: 'Gelişim ekranındaki günlük manevi bilgi kartıdır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Başlık + metin + isteğe bağlı kaynak beklenir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.hubGelisimMedical:
      return (
        surface: 'Gelişim ekranındaki günlük sağlık/bilimsel destek kartıdır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Başlık + metin + isteğe bağlı kaynak beklenir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.hubArinmaIslamic:
      return (
        surface: 'Arınma/bırakma ekranındaki günlük manevi destek kartıdır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Başlık + metin + isteğe bağlı kaynak beklenir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.hubArinmaMedical:
      return (
        surface:
            'Arınma/bırakma ekranındaki günlük sağlık/bilimsel destek kartıdır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Başlık + metin + isteğe bağlı kaynak beklenir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.notificationArinmaBodies:
      return (
        surface:
            'Otomatik arınma bildirimlerinin gövde metinlerinde kullanılır.',
        cadence:
            'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler; bildirim planı yeniden kurulunca görünür.',
        format: 'Kısa bildirim metni beklenir; çok uzun metin kesilebilir.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.notificationNamazWisdom:
      return (
        surface:
            'Günlük "Namaz" bildiriminin (slot 0) gövde metninde kullanılır. '
            'Boşsa home_namaz_wisdom havuzuna, o da boşsa yerleşik listeye düşer.',
        cadence:
            'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler; bildirim planı yeniden kurulunca görünür.',
        format:
            'Kısa Türkçe metin zorunlu; tür (Söz / Hadis / Ayet) ve kaynak isteğe bağlıdır.',
        delay: const Duration(hours: 6),
      );
    case QuotePoolIds.notificationDailyNamazReminder:
      return (
        surface:
            'Günlük yerel bildirim hatırlatıcısının (slot 0) içeriğini belirler. '
            'En yüksek önceliğe sahiptir; boşsa notification_namaz_wisdom → '
            'home_namaz_wisdom → yerleşik listeye sırayla düşer.',
        cadence:
            'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler; '
            'bildirim planı yeniden kurulunca görünür.',
        format:
            'Kısa namaza teşvik edici metin; tür (Söz / Hadis / Ayet / Hatırlatıcı) '
            've kaynak isteğe bağlıdır. Çok uzun metin (>300 karakter) kesilebilir.',
        delay: const Duration(hours: 6),
      );
    default:
      return (
        surface: 'Bu havuz uygulama içi içerik kaynağı olarak kullanılır.',
        cadence: 'Kullanıcı cihazları bu havuzu en fazla 6 saatte bir yeniler.',
        format: 'Kısa ve temiz metin önerilir.',
        delay: const Duration(hours: 6),
      );
  }
}

DateTime? _adminDateFromValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
}

String _durationText(Duration d) {
  if (d.isNegative || d == Duration.zero) return '0 dk';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0 && m > 0) return '${h}s ${m}dk';
  if (h > 0) return '${h}s';
  return '${m}dk';
}

List<String> _poolQualityWarnings(
  String poolId,
  List<Map<String, dynamic>> items,
) {
  final warnings = <String>[];
  if (items.isEmpty) {
    warnings.add(
      'Havuz boş; kullanıcı tarafı asset/yerleşik yedeğe düşebilir.',
    );
    return warnings;
  }
  var emptyRequired = 0;
  var longNotification = 0;
  final seen = <String>{};
  var duplicates = 0;
  for (final m in items) {
    final title = m['title']?.toString().trim() ?? '';
    final body = m['body']?.toString().trim() ?? '';
    final text = m['text']?.toString().trim() ?? '';
    final turkish = m['turkish']?.toString().trim() ?? '';
    final arabic = m['arabic']?.toString().trim() ?? '';
    final ref = m['ref']?.toString().trim() ?? '';
    final key =
        (title.isNotEmpty
                ? '$title|$body'
                : text.isNotEmpty
                ? text
                : turkish)
            .toLowerCase();
    if (key.isNotEmpty && !seen.add(key)) duplicates++;

    if (poolId.startsWith('hub_')) {
      if (title.isEmpty || body.isEmpty) emptyRequired++;
    } else if (poolId == QuotePoolIds.homeNamazWisdom) {
      if (turkish.isEmpty) emptyRequired++;
    } else if (poolId == QuotePoolIds.healingComfort) {
      if (turkish.isEmpty || arabic.isEmpty) emptyRequired++;
      if (poolId == QuotePoolIds.healingComfort && ref.isEmpty) emptyRequired++;
    } else {
      if (text.isEmpty && turkish.isEmpty) emptyRequired++;
    }
    if (poolId == QuotePoolIds.notificationArinmaBodies &&
        (text.length > 140 || turkish.length > 140)) {
      longNotification++;
    }
    if ((poolId == QuotePoolIds.notificationNamazWisdom ||
            poolId == QuotePoolIds.notificationDailyNamazReminder) &&
        (text.length > 300 || turkish.length > 300)) {
      longNotification++;
    }
  }
  if (emptyRequired > 0) {
    warnings.add('$emptyRequired kayıtta zorunlu alan eksik görünüyor.');
  }
  if (duplicates > 0) warnings.add('$duplicates olası tekrar kayıt var.');
  if (longNotification > 0) {
    warnings.add('$longNotification bildirim metni uzun; cihazda kesilebilir.');
  }
  return warnings;
}

Widget _adminStatusPill({
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

Widget _buildPoolUsageCard({
  required String poolId,
  required Map<String, dynamic>? poolDoc,
  required String? poolError,
  required List<Map<String, dynamic>> items,
}) {
  final info = _poolUsageInfo(poolId);
  final updatedAt = _adminDateFromValue(poolDoc?['updatedAt']);
  final liveAt = updatedAt?.add(info.delay);
  final now = DateTime.now();
  final warnings = _poolQualityWarnings(poolId, items);
  final hasError = poolError != null;
  final isPropagating = liveAt != null && liveAt.isAfter(now);
  final color = hasError
      ? Colors.redAccent
      : warnings.isNotEmpty
      ? Colors.amber
      : isPropagating
      ? Colors.amber
      : AppColors.accentNeonGreen;
  final label = hasError
      ? 'Dikkat'
      : warnings.isNotEmpty
      ? 'Kontrol et'
      : isPropagating
      ? 'Yayılıyor'
      : 'Yayında';
  final eta = liveAt == null
      ? 'Son kayıt zamanı yok'
      : isPropagating
      ? 'Tahmini canlı: ${_shortDateTime(liveAt)} · kalan ${_durationText(liveAt.difference(now))}'
      : 'Cache süresi geçti · son kayıt ${_shortDateTime(updatedAt!)}';

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Card(
      color: const Color(0xFF0F2419),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Bu havuz nerede görünür?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _adminStatusPill(color: color, label: label),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            eta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(info.surface)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              info.cadence,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              info.format,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings
                .take(3)
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(top: 3),
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
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    ),
  );
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
      _buildPoolUsageCard(
        poolId: poolId,
        poolDoc: poolDoc,
        poolError: poolError,
        items: allItems,
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
