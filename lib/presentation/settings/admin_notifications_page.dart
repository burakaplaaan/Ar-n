// Admin — Ayet Bildirimleri (sade, tek sekme).
//
// Bu panel saat:dakika eşleşmeli ayet bildirimlerini yönetir:
//   • Genel ayarlar (otomatik açık/kapalı, kaç günde bir gönderim, varsayılan
//     tekrar süresi).
//   • Hazır bildirim metinleri havuzu (otomatik gönderimlerde ve ayet
//     dosyasında bildirim metni boş bırakıldığında rastgele seçilir).
//   • Ayet listesi: her ayetin kendi saat (HH:MM = Sure:Ayet), sure adı,
//     Türkçe meal, bildirim metni (özel veya hazır havuz), kendi tekrar süresi
//     ve etkinlik tiki vardır.
//   • Her ayet için "▶ Şimdi gönder" — `sendMomentVerseNow` callable'ı
//     çağırır, push'u anında atar (saat/cooldown bypass eder).
//
// Cloud function tarafı (`functions/index.js`) bu sayfayla uyumludur:
//   • `admin_ntf_pool/{id}` — ayet kayıtları
//   • `admin_ntf_config/schedule` — global ayarlar
//   • `admin_ntf_config/teasers` — hazır metin havuzu
//   • `admin_ntf_config/current_moment` — push tıklanınca okunan 5dk pencere

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/firebase/firebase_bootstrap.dart';

// ── Sabitler ──────────────────────────────────────────────────────────────────

abstract final class _Col {
  static const String pool = 'admin_ntf_pool';
  static const String config = 'admin_ntf_config';
  static const String scheduleDoc = 'schedule';
  static const String teasersDoc = 'teasers';
}

/// Cloud function bölgesi — `functions/index.js` `region: europe-west1` ile
/// senkron tutulmalıdır.
const String _kFunctionsRegion = 'europe-west1';

// ── Renkler & yardımcılar ────────────────────────────────────────────────────

const _kBgScaffold = Color(0xFF071815);
const _kBgCard = Color(0xFF0F2419);
const _kBgInput = Color(0xFF162C22);

String _pad2(int v) => v.toString().padLeft(2, '0');
String _clockStr(int h, int m) => '${_pad2(h)}:${_pad2(m)}';

DateTime? _toDateTime(Object? v) {
  if (v is Timestamp) return v.toDate().toLocal();
  if (v is DateTime) return v.toLocal();
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt()).toLocal();
  if (v is String) {
    // 'YYYY-MM-DD' formatı (lastSentDate)
    final parts = v.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final mo = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && mo != null && d != null) return DateTime(y, mo, d);
    }
    return DateTime.tryParse(v);
  }
  return null;
}

String _fmtAgo(DateTime? d) {
  if (d == null) return 'henüz gönderilmedi';
  final diff = DateTime.now().difference(d);
  if (diff.inDays >= 1) return '${diff.inDays} gün önce';
  if (diff.inHours >= 1) return '${diff.inHours} sa önce';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} dk önce';
  return 'az önce';
}

