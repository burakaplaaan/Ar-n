// Günlük namaz hatırlatıcısı — Arapça metin + Türkçe meal/çeviri.
// Kaynak etiketleri: yaygın rivayet ve âlim sözleri; derin ilim için mümessil kitaplara başvurulmalıdır.

class DailyNamazWisdom {
  const DailyNamazWisdom({
    required this.arabic,
    required this.turkish,
    required this.kind,
    this.source,
  });

  final String arabic;
  final String turkish;
  /// "Hadis" veya "Söz"
  final String kind;
  final String? source;
}

/// Havuz: her gün ana sayfada biri; bittiğinde başa döner.
const List<DailyNamazWisdom> kDailyNamazWisdomList = [
  DailyNamazWisdom(
    arabic: '',
    turkish: '"Gönlümün ferahlığı namazdadır."',
    kind: 'Hadis',
    source: 'Hadis-i Şerif',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: '"Namaz, kalbin parıltısıdır."',
    kind: 'Hadis',
    source: 'Hadis-i Şerif',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Sizden biri namaz kıldığında, aslında Rabbi ile özel olarak konuşmaktadır."',
    kind: 'Hadis',
    source: 'Hadis-i Şerif',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Sabah namazı, günün geri kalanı için kalbe verilen bir sözdür: Bugün güvendesin."',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Secde, başını dünyanın omzundan çekip Allah’ın rahmetine yaslamaktır."',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: '"İçiniz daraldığında namaz kılın."',
    kind: 'Hadis',
    source: 'Hadis-i Şerif',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: '"Kulun Rabbine en yakın olduğu an, secdedir."',
    kind: 'Hadis',
    source: 'Hadis-i Şerif',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: '"Namaz, dünya koşturmacasında ruhun içtiği bir yudum sudur."',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: '"Kim namazı bırakmazsa, namaz da onun elini bırakmaz."',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Seccade, dünyanın en güvenli "sessiz odası"dır. Kimse seni orada bölemez.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namazda okuduğun her ayet, ruhuna sürülen bir merhem gibidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Yalnızım" deme; secdede yerin altına, kıyamda göğün katlarına bağlanıyorsun.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: 'Namaz, insanın kendi içine yaptığı en güzel yolculuktur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Abdest alırken suyun sadece elini değil, içindeki sıkıntıları da akıtıp gittiğini hayal et.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: 'Namaz, "Ben buradayım, yanındayım" diyen bir dost sesidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Her "Selâm" verişinde, dünyaya yeniden, daha temiz bir başlangıç yaparsın.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: 'Namaz, hayatın karmaşasına karşı çekilen bir "huzur resti"dir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Secdede fısıldarsın, gökyüzünden duyulur." Öyle zarif, öyle derin bir iletişim.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz seni mükemmel yapmaz ama seni "daha iyi bir sen" yapar.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Hayat bir fırtınaysa, namaz o fırtınanın ortasındaki sakin merkezdir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Sadece alnını değil, tüm endişelerini de seccadeye bırakabilirsin.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz kıldığında zamanın bereketi artar; koşturmak yerine sakinleşerek yetişirsin.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Bir çiçeğin güneşe dönmesi gibi, ruhun da her vakit ışığa döner.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish: 'Namaz, insanın kendisine ayırdığı en kaliteli mesaidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Kendini kaybolmuş hissettiğinde, pusulan seccaden olsun; seni hep "merkeze" döndürür.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz bir "buluşma"dır; sevdiğine kavuşan birinin heyecanı ve huzuruyla dolu',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Koşuşturmanın içinde her şeyin çok hızlı aktığı o anlarda, namaz senin için zamanı durduran bir "duraklama" düğmesidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Seccade, dünyanın en samimi psikoloğudur. Oraya her gittiğinde içindeki düğümlerin yavaş yavaş çözüldüğünü hissedersin.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Alnını yere koyduğunda dünyanın tüm sesleri kısalır ve sadece kendi kalbinin atışıyla Yaratıcı’nın huzurunu duyarsın.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Her şeyi ben halletmeliyim" yorgunluğunu üzerinden atıp, her şeyi çekip çeviren kudrete güvenerek rahatlamaktır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Hiçbir yere sığamadığını hissettiğinde, namaz sana ait olduğun asıl yerin neresi olduğunu, aslında hiç kimsesiz olmadığını hatırlatır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaza durduğun an, "Neredeydin?" diyen bir hesap sorma makamına değil; "Seni bekliyordum" diyen sonsuz bir merhamet kucağına gitmiş olursun.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Secde, insanın kendi içine yaptığı en sessiz ve en derin yolculuktur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Dünyanın gürültüsünü dışarıda bırakıp ruhunun sesini dinlediğin o an; namazdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Seccade, tüm maskelerini çıkarıp sadece kendin olabildiğin en özgür alanındır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Anlatamıyorum" dediğin her şeyi, kelimelere dökmeden secdede bırakabilirsin.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, hayatın karmaşasına karşı ruhuna verdiğin en zarif moladır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Alnını yere koyduğunda, kalbindeki tüm ağırlıkların toprağa aktığını hisset.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'İnsanların beklentilerinden yorulduğunda, seni sadece sen olduğun için sevene sığınmaktır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, kimsesizliğin ortasında "Sahibim var" diyebilmenin verdiği o derin nefesidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Ruhun yorulduğunda gidebileceğin en sakin liman, her zaman seninle olan seccadendir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Hiçbir yere sığamadığın anlarda, sadece bir rükû mesafesinde bekleyen o sonsuz huzurdur.',
    kind: 'Söz',
  ),
];

/// Yerel takvime göre gün anahtarı; aynı gün her açılışta aynı içerik.
int dailyNamazWisdomIndex(DateTime nowLocal) {
  assert(
    kDailyNamazWisdomList.isNotEmpty,
    'kDailyNamazWisdomList must not be empty.',
  );
  if (kDailyNamazWisdomList.isEmpty) {
    throw StateError('kDailyNamazWisdomList is empty.');
  }
  final d = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  final n = kDailyNamazWisdomList.length;
  return ((days % n) + n) % n;
}

DailyNamazWisdom dailyNamazWisdomFor(DateTime nowLocal) {
  return kDailyNamazWisdomList[dailyNamazWisdomIndex(nowLocal)];
}

/// Günün bildirimi — ana sayfadaki karttan farklı indeks (aynı havuz).
DailyNamazWisdom dailyNamazWisdomForNotification(DateTime nowLocal) {
  assert(
    kDailyNamazWisdomList.isNotEmpty,
    'kDailyNamazWisdomList must not be empty.',
  );
  if (kDailyNamazWisdomList.isEmpty) {
    throw StateError('kDailyNamazWisdomList is empty.');
  }
  final d = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final anchor = DateTime(2020, 1, 1);
  final days = d.difference(anchor).inDays;
  final n = kDailyNamazWisdomList.length;
  final idx = (((days + (n ~/ 2)) % n) + n) % n;
  return kDailyNamazWisdomList[idx];
}
