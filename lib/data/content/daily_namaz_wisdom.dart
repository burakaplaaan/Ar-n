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
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, aciz bir ruhun Sonsuz Kudret\'e yaslanıp ferahlamasıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        '"Allah-u Ekber" demek, ruhun dünyevi bütün korkulardan özgürleşmesidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Rabbine yönelen bir ruh, dünyanın bütün çıkmaz sokaklarından kurtulur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, kalbin ritmini Allah\'ın rızasına ayarlayan şifalı bir dokunuştur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz kılan insan, ruhunu Allah\'ın himayesine ve şifasına emanet etmiştir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Ruhun gerçek hürriyeti ve şifası, sadece Allah\'a kul olup namazla divana durmaktır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Her rekat, insanın dünyadan bir adım daha uzaklaşıp manevi şifaya yaklaşmasıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Allah ile baş başa kalmanın verdiği huzur, ruhun en kalıcı merhemidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, çaresizlik hissinin yerini ilahi bir güvenin aldığı anın adıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Yönünü kıbleye çevirenin ruhu, asla pusulasız kalıp kaybolmaz.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Sabah namazı, uyanan güne ve ruha sürülen ilk şifa merhemidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Beş vakit namaz, ruhu günde beş defa iyileştiren manevi bir terapidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namazın ardındaki dua, iyileşen ruhun Allah\'a sunduğu bir teşekkür mektubudur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Ezan sesi, ruhun şifahanesine çağrılan bir acil şifa davetidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Gecenin karanlığında kılınan teheccüd, ruhun en gizli yaralarını iyileştirir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, insana umutsuzluğun yasak olduğunu hatırlatan ilahi bir umut ışığıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Zamanı namazla ölçen insanın ruhu, dünyanın telaşı içinde yara almaz.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namazsızlık ruhun kuraklığı, namaz ise ona can veren rahmet yağmurudur.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Şifa arayan kalpler için namaz, yan etkisi olmayan tek ve en kesin ilaçtır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Ahiretteki kurtuluşun anahtarı olan namaz, dünyada da ruhun en büyük şifasıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, savrulan ömrümüzü seccadeye sabitleyen, hayatı toparlayan manevi bir demirdir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Günün sahibine gün içinde beş kez selam vermeden, o günün gerçek bereketi bulunmaz.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Ezan, dünyanın geçici işlerine "dur", kalıcı ve sonsuz olana "gel" deme anıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Vaktini namaza göre ayarlayanın, hayatı da huzura göre şekillenir ve düzene girer.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, hayatın bitmek bilmeyen karmaşasına atılan ilahi bir düğümdür; dağılanı toparlar.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, kulluğun en saf haliyle "Seni unutmadım Rabbim" demenin bedensel ve ruhsal ispatıdır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Kimsenin seni duymadığı ve anlamadığı anlarda, seni en iyi anlayanla baş başa kalmaktır.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Rabbinle arandaki manevi bağı koparmak istemiyorsan, seccadenle olan bağını sıkı tutmalısın.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Dünyada tüm kapılar yüzüne kapandığında, namaz arşın rahmet kapılarını sana sonuna kadar açar.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Evinde bir seccade serecek kadar yerin varsa, dünyadaki en güvenli sığınağa sahipsin demektir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Namaz, dünyaya ve kula kulluk etmekten kurtulup sadece Allah\'a eğilmenin asil hürriyetidir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Her secde, nefsin kibrini sessizce toprağa gömüp tevazuyu baş tacı etmektir.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Dünyayı arkana atıp, sonsuzluğu karşına aldığın o muazzam ve dik duruştur kıyam.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Bütün yüklerini, dertlerini ve tasalarını tek bir "Allah-u Ekber" nidasıyla O\'na bırakmanın adıdır namaz.',
    kind: 'Söz',
  ),
  DailyNamazWisdom(
    arabic: '',
    turkish:
        'Yalnızca Allah\'ın huzurunda rükûda eğilen bir beden, hayatta karşılaştığı hiçbir zorluk karşısında eğilmez.',
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
