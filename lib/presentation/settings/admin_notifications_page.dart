// Admin — Bildirim yönetimi: havuz (saat bazlı) + manuel yayınlar.
// Her havuz öğesinin kendi gönderim saati vardır (HH:MM).
// Cloud Function her dakika çalışır; o dakikaya eşleşen öğeleri gönderir.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/firebase/firebase_bootstrap.dart';

// ── Sabitler ──────────────────────────────────────────────────────────────────

abstract final class _Col {
  static const String pool = 'admin_ntf_pool';
  static const String broadcasts = 'admin_scheduled_notifications';
  static const String config = 'admin_ntf_config';
  static const String configDoc = 'schedule';
}

// ── Yardımcılar ───────────────────────────────────────────────────────────────

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
  }
  return null;
}

String _fmtDt(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}

String _fmtRelative(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
  if (diff.inDays < 1) return '${diff.inHours} sa önce';
  return '${diff.inDays} gün önce';
}

String _clockStr(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

// ── Sayfa ─────────────────────────────────────────────────────────────────────

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ── Havuz ──────────────────────────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _poolDocs = [];
  bool _poolLoading = false;
  String? _poolError;
  String _poolSearch = '';

  // ── Gönderim ayarları ─────────────────────────────────────────────
  int _sendEveryNDays = 3;
  int _minRepeatDays = 60;
  String? _lastAutoSentDate;
  bool _scheduleConfigLoading = false;
  bool _scheduleConfigSaving = false;
  bool _scheduleConfigLoaded = false;

  // ── Manuel yayınlar ───────────────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _broadcastDocs = [];
  bool _broadcastLoading = false;
  String? _broadcastError;
  bool _broadcastLoaded = false;

  final _bTitleCtrl = TextEditingController();
  final _bBodyCtrl = TextEditingController();
  DateTime? _bScheduledAt;
  bool _bSaving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _loadPool();
    _loadScheduleConfig();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabs.index == 1 && !_broadcastLoaded && !_broadcastLoading) {
      _loadBroadcasts();
    }
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    _bTitleCtrl.dispose();
    _bBodyCtrl.dispose();
    super.dispose();
  }

  // ── Yükleyiciler ──────────────────────────────────────────────────

  Future<void> _loadPool() async {
    if (!isFirebaseReady) return;
    setState(() {
      _poolLoading = true;
      _poolError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.pool)
          .orderBy('hour')
          .orderBy('minute')
          .get(const GetOptions(source: Source.serverAndCache));
      _poolDocs = snap.docs;
    } catch (e) {
      _poolError = 'Havuz yüklenemedi: $e';
    } finally {
      if (mounted) setState(() => _poolLoading = false);
    }
  }

  Future<void> _loadBroadcasts() async {
    if (!isFirebaseReady) return;
    setState(() {
      _broadcastLoading = true;
      _broadcastError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.broadcasts)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      _broadcastDocs = snap.docs;
      _broadcastLoaded = true;
    } catch (e) {
      _broadcastError = 'Yayınlar yüklenemedi: $e';
    } finally {
      if (mounted) setState(() => _broadcastLoading = false);
    }
  }

  // ── Gönderim ayarları ─────────────────────────────────────────────

  Future<void> _loadScheduleConfig() async {
    if (!isFirebaseReady || _scheduleConfigLoaded) return;
    setState(() => _scheduleConfigLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.configDoc)
          .get(const GetOptions(source: Source.serverAndCache));
      if (snap.exists) {
        final d = snap.data()!;
        _sendEveryNDays = (d['sendEveryNDays'] as int?) ?? 3;
        _minRepeatDays = (d['minRepeatDays'] as int?) ?? 60;
        _lastAutoSentDate = d['lastAutoSentDate']?.toString();
      }
      _scheduleConfigLoaded = true;
    } catch (_) {
      // sessiz hata — varsayılanlar kalır
    } finally {
      if (mounted) setState(() => _scheduleConfigLoading = false);
    }
  }

  Future<void> _saveScheduleConfig() async {
    if (!isFirebaseReady || _scheduleConfigSaving) return;
    setState(() => _scheduleConfigSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(_Col.config)
          .doc(_Col.configDoc)
          .set(
        {
          'sendEveryNDays': _sendEveryNDays,
          'minRepeatDays': _minRepeatDays,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        SetOptions(merge: true),
      );
      _snack('Ayarlar kaydedildi.');
    } catch (e) {
      _snack('Kaydedilemedi: $e', error: true);
    } finally {
      if (mounted) setState(() => _scheduleConfigSaving = false);
    }
  }

  // ── Havuz işlemleri ───────────────────────────────────────────────

  Future<void> _addOrEditPoolItem({
    String? docId,
    String initialTitle = '',
    String initialText = '',
    String initialRef = '',
    int initialHour = 21,
    int initialMinute = 0,
    bool initialEnabled = true,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final textCtrl = TextEditingController(text: initialText);
    final refCtrl = TextEditingController(text: initialRef);
    final isEdit = docId != null;

    final result = await showDialog<_PoolItemResult>(
      context: context,
      builder: (ctx) => _PoolItemDialog(
        isEdit: isEdit,
        titleCtrl: titleCtrl,
        textCtrl: textCtrl,
        refCtrl: refCtrl,
        initialHour: initialHour,
        initialMinute: initialMinute,
        initialEnabled: initialEnabled,
      ),
    );

    titleCtrl.dispose();
    textCtrl.dispose();
    refCtrl.dispose();

    if (result == null) return;

    final text = result.text.trim();
    if (text.isEmpty) {
      _snack('Metin boş olamaz.', error: true);
      return;
    }

    try {
      final col = FirebaseFirestore.instance.collection(_Col.pool);
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final data = {
        'title': result.title.trim(),
        'text': text,
        'ref': result.ref.trim(),
        'hour': result.hour,
        'minute': result.minute,
        'enabled': result.enabled,
      };
      if (isEdit) {
        await col.doc(docId).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': email,
        });
        _snack('Öğe güncellendi.');
      } else {
        await col.add({
          ...data,
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': email,
        });
        _snack('Havuza eklendi.');
      }
      await _loadPool();
    } catch (e) {
      _snack('İşlem başarısız: $e', error: true);
    }
  }

  Future<void> _deletePoolItem(String docId, String preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2419),
        title: const Text('Sil'),
        content: Text(
          '"${preview.length > 60 ? "${preview.substring(0, 60)}…" : preview}"\nsilinsin mi?',
        ),
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
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection(_Col.pool)
          .doc(docId)
          .delete();
      _snack('Öğe silindi.');
      await _loadPool();
    } catch (e) {
      _snack('Silinemedi: $e', error: true);
    }
  }

  Future<void> _togglePoolItemEnabled(String docId, bool current) async {
    try {
      await FirebaseFirestore.instance
          .collection(_Col.pool)
          .doc(docId)
          .update({'enabled': !current});
      await _loadPool();
    } catch (e) {
      _snack('Güncellenemedi: $e', error: true);
    }
  }

  // ── Manuel yayın işlemleri ────────────────────────────────────────

  Future<void> _pickBroadcastDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _bScheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentNeonGreen,
            surface: const Color(0xFF0F2419),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _bScheduledAt ?? now.add(const Duration(hours: 1)),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentNeonGreen,
            surface: const Color(0xFF0F2419),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _bScheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _scheduleBroadcast() async {
    final title = _bTitleCtrl.text.trim();
    final body = _bBodyCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Başlık boş olamaz.', error: true);
      return;
    }
    if (body.isEmpty) {
      _snack('Metin boş olamaz.', error: true);
      return;
    }
    if (_bScheduledAt == null) {
      _snack('Gönderim zamanı seçin.', error: true);
      return;
    }
    if (_bScheduledAt!.isBefore(DateTime.now())) {
      _snack('Geçmiş bir zaman seçildi.', error: true);
      return;
    }
    if (_bSaving) return;
    setState(() => _bSaving = true);
    try {
      await FirebaseFirestore.instance.collection(_Col.broadcasts).add({
        'title': title,
        'body': body,
        'scheduledAt': Timestamp.fromDate(_bScheduledAt!),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email ?? '',
      });
      _bTitleCtrl.clear();
      _bBodyCtrl.clear();
      setState(() => _bScheduledAt = null);
      _snack('Bildirim planlandı.');
      await _loadBroadcasts();

      // Havuza ekleme teklifi
      if (mounted) {
        await _offerAddToPool(title: title, text: body);
      }
    } catch (e) {
      _snack('Planlanamadı: $e', error: true);
    } finally {
      if (mounted) setState(() => _bSaving = false);
    }
  }

  Future<void> _offerAddToPool({
    required String title,
    required String text,
  }) async {
    int selectedHour = 21;
    int selectedMinute = 0;
    bool addEnabled = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF0F2419),
          title: Text(
            'Havuza da ekleyelim mi?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$title"',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay(
                      hour: selectedHour,
                      minute: selectedMinute,
                    ),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.accentNeonGreen,
                          surface: const Color(0xFF0F2419),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setLocal(() {
                      selectedHour = picked.hour;
                      selectedMinute = picked.minute;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.accentNeonGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gönderim saati',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _clockStr(selectedHour, selectedMinute),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentNeonGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Etkin',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: addEnabled,
                    activeTrackColor:
                        AppColors.accentNeonGreen.withValues(alpha: 0.4),
                    activeThumbColor: AppColors.accentNeonGreen,
                    onChanged: (v) => setLocal(() => addEnabled = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hayır'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppColors.accentNeonGreen.withValues(alpha: 0.2),
                foregroundColor: AppColors.accentNeonGreen,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Havuza Ekle'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await FirebaseFirestore.instance.collection(_Col.pool).add({
        'title': title,
        'text': text,
        'ref': '',
        'hour': selectedHour,
        'minute': selectedMinute,
        'enabled': addEnabled,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': email,
      });
      _snack('Havuza da eklendi.');
      await _loadPool();
    } catch (e) {
      _snack('Havuza eklenemedi: $e', error: true);
    }
  }

  Future<void> _cancelBroadcast(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_Col.broadcasts)
          .doc(docId)
          .update({'status': 'cancelled'});
      _snack('İptal edildi.');
      await _loadBroadcasts();
    } catch (e) {
      _snack('İptal başarısız: $e', error: true);
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071815),
      appBar: AppBar(
        backgroundColor: AppColors.emeraldDark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bildirimler',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accentNeonGreen,
          labelColor: AppColors.accentNeonGreen,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.format_list_bulleted_rounded), text: 'Havuz'),
            Tab(icon: Icon(Icons.send_rounded), text: 'Yayınlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildPoolTab(), _buildBroadcastsTab()],
      ),
    );
  }

  // ── Tab 1: Havuz — ayar paneli ────────────────────────────────────

  Widget _buildScheduleConfigPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Gönderim Ayarları',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                if (_lastAutoSentDate != null)
                  Text(
                    'Son: $_lastAutoSentDate',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _scheduleRow(
              label: 'Her',
              value: _sendEveryNDays,
              suffix: 'günde bir gönder',
              min: 1,
              max: 30,
              onDecrement: () =>
                  setState(() => _sendEveryNDays = (_sendEveryNDays - 1).clamp(1, 30)),
              onIncrement: () =>
                  setState(() => _sendEveryNDays = (_sendEveryNDays + 1).clamp(1, 30)),
            ),
            const SizedBox(height: 8),
            _scheduleRow(
              label: 'Aynı söz en erken',
              value: _minRepeatDays,
              suffix: 'gün sonra tekrar',
              min: 7,
              max: 365,
              onDecrement: () =>
                  setState(() => _minRepeatDays = (_minRepeatDays - 1).clamp(7, 365)),
              onIncrement: () =>
                  setState(() => _minRepeatDays = (_minRepeatDays + 1).clamp(7, 365)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.accentNeonGreen.withValues(alpha: 0.18),
                  foregroundColor: AppColors.accentNeonGreen,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _scheduleConfigSaving ? null : _saveScheduleConfig,
                child: _scheduleConfigSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRow({
    required String label,
    required int value,
    required String suffix,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: 8),
        _stepBtn(Icons.remove, value <= min ? null : onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.accentNeonGreen,
            ),
          ),
        ),
        _stepBtn(Icons.add, value >= max ? null : onIncrement),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            suffix,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: onTap != null
                ? AppColors.accentNeonGreen.withValues(alpha: 0.12)
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
            size: 14,
            color: onTap != null ? AppColors.accentNeonGreen : Colors.white24,
          ),
        ),
      );

  // ── Tab 1: Havuz ──────────────────────────────────────────────────

  Widget _buildPoolTab() {
    final filtered = _poolSearch.isEmpty
        ? _poolDocs
        : _poolDocs.where((d) {
            final data = d.data();
            final q = _poolSearch.toLowerCase();
            return (data['text'] ?? '').toString().toLowerCase().contains(q) ||
                (data['title'] ?? '').toString().toLowerCase().contains(q) ||
                (data['ref'] ?? '').toString().toLowerCase().contains(q) ||
                _clockStr(
                  data['hour'] as int? ?? 0,
                  data['minute'] as int? ?? 0,
                ).contains(q);
          }).toList();

    return Column(
      children: [
        _buildScheduleConfigPanel(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Ara… (${_poolDocs.length} öğe)',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Colors.white38,
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
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (v) => setState(() => _poolSearch = v),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.accentNeonGreen.withValues(alpha: 0.18),
                  foregroundColor: AppColors.accentNeonGreen,
                ),
                onPressed: _poolLoading ? null : () => _addOrEditPoolItem(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
              ),
            ],
          ),
        ),
        if (_poolError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              _poolError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _poolLoading && _poolDocs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    _poolSearch.isEmpty
                        ? 'Havuz boş. "Ekle" ile öğe oluşturun.'
                        : 'Sonuç bulunamadı.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final doc = filtered[i];
                    final data = doc.data();
                    final title = data['title']?.toString() ?? '';
                    final text = data['text']?.toString() ?? '';
                    final ref = data['ref']?.toString() ?? '';
                    final hour = data['hour'] as int? ?? 0;
                    final minute = data['minute'] as int? ?? 0;
                    final enabled = data['enabled'] as bool? ?? true;
                    final addedAt = _toDateTime(data['addedAt']);
                    final clock = _clockStr(hour, minute);
                    final preview = title.isNotEmpty ? title : text;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: enabled
                          ? const Color(0xFF0F2419)
                          : const Color(0xFF0A1C15),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 6, 8, 6),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: enabled
                                ? AppColors.accentNeonGreen
                                    .withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: enabled
                                  ? AppColors.accentNeonGreen
                                      .withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            clock,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: enabled
                                  ? AppColors.accentNeonGreen
                                  : Colors.white38,
                            ),
                          ),
                        ),
                        title: Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: enabled ? Colors.white : Colors.white38,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (text.isNotEmpty && title.isNotEmpty)
                              Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            if (ref.isNotEmpty)
                              Text(
                                ref,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accentNeonGreen
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            Text(
                              _fmtRelative(addedAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: enabled ? 'Devre dışı bırak' : 'Etkinleştir',
                              icon: Icon(
                                enabled
                                    ? Icons.toggle_on_rounded
                                    : Icons.toggle_off_rounded,
                                size: 28,
                                color: enabled
                                    ? AppColors.accentNeonGreen
                                    : Colors.white24,
                              ),
                              onPressed: () =>
                                  _togglePoolItemEnabled(doc.id, enabled),
                            ),
                            IconButton(
                              tooltip: 'Düzenle',
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Colors.white38,
                              ),
                              onPressed: () => _addOrEditPoolItem(
                                docId: doc.id,
                                initialTitle: title,
                                initialText: text,
                                initialRef: ref,
                                initialHour: hour,
                                initialMinute: minute,
                                initialEnabled: enabled,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _deletePoolItem(doc.id, preview),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Tab 2: Yayınlar ───────────────────────────────────────────────

  Widget _buildBroadcastsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yeni bildirim planla',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.accentNeonGreen,
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _bTitleCtrl,
                label: 'Başlık',
                hint: 'Örn. 21. Sure, 5. Ayet',
                maxLength: 65,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _bBodyCtrl,
                label: 'Metin',
                hint: 'Bildirim gövdesi…',
                maxLines: 4,
                maxLength: 200,
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickBroadcastDateTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162C22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 20,
                        color: _bScheduledAt != null
                            ? AppColors.accentNeonGreen
                            : Colors.white38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _bScheduledAt != null
                              ? _fmtDt(_bScheduledAt)
                              : 'Tarih ve saat seçin…',
                          style: TextStyle(
                            color: _bScheduledAt != null
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.accentNeonGreen.withValues(alpha: 0.2),
                  foregroundColor: AppColors.accentNeonGreen,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _bSaving ? null : _scheduleBroadcast,
                icon: _bSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.schedule_send_rounded),
                label: const Text(
                  'Planla',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Geçmiş yayınlar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: Colors.white54,
              onPressed: _broadcastLoading ? null : _loadBroadcasts,
            ),
          ],
        ),
        if (_broadcastError != null)
          Text(
            _broadcastError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        if (_broadcastLoading && _broadcastDocs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_broadcastDocs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Henüz yayın yok.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          )
        else
          ...List.generate(_broadcastDocs.length, (i) {
            final doc = _broadcastDocs[i];
            final data = doc.data();
            final status = data['status']?.toString() ?? 'unknown';
            final scheduledAt = _toDateTime(data['scheduledAt']);
            final sentAt = _toDateTime(data['sentAt']);
            final title = data['title']?.toString() ?? '';
            final body = data['body']?.toString() ?? '';
            final errorMsg = data['errorMessage']?.toString();

            final (Color statusColor, String statusLabel, IconData statusIcon) =
                switch (status) {
                  'pending' => (
                      Colors.amber,
                      'Bekliyor',
                      Icons.hourglass_empty_rounded,
                    ),
                  'sent' => (
                      AppColors.accentNeonGreen,
                      'Gönderildi',
                      Icons.check_circle_rounded,
                    ),
                  'cancelled' => (
                      Colors.white38,
                      'İptal',
                      Icons.cancel_rounded,
                    ),
                  'failed' => (
                      Colors.redAccent,
                      'Hata',
                      Icons.error_rounded,
                    ),
                  _ => (Colors.white38, status, Icons.circle_outlined),
                };

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFF0F2419),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        _pill(statusLabel, statusColor),
                        const Spacer(),
                        if (status == 'pending')
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _cancelBroadcast(doc.id),
                            child: const Text(
                              'İptal',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Planlandı: ${_fmtDt(scheduledAt)}'
                      '${sentAt != null ? "  •  Gönderildi: ${_fmtDt(sentAt)}" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    if (errorMsg != null && errorMsg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Hata: $errorMsg',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Ortak widget yardımcıları ──────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2419),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: const Color(0xFF162C22),
          counterStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
}

// ── Pool item result model ─────────────────────────────────────────────────────

class _PoolItemResult {
  const _PoolItemResult({
    required this.title,
    required this.text,
    required this.ref,
    required this.hour,
    required this.minute,
    required this.enabled,
  });

  final String title;
  final String text;
  final String ref;
  final int hour;
  final int minute;
  final bool enabled;
}

// ── Pool item dialog ──────────────────────────────────────────────────────────

class _PoolItemDialog extends StatefulWidget {
  const _PoolItemDialog({
    required this.isEdit,
    required this.titleCtrl,
    required this.textCtrl,
    required this.refCtrl,
    required this.initialHour,
    required this.initialMinute,
    required this.initialEnabled,
  });

  final bool isEdit;
  final TextEditingController titleCtrl;
  final TextEditingController textCtrl;
  final TextEditingController refCtrl;
  final int initialHour;
  final int initialMinute;
  final bool initialEnabled;

  @override
  State<_PoolItemDialog> createState() => _PoolItemDialogState();
}

class _PoolItemDialogState extends State<_PoolItemDialog> {
  late int _hour;
  late int _minute;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _enabled = widget.initialEnabled;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentNeonGreen,
            surface: const Color(0xFF0F2419),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clockStr(_hour, _minute);

    return AlertDialog(
      backgroundColor: const Color(0xFF0F2419),
      title: Text(
        widget.isEdit ? 'Öğeyi Düzenle' : 'Havuza Ekle',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saat seçici
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: AppColors.accentNeonGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gönderim saati',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      clock,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.accentNeonGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _dlgField(widget.titleCtrl, 'Başlık', 'Örn. Sure 21, Ayet 5', maxLength: 65),
            const SizedBox(height: 10),
            _dlgField(widget.textCtrl, 'Metin *', 'Ayet/söz metni…', maxLines: 4, maxLength: 200),
            const SizedBox(height: 10),
            _dlgField(widget.refCtrl, 'Kaynak', "Örn. Kur'an 21:5", maxLength: 80),
            const SizedBox(height: 12),
            // Etkinlik toggle
            Row(
              children: [
                Text(
                  'Etkin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _enabled,
                  activeTrackColor:
                      AppColors.accentNeonGreen.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.accentNeonGreen,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentNeonGreen.withValues(alpha: 0.2),
            foregroundColor: AppColors.accentNeonGreen,
          ),
          onPressed: () => Navigator.pop(
            context,
            _PoolItemResult(
              title: widget.titleCtrl.text,
              text: widget.textCtrl.text,
              ref: widget.refCtrl.text,
              hour: _hour,
              minute: _minute,
              enabled: _enabled,
            ),
          ),
          child: Text(widget.isEdit ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }

  static Widget _dlgField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
    int? maxLength,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
          filled: true,
          fillColor: const Color(0xFF162C22),
          counterStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
}