// ── Sayfa ────────────────────────────────────────────────────────────────────

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage> {
  // Genel ayarlar
  bool _autoEnabled = true;
  int _sendEveryNDays = 3;
  int _defaultMinRepeatDays = 60;
  String? _lastAutoSentDate;
  bool _scheduleSaving = false;
  bool _scheduleLoaded = false;

  // Bugünün planı (today_plan dokümanı)
  Map<String, dynamic>? _todayPlan;
  bool _todayPlanLoading = false;

  // Hazır metin havuzu
  List<String> _teasers = const [];
  bool _teasersSaving = false;
  bool _teasersLoaded = false;
  bool _teasersExpanded = false;
  final TextEditingController _newTeaserCtrl = TextEditingController();

  // Test bildirimi
  bool _testSending = false;

  // Ayet havuzu
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _poolDocs = const [];
  bool _poolLoading = false;
  String? _poolError;
  String _poolSearch = '';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _loadTeasers();
    _loadPool();
    _loadTodayPlan();
  }

  @override
  void dispose() {
    _newTeaserCtrl.dispose();
    super.dispose();
  }

  // ── Yükleyiciler ─────────────────────────────────────────────────────────

  Future<void> _loadSchedule() async {
    if (!isFirebaseReady || _scheduleLoaded) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.scheduleDoc)
          .get(const GetOptions(source: Source.serverAndCache));
      if (snap.exists) {
        final d = snap.data()!;
        _autoEnabled = (d['autoEnabled'] as bool?) ?? true;
        _sendEveryNDays = (d['sendEveryNDays'] as num?)?.toInt() ?? 3;
        _defaultMinRepeatDays = (d['minRepeatDays'] as num?)?.toInt() ?? 60;
        _lastAutoSentDate = d['lastAutoSentDate']?.toString();
      }
      _scheduleLoaded = true;
      if (mounted) setState(() {});
    } catch (_) {
      // sessiz hata — varsayılanlar kalır
    }
  }

  Future<void> _loadTodayPlan() async {
    if (!isFirebaseReady) return;
    setState(() => _todayPlanLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc('today_plan')
          .get(const GetOptions(source: Source.server));
      _todayPlan = snap.exists ? snap.data() : null;
    } catch (_) {
      _todayPlan = null;
    } finally {
      if (mounted) setState(() => _todayPlanLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (!isFirebaseReady || _scheduleSaving) return;
    setState(() => _scheduleSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.scheduleDoc)
          .set(
        {
          'autoEnabled': _autoEnabled,
          'sendEveryNDays': _sendEveryNDays,
          'minRepeatDays': _defaultMinRepeatDays,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        SetOptions(merge: true),
      );
      _snack('Ayarlar kaydedildi.');
    } catch (e) {
      _snack('Kaydedilemedi: $e', error: true);
    } finally {
      if (mounted) setState(() => _scheduleSaving = false);
    }
  }

  Future<void> _loadTeasers() async {
    if (!isFirebaseReady || _teasersLoaded) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.teasersDoc)
          .get(const GetOptions(source: Source.serverAndCache));
      if (snap.exists) {
        final raw = snap.data()?['texts'];
        if (raw is List) {
          _teasers = raw
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
      }
      _teasersLoaded = true;
      if (mounted) setState(() {});
    } catch (_) {
      // sessiz
    }
  }

  Future<void> _saveTeasers() async {
    if (!isFirebaseReady) return;
    setState(() => _teasersSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.teasersDoc)
          .set({
        'texts': _teasers,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.email ?? '',
      }, SetOptions(merge: true));
    } catch (e) {
      _snack('Hazır metinler kaydedilemedi: $e', error: true);
    } finally {
      if (mounted) setState(() => _teasersSaving = false);
    }
  }

  Future<void> _loadPool() async {
    if (!isFirebaseReady) return;
    setState(() {
      _poolLoading = true;
      _poolError = null;
    });
    try {
      // Not: `orderBy('hour').orderBy('minute')` Firestore composite index
      // gerektirir; küçük havuzlar için client-side sort yeterli ve index'siz.
      final snap = await FirebaseFirestore.instance
          .collection(_Col.pool)
          .get(const GetOptions(source: Source.serverAndCache));
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final ha = (a.data()['hour'] as num?)?.toInt() ?? 0;
          final hb = (b.data()['hour'] as num?)?.toInt() ?? 0;
          if (ha != hb) return ha.compareTo(hb);
          final ma = (a.data()['minute'] as num?)?.toInt() ?? 0;
          final mb = (b.data()['minute'] as num?)?.toInt() ?? 0;
          return ma.compareTo(mb);
        });
      _poolDocs = docs;
    } catch (e) {
      _poolError = 'Liste yüklenemedi: $e';
    } finally {
      if (mounted) setState(() => _poolLoading = false);
    }
  }

  // ── Yardımcı: snackbar ───────────────────────────────────────────────────

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : AppColors.emeraldDark,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Hazır metin işlemleri (her değişiklikte otomatik kaydedilir) ─────────

  Future<void> _addTeaser() async {
    final t = _newTeaserCtrl.text.trim();
    if (t.isEmpty) {
      _snack('Boş metin eklenemez.', error: true);
      return;
    }
    if (_teasers.contains(t)) {
      _snack('Bu metin zaten listede.', error: true);
      return;
    }
    setState(() {
      _teasers = [..._teasers, t];
      _newTeaserCtrl.clear();
    });
    await _saveTeasers();
  }

  Future<void> _removeTeaser(int index) async {
    if (index < 0 || index >= _teasers.length) return;
    setState(() {
      final next = [..._teasers]..removeAt(index);
      _teasers = next;
    });
    await _saveTeasers();
  }

  Future<void> _editTeaser(int index) async {
    if (index < 0 || index >= _teasers.length) return;
    final updated = await _showTextDialog(
      title: 'Hazır Metni Düzenle',
      initial: _teasers[index],
      hint: 'Bildirim gövdesi',
      maxLines: 3,
    );
    if (updated == null) return;
    final t = updated.trim();
    if (t.isEmpty) return;
    setState(() {
      final next = [..._teasers];
      next[index] = t;
      _teasers = next;
    });
    await _saveTeasers();
  }

  // ── Pool item işlemleri ──────────────────────────────────────────────────

  Future<void> _addOrEditPoolItem({String? docId, Map<String, dynamic>? existing}) async {
    final res = await showDialog<_PoolItemResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PoolItemDialog(
        teasers: _teasers,
        defaultMinRepeatDays: _defaultMinRepeatDays,
        initial: existing,
        isEdit: docId != null,
      ),
    );
    if (res == null) return;

    try {
      final col = FirebaseFirestore.instance.collection(_Col.pool);
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final payload = <String, dynamic>{
        'hour': res.hour,
        'minute': res.minute,
        // Saat:dakika ↔ Sure:Ayet kuralı: numara alanları otomatik türetilir.
        'surahNumber': res.hour,
        'verseNumber': res.minute,
        'surahName': res.surahName.trim(),
        'text': res.text.trim(),
        'ref': res.ref.trim(),
        'notificationBody': res.notificationBody.trim(),
        'enabled': res.enabled,
      };
      if (docId != null) {
        await col.doc(docId).update({
          ...payload,
          // Güncelleme: null ise alanı sil (FieldValue.delete yalnızca update/merge ile çalışır).
          if (res.minRepeatDaysOverride != null)
            'minRepeatDays': res.minRepeatDaysOverride
          else
            'minRepeatDays': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': email,
        });
        _snack('Güncellendi.');
      } else {
        await col.add({
          ...payload,
          // Ekleme: null ise alanı hiç gönderme; FieldValue.delete() add() ile kullanılamaz.
          if (res.minRepeatDaysOverride != null)
            'minRepeatDays': res.minRepeatDaysOverride,
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': email,
        });
        _snack('Eklendi.');
      }
      await _loadPool();
    } catch (e) {
      _snack('İşlem başarısız: $e', error: true);
    }
  }

  Future<void> _deletePoolItem(String docId, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kBgCard,
        title: const Text('Sil'),
        content: Text('"$label" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection(_Col.pool).doc(docId).delete();
      _snack('Silindi.');
      await _loadPool();
    } catch (e) {
      _snack('Silinemedi: $e', error: true);
    }
  }

  Future<void> _toggleEnabled(String docId, bool current) async {
    try {
      await FirebaseFirestore.instance
          .collection(_Col.pool)
          .doc(docId)
          .update({'enabled': !current});
      await _loadPool();
    } catch (e) {
      _snack('Değiştirilemedi: $e', error: true);
    }
  }

  /// Hızlı test — pool'a dokunmaz, sabit "TEST · ..." başlıklı push atar.
  /// Cooldown veya `lastSentDate` etkilenmez. Bildirime tıklanınca
  /// `MomentVersePage` test ayeti ile 5 dakikalık pencerede açılır.
  Future<void> _sendTestNotification() async {
    if (_testSending) return;
    setState(() => _testSending = true);
    try {
      _snack('Test bildirimi gönderiliyor…');
      final callable = FirebaseFunctions.instanceFor(region: _kFunctionsRegion)
          .httpsCallable('sendTestNotification');
      final res = await callable.call<Map<String, dynamic>>(<String, dynamic>{});
      if (res.data['ok'] == true) {
        _snack('Test bildirimi gönderildi. Cihazına gelmesi 5–30 sn sürebilir.');
      } else {
        _snack('Test başarısız.', error: true);
      }
    } on FirebaseFunctionsException catch (e) {
      _snack('Hata (${e.code}): ${e.message ?? e.code}', error: true);
    } catch (e) {
      _snack('Gönderilemedi: $e', error: true);
    } finally {
      if (mounted) setState(() => _testSending = false);
    }
  }

  Future<void> _sendNow(String docId, String preview) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kBgCard,
        title: const Text('Şimdi gönder'),
        content: Text(
          'Bu ayet TÜM kullanıcılara hemen bildirim olarak gönderilsin mi?\n\n"$preview"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentNeonGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      _snack('Gönderiliyor…');
      final callable = FirebaseFunctions.instanceFor(region: _kFunctionsRegion)
          .httpsCallable('sendMomentVerseNow');
      final res = await callable.call<Map<String, dynamic>>({
        'poolItemId': docId,
      });
      if (res.data['ok'] == true) {
        _snack('Bildirim gönderildi.');
        await _loadPool();
      } else {
        _snack('Gönderim başarısız.', error: true);
      }
    } on FirebaseFunctionsException catch (e) {
      _snack('Hata (${e.code}): ${e.message ?? e.code}', error: true);
    } catch (e) {
      _snack('Gönderilemedi: $e', error: true);
    }
  }

  // ── Genel metin dialog ───────────────────────────────────────────────────

  Future<String?> _showTextDialog({
    required String title,
    required String initial,
    String hint = '',
    int maxLines = 1,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kBgCard,
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentNeonGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final v = ctrl.text;
              ctrl.dispose();
              Navigator.pop(ctx, v);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _poolSearch.isEmpty
        ? _poolDocs
        : _poolDocs.where((doc) {
            final d = doc.data();
            final q = _poolSearch.toLowerCase();
            return (d['text']?.toString().toLowerCase() ?? '').contains(q) ||
                (d['surahName']?.toString().toLowerCase() ?? '').contains(q) ||
                (d['notificationBody']?.toString().toLowerCase() ?? '')
                    .contains(q) ||
                _clockStr(
                  (d['hour'] as num?)?.toInt() ?? 0,
                  (d['minute'] as num?)?.toInt() ?? 0,
                ).contains(q);
          }).toList(growable: false);

    return Scaffold(
      backgroundColor: _kBgScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.emeraldDark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ayet Bildirimleri',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _poolLoading ? null : _loadPool,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPool,
        color: AppColors.accentNeonGreen,
        backgroundColor: _kBgCard,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSchedulePanel()),
            SliverToBoxAdapter(child: _buildTestPanel()),
            SliverToBoxAdapter(child: _buildTeasersPanel()),
            SliverToBoxAdapter(child: _buildListHeader()),
            if (_poolError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    _poolError!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
            if (_poolLoading && _poolDocs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildPoolItemCard(filtered[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bugünün plan durumu ───────────────────────────────────────────────────

  Widget _buildTodayPlanRow() {
    if (_todayPlanLoading) {
      return const SizedBox(
        height: 20,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final plan = _todayPlan;
    if (plan == null) {
      return _planChip(
        icon: Icons.schedule_rounded,
        label: 'Bugün için henüz plan yok',
        color: Colors.white38,
      );
    }
    final planDate = plan['date']?.toString() ?? '';
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (planDate != todayStr) {
      return _planChip(
        icon: Icons.schedule_rounded,
        label: 'Bugün için henüz plan yok (son: $planDate)',
        color: Colors.white38,
      );
    }
    final sent = plan['sent'] as bool? ?? false;
    final missed = plan['missedAt'] != null;
    final sendAtHour = (plan['sendAtHour'] as num?)?.toInt();
    final sendAtMin = (plan['sendAtMin'] as num?)?.toInt();
    final timeStr = (sendAtHour != null && sendAtMin != null)
        ? '${_pad2(sendAtHour)}:${_pad2(sendAtMin)}'
        : '?';

    if (sent && missed) {
      return _planChip(
        icon: Icons.warning_amber_rounded,
        label: 'Bugün pencere geçti — $timeStr için planlanmıştı',
        color: Colors.orangeAccent,
        onRefresh: _loadTodayPlan,
      );
    }
    if (sent) {
      return _planChip(
        icon: Icons.check_circle_outline_rounded,
        label: 'Bugün gönderildi ($timeStr)',
        color: AppColors.accentNeonGreen,
        onRefresh: _loadTodayPlan,
      );
    }
    return _planChip(
      icon: Icons.timer_outlined,
      label: 'Bugün $timeStr\'de gönderilecek',
      color: Colors.white70,
      onRefresh: _loadTodayPlan,
    );
  }

  Widget _planChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onRefresh,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ),
        if (onRefresh != null)
          InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.refresh_rounded,
                size: 14,
                color: Colors.white38,
              ),
            ),
          ),
      ],
    );
  }

  // ── Kart: Genel ayarlar ──────────────────────────────────────────────────

  Widget _buildSchedulePanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.tune_rounded, 'Genel Ayarlar'),
            const SizedBox(height: 12),

            // Otomatik AÇIK/KAPALI — toggle anında kaydedilir.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _autoEnabled
                    ? AppColors.accentNeonGreen.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _autoEnabled
                      ? AppColors.accentNeonGreen.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _autoEnabled
                        ? Icons.autorenew_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 20,
                    color: _autoEnabled
                        ? AppColors.accentNeonGreen
                        : Colors.white54,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _autoEnabled ? 'Otomatik AÇIK' : 'Otomatik KAPALI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _autoEnabled
                                ? AppColors.accentNeonGreen
                                : Colors.white70,
                          ),
                        ),
                        Text(
                          _autoEnabled
                              ? 'Her dakika eşleşen ayet kontrol edilir.'
                              : 'Sadece "▶ Şimdi" butonu çalışır.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _autoEnabled,
                    activeTrackColor:
                        AppColors.accentNeonGreen.withValues(alpha: 0.4),
                    activeThumbColor: AppColors.accentNeonGreen,
                    onChanged: (v) async {
                      setState(() => _autoEnabled = v);
                      await _saveSchedule();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            _stepperRow(
              label: 'Her',
              suffix: 'günde bir gönderim',
              value: _sendEveryNDays,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _sendEveryNDays = v),
            ),
            const SizedBox(height: 8),
            _stepperRow(
              label: 'Varsayılan tekrar',
              suffix: 'gün',
              value: _defaultMinRepeatDays,
              min: 1,
              max: 365,
              onChanged: (v) => setState(() => _defaultMinRepeatDays = v),
            ),
            const SizedBox(height: 12),

            // Bugünün planı
            _buildTodayPlanRow(),

            const SizedBox(height: 12),
            Row(
              children: [
                if (_lastAutoSentDate != null)
                  Expanded(
                    child: Text(
                      'Son otomatik: $_lastAutoSentDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.accentNeonGreen.withValues(alpha: 0.18),
                    foregroundColor: AppColors.accentNeonGreen,
                  ),
                  onPressed: _scheduleSaving ? null : _saveSchedule,
                  child: _scheduleSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Kart: Hızlı test ──────────────────────────────────────────────────────
  //
  // Saat/dakika beklemeden push akışını test etmek için belirgin tek buton.
  // `sendTestNotification` callable'ı çağırır; pool'a dokunmaz, cooldown'ları
  // bozmaz. Bildirime tıklanınca MomentVersePage 5dk pencereyle açılır.
  Widget _buildTestPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.accentNeonGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlı Test',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saati beklemeden cihazına test bildirimi at.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentNeonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _testSending ? null : _sendTestNotification,
              icon: _testSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _testSending ? 'Gönderiliyor' : 'Test At',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kart: Hazır metinler (collapsible) ───────────────────────────────────

  Widget _buildTeasersPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () =>
                  setState(() => _teasersExpanded = !_teasersExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hazır Bildirim Metinleri',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_teasers.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _teasersExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
            if (_teasersExpanded) ...[
              const SizedBox(height: 8),
              Text(
                'Bir ayetin "bildirim metni" alanı boşsa, bu havuzdan rastgele bir metin seçilir.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 10),
              if (_teasers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Henüz hazır metin yok.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(_teasers.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                      decoration: BoxDecoration(
                        color: _kBgInput,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _teasers[i],
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.white54,
                            ),
                            tooltip: 'Düzenle',
                            onPressed: () => _editTeaser(i),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Sil',
                            onPressed: () => _removeTeaser(i),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTeaserCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Yeni hazır metin…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: _kBgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTeaser(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.accentNeonGreen.withValues(alpha: 0.18),
                      foregroundColor: AppColors.accentNeonGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _teasersSaving ? null : _addTeaser,
                    child: _teasersSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _teasersSaving
                    ? 'Kaydediliyor…'
                    : 'Değişiklikler otomatik kaydedilir.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Liste başlığı + arama ────────────────────────────────────────────────

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader(
                Icons.format_list_bulleted_rounded,
                'Ayetler',
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_poolDocs.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addOrEditPoolItem(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Yeni Ayet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentNeonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ara… (saat, sure adı, metin)',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.white38,
              ),
              filled: true,
              fillColor: _kBgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (v) => setState(() => _poolSearch = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              _poolSearch.isEmpty
                  ? 'Henüz ayet eklenmedi.\nAlttaki "+ Yeni Ayet" ile başla.'
                  : 'Aramaya uyan ayet bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pool item kartı ──────────────────────────────────────────────────────

  Widget _buildPoolItemCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final hour = (d['hour'] as num?)?.toInt() ?? 0;
    final minute = (d['minute'] as num?)?.toInt() ?? 0;
    final surahName = d['surahName']?.toString() ?? '';
    final text = d['text']?.toString() ?? '';
    final ref = d['ref']?.toString() ?? '';
    final body = d['notificationBody']?.toString() ?? '';
    final enabled = (d['enabled'] as bool?) ?? true;
    final lastSentDate = _toDateTime(d['lastSentDate']);
    final lastSentAt = _toDateTime(d['lastSentAt']);
    final lastSent = lastSentAt ?? lastSentDate;
    final itemMinRepeat = (d['minRepeatDays'] as num?)?.toInt();
    final hasOverride = itemMinRepeat != null;

    final clock = _clockStr(hour, minute);
    final label = text.isNotEmpty
        ? (text.length > 40 ? '${text.substring(0, 40)}…' : text)
        : 'Sure $hour:$minute';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: enabled ? _kBgCard : const Color(0xFF0A1C15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppColors.accentNeonGreen.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: saat + sure no + sure adı + toggle
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.accentNeonGreen.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: enabled
                          ? AppColors.accentNeonGreen.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    clock,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: enabled
                          ? AppColors.accentNeonGreen
                          : Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sure $hour, Ayet $minute',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.accentNeonGreen
                                  .withValues(alpha: 0.7)
                              : Colors.white24,
                        ),
                      ),
                      if (surahName.isNotEmpty)
                        Text(
                          surahName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: enabled ? Colors.white : Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  activeTrackColor:
                      AppColors.accentNeonGreen.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.accentNeonGreen,
                  onChanged: (_) => _toggleEnabled(doc.id, enabled),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _iconLine(
                icon: Icons.menu_book_rounded,
                text: text,
                maxLines: 2,
                color: enabled ? Colors.white : Colors.white38,
              ),
            ],
            if (body.isNotEmpty || _teasers.isNotEmpty) ...[
              const SizedBox(height: 6),
              _iconLine(
                icon: Icons.notifications_active_outlined,
                text: body.isNotEmpty
                    ? body
                    : '(Hazır havuzdan rastgele seçilecek)',
                maxLines: 2,
                color: body.isNotEmpty
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.4),
                italic: body.isEmpty,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  hasOverride
                      ? '$itemMinRepeat gün tekrar'
                      : '$_defaultMinRepeatDays gün (varsayılan)',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasOverride
                        ? AppColors.accentNeonGreen.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.4),
                    fontWeight:
                        hasOverride ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.history_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _fmtAgo(lastSent),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (ref.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ref,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.accentNeonGreen.withValues(alpha: 0.18),
                    foregroundColor: AppColors.accentNeonGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _sendNow(doc.id, label),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text(
                    'Şimdi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Düzenle',
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.white60,
                  ),
                  onPressed: () =>
                      _addOrEditPoolItem(docId: doc.id, existing: d),
                ),
                IconButton(
                  tooltip: 'Sil',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deletePoolItem(doc.id, label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Küçük yardımcı widget'lar ────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }

  Widget _stepperRow({
    required String label,
    required String suffix,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        _stepBtn(
          Icons.remove,
          value <= min ? null : () => onChanged((value - 1).clamp(min, max)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.accentNeonGreen,
              ),
            ),
          ),
        ),
        _stepBtn(
          Icons.add,
          value >= max ? null : () => onChanged((value + 1).clamp(min, max)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            suffix,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.accentNeonGreen.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onTap != null
                ? AppColors.accentNeonGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: onTap != null ? AppColors.accentNeonGreen : Colors.white24,
        ),
      ),
    );
  }

  Widget _iconLine({
    required IconData icon,
    required String text,
    Color? color,
    int maxLines = 1,
    bool italic = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: color ?? Colors.white,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pool item ekleme/düzenleme dialog'u
// ─────────────────────────────────────────────────────────────────────────────

class _PoolItemResult {
  const _PoolItemResult({
    required this.hour,
    required this.minute,
    required this.surahName,
    required this.text,
    required this.ref,
    required this.notificationBody,
    required this.enabled,
    required this.minRepeatDaysOverride,
  });

  final int hour;
  final int minute;
  final String surahName;
  final String text;
  final String ref;
  final String notificationBody;
  final bool enabled;
  final int? minRepeatDaysOverride;
}

class _PoolItemDialog extends StatefulWidget {
  const _PoolItemDialog({
    required this.teasers,
    required this.defaultMinRepeatDays,
    required this.isEdit,
    this.initial,
  });

  final List<String> teasers;
  final int defaultMinRepeatDays;
  final bool isEdit;
  final Map<String, dynamic>? initial;

  @override
  State<_PoolItemDialog> createState() => _PoolItemDialogState();
}

class _PoolItemDialogState extends State<_PoolItemDialog> {
  late int _hour;
  late int _minute;
  late bool _enabled;
  late bool _useCustomBody;
  late bool _useCustomRepeat;
  late int _customRepeatDays;

  final _surahNameCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    // Firestore num/double/int karışıklığına karşı num? üzerinden okunur.
    _hour = (init?['hour'] as num?)?.toInt() ?? 21;
    _minute = (init?['minute'] as num?)?.toInt() ?? 5;
    _enabled = (init?['enabled'] as bool?) ?? true;
    _surahNameCtrl.text = init?['surahName']?.toString() ?? '';
    _textCtrl.text = init?['text']?.toString() ?? '';
    _refCtrl.text = init?['ref']?.toString() ?? '';
    final body = init?['notificationBody']?.toString() ?? '';
    _useCustomBody = body.isNotEmpty;
    _bodyCtrl.text = body;
    final overrideDays = (init?['minRepeatDays'] as num?)?.toInt();
    _useCustomRepeat = overrideDays != null;
    _customRepeatDays = overrideDays ?? widget.defaultMinRepeatDays;
  }

  @override
  void dispose() {
    _surahNameCtrl.dispose();
    _textCtrl.dispose();
    _refCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentNeonGreen,
            onPrimary: Colors.black,
            surface: _kBgCard,
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: _kBgCard,
            hourMinuteColor: _kBgInput,
            dayPeriodColor: _kBgInput,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  bool _validate() {
    if (_textCtrl.text.trim().isEmpty) return false;
    if (_useCustomBody && _bodyCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayet metni zorunlu (özel bildirim seçtiysen onu da doldur).'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _PoolItemResult(
        hour: _hour,
        minute: _minute,
        surahName: _surahNameCtrl.text,
        text: _textCtrl.text,
        ref: _refCtrl.text,
        notificationBody: _useCustomBody ? _bodyCtrl.text : '',
        enabled: _enabled,
        minRepeatDaysOverride: _useCustomRepeat ? _customRepeatDays : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: _kBgCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isEdit
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    color: AppColors.accentNeonGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEdit ? 'Ayeti Düzenle' : 'Yeni Ayet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saat seçici
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _kBgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentNeonGreen
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppColors.accentNeonGreen
                                    .withValues(alpha: 0.85),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saat',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    Text(
                                      _clockStr(_hour, _minute),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentNeonGreen,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Sure $_hour · Ayet $_minute',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Saat:dakika otomatik olarak Sure:Ayet olur',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _dialogLabel('Sure Adı'),
                      _dialogField(
                        ctrl: _surahNameCtrl,
                        hint: 'Örn. Enbiyâ',
                      ),
                      const SizedBox(height: 12),

                      _dialogLabel('Ayet (Türkçe meal)'),
                      _dialogField(
                        ctrl: _textCtrl,
                        hint: 'Ayet meali…',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),

                      _dialogLabel('Kaynak (opsiyonel)'),
                      _dialogField(
                        ctrl: _refCtrl,
                        hint: "Örn. Kur'an 21:5",
                      ),
                      const SizedBox(height: 16),

                      // Bildirim metni
                      _sectionTitle('Bildirim Metni'),
                      const SizedBox(height: 8),
                      _radioRow(
                        label: 'Hazır havuzdan rastgele seç',
                        subtitle: widget.teasers.isEmpty
                            ? 'Havuz boş — sabit fallback metinler kullanılır'
                            : '${widget.teasers.length} hazır metin var',
                        value: false,
                        groupValue: _useCustomBody,
                        onChanged: (v) =>
                            setState(() => _useCustomBody = v ?? false),
                      ),
                      _radioRow(
                        label: 'Kendim yazacağım',
                        subtitle: 'Bu ayete özel sabit metin',
                        value: true,
                        groupValue: _useCustomBody,
                        onChanged: (v) =>
                            setState(() => _useCustomBody = v ?? false),
                      ),
                      if (_useCustomBody) ...[
                        const SizedBox(height: 8),
                        _dialogField(
                          ctrl: _bodyCtrl,
                          hint: 'Örn. Bu vaktin sende bırakacağı izi merak ediyor musun?',
                          maxLines: 3,
                        ),
                        if (widget.teasers.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Hızlı doldur:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.teasers
                                .map(
                                  (t) => ActionChip(
                                    label: Text(
                                      t.length > 30
                                          ? '${t.substring(0, 30)}…'
                                          : t,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: _kBgInput,
                                    side: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.08),
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _bodyCtrl.text = t),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),

                      // Tekrar süresi
                      _sectionTitle('Tekrar Süresi'),
                      const SizedBox(height: 8),
                      _radioRow(
                        label:
                            'Varsayılan (${widget.defaultMinRepeatDays} gün)',
                        value: false,
                        groupValue: _useCustomRepeat,
                        onChanged: (v) =>
                            setState(() => _useCustomRepeat = v ?? false),
                      ),
                      _radioRow(
                        label: 'Bu ayet için özel:',
                        value: true,
                        groupValue: _useCustomRepeat,
                        onChanged: (v) =>
                            setState(() => _useCustomRepeat = v ?? false),
                      ),
                      if (_useCustomRepeat) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _customRepeatDays <= 1
                                    ? null
                                    : () => setState(() => _customRepeatDays--),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentNeonGreen
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: AppColors.accentNeonGreen,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$_customRepeatDays',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentNeonGreen,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _customRepeatDays >= 365
                                    ? null
                                    : () => setState(() => _customRepeatDays++),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentNeonGreen
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 16,
                                    color: AppColors.accentNeonGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'gün',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Etkin
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kBgInput,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _enabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_outlined,
                              size: 18,
                              color: _enabled
                                  ? AppColors.accentNeonGreen
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _enabled
                                    ? 'Etkin — saatinde otomatik atılır'
                                    : 'Devre dışı — atılmaz',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _enabled
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _enabled,
                              activeTrackColor: AppColors.accentNeonGreen
                                  .withValues(alpha: 0.4),
                              activeThumbColor: AppColors.accentNeonGreen,
                              onChanged: (v) => setState(() => _enabled = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentNeonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      widget.isEdit ? 'Güncelle' : 'Kaydet',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog yardımcıları

  Widget _dialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController ctrl,
    String hint = '',
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        filled: true,
        fillColor: _kBgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _radioRow({
    required String label,
    String? subtitle,
    required bool value,
    required bool groupValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected
                  ? AppColors.accentNeonGreen
                  : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
