// Admin panelinden tek dokunuşla Firestore’a yazılabilecek yerleşik içerikler.

import 'dart:convert';

import '../../core/constants/quote_pool_ids.dart';
import '../../presentation/qibla/healing_frequencies/healing_daily_comfort_entries.dart';
import '../content/arin_ntf_messages.dart';
import '../content/daily_namaz_wisdom.dart';
import '../willpower/insight_quote_pools.dart';

abstract final class QuotePoolDefaults {
  static List<Map<String, dynamic>> notificationArinmaBodies() {
    return kArinmaNtfBodies.map((s) => <String, dynamic>{'text': s}).toList();
  }

  static List<Map<String, dynamic>> homeNamazWisdom() {
    return kDailyNamazWisdomList
        .map(
          (e) => <String, dynamic>{
            'arabic': e.arabic,
            'turkish': e.turkish,
            'kind': e.kind,
            if (e.source != null) 'source': e.source,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> notificationNamazWisdom() {
    return const <Map<String, dynamic>>[
      {'text': '"Sabret! Senin sabrın ancak Allah\'ın yardımıyladır."', 'kind': 'Ayet', 'source': 'Nahl, 127'},
      {'text': '"Kalpler ancak Allah\'ı anmakla huzur bulur."', 'kind': 'Ayet', 'source': 'Ra\'d, 28'},
      {'text': '"O, her şeyi hakkıyla bilendir; içindekileri O\'na bırak."', 'kind': 'Söz'},
      {'text': '"Dünya geçici, dertler misafir; asıl olan Allah\'ın rızasıdır."', 'kind': 'Söz'},
      {'text': '"Niyetin neyse nasibin odur."', 'kind': 'Söz'},
      {'text': '"Zorlukla beraber bir kolaylık vardır."', 'kind': 'Ayet', 'source': 'İnşirah, 5'},
      {'text': '"Dua, müminin en güçlü silahıdır; bugün dua ettin mi?"', 'kind': 'Söz'},
      {'text': '"Hayırlı olanı iste, gerisini O\'na bırak. O en iyisini bilendir."', 'kind': 'Söz'},
      {'text': '"Güzel günler sana gelmez, sen onlara yürüyeceksin."', 'kind': 'Söz', 'source': 'Hz. Mevlana'},
      {'text': '"Gönül, Allah\'ın evidir; onu temiz tut."', 'kind': 'Söz'},
      {'text': '"Dilini sustur, kalbin konuşsun."', 'kind': 'Söz'},
      {'text': '"Nasibinde varsa gelir seni bulur, yeter ki sen dik dur."', 'kind': 'Söz'},
      {'text': '"Yorulunca vazgeçme, tevekkül et. Şüphesiz O, sabredenleri sever."', 'kind': 'Söz'},
      {'text': '"Niyetin iyiyse, yolun da hayırlıdır."', 'kind': 'Söz'},
      {'text': '"Şükretmek, sahip olduğun nimetin sigortasıdır."', 'kind': 'Söz'},
      {'text': '"Olmadı diye üzüldüğün şeye gün gelir \'iyi ki olmamış\' dersin; sabret."', 'kind': 'Söz'},
      {'text': '"Kalp kırma; zira o, Allah\'ın komşusudur."', 'kind': 'Söz'},
    ];
  }

  static List<Map<String, dynamic>> notificationDailyNamazReminder() {
    return const <Map<String, dynamic>>[
      {
        'text':
            'Bugün sana verilen temiz bir sayfa; içini iyilik ve niyetle doldurmaya ne dersin?',
        'kind': 'Söz',
      },
      {
        'text':
            'Aldığın her nefes, sana bahşedilen benzersiz bir hediye. Kıymetini bilerek yaşa.',
        'kind': 'Söz',
      },
      {
        'text':
            'Zihnindeki karmaşayı bir kenara bırak ve seni var edene sonsuz bir güvenle bağlan.',
        'kind': 'Söz',
      },
      {
        'text':
            'Elinden gelenin en iyisini yap, gerisini O\'na bırak. Huzur teslimiyettedir.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün birinin yüzünde tebessüm olmaya niyet et; bir gülümseme en güzel sadakadır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Kalbini bugün sadece sevgiye ve sükunete aç; içinde nefrete yer kalmasın.',
        'kind': 'Söz',
      },
      {
        'text':
            '"Allah bize yeter, O ne güzel vekildir." Bu güvenle yoluna devam et.',
        'kind': 'Ayet',
        'source': 'Âl-i İmrân, 173',
      },
      {
        'text':
            'Etrafındaki küçük mucizeleri fark et; bir kuşun sesi bile aslında bir davettir.',
        'kind': 'Söz',
      },
      {
        'text':
            'Zorlukların arkasındaki kolaylığı gör; sabır, ruhun en güçlü azığıdır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Ruhunu kısa bir dua ile uyandır; hayatın telaşına kapılmadan önce kalbine dön.',
        'kind': 'Söz',
      },
      {
        'text':
            'Başkalarının eksiklerine değil, kendi kalbinin derinliklerine odaklanmayı dene.',
        'kind': 'Söz',
      },
      {
        'text':
            'Dilinden güzel sözü, gönlünden iyi niyeti eksik etme; iyilik her zaman yolunu bulur.',
        'kind': 'Söz',
      },
      {
        'text':
            'Her an yeni bir başlangıçtır; dünün yüklerini dünde bırak, şimdi yeniden başla.',
        'kind': 'Söz',
      },
      {
        'text':
            'Rızkın için çabalarken, kalbini rızkı verene emanet etmenin hafifliğini yaşa.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün bir canı sevindir ya da bir dosta hatır sor; dünya paylaştıkça güzelleşir.',
        'kind': 'Söz',
      },
      {
        'text':
            'Kendini inançla kuşan; unutma ki sen çok özel bir niyetle yaratıldın.',
        'kind': 'Söz',
      },
      {
        'text':
            'Zihnini sustur, kalbinin sesini dinle; orada her zaman bir umut ışığı vardır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Arınmak için büyük adımlara gerek yok; içten bir şükür ruhunu yıkamaya yeter.',
        'kind': 'Söz',
      },
      {
        'text':
            'Telaş dindiğinde elini kalbine koy ve sahip olduğun her şey için sessizce teşekkür et.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün seni yoran ne varsa O\'na emanet et; O her şeyi hakkıyla bilendir.',
        'kind': 'Söz',
      },
      {
        'text':
            '"Kalpler ancak Allah\'ı anmakla huzur bulur." Şimdi kalbini huzura davet etme vakti.',
        'kind': 'Ayet',
        'source': 'Ra\'d, 28',
      },
      {
        'text':
            'Yaşadığın her deneyim, seni olgunlaştırmak için tasarlanmış birer öğretmendir.',
        'kind': 'Söz',
      },
      {
        'text':
            'Karanlığı geceyle örten, içindeki sıkıntıları da ferahlıkla örtsün.',
        'kind': 'Söz',
      },
      {
        'text':
            'Kaderin, senin planlarından daha güzel kapılar açabileceğine tüm kalbinle inan.',
        'kind': 'Söz',
      },
      {
        'text': 'Tevbe ile ruhunu tazele; O, bağışlamayı ve samimiyetle dönenleri sever.',
        'kind': 'Söz',
      },
      {
        'text':
            'Dua, mesafeleri aradan kaldıran en güçlü bağdır; sevdiklerini duana ortak et.',
        'kind': 'Söz',
      },
      {
        'text':
            'Kendine çok yüklendiysen dur ve hatırla: Sen de bir emanetsin, kendine şefkat göster.',
        'kind': 'Söz',
      },
      {
        'text':
            'Dünyanın gürültüsünü dışarıda bırak; içindeki o sessiz ve dingin limana çekil.',
        'kind': 'Söz',
      },
      {
        'text':
            'Kalbindeki niyetleri bilen biri var; anlaşılmadığını hissettiğinde sadece O\'na sığın.',
        'kind': 'Söz',
      },
      {
        'text':
            'Başını yastığa koymadan veya yeni bir işe başlamadan önce kalbini temizle.',
        'kind': 'Söz',
      },
      {
        'text':
            'Gökyüzündeki kusursuz nizamı izle ve bu büyük tablodaki yerini hatırla.',
        'kind': 'Söz',
      },
      {
        'text': 'Arınmış bir kalp, en büyük zenginliktir. Kalbini koru.',
        'kind': 'Söz',
      },
      {
        'text':
            'İyilik yap ve unut; çünkü O, yapılan hiçbir iyiliği karşılıksız bırakmaz.',
        'kind': 'Söz',
      },
      {
        'text': 'Bugün kendine şu soruyu sor: "Ruhum bugün neyle beslendi?"',
        'kind': 'Söz',
      },
      {
        'text': 'Öfkeni sabırla, kırgınlığını dua ile onar.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bir an dur ve sadece nefesine odaklan; yaşıyorsun ve bu en büyük mucize.',
        'kind': 'Söz',
      },
      {
        'text':
            'Hayatın akışına direnme; su gibi ol, yolunu bul ve incitmeden ak.',
        'kind': 'Söz',
      },
      {
        'text':
            'Hiçbir dua karşılıksız değildir; ya aynen verilir, ya daha iyisiyle değiştirilir.',
        'kind': 'Söz',
      },
      {
        'text': 'Samimiyet, en kısa yoldur. İşlerini samimiyetle güzelleştir.',
        'kind': 'Söz',
      },
      {
        'text':
            'İyilikte yarışanlardan ol; çünkü hayat biriktirdiğin değil, paylaştığın kadardır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün kalbinden geçen hayırlı bir duanın gerçekleşmeyeceğinden korkma.',
        'kind': 'Söz',
      },
      {
        'text':
            'Görünene değil, görünene hayat veren manaya bakmayı dene.',
        'kind': 'Söz',
      },
      {
        'text':
            'Tevekkül, çabayı bırakmak değil; çabanın sonucunu huzurla beklemektir.',
        'kind': 'Söz',
      },
      {
        'text': 'Merhamet et ki, sana da merhamet edilsin. Kalbini yumuşat.',
        'kind': 'Söz',
      },
      {
        'text':
            'Affetmek, ruhu özgür bırakmaktır. Bugün birini değil, aslında kendini özgür bırak.',
        'kind': 'Söz',
      },
      {
        'text':
            'Şükür, elindeki nimeti çoğaltan en tılsımlı anahtardır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Sessizlikte çok şey gizlidir; bazen sadece susmak en derin duadır.',
        'kind': 'Söz',
      },
      {
        'text':
            'Yaradan\'ın sana olan sevgisini, her sabah doğan güneşte ara.',
        'kind': 'Söz',
      },
      {
        'text':
            'Başarıyı değil, rızayı hedefle. Rıza olunca huzur kendiliğinden gelir.',
        'kind': 'Söz',
      },
      {
        'text':
            'Yalnız değilsin; damarlarındaki kanda, aldığın nefeste O seninle.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün bir yabancıya selam ver; kalpler arasındaki köprüleri hatırla.',
        'kind': 'Söz',
      },
      {
        'text': 'Kırıldığın yerden filizlenirsin; acılarını sabır toprağına ek.',
        'kind': 'Söz',
      },
      {
        'text':
            'Her şeyin bir vakti vardır. Çiçek vaktinden önce açmaz, güneş vaktinden önce doğmaz.',
        'kind': 'Söz',
      },
      {
        'text':
            'İnanç, karanlıkta yolu görebilmektir. Işığını içinden eksik etme.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bugün sadece kendin için değil, tanımadığın biri için de dua et.',
        'kind': 'Söz',
      },
      {
        'text':
            'Ruhun yorulduğunda secdeye kapan; yerin sinesinde göğün huzurunu bul.',
        'kind': 'Söz',
      },
      {
        'text':
            'Sahip olduğun en değerli mülk, tertemiz bir vicdandır. Onu lekeleme.',
        'kind': 'Söz',
      },
      {
        'text':
            'Az ama sürekli olan iyilik, ruhu diri tutar. Küçük adımlardan korkma.',
        'kind': 'Söz',
      },
      {
        'text':
            'Bakışını dünyadan kalbine çevir; gerçek arınma orada başlar.',
        'kind': 'Söz',
      },
    ];
  }

  static List<Map<String, dynamic>> zikirDailyReflections() {
    const rows = <String>[
      'Zikir, kalbin yorulmak bilmeyen o bitmek bilmeyen uğultusunu dindirme sanatıdır.',
      'Dile düşen her kelime, ruhun üzerindeki tozları birer birer temizleyen bir yağmur damlasıdır.',
      'Dünyanın karmaşasında kaybolduğunda, kendi ismini değil, O\'nun ismini hatırlayarak kendini bulursun.',
      'Zikir, sessizliğin içinde yankılanan en samimi ve en derin fısıltıdır.',
      'Kalbin vuruşlarını birer tesbihe dönüştürmek, hayatı ritimli bir huzura kavuşturur.',
      'Kelimeler dudaktan döküldükçe, içindeki o devasa boşluğun şefkatle dolduğunu hissedersin.',
      'Zikir, aklın labirentlerinden çıkıp kalbin geniş ovalarına ulaşmanın en kısa yoludur.',
      'Unutkanlıklar denizinde boğulurken, bir kelimeyle hatırlamak ruhun can simididir.',
      'İçindeki fırtınaları dindirmek istiyorsan, dilini huzurun zikrine alıştır.',
      'Her zikir, ruhun karanlık köşelerine bırakılan küçük ve zarif birer mum ışığıdır.',
      'Zamanın acımasız akışına karşı, kalbi ebediyete bağlayan kopmaz bir bağdır.',
      'Zikir, insanın kendine verdiği en anlamlı ve en dingin mola anıdır.',
      'Söylediğin her güzel kelime, ruhunun bahçesinde açan birer çiçek gibidir.',
      'Zihin düşüncelerin yüküyle ağırlaştığında, zikir tüm fazlalıkları bir kenara iter.',
      'Kelimelerin gücüyle kalbi parlatmak, dünyayı daha net görmeni sağlar.',
      'Zikir, yalnızlığın ortasında kimsesiz olmadığını fısıldayan gizli bir arkadaştır.',
      'Kalbin pasını silen, ruhun aynasını parlatan en naif temizliktir.',
      'Her nefeste O\'nu anmak, hayatın her saniyesini anlamlı bir şiire dönüştürür.',
      'Zikir, kaygının bittiği ve güvenin başladığı o ince çizgidir.',
      'Dilin damağınla buluştuğu her an, ruhun gökyüzüyle buluştuğu andır.',
      'Dünyanın sahte renklerinden yorulan gözler için zikir, en saf beyazdır.',
      'Kalbin her atışında bir "hu" bulmak, varlığın özüne dokunmaktır.',
      'Zikir, kalbin üzerine serilen yumuşak ve huzurlu bir kadife örtüdür.',
      'Kelimelerin ötesindeki o derin sessizliğe ulaşmak için zikir en emin köprüdür.',
      'İnsanın kendiyle barışması, dilinin sevgiyi zikretmesiyle başlar.',
      'Zikir, ruhun yarasını saran, kanayan yerlerini dindiren bir merhemdir.',
      'Gözle görülmeyen ama kalple hissedilen o en büyük güce tutunma halidir.',
      'Her tesbih tanesi, seni yoran bir endişeyi parmaklarının ucundan bırakıp gitmektir.',
      'Zikir, nefes almanın sadece biyolojik değil, ruhsal bir eylem olduğunu hatırlatır.',
      'Kalbin en derin odasında yankılanan o tek isim, tüm soruların en huzurlu cevabıdır.',
    ];
    return rows
        .map(
          (tr) => <String, dynamic>{
            'text_tr': tr,
            'text': tr,
            // text_en / text_ar çevirileri mevcut değil; localizedPoolField
            // bu anahtarları bulamayınca otomatik olarak text_tr'ye düşer.
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> healingComfort() {
    return HealingDailyComfort.entries
        .map(
          (e) => <String, dynamic>{
            'arabic': e.arabic,
            'turkish': e.turkish,
            'ref': e.ref,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _hubIslamicMaps() {
    final j =
        jsonDecode(kInsightHubEmbeddedJson) as Map<String, dynamic>;
    final raw = j['islamic'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static List<Map<String, dynamic>> _hubMedicalMaps() {
    final j =
        jsonDecode(kInsightHubEmbeddedJson) as Map<String, dynamic>;
    final raw = j['medical'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Tek havuz için yerleşik tohumlama (önce [QuotePoolBulkSeeder] tercih edilir).
  static List<Map<String, dynamic>>? itemsForPoolId(String poolId) {
    switch (poolId) {
      case QuotePoolIds.notificationArinmaBodies:
        return notificationArinmaBodies();
      case QuotePoolIds.homeNamazWisdom:
        return homeNamazWisdom();
      case QuotePoolIds.zikirDailyReflections:
        return zikirDailyReflections();
      case QuotePoolIds.healingComfort:
        return healingComfort();
      case QuotePoolIds.hubGelisimIslamic:
      case QuotePoolIds.hubArinmaIslamic:
        return _hubIslamicMaps();
      case QuotePoolIds.hubGelisimMedical:
      case QuotePoolIds.hubArinmaMedical:
        return _hubMedicalMaps();
      default:
        return null;
    }
  }
}
