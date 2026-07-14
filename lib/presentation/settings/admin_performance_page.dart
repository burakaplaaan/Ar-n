import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
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
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              _buildOverview(),
              const SizedBox(height: 14),
              _buildNotifications(),
              const SizedBox(height: 14),
              _buildWidgets(),
              const SizedBox(height: 14),
              _buildContent(),
              const SizedBox(height: 12),
              Text(
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
    );
  }

  Widget _buildOverview() {
    final views = _dailyTotal(const ['content', 'views']);
    final likes = _dailyTotal(const ['content', 'likes']);
    final saves = _dailyTotal(const ['content', 'saves']);
    final clicks = _dailyTotal(const ['notifications', 'clicks']);
    final widgets = _asMap(_data['widgets']);
    final active = _numberAt(widgets, [_days == 30 ? 'active30' : 'active7']);

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
          _Kpi(label: 'Aktif widget kullanıcısı', value: _count(active)),
        ],
      ),
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
    final total = _numberAt(data, const ['totalEverUsers']);
    final active7 = _numberAt(data, const ['active7']);
    final active30 = _numberAt(data, const ['active30']);
    final churned = _numberAt(data, const ['currentChurned']);
    final returned = _numberAt(data, const ['totalReturned']);
    final unlocks = _numberAt(data, const ['totalUnlocks']);
    final userDays = _numberAt(data, const ['activeUserDays']);
    final averageDays = total > 0 ? userDays / total : 0;

    return _SectionCard(
      title: 'Widget Kullanımı',
      subtitle: 'Kullanım ve 48 saatlik bırakma tahmini',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Kpi(label: 'Toplam kullanıcı', value: _count(total)),
          _Kpi(label: 'Son 7 gün aktif', value: _count(active7)),
          _Kpi(label: 'Son 30 gün aktif', value: _count(active30)),
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
