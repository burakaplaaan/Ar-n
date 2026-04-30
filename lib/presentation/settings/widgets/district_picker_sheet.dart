// lib/presentation/settings/widgets/district_picker_sheet.dart
//
// Diyanet ilçe seçimi için iki aşamalı bottom sheet:
//   1. İl listesi (81 kayıt, alfabetik, arama kutusu ile filtre)
//   2. Seçilen ilin ilçe listesi (ör. Kocaeli → 9 ilçe)
// Kullanıcı ilçeyi seçtiğinde `DiyanetDistrict` döndürülür; kapatırsa
// `null`. Sayfa bunu `LocationService.saveManualDistrict` ile kaydeder
// ve `prayerTimesProvider`'ı invalidate eder.
//
// Arama Türkçe karakter duyarsız: `normalize("Körfez") ≈ normalize("korfez")`.
// Asset ALL-CAPS Türkçe tutuyor; UI görünümünde `displayLabel` kullanılır.

import 'package:flutter/material.dart';

import '../../../data/services/diyanet_district_matcher.dart';

/// İki aşamalı picker'ı açar. Kullanıcı iptal ederse `null` döner.
/// `context` yalnızca sheet'i açmak için gerekli; çağıran taraf widget hâlâ
/// bağlıysa (genelde hemen ardından async işlem yoksa) doğrudan çağrılır.
/// Eğer çağıran tarafta `await DiyanetDistrictMatcher.loadOnce()` gibi
/// async bekleme yapılmışsa, caller'ın kendi `mounted` kontrolünü yapması
/// tercih edilir; bu fonksiyon içinde State referansı olmadığı için burada
/// async gap sonrası context kullanımı kaçınılmaz.
Future<DiyanetDistrict?> showDistrictPickerSheet(BuildContext context) async {
  // Asset yükleme önce yap → context kullanmadan biter. Bu sayede aşağıda
  // `showModalBottomSheet` çağrısı context'i doğrudan await sonrasında
  // kullanıyor gibi görünse de çağıran widget ağacı hâlâ bağlı olmalı
  // (caller bu fonksiyonu await ederken widget'ı dispose ederse zaten
  // sonuç kullanılmaz). `context.mounted` ile defans.
  await DiyanetDistrictMatcher.loadOnce();
  if (!context.mounted) return null;

  final picked = await showModalBottomSheet<DiyanetDistrict>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => const _DistrictPickerBody(),
  );
  return picked;
}

class _DistrictPickerBody extends StatefulWidget {
  const _DistrictPickerBody();

  @override
  State<_DistrictPickerBody> createState() => _DistrictPickerBodyState();
}

class _DistrictPickerBodyState extends State<_DistrictPickerBody> {
  /// `null` iken il listesi; doluyken seçilen il adı → ilçe listesi.
  String? _selectedIlNormalized;
  String? _selectedIlDisplay;
  String _query = '';

  late final List<DiyanetDistrict> _all = DiyanetDistrictMatcher.all;

  late final List<_IlRow> _iller = () {
    final seen = <String, _IlRow>{};
    for (final d in _all) {
      final nIl = _normalizeSearch(d.il);
      seen.putIfAbsent(
        nIl,
        () => _IlRow(ilId: d.ilId, ilAdi: d.il, normalized: nIl),
      );
    }
    final list = seen.values.toList()
      ..sort((a, b) => a.ilAdi.compareTo(b.ilAdi));
    return list;
  }();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: maxHeight,
      child: Column(
        children: [
          _Handle(),
          _Header(
            title: _selectedIlDisplay == null
                ? 'İl seç'
                : 'İlçe seç — $_selectedIlDisplay',
            onBack: _selectedIlDisplay == null
                ? null
                : () => setState(() {
                      _selectedIlDisplay = null;
                      _selectedIlNormalized = null;
                      _query = '';
                    }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: _selectedIlDisplay == null
                    ? 'İl ara (ör. Kocaeli)'
                    : 'İlçe ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _selectedIlNormalized == null
                ? _buildIlList()
                : _buildIlceList(_selectedIlNormalized!),
          ),
        ],
      ),
    );
  }

  Widget _buildIlList() {
    final q = _normalizeSearch(_query);
    final filtered = q.isEmpty
        ? _iller
        : _iller.where((r) => r.normalized.contains(q)).toList();
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final r = filtered[i];
        return ListTile(
          title: Text(_prettyIlAdi(r.ilAdi)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _selectedIlNormalized = r.normalized;
            _selectedIlDisplay = _prettyIlAdi(r.ilAdi);
            _query = '';
          }),
        );
      },
    );
  }

  Widget _buildIlceList(String ilNormalized) {
    final ilceler = _all
        .where((d) => _normalizeSearch(d.il) == ilNormalized)
        .toList()
      ..sort((a, b) => a.ilce.compareTo(b.ilce));
    final q = _normalizeSearch(_query);
    final filtered = q.isEmpty
        ? ilceler
        : ilceler.where((d) => _normalizeSearch(d.ilce).contains(q)).toList();
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final d = filtered[i];
        final isMerkez =
            _normalizeSearch(d.il) == _normalizeSearch(d.ilce);
        return ListTile(
          title: Text(isMerkez ? '${_prettyIlAdi(d.ilce)} (Merkez)' : _prettyIlAdi(d.ilce)),
          onTap: () => Navigator.of(ctx).pop(d),
        );
      },
    );
  }

  /// Picker içi arama için normalize — matcher ile birebir aynı mantık,
  /// fakat küçük bir wrapper. İçsel dublikasyonu ileride kaldırılabilir.
  static String _normalizeSearch(String s) {
    final buf = StringBuffer();
    const map = {
      'İ': 'i', 'I': 'i', 'ı': 'i', 'i': 'i',
      'Ç': 'c', 'ç': 'c',
      'Ş': 's', 'ş': 's',
      'Ğ': 'g', 'ğ': 'g',
      'Ö': 'o', 'ö': 'o',
      'Ü': 'u', 'ü': 'u',
      'Â': 'a', 'â': 'a',
      'Î': 'i', 'î': 'i',
      'Û': 'u', 'û': 'u',
    };
    for (final ch in s.characters) {
      final mapped = map[ch];
      if (mapped != null) {
        buf.write(mapped);
      } else {
        final lc = ch.toLowerCase();
        if (lc.length == 1 &&
            (lc.codeUnitAt(0) >= 0x61 && lc.codeUnitAt(0) <= 0x7A ||
                lc.codeUnitAt(0) >= 0x30 && lc.codeUnitAt(0) <= 0x39)) {
          buf.write(lc);
        }
      }
    }
    return buf.toString();
  }

  static String _prettyIlAdi(String s) {
    return s
        .split(RegExp(r'[ \-/]+'))
        .map((w) {
          if (w.isEmpty) return w;
          final lower = w.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }
}

class _IlRow {
  final int ilId;
  final String ilAdi;
  final String normalized;

  const _IlRow({
    required this.ilId,
    required this.ilAdi,
    required this.normalized,
  });
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _Header({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
