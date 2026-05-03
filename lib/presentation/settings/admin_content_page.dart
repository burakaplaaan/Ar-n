// Yalnızca admin e-postaları — Firestore söz havuzları + Keşfet kartları.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/admin_allowlist.dart';
import '../../core/constants/quote_pool_ids.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_server_first.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/quote_pools/quote_pool_bulk_seeder.dart';
import '../../data/quote_pools/quote_pool_defaults.dart';
import '../../data/models/inspiration_content_kind.dart';
import '../../data/services/admin_notification_diagnostics_log.dart';
import '../../data/services/app_local_notification_scheduler.dart';
import '../../data/services/app_notification_channel_prefs.dart';
import '../../data/services/inspiration_asset_discovery.dart';
import '../../data/services/prayer_reminder_prefs.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/premium_providers.dart';
import 'admin_dev_tab.dart';
import 'widgets/admin_diagnostics_tab.dart';

part 'admin_content_inspire_form_row.dart';
part 'admin_content_pools_tab.dart';
part 'admin_content_inspire_tab.dart';
part 'admin_content_identity_strip.dart';

class AdminContentPage extends ConsumerStatefulWidget {
  const AdminContentPage({super.key});

  @override
  ConsumerState<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends ConsumerState<AdminContentPage>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// [ArinShell] `extendBody: true` — alt gezinme çubuğu üstüne içerik binmesin.
  static double _shellBodyBottomInset(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 80;
  }

  late final TabController _tabs;
  String _poolId = QuotePoolIds.all.first;
  Map<String, dynamic>? _poolDoc;
  bool _poolLoading = false;
  // "Tüm havuzları tohumla" uzun sürebilir; butonda ayrı bir progress göstermek
  // ve idempotent kilit tutmak için ikinci bayrak tutuyoruz (`_poolLoading` tüm
  // havuz işlemlerinde true olabilir, spinner'ı sadece bulk seed'e bağlamak).
  bool _seedingAll = false;
  bool _inspireLoading = false;
  String? _poolError;
  String? _inspireError;
  bool _inspireLoadStarted = false;

  /// Pool havuzunda öğe aramak için. Case-insensitive prefix/contains.
  String _poolSearch = '';

