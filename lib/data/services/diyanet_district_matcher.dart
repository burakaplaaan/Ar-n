// lib/data/services/diyanet_district_matcher.dart
//
// Diyanet (ezanvakti) ilçe tablosu — `assets/diyanet_tr_districts.json` —
// üzerinden `(il, ilçe)` çiftinden `ilceId`'ye eşleme.
//
// Neden ayrı bir sınıf?
//   - Android Geocoder'ın döndürdüğü `subAdministrativeArea` sık sık farklı
//     yazım varyantlarıyla geliyor: "İzmit" / "Izmit" / "IZMIT" / "izmi̇t".
//     Tüm bunları Diyanet asset'indeki kayıtlarla eşleştirmek için
//     Türkçe'ye duyarlı bir normalize fonksiyonu + il-sınırlı lookup gerek.
//   - Match başarısız olursa "il merkezine düş" fallback mantığı var
//     (Diyanet asset'te bazı ilçeler birleştirilmiş; ör. İstanbul'da 39
//     resmi ilçe, Diyanet'te 19 kayıt). Kullanıcı "Beyoğlu"nda olduğunu
//     söylese bile vakit olarak İstanbul merkez kullanılır.
//
// Yükleme stratejisi: asset bir kere `loadOnce()` ile okunur ve in-memory
// iki index tutulur (`_byNormIlIlce` ve `_ilMerkez`); sonraki tüm lookup'lar
// O(1). Asset ~48 KB, tek seferlik I/O; init etkisi <20 ms.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class DiyanetDistrict {
  final int id;
  final String ilce;
  final int ilId;
  final String il;

  const DiyanetDistrict({
    required this.id,
    required this.ilce,
    required this.ilId,
    required this.il,
  });

  factory DiyanetDistrict.fromMap(Map<String, dynamic> m) => DiyanetDistrict(
        id: m['id'] as int,
        ilce: m['ilce'] as String,
        ilId: m['ilId'] as int,
        il: m['il'] as String,
      );

  Map<String, Object> toMap() => {
        'id': id,
        'ilce': ilce,
        'ilId': ilId,
        'il': il,
      };

  /// Chip / picker UI'nda "Gebze / Kocaeli" biçiminde insan etiketi.
  String get displayLabel {
    final ilcePretty = _pretty(ilce);
    final ilPretty = _pretty(il);
    if (ilcePretty == ilPretty) return ilPretty; // il merkezi = aynı isim
    return '$ilcePretty / $ilPretty';
  }

  /// Diyanet asset'i kayıtları ALL-CAPS Türkçe ("GEBZE", "KOCAELİ")
  /// tutuyor. UI'da yalnız ilk harf büyük olacak şekilde kelime bazlı
  /// title-case çevirir. Dart'ın `toLowerCase`'i "İ" için "i̇" üretir ama
  /// display amaçlı bu kabul edilebilir (Unicode composing dot).
  static String _pretty(String s) {
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

class DiyanetDistrictMatcher {
  static List<DiyanetDistrict>? _all;
  static Map<String, DiyanetDistrict>? _byNormIlIlce;

  /// Her il için "merkez ilçe" — il adıyla ilçe adı eşit olan kayıt
  /// (ör. SehirID=551 KOCAELI → IlceID=9654 KOCAELİ). Bu ilk tercihli
  /// "il-fallback" hedefi. Eşleşme yoksa il içindeki ilk ilçe alınır.
  static Map<int, DiyanetDistrict>? _ilMerkez;

  static Future<void> loadOnce() async {
    if (_all != null) return;
    final raw = await rootBundle.loadString(
      'assets/diyanet_tr_districts.json',
    );
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DiyanetDistrict.fromMap)
        .toList(growable: false);
    _all = list;

    final byKey = <String, DiyanetDistrict>{};
    final merkez = <int, DiyanetDistrict>{};
    final firstInIl = <int, DiyanetDistrict>{};
    for (final d in list) {
      byKey['${_norm(d.il)}|${_norm(d.ilce)}'] = d;
      firstInIl.putIfAbsent(d.ilId, () => d);
      if (_norm(d.il) == _norm(d.ilce)) {
        merkez[d.ilId] = d;
      }
    }
    // Merkez eşleşmesi olmayan iller için ilk ilçe.
    for (final entry in firstInIl.entries) {
      merkez.putIfAbsent(entry.key, () => entry.value);
    }

    _byNormIlIlce = byKey;
    _ilMerkez = merkez;
  }

  /// UI'ın tam listeyi (il + ilçe) göstermesi için.
  static List<DiyanetDistrict> get all {
    final a = _all;
    if (a == null) {
      throw StateError(
        'DiyanetDistrictMatcher.loadOnce() çağrılmadı; asset yüklenmemiş.',
      );
    }
    return a;
  }

  /// [ilAdi] + [ilceAdi] kombinasyonundan `ilceId` döndürür. Eşleşme
  /// bulunamazsa ve [ilAdi] bir ile çözülebilirse il merkezine düşer;
  /// o da yoksa `null` döner.
  ///
  /// Reverse-geocoding çıktılarını düşünerek "büyük/küçük, Türkçe karakter,
  /// fazla boşluk, başa/sona konan apostrof" durumlarını tolere eder.
  static DiyanetDistrict? match({
    required String? ilAdi,
    String? ilceAdi,
  }) {
    final byKey = _byNormIlIlce;
    final merkez = _ilMerkez;
    if (byKey == null || merkez == null) {
      throw StateError('DiyanetDistrictMatcher.loadOnce() çağrılmadı.');
    }
    if (ilAdi == null || ilAdi.trim().isEmpty) return null;

    final nIl = _norm(ilAdi);
    if (ilceAdi != null && ilceAdi.trim().isNotEmpty) {
      final hit = byKey['$nIl|${_norm(ilceAdi)}'];
      if (hit != null) return hit;

      // İlçe adı Android Geocoder'dan "İzmit/Kocaeli" gibi bileşik gelebilir.
      final parts = ilceAdi.split(RegExp(r'[\/,]'));
      for (final p in parts) {
        final hit2 = byKey['$nIl|${_norm(p)}'];
        if (hit2 != null) return hit2;
      }
    }
    // İl merkezine düş.
    for (final d in merkez.values) {
      if (_norm(d.il) == nIl) return d;
    }
    return null;
  }

  /// [ilceId] ile tam kayıt döndürür; yoksa `null`.
  static DiyanetDistrict? byId(int ilceId) {
    final a = _all;
    if (a == null) return null;
    for (final d in a) {
      if (d.id == ilceId) return d;
    }
    return null;
  }

  /// Test-only: asset yüklemeden doğrudan liste enjekte et. Unit test'ler
  /// `rootBundle` olmadan matcher'ı doğrulamak için kullanır.
  static void debugSetFixtures(List<DiyanetDistrict> fixtures) {
    _all = List.unmodifiable(fixtures);
    _byNormIlIlce = {
      for (final d in fixtures) '${_norm(d.il)}|${_norm(d.ilce)}': d,
    };
    final merkez = <int, DiyanetDistrict>{};
    final firstInIl = <int, DiyanetDistrict>{};
    for (final d in fixtures) {
      firstInIl.putIfAbsent(d.ilId, () => d);
      if (_norm(d.il) == _norm(d.ilce)) merkez[d.ilId] = d;
    }
    for (final e in firstInIl.entries) {
      merkez.putIfAbsent(e.key, () => e.value);
    }
    _ilMerkez = merkez;
  }

  /// Türkçe güvenli normalize:
  ///   - Unicode NFC çözümleme
  ///   - `İ → i`, `I → ı → i`, `Ç→c, Ş→s, Ğ→g, Ö→o, Ü→u`
  ///   - Tüm ayraçlar (boşluk / tire / slash / nokta / apostrof) temizlenir
  ///   - Küçük harfe indirilir
  /// Dart'ın `toLowerCase`'i locale-agnostic; Türkçe'de yanlış sonuç üretir
  /// (örn. "İ" → "i̇" birleşik). Bu yüzden eşleme öncesi char-map önce.
  static String _norm(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      // Türkçe karakter → ASCII eşdeğeri (küçük harf).
      switch (r) {
        case 0x0130: // İ
        case 0x0069: // i
        case 0x0131: // ı
        case 0x0049: // I
          buf.write('i');
          continue;
        case 0x00C7: // Ç
        case 0x00E7: // ç
          buf.write('c');
          continue;
        case 0x015E: // Ş
        case 0x015F: // ş
          buf.write('s');
          continue;
        case 0x011E: // Ğ
        case 0x011F: // ğ
          buf.write('g');
          continue;
        case 0x00D6: // Ö
        case 0x00F6: // ö
          buf.write('o');
          continue;
        case 0x00DC: // Ü
        case 0x00FC: // ü
          buf.write('u');
          continue;
        case 0x00C2: // Â
        case 0x00E2: // â
          buf.write('a');
          continue;
        case 0x00CE: // Î
        case 0x00EE: // î
          buf.write('i');
          continue;
        case 0x00DB: // Û
        case 0x00FB: // û
          buf.write('u');
          continue;
      }
      // ASCII A-Z → küçüğe çevir.
      if (r >= 0x41 && r <= 0x5A) {
        buf.writeCharCode(r + 0x20);
        continue;
      }
      // ASCII a-z ve 0-9 → aynen.
      if ((r >= 0x61 && r <= 0x7A) || (r >= 0x30 && r <= 0x39)) {
        buf.writeCharCode(r);
        continue;
      }
      // Diğer her şey (boşluk, tire, apostrof, nokta, ...) atılır.
    }
    return buf.toString();
  }
}
