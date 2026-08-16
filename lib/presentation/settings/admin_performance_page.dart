import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/product_metric_features.dart';
import 'admin_install_audience_strip.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

class AdminPerformancePage extends StatefulWidget {
  const AdminPerformancePage({super.key});

  @override
  State<AdminPerformancePage> createState() => _AdminPerformancePageState();
}

class _AdminPerformancePageState extends State<AdminPerformancePage> {
  static const _region = 'europe-west1';

  int _days = 7;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('getAdminPerformance');
      final result = await callable.call(<String, Object>{'days': _days});
      if (!mounted) return;
      setState(() => _data = _asMap(result.data));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Performans verileri alınamadı. Functions ve kuralların '
            'yayınlandığından emin olun.\n$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): _normalize(entry.value),
    };
  }

  static Object? _normalize(Object? value) {
    if (value is Map) return _asMap(value);
    if (value is List) return value.map(_normalize).toList();
    return value;
  }

  static num _numberAt(Map<String, dynamic> map, List<String> path) {
    Object? cursor = map;
    for (final key in path) {
      if (cursor is! Map) return 0;
      cursor = cursor[key];
    }
    return cursor is num ? cursor : num.tryParse('$cursor') ?? 0;
  }

  List<Map<String, dynamic>> _rows(String key) {
    final raw = _data[key];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => _asMap(e)).toList();
  }

  num _dailyTotal(List<String> path) {
    return _rows(
      'daily',
    ).fold<num>(0, (sum, row) => sum + _numberAt(row, path));
  }

  String _count(num value) {
    final n = value.round();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} Mn';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} B';
    return '$n';
  }

  String _dateTime(int ms) {
    if (ms <= 0) return 'Tarih yok';
    final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        title: const Text('İçerik Performansı'),
        backgroundColor: AppColors.emeraldDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: [
            const AdminInstallAudienceStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RangeSelector(
                    days: _days,
                    onChanged: (days) {
                      if (_days == days) return;
                      setState(() => _days = days);
                      _load();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: ArinLoader()),
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!, onRetry: _load)
                  else ...[
                    _buildOverview(),
                    const SizedBox(height: 14),
                    _buildDayUsage(),
                    const SizedBox(height: 14),
                    _buildNotifications(),
                    const SizedBox(height: 14),
                    _buildWidgets(),
                    const SizedBox(height: 14),
                    _buildContent(),
                    const SizedBox(height: 12),
                    Text(
                      'Günler İstanbul saatiyle gece 12’de değişir. Reklamlar “kaç '
                      'kez”, özellikler “o gün kaç kişi açtı” olarak sayılır. '
                      'Veriler bu sürüm yayınlandıktan sonra birikir. Bildirim hedef '
                      'kitlesi topic aboneliği tahminidir; FCM gerçek teslim edilen '
                      'kişi sayısını vermez. Android ve iOS widget kaldırılmasını '
                      'kesin olarak bildirmez. Bu nedenle “bıraktı”, daha önce '
                      'render edilmiş tüm widgetları 48 saat kilitli kalıp reklamla '
                      'veya premium ile açmayan kullanıcı tahminidir.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final views = _dailyTotal(const ['content', 'views']);
    final likes = _dailyTotal(const ['content', 'likes']);
    final saves = _dailyTotal(const ['content', 'saves']);
    final clicks = _dailyTotal(const ['notifications', 'clicks']);
    final widgets = _asMap(_data['widgets']);
    final lockNotif = _asMap(widgets['lockNotif']);
    final activeKey = _days == 30 ? 'active30' : 'active7';
    final activeHome = _numberAt(widgets, [activeKey]);
    final activeLock = _numberAt(lockNotif, [activeKey]);
    final todayAds = _numberAt(_asMap(_data['today']), const ['ads', 'watches']);

    return _SectionCard(
      title: 'Genel Bakış',
      subtitle: 'Son $_days günün sade özeti',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Kpi(label: 'Görüntülenme', value: _count(views)),
          _Kpi(label: 'Beğeni', value: _count(likes)),
          _Kpi(label: 'Kaydetme', value: _count(saves)),
          _Kpi(label: 'Bildirim tıklaması', value: _count(clicks)),
          _Kpi(label: 'Aktif ana ekran widget', value: _count(activeHome)),
          _Kpi(
            label: 'Aktif kilit ekranı bildirimi',
            value: _count(activeLock),
          ),
          _Kpi(label: 'Bugün reklam izlenme', value: _count(todayAds)),
        ],
      ),
    );
  }

  String _dayLabel(String? dayKey) {
    final raw = (dayKey ?? '').trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return 'Tarih yok';
    final parts = raw.split('-');
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  Widget _buildDayUsage() {
    final today = _asMap(_data['today']);
    final yesterday = _asMap(_data['yesterday']);
    return Column(
      children: [
        _DayUsageCard(
          title: 'Bugün',
          subtitle:
              '${_dayLabel(today['dayKey']?.toString())} · gece 12’ye kadar '
              '(İstanbul)',
          ads: _asMap(today['ads']),
          features: _asMap(today['features']),
          count: _count,
        ),
        const SizedBox(height: 14),
        _DayUsageCard(
          title: 'Dün',
          subtitle: '${_dayLabel(yesterday['dayKey']?.toString())} · tamamlandı',
          ads: _asMap(yesterday['ads']),
          features: _asMap(yesterday['features']),
          count: _count,
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    final rows = _rows('deliveries');
    final currentAudience = _numberAt(_data, const ['notificationAudience']);
    return _SectionCard(
      title: 'Bildirimler',
      subtitle:
          'Şu an tahmini hedef kitle: ${_count(currentAudience)} kullanıcı',
      child: rows.isEmpty
          ? const _EmptyText('Henüz ölçümlenmiş bildirim gönderilmedi.')
          : Column(
              children: [
                for (final row in rows.take(20))
                  _NotificationRow(
                    title: '${row['title'] ?? 'Başlıksız bildirim'}',
                    body: '${row['body'] ?? ''}',
                    date: _dateTime((row['sentAtMs'] as num?)?.toInt() ?? 0),
                    audience: (row['audienceEstimate'] as num?)?.toInt() ?? 0,
                    clicks: (row['uniqueClicks'] as num?)?.toInt() ?? 0,
                    isTest: row['isTest'] == true,
                    status: '${row['status'] ?? ''}',
                  ),
              ],
            ),
    );
  }

  Widget _buildWidgets() {
    final data = _asMap(_data['widgets']);
    final lockNotif = _asMap(data['lockNotif']);
    final total = _numberAt(data, const ['totalEverUsers']);
    final active7 = _numberAt(data, const ['active7']);
    final active30 = _numberAt(data, const ['active30']);
    final churned = _numberAt(data, const ['currentChurned']);
    final returned = _numberAt(data, const ['totalReturned']);
    final unlocks = _numberAt(data, const ['totalUnlocks']);
    final userDays = _numberAt(data, const ['activeUserDays']);
    final averageDays = total > 0 ? userDays / total : 0;
    final lockTotal = _numberAt(lockNotif, const ['totalEverUsers']);
    final lockActive7 = _numberAt(lockNotif, const ['active7']);
    final lockActive30 = _numberAt(lockNotif, const ['active30']);

    return _SectionCard(
      title: 'Widget Kullanımı',
      subtitle:
          'Ana ekran widget ve kilit ekranı bildirimi ayrı sayılır. '
          'Kilit KPI’ları yeni sayaçtan başlar; eski “toplam” içinde '
          'kilit-only kullanıcı kalabilir. Bırakma tahmini yalnızca ana ekran için.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Kpi(label: 'Ana ekran toplam', value: _count(total)),
          _Kpi(label: 'Ana ekran 7 gün aktif', value: _count(active7)),
          _Kpi(label: 'Ana ekran 30 gün aktif', value: _count(active30)),
          _Kpi(label: 'Kilit bildirimi toplam', value: _count(lockTotal)),
          _Kpi(label: 'Kilit bildirimi 7 gün aktif', value: _count(lockActive7)),
          _Kpi(
            label: 'Kilit bildirimi 30 gün aktif',
            value: _count(lockActive30),
          ),
          _Kpi(label: 'Kullanmayı bıraktı', value: _count(churned)),
          _Kpi(label: 'Geri döndü', value: _count(returned)),
          _Kpi(label: 'Reklamla açtı', value: _count(unlocks)),
          _Kpi(
            label: 'Ort. aktif kullanım',
            value: '${averageDays.toStringAsFixed(1)} gün',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final rows = _rows('content');
    return _SectionCard(
      title: 'İçerikler',
      subtitle: 'En çok görüntülenen, beğenilen ve kaydedilen kartlar',
      child: rows.isEmpty
          ? const _EmptyText('Henüz içerik etkileşimi kaydedilmedi.')
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _ContentRow(rank: i + 1, data: rows[i]),
              ],
            ),
    );
  }
}

class _DayUsageCard extends StatelessWidget {
  const _DayUsageCard({
    required this.title,
    required this.subtitle,
    required this.ads,
    required this.features,
    required this.count,
  });

  final String title;
  final String subtitle;
  final Map<String, dynamic> ads;
  final Map<String, dynamic> features;
  final String Function(num value) count;

  num _adWatches(String feature) {
    final by = ads['byFeature'];
    if (by is! Map) return 0;
    final row = by[feature];
    if (row is! Map) return 0;
    final value = row['watches'];
    return value is num ? value : num.tryParse('$value') ?? 0;
  }

  num _featureUsers(String feature) {
    final by = features['byFeature'];
    if (by is! Map) return 0;
    final row = by[feature];
    if (row is! Map) return 0;
    final value = row['users'];
    return value is num ? value : num.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalAds = ads['watches'] is num
        ? ads['watches'] as num
        : num.tryParse('${ads['watches']}') ?? 0;
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reklam izlenme (kaç kez)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final feature in ProductMetricFeatures.all)
            _UsageLine(
              label: ProductMetricFeatures.labelTr(feature),
              value: count(_adWatches(feature)),
            ),
          _UsageLine(
            label: 'Toplam',
            value: count(totalAds),
            emphasize: true,
          ),
          const SizedBox(height: 14),
          Text(
            'Özellik açan kişi (kaç kişi)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final feature in ProductMetricFeatures.all)
            _UsageLine(
              label: ProductMetricFeatures.labelTr(feature),
              value: count(_featureUsers(feature)),
            ),
        ],
      ),
    );
  }
}

class _UsageLine extends StatelessWidget {
  const _UsageLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: emphasize ? 0.9 : 0.62),
                fontSize: emphasize ? 12.5 : 12,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize
                  ? AppColors.accentNeonGreen
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: emphasize ? 14 : 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Tarih aralığı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final value in const [7, 30]) ...[
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('$value gün'),
            selected: days == value,
            onSelected: (_) => onChanged(value),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.homeCardSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accentNeonGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.body,
    required this.date,
    required this.audience,
    required this.clicks,
    required this.isTest,
    required this.status,
  });

  final String title;
  final String body;
  final String date;
  final int audience;
  final int clicks;
  final bool isTest;
  final String status;

  @override
  Widget build(BuildContext context) {
    final rate = audience > 0 ? clicks * 100 / audience : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isTest)
                  const _Badge(text: 'TEST')
                else if (status != 'sent')
                  _Badge(text: status.toUpperCase()),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '$date  •  Hedef: $audience  •  Tıklayan: $clicks  •  '
              'Oran: %${rate.toStringAsFixed(1)}',
              style: const TextStyle(
                color: AppColors.accentNeonGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({required this.rank, required this.data});

  final int rank;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final views = (data['views'] as num?)?.toInt() ?? 0;
    final likes = (data['likes'] as num?)?.toInt() ?? 0;
    final saves = (data['saves'] as num?)?.toInt() ?? 0;
    final rate = views > 0 ? (likes + saves) * 100 / views : 0.0;
    final label = '${data['label'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank.',
              style: const TextStyle(
                color: AppColors.accentNeonGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.isEmpty ? '${data['id'] ?? 'İçerik'}' : label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$views görüntülenme  •  $likes beğeni  •  $saves kayıt  •  '
                  '%${rate.toStringAsFixed(1)} etkileşim',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Veri alınamadı',
      subtitle: 'Bağlantı veya yayın durumu kontrol edilmeli',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