  Map<String, dynamic>? _inspireDoc;
  final List<_InspireFormRow> _inspireRows = [];
  List<int> _inspireImageIndices = const [];
  final Random _rng = Random();
  bool _diagLoading = false;
  int _diagPendingCount = 0;
  List<NotificationDiagnosticsEntry> _diagLogs = const [];
  bool _isAdminVerified = false;
  bool _adminBootstrapped = false;
  bool _adminGrantsLoading = false;
  String? _adminGrantsError;
  List<_AdminGrantRow> _adminGrants = const [];
  List<_AdminGrantRow> _adminInvites = const [];
  bool _premiumLoading = false;
  String? _premiumError;
  List<_PremiumGrantRow> _premiumEntitlements = const [];
  List<_PremiumGrantRow> _premiumInvites = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted) return;
    // indexIsChanging sırasında return etmeyin: ilk Keşfet geçişinde yükleme hiç
    // tetiklenmeyebiliyor (animasyon bitene kadar listener tekrar gelmeyebilir).
    if (_tabs.index == 1 && !_inspireLoadStarted) {
      _inspireLoadStarted = true;
      _loadInspire();
    }
    if (_tabs.index == 2 && _diagLogs.isEmpty && !_diagLoading) {
      _loadDiagnostics();
    }
    if (_tabs.index == 4 && !_adminGrantsLoading && _adminGrants.isEmpty) {
      _loadAdminGrants();
    }
    if (_tabs.index == 5 &&
        !_premiumLoading &&
        _premiumEntitlements.isEmpty &&
        _premiumInvites.isEmpty) {
      _loadPremiumGrants();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    for (final r in _inspireRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPool() async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    setState(() {
      _poolLoading = true;
      _poolError = null;
    });
    try {
      final docRef = FirebaseFirestore.instance
          .collection('quote_pools')
          .doc(_poolId);
      final snap = await getDocumentServerFirst(
        docRef,
        debugLabel: 'AdminContentPage quote_pools',
      );
      _poolDoc = snap.data();
    } catch (e) {
      _poolError = _friendlyAdminError(
        e,
        fallback: l10n.adminPoolDataUnavailable,
      );
    }
    if (mounted) {
      setState(() => _poolLoading = false);
    }
  }

  Future<void> _savePool(
    List<Map<String, dynamic>> items, {
    String actionLabel = '',
    bool confirmBeforeSave = true,
    Map<String, dynamic> restoredDocumentFields = const <String, dynamic>{},
  }) async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    if (_poolLoading) return;
    final oldItems = _itemsFromDoc();
    final resolvedActionLabel = actionLabel.isEmpty
        ? l10n.adminPoolChangeAction
        : actionLabel;
    if (confirmBeforeSave) {
      final ok = await _confirmSavePreview(
        title: l10n.adminReviewBeforeSaveTitle,
        actionLabel: resolvedActionLabel,
        oldCount: oldItems.length,
        newCount: items.length,
        changedCount: _changedItemCount(oldItems, items),
      );
      if (!ok) return;
    }
    setState(() {
      _poolLoading = true;
      _poolError = null;
    });
    var saved = false;
    try {
      final v = (_poolDoc?['version'] as num?)?.toInt() ?? 0;
      final docRef = FirebaseFirestore.instance
          .collection('quote_pools')
          .doc(_poolId);
      final auditRef = FirebaseFirestore.instance
          .collection('admin_audit')
          .doc();
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final fresh = await tx.get(docRef);
        final freshVersion = (fresh.data()?['version'] as num?)?.toInt() ?? 0;
        if (freshVersion != v) {
          throw const _AdminVersionConflict();
        }
        final nextDoc = <String, dynamic>{
          if (fresh.data() != null) ...fresh.data()!,
          ...restoredDocumentFields,
          'version': v + 1,
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        tx.set(docRef, nextDoc, SetOptions(merge: false));
        tx.set(
          auditRef,
          _adminAuditPayload(
            action: resolvedActionLabel,
            targetType: 'quote_pool',
            targetId: _poolId,
            beforeVersion: v,
            afterVersion: v + 1,
            beforeCount: oldItems.length,
            afterCount: items.length,
          ),
        );
      });
      saved = true;
      _snack(l10n.adminPoolSaved);
    } catch (e) {
      final msg = _friendlyAdminError(e, fallback: l10n.adminPoolSaveFailed);
      if (mounted) {
        setState(() => _poolError = msg);
      }
      _snack(msg);
    } finally {
      if (mounted) {
        setState(() => _poolLoading = false);
      }
    }
    if (saved) {
      await _loadPool();
    }
  }

  Future<void> _seedDefaults() async {
    final items = QuotePoolDefaults.itemsForPoolId(_poolId);
    if (items == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _poolId == QuotePoolIds.personalizedQuotes ||
                      _poolId == QuotePoolIds.widgetQuote
                  ? l10n.adminUseSeedAllForPool
                  : l10n.adminNoBuiltInSeedForPool,
            ),
          ),
        );
      }
      return;
    }
    await _savePool(items, actionLabel: l10n.adminSeedSelectedPoolDefaults);
  }

  /// Kaza güvencesi: mevcut havuzu JSON olarak dışa aktar → Drive, WhatsApp,
  /// Notes vs. ile yedeği tut. "Tüm havuzları tohumla" yanlışlıkla çalışırsa
  /// veya silme kazası olursa, admin bu JSON'u açıp yeniden yazabilir.
  Future<void> _exportCurrentPool() async {
    if (_poolDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminPoolNotLoadedYet)));
      return;
    }
    try {
      final payload = {
        'poolId': _poolId,
        'exportedAt': DateTime.now().toIso8601String(),
        'document': _poolDoc,
      };
      const enc = JsonEncoder.withIndent('  ');
      final jsonStr = enc.convert(payload);

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${dir.path}/arin-pool-$_poolId-$ts.json');
      await file.writeAsString(jsonStr);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.adminPoolBackupShareText(_poolId, ts),
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: l10n.adminPoolBackupShareSubject,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(l10n.adminBackupCreationFailed(e.toString()))),
      );
    }
  }

  Future<void> _importPoolBackup() async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    if (_poolLoading) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null) return;

      final raw = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _snack(l10n.adminBackupInvalidJsonObject);
        return;
      }
      final backup = Map<String, dynamic>.from(decoded);
      final backupPoolId = backup['poolId']?.toString();
      final rawDocument = backup['document'] ?? backup;
      if (rawDocument is! Map) {
        _snack(l10n.adminBackupPoolDocumentMissing);
        return;
      }
      final document = Map<String, dynamic>.from(rawDocument);
      final rawItems = document['items'];
      if (rawItems is! List) {
        _snack(l10n.adminBackupItemsListMissing);
        return;
      }
      final items = <Map<String, dynamic>>[
        for (final e in rawItems)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      if (items.length != rawItems.length) {
        _snack(l10n.adminBackupContainsUnreadableRecords);
        return;
      }

      final sourceText = backupPoolId == null || backupPoolId.isEmpty
          ? l10n.adminUnknownPool
          : backupPoolId;
      final samePool = backupPoolId == null || backupPoolId == _poolId;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.adminRestoreBackupTitle),
          content: Text(
            l10n.adminRestoreBackupDialogBody(
              file.name,
              sourceText,
              _poolId,
              items.length,
              samePool
                  ? ''
                  : '${l10n.adminRestoreBackupDifferentPoolWarning}\n\n',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.quitOnboardingContinueAction),
            ),
          ],
        ),
      );
      if (ok != true) return;

      await _savePool(
        items,
        actionLabel: l10n.adminRestoreFromBackupAction(file.name),
        restoredDocumentFields: _restorablePoolFields(document),
      );
    } catch (e) {
      final msg = _friendlyAdminError(
        e,
        fallback: l10n.adminRestoreBackupFailed,
      );
      _snack(msg);
    }
  }

  /// [mergeOnly] true → mevcut manuel düzenlemeleri KORUR, sadece yerleşikte
  /// olup Firestore'da eksik olanları ekler. false → TAM üzerine yazar.
  Future<void> _seedAllPools({bool mergeOnly = false}) async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    if (_poolLoading || _seedingAll) return;
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (mergeOnly && role?.canSeedMissingPools != true) {
      _snack(l10n.adminRequiresManagerOrFullAccessForMissingSeed);
      return;
    }
    if (!mergeOnly && role?.canResetAllPools != true) {
      _snack(l10n.adminRequiresFullAccessForReset);
      return;
    }

    QuotePoolSeedPreview preview;
    setState(() {
      _poolLoading = true;
      _seedingAll = true;
      _poolError = null;
    });
    try {
      preview = await QuotePoolBulkSeeder.previewSeedAllPools(
        FirebaseFirestore.instance,
        mergeOnly: mergeOnly,
      );
    } catch (e) {
      final msg = _friendlyAdminError(
        e,
        fallback: l10n.adminBulkPreviewFailed,
      );
      if (mounted) {
        setState(() {
          _poolError = msg;
          _poolLoading = false;
          _seedingAll = false;
        });
      }
      _snack(msg);
      return;
    }
    if (mounted) {
      setState(() {
        _poolLoading = false;
        _seedingAll = false;
      });
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          mergeOnly
              ? l10n.adminAddMissingRecords
              : l10n.adminSeedAllPoolsTitle,
        ),
        content: Text(
          mergeOnly
              ? l10n.adminMergeSeedPreview(
                  preview.poolCount,
                  preview.changedPoolCount,
                  preview.addedItemCount,
                  preview.targetItemCount,
                )
              : l10n.adminResetSeedPreview(
                  preview.poolCount,
                  preview.changedPoolCount,
                  preview.currentItemCount,
                  preview.targetItemCount,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: mergeOnly
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              mergeOnly ? l10n.adminAddAction : l10n.adminOverwriteAction,
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _poolLoading = true;
      _seedingAll = true;
      _poolError = null;
    });
    try {
      await _writeAdminAudit(
        action: mergeOnly
            ? l10n.adminAuditAddMissingToAllPools
            : l10n.adminAuditResetAllPools,
        targetType: 'quote_pools',
        targetId: 'all',
        beforeCount: preview.currentItemCount,
        afterCount: preview.targetItemCount,
        details: {
          'poolCount': preview.poolCount,
          'changedPoolCount': preview.changedPoolCount,
          'addedItemCount': preview.addedItemCount,
          'mergeOnly': mergeOnly,
          'status': 'started',
        },
      );
      await QuotePoolBulkSeeder.seedAllPools(
        FirebaseFirestore.instance,
        mergeOnly: mergeOnly,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mergeOnly
                  ? l10n.adminMissingItemsAddedToPools
                  : l10n.adminAllPoolsOverwritten,
            ),
          ),
        );
      }
      await _loadPool();
    } catch (e) {
      if (mounted) {
        setState(() => _poolError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _poolLoading = false;
          _seedingAll = false;
        });
      }
    }
  }

  Future<void> _loadInspire() async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    setState(() {
      _inspireLoading = true;
      _inspireError = null;
    });
    for (final r in _inspireRows) {
      r.dispose();
    }
    _inspireRows.clear();
    try {
      final indices = await InspirationAssetDiscovery.discoverConsecutiveJpeg();
      if (mounted) {
        setState(() => _inspireImageIndices = indices);
      }
      final docRef = FirebaseFirestore.instance
          .collection('app_public')
          .doc('inspiration_cards');
      final snap = await getDocumentServerFirst(
        docRef,
        debugLabel: 'AdminContentPage inspiration_cards',
      );
      _inspireDoc = snap.data();
      final raw = _inspireDoc?['items'];
      final useIdx = indices.isNotEmpty ? indices : <int>[1];
      if (raw is List) {
        for (var i = 0; i < raw.length; i++) {
          final e = raw[i];
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          _inspireRows.add(_InspireFormRow.fromMap(m, useIdx, _rng));
        }
      }
    } catch (e) {
      _inspireError = _friendlyAdminError(
        e,
        fallback: l10n.adminInspireCardsUnavailable,
      );
    }
    if (mounted) {
      setState(() => _inspireLoading = false);
    }
  }

  Future<void> _loadDiagnostics() async {
    if (!_isAdminVerified) return;
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (role?.canUseDiagnostics != true) return;
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _diagLoading = true);
    try {
      final pending =
          await AppLocalNotificationScheduler.pendingScheduleCount();
      final logs = AdminNotificationDiagnosticsLog.readAll(prefs);
      if (!mounted) return;
      setState(() {
        _diagPendingCount = pending;
        _diagLogs = logs;
      });
    } finally {
      if (mounted) {
        setState(() => _diagLoading = false);
      }
    }
  }

  Future<void> _clearDiagnostics() async {
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (role?.canUseDiagnostics != true) {
      _snack(l10n.adminRequiresManagerOrFullAccessForDiagnostics);
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await AdminNotificationDiagnosticsLog.clear(prefs);
    if (!mounted) return;
    await _loadDiagnostics();
    _snack(l10n.adminNotificationLogsCleared);
  }

  Future<void> _exportDiagnostics() async {
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (role?.canUseDiagnostics != true) {
      _snack(l10n.adminRequiresManagerOrFullAccessForDiagnostics);
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      final payload = AdminNotificationDiagnosticsLog.exportPrettyJson(prefs);
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${dir.path}/arin-notification-log-$ts.json');
      await file.writeAsString(payload);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.adminNotificationLogsShareText(ts),
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: l10n.adminNotificationLogsShareSubject,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(l10n.adminLogExportFailed(e.toString()));
    }
  }

  Future<void> _saveInspire() async {
    if (!isFirebaseReady || !_isAdminVerified) return;
    if (_inspireLoading) return;
    setState(() {
      _inspireLoading = true;
      _inspireError = null;
    });
    final list = <Map<String, dynamic>>[];
    try {
      for (final row in _inspireRows) {
        final trText = row.tr.text.trim();
        if (trText.isEmpty) {
          _snack(l10n.adminInspireCardHasEmptyTurkishText);
          return;
        }
        list.add(row.toFirestoreMap());
      }
      final oldItems = _inspireItemsFromDoc();
      final ok = await _confirmSavePreview(
        title: l10n.adminReviewCardsBeforeSaveTitle,
        actionLabel: l10n.adminInspireCardsWillBeUpdated,
        oldCount: oldItems.length,
        newCount: list.length,
        changedCount: _changedItemCount(oldItems, list),
      );
      if (!ok) return;
      final v = (_inspireDoc?['version'] as num?)?.toInt() ?? 0;
      final docRef = FirebaseFirestore.instance
          .collection('app_public')
          .doc('inspiration_cards');
      final auditRef = FirebaseFirestore.instance
          .collection('admin_audit')
          .doc();
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final fresh = await tx.get(docRef);
        final freshVersion = (fresh.data()?['version'] as num?)?.toInt() ?? 0;
        if (freshVersion != v) {
          throw const _AdminVersionConflict();
        }
        final nextDoc = <String, dynamic>{
          if (fresh.data() != null) ...fresh.data()!,
          'version': v + 1,
          'items': list,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        tx.set(docRef, nextDoc, SetOptions(merge: false));
        tx.set(
          auditRef,
          _adminAuditPayload(
            action: l10n.adminAuditInspireCardsUpdated,
            targetType: 'app_public',
            targetId: 'inspiration_cards',
            beforeVersion: v,
            afterVersion: v + 1,
            beforeCount: oldItems.length,
            afterCount: list.length,
          ),
        );
      });
      _snack(l10n.adminInspireCardsSaved);
      await _loadInspire();
    } catch (e) {
      final msg = _friendlyAdminError(
        e,
        fallback: l10n.adminInspireCardsSaveFailed,
      );
      if (mounted) {
        setState(() => _inspireError = msg);
      }
      _snack(msg);
    } finally {
      if (mounted) {
        setState(() => _inspireLoading = false);
      }
    }
  }

  void _addInspireCard() {
    final useIdx = _inspireImageIndices.isNotEmpty
        ? _inspireImageIndices
        : <int>[1];
    setState(() {
      _inspireRows.add(_InspireFormRow.empty(useIdx, _rng));
    });
  }

  /// Admin silme işlemleri için kısa onay. [preview] null ise sade bir mesaj
  /// gösterir; doluysa silinecek öğenin kısa içeriğini de gösterir ki kullanıcı
  /// yanlışlıkla dokunduğunu fark edebilsin.
  Future<bool> _confirmDelete({
    required String title,
    required String message,
    String? preview,
    String? confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (preview != null && preview.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  preview.length > 180
                      ? '${preview.substring(0, 180)}…'
                      : preview,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel ?? l10n.settingsDeleteAction),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _removeInspireAt(int i) {
    setState(() {
      final r = _inspireRows.removeAt(i);
      r.dispose();
    });
  }

  /// Kart kopyala: metin alanlarını klonlar, tasarım metasını yeniden üretir
  /// (aynı imageIndex çakışmasın), aynı satırın altına ekler. `id` yeniden
  /// atanır — Firestore'da çift kart olmaz.
  void _duplicateInspireAt(int i) {
    final src = _inspireRows[i];
    final useIdx = _inspireImageIndices.isNotEmpty
        ? _inspireImageIndices
        : <int>[1];
    final clone = _InspireFormRow(
      tr: TextEditingController(text: src.tr.text),
      ar: TextEditingController(text: src.ar.text),
      source: TextEditingController(text: src.source.text),
      verseRef: TextEditingController(text: src.verseRef.text),
      design: _InspireFormRow._sanitizeDesign(
        <String, dynamic>{},
        useIdx,
        _rng,
      ),
      contentKind: src.contentKind,
      showInMainFeed: src.showInMainFeed,
    );
    setState(() {
      _inspireRows.insert(i + 1, clone);
    });
  }

  List<Map<String, dynamic>> _itemsFromDoc() {
    final raw = _poolDoc?['items'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _inspireItemsFromDoc() {
    final raw = _inspireDoc?['items'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _changedItemCount(
    List<Map<String, dynamic>> before,
    List<Map<String, dynamic>> after,
  ) {
    var changed = 0;
    final maxLen = max(before.length, after.length);
    for (var i = 0; i < maxLen; i++) {
      final oldJson = i < before.length ? _stableJson(before[i]) : null;
      final newJson = i < after.length ? _stableJson(after[i]) : null;
      if (oldJson != newJson) changed++;
    }
    return changed;
  }

  String _stableJson(Map<String, dynamic> value) {
    final sorted = <String, dynamic>{};
    final keys = value.keys.toList()..sort();
    for (final key in keys) {
      sorted[key] = value[key];
    }
    return jsonEncode(sorted);
  }

  Map<String, dynamic> _restorablePoolFields(Map<String, dynamic> document) {
    final out = Map<String, dynamic>.from(document)
      ..remove('items')
      ..remove('version')
      ..remove('updatedAt');
    return out;
  }

  Future<bool> _confirmSavePreview({
    required String title,
    required String actionLabel,
    required int oldCount,
    required int newCount,
    required int changedCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(actionLabel),
            const SizedBox(height: 12),
            Text(l10n.adminCurrentRecordCount(oldCount)),
            Text(l10n.adminRecordCountToSave(newCount)),
            Text(l10n.adminChangedRowCount(changedCount)),
            const SizedBox(height: 12),
            Text(
              l10n.adminConcurrentEditWarning,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.quitOnboardingAbortAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminSaveAction),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _writeAdminAudit({
    required String action,
    required String targetType,
    required String targetId,
    int? beforeVersion,
    int? afterVersion,
    int? beforeCount,
    int? afterCount,
    Map<String, Object?> details = const <String, Object?>{},
  }) async {
    if (!isFirebaseReady) return;
    await FirebaseFirestore.instance
        .collection('admin_audit')
        .add(
          _adminAuditPayload(
            action: action,
            targetType: targetType,
            targetId: targetId,
            beforeVersion: beforeVersion,
            afterVersion: afterVersion,
            beforeCount: beforeCount,
            afterCount: afterCount,
            details: details,
          ),
        );
  }

  Map<String, Object?> _adminAuditPayload({
    required String action,
    required String targetType,
    required String targetId,
    int? beforeVersion,
    int? afterVersion,
    int? beforeCount,
    int? afterCount,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    return {
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'uid': user?.uid,
      'email': user?.email,
      'role': role?.name,
      'beforeVersion': beforeVersion,
      'afterVersion': afterVersion,
      'beforeCount': beforeCount,
      'afterCount': afterCount,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String _normalizeAdminTarget(String value) => value.trim().toLowerCase();

  bool _adminTargetIsEmail(String value) => value.contains('@');

  Future<void> _loadAdminGrants() async {
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (role?.canManageAdmins != true) return;
    setState(() {
      _adminGrantsLoading = true;
      _adminGrantsError = null;
    });
    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('admin_users')
          .get(const GetOptions(source: Source.server));
      final invitesSnap = await FirebaseFirestore.instance
          .collection('admin_invites')
          .get(const GetOptions(source: Source.server));
      final users = usersSnap.docs.map((doc) {
        final data = doc.data();
        return _AdminGrantRow(
          id: doc.id,
          label: data['email']?.toString() ?? doc.id,
          role: AdminRole.fromWire(data['role']?.toString()),
          isInvite: false,
        );
      }).toList()..sort((a, b) => a.label.compareTo(b.label));
      final invites = invitesSnap.docs.map((doc) {
        final data = doc.data();
        return _AdminGrantRow(
          id: doc.id,
          label: data['email']?.toString() ?? doc.id,
          role: AdminRole.fromWire(data['role']?.toString()),
          isInvite: true,
        );
      }).toList()..sort((a, b) => a.label.compareTo(b.label));
      if (!mounted) return;
      setState(() {
        _adminGrants = users;
        _adminInvites = invites;
      });
    } catch (e) {
      final msg = _friendlyAdminError(e, fallback: l10n.adminGrantsListFetchFailed);
      if (mounted) {
        setState(() => _adminGrantsError = msg);
      }
    } finally {
      if (mounted) {
        setState(() => _adminGrantsLoading = false);
      }
    }
  }

  Future<void> _openGrantDialog({_AdminGrantRow? existing}) async {
    final targetCtrl = TextEditingController(
      text: existing?.label == existing?.id
          ? existing?.id ?? ''
          : existing?.label ?? '',
    );
    var selectedRole = existing?.role == AdminRole.none
        ? AdminRole.content
        : existing?.role ?? AdminRole.content;
    final result = await showDialog<({String target, AdminRole role})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? l10n.adminGrantAccessAction : l10n.adminEditGrantAction,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: targetCtrl,
                enabled: existing == null,
                decoration: InputDecoration(
                  labelText: l10n.adminEmailOrUidLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminRole>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: l10n.adminLevelLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: AdminRole.content,
                    child: Text(l10n.adminRoleContentLabel),
                  ),
                  DropdownMenuItem(
                    value: AdminRole.manager,
                    child: Text(l10n.adminRoleManagerLabel),
                  ),
                  DropdownMenuItem(
                    value: AdminRole.developer,
                    child: Text(l10n.adminRoleDeveloperLabel),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setLocal(() => selectedRole = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (
                target: targetCtrl.text,
                role: selectedRole,
              )),
              child: Text(l10n.adminSaveAction),
            ),
          ],
        ),
      ),
    );
    targetCtrl.dispose();
    if (result == null) return;
    await _saveAdminGrant(
      target: existing?.id ?? result.target,
      role: result.role,
      isInvite: existing?.isInvite,
    );
  }

  Future<void> _saveAdminGrant({
    required String target,
    required AdminRole role,
    bool? isInvite,
  }) async {
    final currentRole = ref.read(currentAdminRoleProvider).asData?.value;
    if (currentRole?.canManageAdmins != true) {
      _snack(l10n.adminFullAccessRequiredForGrantManagement);
      return;
    }
    final normalized = _normalizeAdminTarget(target);
    if (normalized.isEmpty) {
      _snack(l10n.adminEmailOrUidCannotBeEmpty);
      return;
    }
    if (AdminAllowlist.kFullAccessAdminEmails.contains(normalized)) {
      _snack(l10n.adminAccountAlreadyFullAccess);
      return;
    }
    final invite = isInvite ?? _adminTargetIsEmail(normalized);
    final collection = invite ? 'admin_invites' : 'admin_users';
    final docRef = FirebaseFirestore.instance
        .collection(collection)
        .doc(normalized);
    final auditRef = FirebaseFirestore.instance.collection('admin_audit').doc();
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, {
        if (invite) 'email': normalized,
        if (!invite) 'uid': normalized,
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
      batch.set(
        auditRef,
        _adminAuditPayload(
          action: l10n.adminAuditGrantSaved,
          targetType: collection,
          targetId: normalized,
          details: {'role': role.name, 'invite': invite},
        ),
      );
      await batch.commit();
      AdminAllowlist.invalidateCache();
      ref.invalidate(currentAdminRoleProvider);
      ref.invalidate(isCurrentUserAdminProvider);
      _snack(l10n.adminGrantSaved);
      await _loadAdminGrants();
    } catch (e) {
      _snack(_friendlyAdminError(e, fallback: l10n.adminGrantSaveFailed));
    }
  }

  Future<void> _deleteAdminGrant(_AdminGrantRow row) async {
    final currentRole = ref.read(currentAdminRoleProvider).asData?.value;
    if (currentRole?.canManageAdmins != true) {
      _snack(l10n.adminFullAccessRequiredForGrantManagement);
      return;
    }
    if (AdminAllowlist.kFullAccessAdminEmails.contains(row.id)) {
      _snack(l10n.adminFullAccessAccountCannotBeRemoved);
      return;
    }
    final confirmed = await _confirmDelete(
      title: l10n.adminRemoveGrantTitle,
      message: l10n.adminRemoveGrantMessage(row.label),
      preview: row.id,
      confirmLabel: l10n.willpowerHubRemoveAction,
    );
    if (!confirmed) return;
    final collection = row.isInvite ? 'admin_invites' : 'admin_users';
    final docRef = FirebaseFirestore.instance
        .collection(collection)
        .doc(row.id);
    final auditRef = FirebaseFirestore.instance.collection('admin_audit').doc();
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(docRef);
      batch.set(
        auditRef,
        _adminAuditPayload(
          action: l10n.adminAuditGrantRemoved,
          targetType: collection,
          targetId: row.id,
          details: {'role': row.role.name},
        ),
      );
      await batch.commit();
      AdminAllowlist.invalidateCache();
      ref.invalidate(currentAdminRoleProvider);
      ref.invalidate(isCurrentUserAdminProvider);
      _snack(l10n.adminGrantRemoved);
      await _loadAdminGrants();
    } catch (e) {
      _snack(_friendlyAdminError(e, fallback: l10n.adminGrantRemoveFailed));
    }
  }

  Future<void> _loadPremiumGrants() async {
    final role = ref.read(currentAdminRoleProvider).asData?.value;
    if (role?.canManageAdmins != true) return;
    setState(() {
      _premiumLoading = true;
      _premiumError = null;
    });
    try {
      final entitlementsSnap = await FirebaseFirestore.instance
          .collection('premium_entitlements')
          .limit(80)
          .get(const GetOptions(source: Source.server));
      final invitesSnap = await FirebaseFirestore.instance
          .collection('premium_invites')
          .limit(80)
          .get(const GetOptions(source: Source.server));
      final entitlements = entitlementsSnap.docs.map((doc) {
        final data = doc.data();
        return _PremiumGrantRow(
          id: doc.id,
          label: data['email']?.toString() ?? data['uid']?.toString() ?? doc.id,
          active: data['active'] == true,
          expiresAt: _dateFromAdminValue(data['expiresAt']),
          source: data['source']?.toString() ?? 'admin',
          isInvite: false,
        );
      }).toList()..sort((a, b) => a.label.compareTo(b.label));
      final invites = invitesSnap.docs.map((doc) {
        final data = doc.data();
        return _PremiumGrantRow(
          id: doc.id,
          label: data['email']?.toString() ?? doc.id,
          active: data['active'] == true,
          expiresAt: _dateFromAdminValue(data['expiresAt']),
          source: data['source']?.toString() ?? 'admin',
          isInvite: true,
        );
      }).toList()..sort((a, b) => a.label.compareTo(b.label));
      if (!mounted) return;
      setState(() {
        _premiumEntitlements = entitlements;
        _premiumInvites = invites;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _premiumError = _friendlyAdminError(
          e,
          fallback: 'Premium listesi alınamadı.',
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _premiumLoading = false);
      }
    }
  }

  DateTime? _dateFromAdminValue(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _openPremiumGrantDialog({_PremiumGrantRow? existing}) async {
    final targetCtrl = TextEditingController(
      text: existing?.label == existing?.id
          ? existing?.id ?? ''
          : existing?.label ?? '',
    );
    final daysCtrl = TextEditingController();
    final result = await showDialog<({String target, int? days})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Premium ver' : 'Premium düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: targetCtrl,
              enabled: existing == null,
              decoration: const InputDecoration(
                labelText: 'E-posta veya UID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Süre (gün) - boş bırakırsan süresiz',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final rawDays = int.tryParse(daysCtrl.text.trim());
              Navigator.pop(ctx, (
                target: targetCtrl.text,
                days: rawDays == null || rawDays <= 0 ? null : rawDays,
              ));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    targetCtrl.dispose();
    daysCtrl.dispose();
    if (result == null) return;
    await _savePremiumGrant(
      target: existing?.id ?? result.target,
      days: result.days,
      isInvite: existing?.isInvite,
    );
  }

  Future<void> _savePremiumGrant({
    required String target,
    required int? days,
    bool? isInvite,
  }) async {
    final currentRole = ref.read(currentAdminRoleProvider).asData?.value;
    if (currentRole?.canManageAdmins != true) {
      _snack('Premium yönetimi için tam yetki gerekiyor.');
      return;
    }
    final normalized = _normalizeAdminTarget(target);
    if (normalized.isEmpty) {
      _snack('E-posta veya UID boş olamaz.');
      return;
    }
    final invite = isInvite ?? _adminTargetIsEmail(normalized);
    final collection = invite ? 'premium_invites' : 'premium_entitlements';
    final docRef = FirebaseFirestore.instance
        .collection(collection)
        .doc(normalized);
    final auditRef = FirebaseFirestore.instance.collection('admin_audit').doc();
    final expiresAt = days == null
        ? null
        : Timestamp.fromDate(DateTime.now().add(Duration(days: days)));
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, {
        if (invite) 'email': normalized,
        if (!invite) 'uid': normalized,
        'active': true,
        'source': 'admin',
        'productId': 'admin_grant',
        'platform': 'firebase_admin_panel',
        'expiresAt': expiresAt,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
      batch.set(
        auditRef,
        _adminAuditPayload(
          action: 'Premium verildi',
          targetType: collection,
          targetId: normalized,
          details: {'days': days, 'invite': invite},
        ),
      );
      await batch.commit();
      ref.invalidate(premiumEntitlementProvider);
      _snack('Premium kaydı güncellendi.');
      await _loadPremiumGrants();
    } catch (e) {
      _snack(_friendlyAdminError(e, fallback: 'Premium kaydedilemedi.'));
    }
  }

  Future<void> _revokePremiumGrant(_PremiumGrantRow row) async {
    final currentRole = ref.read(currentAdminRoleProvider).asData?.value;
    if (currentRole?.canManageAdmins != true) {
      _snack('Premium yönetimi için tam yetki gerekiyor.');
      return;
    }
    final confirmed = await _confirmDelete(
      title: 'Premium geri alınsın mı?',
      message: '${row.label} için premium erişimi pasife alınacak.',
      preview: row.id,
      confirmLabel: 'Geri al',
    );
    if (!confirmed) return;
    final collection = row.isInvite ? 'premium_invites' : 'premium_entitlements';
    final docRef = FirebaseFirestore.instance.collection(collection).doc(row.id);
    final auditRef = FirebaseFirestore.instance.collection('admin_audit').doc();
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, {
        'active': false,
        'revokedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
      batch.set(
        auditRef,
        _adminAuditPayload(
          action: 'Premium geri alındı',
          targetType: collection,
          targetId: row.id,
          details: {'source': row.source},
        ),
      );
      await batch.commit();
      ref.invalidate(premiumEntitlementProvider);
      _snack('Premium erişimi pasife alındı.');
      await _loadPremiumGrants();
    } catch (e) {
      _snack(_friendlyAdminError(e, fallback: 'Premium geri alınamadı.'));
    }
  }

  _PoolEditorKind _poolEditorKind(String poolId) {
    switch (poolId) {
      case QuotePoolIds.notificationArinmaBodies:
      case QuotePoolIds.zikirDailyReflections:
        return _PoolEditorKind.textOnly;
      case QuotePoolIds.widgetQuote:
        return _PoolEditorKind.textAndSource;
      case QuotePoolIds.personalizedQuotes:
        return _PoolEditorKind.personalized;
      case QuotePoolIds.homeNamazWisdom:
        return _PoolEditorKind.namazWisdom;
      case QuotePoolIds.healingComfort:
        return _PoolEditorKind.healing;
      case QuotePoolIds.hubGelisimIslamic:
      case QuotePoolIds.hubGelisimMedical:
      case QuotePoolIds.hubArinmaIslamic:
      case QuotePoolIds.hubArinmaMedical:
        return _PoolEditorKind.hubInsight;
      default:
        return _PoolEditorKind.textOnly;
    }
  }

  Future<void> _editPoolItem(
    List<Map<String, dynamic>> items,
    int index,
  ) async {
    final kind = _poolEditorKind(_poolId);
    final existing = index >= 0
        ? Map<String, dynamic>.from(items[index])
        : null;

    final textCtrl = TextEditingController(
      text: _poolTextField(existing, kind),
    );
    final sourceCtrl = TextEditingController(
      text: existing?['source']?.toString() ?? '',
    );
    final arabicCtrl = TextEditingController(text: _poolArabic(existing, kind));
    final refCtrl = TextEditingController(
      text: existing?['ref']?.toString() ?? '',
    );
    var kindValue = existing?['kind']?.toString() ?? 'Hadis';
    if (!['Hadis', 'Âyet', 'Söz'].contains(kindValue)) {
      kindValue = 'Hadis';
    }
    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final bodyCtrl = TextEditingController(
      text: existing?['body']?.toString() ?? '',
    );
    final referenceCtrl = TextEditingController(
      text: existing?['reference']?.toString() ?? '',
    );

    var kindValueOut = kindValue;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                index >= 0 ? l10n.adminEditItemTitle : l10n.adminAddItemTitle,
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (kind == _PoolEditorKind.textOnly) ...[
                        TextField(
                          controller: textCtrl,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: l10n.adminWordLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (kind == _PoolEditorKind.textAndSource) ...[
                        TextField(
                          controller: textCtrl,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: l10n.adminTextLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: sourceCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminOptionalSourceLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (kind == _PoolEditorKind.personalized) ...[
                        TextField(
                          controller: textCtrl,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: l10n.adminTurkishTextLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: arabicCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.adminOptionalArabicLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: sourceCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminOptionalSourceLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (kind == _PoolEditorKind.namazWisdom) ...[
                        TextField(
                          controller: textCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.adminTurkishLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: arabicCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.adminArabicLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: kindValueOut,
                          decoration: InputDecoration(
                            labelText: l10n.adminTypeLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Hadis',
                              child: Text(l10n.adminInspireContentKindHadith),
                            ),
                            DropdownMenuItem(
                              value: 'Âyet',
                              child: Text(l10n.adminInspireContentKindVerse),
                            ),
                            DropdownMenuItem(
                              value: 'Söz',
                              child: Text(l10n.adminInspireContentKindQuote),
                            ),
                          ],
                          onChanged: (v) =>
                              setLocal(() => kindValueOut = v ?? 'Hadis'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: sourceCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminOptionalSourceLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (kind == _PoolEditorKind.healing) ...[
                        TextField(
                          controller: textCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.adminTurkishLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: arabicCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.adminArabicLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: refCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminReferenceLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (kind == _PoolEditorKind.hubInsight) ...[
                        TextField(
                          controller: titleCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminTitleLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: bodyCtrl,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: l10n.adminTextLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: referenceCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminOptionalSourceReferenceLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.adminSaveAction),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      if (ok != true) return;

      Map<String, dynamic>? built;
      switch (kind) {
        case _PoolEditorKind.textOnly:
          final t = textCtrl.text.trim();
          if (t.isEmpty) {
            _snack(l10n.adminWordCannotBeEmpty);
            return;
          }
          built = {'text': t};
          break;
        case _PoolEditorKind.textAndSource:
          final t = textCtrl.text.trim();
          if (t.isEmpty) {
            _snack(l10n.adminTextCannotBeEmpty);
            return;
          }
          built = {'text': t, 'source': sourceCtrl.text.trim()};
          break;
        case _PoolEditorKind.personalized:
          final t = textCtrl.text.trim();
          if (t.isEmpty) {
            _snack(l10n.adminTurkishTextCannotBeEmpty);
            return;
          }
          built = {
            if (existing != null) ...existing,
            'id':
                existing?['id'] ??
                'admin_${DateTime.now().millisecondsSinceEpoch}',
            'text': t,
            'source': sourceCtrl.text.trim(),
            if (arabicCtrl.text.trim().isNotEmpty)
              'arabic': arabicCtrl.text.trim(),
            'tags': (existing?['tags'] as List?) ?? <String>[],
          };
          break;
        case _PoolEditorKind.namazWisdom:
          final t = textCtrl.text.trim();
          if (t.isEmpty || arabicCtrl.text.trim().isEmpty) {
            _snack(l10n.adminTurkishAndArabicRequired);
            return;
          }
          built = {
            'turkish': t,
            'arabic': arabicCtrl.text.trim(),
            'kind': kindValueOut,
            if (sourceCtrl.text.trim().isNotEmpty)
              'source': sourceCtrl.text.trim(),
          };
          break;
        case _PoolEditorKind.healing:
          final t = textCtrl.text.trim();
          if (t.isEmpty ||
              arabicCtrl.text.trim().isEmpty ||
              refCtrl.text.trim().isEmpty) {
            _snack(l10n.adminTurkishArabicReferenceRequired);
            return;
          }
          built = {
            'turkish': t,
            'arabic': arabicCtrl.text.trim(),
            'ref': refCtrl.text.trim(),
          };
          break;
        case _PoolEditorKind.hubInsight:
          final ti = titleCtrl.text.trim();
          final bo = bodyCtrl.text.trim();
          if (ti.isEmpty || bo.isEmpty) {
            _snack(l10n.adminTitleAndTextRequired);
            return;
          }
          built = {
            'title': ti,
            'body': bo,
            if (referenceCtrl.text.trim().isNotEmpty)
              'reference': referenceCtrl.text.trim(),
          };
          break;
      }

      final next = List<Map<String, dynamic>>.from(items);
      if (index >= 0) {
        next[index] = built;
      } else {
        next.add(built);
      }
      await _savePool(
        next,
        actionLabel: index >= 0
            ? l10n.adminPoolItemWillBeEdited
            : l10n.adminNewPoolItemWillBeAdded,
      );
    } finally {
      textCtrl.dispose();
      sourceCtrl.dispose();
      arabicCtrl.dispose();
      refCtrl.dispose();
      titleCtrl.dispose();
      bodyCtrl.dispose();
      referenceCtrl.dispose();
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  String _friendlyAdminError(Object e, {required String fallback}) {
    if (e is _AdminVersionConflict) {
      return l10n.adminVersionConflictError;
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return l10n.adminNoPermissionForOperation;
        case 'unavailable':
        case 'network-request-failed':
          return l10n.adminNetworkOrServiceUnavailable;
        case 'deadline-exceeded':
          return l10n.adminOperationTimedOut;
        case 'unauthenticated':
          return l10n.adminSessionCouldNotBeVerified;
      }
    }
    return fallback;
  }

  String _poolTextField(Map<String, dynamic>? m, _PoolEditorKind k) {
    if (m == null) return '';
    switch (k) {
      case _PoolEditorKind.textOnly:
      case _PoolEditorKind.textAndSource:
      case _PoolEditorKind.personalized:
        return m['text']?.toString() ?? '';
      case _PoolEditorKind.namazWisdom:
      case _PoolEditorKind.healing:
        return m['turkish']?.toString() ?? '';
      case _PoolEditorKind.hubInsight:
        return '';
    }
  }

  String _poolArabic(Map<String, dynamic>? m, _PoolEditorKind k) {
    if (m == null) return '';
    if (k == _PoolEditorKind.personalized) {
      return m['arabic']?.toString() ?? '';
    }
    if (k == _PoolEditorKind.namazWisdom || k == _PoolEditorKind.healing) {
      return m['arabic']?.toString() ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Admin kontrolü Firestore'a dayandığı için async. Yüklenirken
    // progress göster, sonuç false ise nazik "erişim yok" ekranı.
    final adminAsync = ref.watch(isCurrentUserAdminProvider);
    if (adminAsync.isLoading) {
      _isAdminVerified = false;
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (adminAsync.hasError) {
      _isAdminVerified = false;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminAuthorizationCouldNotBeVerified)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 42),
                const SizedBox(height: 12),
                Text(
                  l10n.adminAuthorizationCheckUnavailable,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(isCurrentUserAdminProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.homeRetryAction),
                ),
                TextButton(
                  onPressed: () => context.go('/settings'),
                  child: Text(l10n.adminBackToSettings),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (adminAsync.asData?.value != true) {
      _isAdminVerified = false;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminNoAccessTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 42),
                const SizedBox(height: 12),
                Text(
                  l10n.adminPageForAdminsOnly,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/settings'),
                  child: Text(l10n.adminBackToSettings),
                ),
              ],
            ),
          ),
        ),
      );
    }
    _isAdminVerified = true;
    if (!_adminBootstrapped) {
      _adminBootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadPool();
        }
      });
    }
    // Salt bilgi amaçlı (identity strip) — yetki kararı yukarıda async
    // kontrol ile verildi; burası sadece "kim giriş yaptı" göstergesi.
    final email = FirebaseAuth.instance.currentUser?.email;
    final adminRole = ref.watch(currentAdminRoleProvider).asData?.value;
    final role = adminRole ?? AdminRole.none;

    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        title: Text(l10n.adminPanelTitle),
        backgroundColor: AppColors.emeraldDark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2_outlined), text: l10n.adminPoolsTab),
            Tab(
              icon: const Icon(Icons.photo_library_outlined),
              text: l10n.adminInspireCardsTab,
            ),
            Tab(
              icon: const Icon(Icons.monitor_heart_outlined),
              text: l10n.adminDiagnosticsTab,
            ),
            Tab(icon: const Icon(Icons.build_outlined), text: l10n.adminDeveloperTab),
            Tab(
              icon: const Icon(Icons.manage_accounts_outlined),
              text: l10n.adminGrantsTab,
            ),
            const Tab(
              icon: Icon(Icons.workspace_premium_outlined),
              text: 'Premium',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _AdminIdentityStrip(
            email: email,
            projectId: Firebase.app().options.projectId,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildPoolsTab(),
                _buildInspireTab(),
                _buildDiagnosticsTab(role),
                _buildDeveloperToolsTab(role),
                _buildAdminGrantsTab(role),
                _buildPremiumGrantsTab(role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.55)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperToolsTab(AdminRole role) {
    if (role.canUseDeveloperTools) {
      return const AdminDevTab();
    }
    return _buildAccessDenied(
      icon: Icons.admin_panel_settings_outlined,
      title: l10n.adminSectionOnlyForFullAccess,
      subtitle: l10n.adminDeveloperToolsDeveloperOnly,
    );
  }

  Widget _buildPoolsTab() {
    if (_poolLoading && _poolDoc == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bottomInset = _shellBodyBottomInset(context);
    final allItems = _itemsFromDoc();
    final q = _poolSearch.trim().toLowerCase();
    final itemIndices = <int>[];
    for (var i = 0; i < allItems.length; i++) {
      if (q.isEmpty) {
        itemIndices.add(i);
        continue;
      }
      final m = allItems[i];
      var hit = false;
      for (final v in m.values) {
        if (v == null) continue;
        if (v.toString().toLowerCase().contains(q)) {
          hit = true;
          break;
        }
      }
      if (hit) itemIndices.add(i);
    }
    final items = <Map<String, dynamic>>[
      for (final idx in itemIndices) allItems[idx],
    ];
    final role =
        ref.watch(currentAdminRoleProvider).asData?.value ?? AdminRole.none;

    return _buildAdminPoolsTab(
      context: context,
      bottomInset: bottomInset,
      allItems: allItems,
      items: items,
      itemIndices: itemIndices,
      poolId: _poolId,
      poolDoc: _poolDoc,
      poolError: _poolError,
      poolSearch: _poolSearch,
      poolLoading: _poolLoading,
      seedingAll: _seedingAll,
      canSeedMissingPools: role.canSeedMissingPools,
      canResetAllPools: role.canResetAllPools,
      onPoolChanged: (v) {
        setState(() => _poolId = v);
        _loadPool();
      },
      onSeedDefaults: _seedDefaults,
      onExportCurrentPool: _exportCurrentPool,
      onImportPoolBackup: _importPoolBackup,
      onSeedAllMergeOnly: () => _seedAllPools(mergeOnly: true),
      onSeedAllReset: () => _seedAllPools(mergeOnly: false),
      onSearchChanged: (v) => setState(() => _poolSearch = v),
      onClearSearch: () => setState(() => _poolSearch = ''),
      onAddItem: () => _editPoolItem(allItems, -1),
      onEditItem: (realIndex) => _editPoolItem(allItems, realIndex),
      onDeleteItem: (realIndex, preview) async {
        final confirmed = await _confirmDelete(
          title: l10n.adminDeletePoolItemTitle,
          message: l10n.adminDeletePoolItemMessage(_poolId),
          preview: preview,
        );
        if (!confirmed) return;
        final next = List<Map<String, dynamic>>.from(allItems)
          ..removeAt(realIndex);
        await _savePool(next, actionLabel: l10n.adminPoolItemWillBeDeleted);
      },
    );
  }

  Widget _buildInspireTab() {
    final bottomInset = _shellBodyBottomInset(context);
    final useIdx = _inspireImageIndices.isNotEmpty
        ? _inspireImageIndices
        : <int>[1];

    return _buildAdminInspireTab(
      context: context,
      bottomInset: bottomInset,
      inspireLoading: _inspireLoading,
      inspireError: _inspireError,
      inspireRows: _inspireRows,
      inspireDoc: _inspireDoc,
      imageIndices: useIdx,
      onAddCard: _addInspireCard,
      onRefreshFromServer: () {
        _inspireLoadStarted = false;
        _loadInspire();
      },
      onPullToRefresh: () async {
        _inspireLoadStarted = false;
        await _loadInspire();
      },
      onDuplicateAt: _duplicateInspireAt,
      onShuffleAt: (i) {
        setState(() {
          _inspireRows[i].rerollDesign(_rng, useIdx);
        });
      },
      onDeleteAt: (i, textPreview) async {
        final confirmed = await _confirmDelete(
          title: l10n.adminRemoveCardFromListTitle,
          message: l10n.adminRemoveCardFromListMessage,
          preview: textPreview,
          confirmLabel: l10n.adminRemoveAction,
        );
        if (!confirmed) return;
        _removeInspireAt(i);
      },
      onKindChanged: (i, kind) {
        setState(() => _inspireRows[i].contentKind = kind);
      },
      onMainFeedChanged: (i, on) {
        setState(() => _inspireRows[i].showInMainFeed = on);
      },
      onSaveAll: _saveInspire,
    );
  }

  String _diagTimeText(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  Widget _buildDiagnosticsTab(AdminRole role) {
    if (!role.canUseDiagnostics) {
      return _buildAccessDenied(
        icon: Icons.monitor_heart_outlined,
        title: l10n.adminDiagnosticsAccessDeniedTitle,
        subtitle: l10n.adminDiagnosticsAccessDeniedSubtitle,
      );
    }
    final prefs = ref.watch(sharedPreferencesProvider);
    final bottomInset = _shellBodyBottomInset(context);
    final appDaily = AppNotificationChannelPrefs.arinmaDailyEnabled(prefs);
    final appMilestone = AppNotificationChannelPrefs.milestoneEnabled(prefs);
    final appTask = AppNotificationChannelPrefs.taskReminderEnabled(prefs);
    final appZikir = AppNotificationChannelPrefs.zikirQuoteEnabled(prefs);
    final prayerOn = PrayerReminderPrefs.isEnabled(prefs);
    return AdminDiagnosticsTab(
      bottomInset: bottomInset,
      prayerOn: prayerOn,
      appDaily: appDaily,
      appMilestone: appMilestone,
      appTask: appTask,
      appZikir: appZikir,
      pendingCount: _diagPendingCount,
      loading: _diagLoading,
      logs: _diagLogs,
      onRefresh: _loadDiagnostics,
      onExport: _exportDiagnostics,
      onClear: _clearDiagnostics,
      formatTime: _diagTimeText,
    );
  }

  String _roleLabel(AdminRole role) {
    switch (role) {
      case AdminRole.content:
        return l10n.adminRoleContentPlain;
      case AdminRole.manager:
        return l10n.adminRoleManagerPlain;
      case AdminRole.developer:
        return l10n.adminRoleDeveloperPlain;
      case AdminRole.none:
        return l10n.adminRoleNonePlain;
    }
  }

  Widget _buildAdminGrantsTab(AdminRole role) {
    if (!role.canManageAdmins) {
      return _buildAccessDenied(
        icon: Icons.manage_accounts_outlined,
        title: l10n.adminGrantManagementAccessDeniedTitle,
        subtitle: l10n.adminGrantManagementAccessDeniedSubtitle,
      );
    }
    final bottomInset = _shellBodyBottomInset(context);
    final rows = <_AdminGrantRow>[..._adminInvites, ..._adminGrants];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      children: [
        Text(
          l10n.adminGrantHint,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _adminGrantsLoading ? null : () => _openGrantDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.adminGrantAccessAction),
            ),
            OutlinedButton.icon(
              onPressed: _adminGrantsLoading ? null : _loadAdminGrants,
              icon: _adminGrantsLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(l10n.adminRefreshAction),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF0F2419),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.adminFixedFullAccess(
                AdminAllowlist.kFullAccessAdminEmails.join(', '),
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (_adminGrantsError != null) ...[
          const SizedBox(height: 8),
          Text(
            _adminGrantsError!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.adminDefinedGrants(rows.length),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Card(
            color: const Color(0xFF0F2419),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _adminGrantsLoading
                    ? l10n.adminGrantsLoading
                    : l10n.adminNoFirestoreGrantsYet,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          )
        else
          ...rows.map(
            (row) => Card(
              color: const Color(0xFF0F2419),
              child: ListTile(
                title: Text(row.label),
                subtitle: Text(
                  '${row.isInvite ? l10n.adminEmailInviteLabel : l10n.adminDevUidLabel} · ${row.id}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(label: Text(_roleLabel(row.role))),
                    IconButton(
                      tooltip: l10n.adminEditTooltip,
                      onPressed: () => _openGrantDialog(existing: row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.willpowerHubRemoveAction,
                      onPressed: () => _deleteAdminGrant(row),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumGrantsTab(AdminRole role) {
    if (!role.canManageAdmins) {
      return _buildAccessDenied(
        icon: Icons.workspace_premium_outlined,
        title: 'Premium yönetimi tam yetki ister',
        subtitle: 'Premium verme/alma işlemleri yalnızca developer rolünde açık.',
      );
    }
    final bottomInset = _shellBodyBottomInset(context);
    final rows = <_PremiumGrantRow>[
      ..._premiumInvites,
      ..._premiumEntitlements,
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      children: [
        Text(
          'Premium kayıtları sadece bu sekme açılınca okunur. Kullanıcı tarafı '
          'da sürekli stream dinlemez; maliyet için tek seferlik entitlement '
          'kontrolü yapar.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed:
                  _premiumLoading ? null : () => _openPremiumGrantDialog(),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('Premium ver'),
            ),
            OutlinedButton.icon(
              onPressed: _premiumLoading ? null : _loadPremiumGrants,
              icon: _premiumLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF0F2419),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'UID girersen premium_entitlements/{uid}, e-posta girersen '
              'premium_invites/{email} yazılır. Kullanıcı giriş yapınca kendi '
              'UID kaydı, yoksa e-posta daveti kontrol edilir.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ),
        if (_premiumError != null) ...[
          const SizedBox(height: 8),
          Text(_premiumError!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 12),
        Text(
          'Premium kayıtları (${rows.length})',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Card(
            color: const Color(0xFF0F2419),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _premiumLoading
                    ? 'Premium kayıtları yükleniyor...'
                    : 'Henüz premium kaydı yok.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          )
        else
          ...rows.map((row) {
            final expires = row.expiresAt == null
                ? 'Süresiz'
                : 'Bitiş: ${_diagTimeText(row.expiresAt!.toIso8601String())}';
            final active = row.active &&
                (row.expiresAt == null ||
                    row.expiresAt!.isAfter(DateTime.now()));
            return Card(
              color: const Color(0xFF0F2419),
              child: ListTile(
                title: Text(row.label),
                subtitle: Text(
                  '${row.isInvite ? 'E-posta daveti' : 'UID'} · ${row.id}\n'
                  '$expires · kaynak: ${row.source}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(active ? 'Aktif' : 'Pasif'),
                      backgroundColor: active
                          ? AppColors.accentNeonGreen.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    IconButton(
                      tooltip: 'Düzenle',
                      onPressed: () => _openPremiumGrantDialog(existing: row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Geri al',
                      onPressed: () => _revokePremiumGrant(row),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AdminVersionConflict implements Exception {
  const _AdminVersionConflict();
}

class _AdminGrantRow {
  const _AdminGrantRow({
    required this.id,
    required this.label,
    required this.role,
    required this.isInvite,
  });

  final String id;
  final String label;
  final AdminRole role;
  final bool isInvite;
}

class _PremiumGrantRow {
  const _PremiumGrantRow({
    required this.id,
    required this.label,
    required this.active,
    required this.expiresAt,
    required this.source,
    required this.isInvite,
  });

  final String id;
  final String label;
  final bool active;
  final DateTime? expiresAt;
  final String source;
  final bool isInvite;
}

enum _PoolEditorKind {
  textOnly,
  textAndSource,
  personalized,
  namazWisdom,
  healing,
  hubInsight,
}
