// Günlük arınma bildirimi — kısa metin havuzu (namaz vaktinden bağımsız).

import 'dart:math';

/// Gün anahtarına göre deterministik seçim (aynı gün aynı metin).
String arinmaNotificationBodyForDay(DateTime dayLocal) {
  final d = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  final i = days % kArinmaNtfBodies.length;
  return kArinmaNtfBodies[i];
}

/// Tahmini dakika: [startMin, endMin] aralığında gün + tuz ile rastgele.
int randomMinutesInWindow({
  required DateTime dayLocal,
  required int salt,
  required int startMin,
  required int endMin,
}) {
  final d = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  final seed = (days * 100003 + salt * 7919) & 0x7fffffff;
  final span = endMin - startMin + 1;
  if (span <= 1) return startMin;
  return startMin + Random(seed).nextInt(span);
}

const List<String> kArinmaNtfBodies = [
  'Bugün de kendine nazik ol; küçük bir adım yeter.',
  'Nefesini yumuşat, kalbini toparla — arınma bir ritimdir.',
  'Gürültü çok; iç sesin hâlâ seninle. Kısa bir duruş.',
  'İyi alışkanlık, küçük tekrarların toplamıdır.',
  'Bugünkü niyetin yeter; mükemmellik değil, sadakat.',
  'Zihin koşsun; sen bir an için durabildiğini hatırla.',
  'Kendine şefkat, başkasına da yer açar.',
  'Küçük bir dua, kısa bir teşekkür — günü yeniden çerçevele.',
];
