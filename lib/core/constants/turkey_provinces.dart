// lib/core/constants/turkey_provinces.dart
// 81 il — ayarlar şehir seçimi ve Aladhan (Turkey) ile uyumlu resmi yazılışlar.

/// Türkiye illeri (alfabetik, Türkçe karakterler korunur).
const List<String> kTurkeyProvinceNames = [
  'Adana',
  'Adıyaman',
  'Afyonkarahisar',
  'Ağrı',
  'Aksaray',
  'Amasya',
  'Ankara',
  'Antalya',
  'Ardahan',
  'Artvin',
  'Aydın',
  'Balıkesir',
  'Bartın',
  'Batman',
  'Bayburt',
  'Bilecik',
  'Bingöl',
  'Bitlis',
  'Bolu',
  'Burdur',
  'Bursa',
  'Çanakkale',
  'Çankırı',
  'Çorum',
  'Denizli',
  'Diyarbakır',
  'Düzce',
  'Edirne',
  'Elazığ',
  'Erzincan',
  'Erzurum',
  'Eskişehir',
  'Gaziantep',
  'Giresun',
  'Gümüşhane',
  'Hakkâri',
  'Hatay',
  'Iğdır',
  'Isparta',
  'İstanbul',
  'İzmir',
  'Kahramanmaraş',
  'Karabük',
  'Karaman',
  'Kars',
  'Kastamonu',
  'Kayseri',
  'Kırıkkale',
  'Kırklareli',
  'Kırşehir',
  'Kilis',
  'Kocaeli',
  'Konya',
  'Kütahya',
  'Malatya',
  'Manisa',
  'Mardin',
  'Mersin',
  'Muğla',
  'Muş',
  'Nevşehir',
  'Niğde',
  'Ordu',
  'Osmaniye',
  'Rize',
  'Sakarya',
  'Samsun',
  'Siirt',
  'Sinop',
  'Sivas',
  'Şanlıurfa',
  'Şırnak',
  'Tekirdağ',
  'Tokat',
  'Trabzon',
  'Tunceli',
  'Uşak',
  'Van',
  'Yalova',
  'Yozgat',
  'Zonguldak',
];

/// Arama için aksan/Türkçe harfleri sadeleştirir (eşleşme toleransı).
String foldTurkishSearch(String input) {
  var s = input.trim();
  // Klavye farkı: İ / I → i (İstanbul, Iğdır vb.)
  s = s.replaceAll('İ', 'i').replaceAll('I', 'i');
  return s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u');
}

/// Yazılan metne göre eşleşen iller (önce başlayanlar, en fazla [limit] adet).
Iterable<String> searchTurkeyProvinces(String query, {int limit = 14}) {
  final q = foldTurkishSearch(query);
  if (q.isEmpty) return const Iterable<String>.empty();

  final matches = kTurkeyProvinceNames.where((p) {
    return foldTurkishSearch(p).contains(q);
  }).toList();

  int rank(String p) {
    final f = foldTurkishSearch(p);
    if (f.startsWith(q)) return 0;
    return 1;
  }

  matches.sort((a, b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra - rb;
    return a.compareTo(b);
  });

  return matches.take(limit);
}

/// Tam eşleşen il adı (büyük/küçük harf ve Türkçe karakter duyarsız) veya null.
String? matchTurkeyProvinceExact(String input) {
  final q = foldTurkishSearch(input);
  if (q.isEmpty) return null;
  for (final p in kTurkeyProvinceNames) {
    if (foldTurkishSearch(p) == q) return p;
  }
  return null;
}
