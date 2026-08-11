part of 'admin_content_page.dart';

/// Panelin üstünde ince bir şerit — hangi admin, hangi Firebase projesine
/// bağlı olduğunu hızlıca bildirir. Yanlış projeye yazım yapma riskini azaltır
/// (prod vs staging). Görsel: koyu yeşil strip + ADMIN rozeti + email + proje.
class _AdminIdentityStrip extends StatelessWidget {
  const _AdminIdentityStrip({required this.email, required this.projectId});

  final String? email;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.emeraldDark.withValues(alpha: 0.4),
            AppColors.emeraldDark.withValues(alpha: 0.15),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.55),
                width: 0.8,
              ),
            ),
            child: Text(
              l10n.adminIdentityBadge,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppColors.accentNeonGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              email ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.dns_outlined,
            size: 13,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 4),
          Text(
            projectId,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Canlı kurulum özeti — `syncInstallPresence` + `getAdminInstallAudience`.
/// Manuel / tahmin rakam yok; son 90 günde uygulamayı açan cihazlar.
class _AdminInstallAudienceStrip extends StatefulWidget {
  const _AdminInstallAudienceStrip();

  @override
  State<_AdminInstallAudienceStrip> createState() =>
      _AdminInstallAudienceStripState();
}

class _AdminInstallAudienceStripState
    extends State<_AdminInstallAudienceStrip> {
  static const _region = 'europe-west1';

  bool _loading = true;
  String? _error;
  int _total = 0;
  int _windowDays = 90;
  List<({String label, int count})> _brands = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('getAdminInstallAudience');
      final result = await callable.call();
      final data = result.data;
      if (data is! Map) {
        throw StateError('Beklenmeyen yanıt');
      }
      final brandsRaw = data['brands'];
      final brands = <({String label, int count})>[];
      if (brandsRaw is List) {
        for (final row in brandsRaw) {
          if (row is! Map) continue;
          final label = row['label']?.toString() ?? '';
          final count = (row['count'] as num?)?.toInt() ?? 0;
          if (label.isEmpty || count <= 0) continue;
          brands.add((label: label, count: count));
        }
      }
      if (!mounted) return;
      setState(() {
        _total = (data['total'] as num?)?.toInt() ?? 0;
        _windowDays = (data['windowDays'] as num?)?.toInt() ?? 90;
        _brands = brands;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kurulum verisi alınamadı';
        _loading = false;
      });
      debugPrint('getAdminInstallAudience: $e');
    }
  }

  static String _formatCount(int value) {
    if (value >= 1000) {
      final asK = value / 1000;
      if (value % 1000 == 0) return '${value ~/ 1000} bin';
      return '${asK.toStringAsFixed(1)} bin';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final brandLine = _brands.isEmpty
        ? (_loading
              ? 'Cihazlar ölçülüyor…'
              : 'Henüz ölçülen kurulum yok — kullanıcılar uygulamayı açtıkça dolar.')
        : _brands
              .map((b) => '${_formatCount(b.count)} ${b.label}')
              .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentNeonGreen.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        '$_total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: AppColors.accentNeonGreen,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _error ?? 'kişide yüklü',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(
                            alpha: _error == null ? 0.78 : 0.55,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _loading ? null : _load,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Canlı · $_windowDays gün',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            brandLine,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}
