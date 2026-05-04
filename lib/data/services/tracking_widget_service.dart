import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/willpower_templates.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import '../repositories/kaza_tracking_repository.dart';
import '../repositories/salat_log_repository.dart';
import 'arin_widget_sync.dart';

abstract final class TrackingWidgetPrefs {
  static const selectedTarget = 'arin_tracking_widget_selected_target';
}

class TrackingWidgetOption {
  const TrackingWidgetOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.snapshot,
  });

  final String id;
  final String title;
  final String subtitle;
  final TrackingWidgetSnapshot snapshot;
}

class TrackingWidgetSnapshot {
  const TrackingWidgetSnapshot({
    required this.title,
    required this.value,
    required this.note,
    required this.quotes,
    this.mode = 'static',
    this.startEpochMs,
    this.dayPrefix = '',
  });

  final String title;
  final String value;
  final String note;
  final List<String> quotes;
  final String mode;
  final int? startEpochMs;
  final String dayPrefix;
}

abstract final class TrackingWidgetService {
  static const _kazaTargetId = 'kaza';

  static String habitTargetId(String habitId) => 'habit:$habitId';

  static Future<List<TrackingWidgetOption>> availableOptions({
    required SharedPreferences prefs,
    required HabitRepository habitRepo,
    required SalatLogRepository salatRepo,
  }) async {
    final options = <TrackingWidgetOption>[];
    final today = DateTime.now();
    final habits = habitRepo.getAll();

    for (final h in habits) {
      if (h.isArchived) continue;
      final option = _optionForHabit(h, habitRepo, salatRepo, today);
      if (option != null) options.add(option);
    }

    final kaza = KazaTrackingRepository(prefs).load();
    if (kaza.hubEnabled && kaza.total > 0) {
      options.add(
        TrackingWidgetOption(
          id: _kazaTargetId,
          title: 'Kaza namazı',
          subtitle: 'Kalan toplam kaza sayısı',
          snapshot: TrackingWidgetSnapshot(
            title: 'Kaza namazı',
            value: 'Kalan ${kaza.total}',
            note: _quoteFor(_QuoteKind.kaza, today),
            quotes: _quotesFor(_QuoteKind.kaza),
          ),
        ),
      );
    }

    return options;
  }

  static String? selectedTarget(SharedPreferences prefs) {
    final raw = prefs.getString(TrackingWidgetPrefs.selectedTarget)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static Future<void> selectTarget({
    required SharedPreferences prefs,
    required HabitRepository habitRepo,
    required SalatLogRepository salatRepo,
    required String? targetId,
  }) async {
    if (targetId == null || targetId.isEmpty) {
      await prefs.remove(TrackingWidgetPrefs.selectedTarget);
      await ArinWidgetSync.clearTracking();
      return;
    }

    final options = await availableOptions(
      prefs: prefs,
      habitRepo: habitRepo,
      salatRepo: salatRepo,
    );
    final selected = _firstWhereOrNull(options, (o) => o.id == targetId);
    if (selected == null) {
      await prefs.remove(TrackingWidgetPrefs.selectedTarget);
      await ArinWidgetSync.clearTracking();
      return;
    }

    await prefs.setString(TrackingWidgetPrefs.selectedTarget, targetId);
    await pushSnapshot(selected.snapshot);
  }

  static Future<void> refreshSelected({
    required SharedPreferences prefs,
    required HabitRepository habitRepo,
    required SalatLogRepository salatRepo,
  }) async {
    final targetId = selectedTarget(prefs);
    if (targetId == null) {
      await ArinWidgetSync.clearTracking();
      return;
    }

    final options = await availableOptions(
      prefs: prefs,
      habitRepo: habitRepo,
      salatRepo: salatRepo,
    );
    final selected = _firstWhereOrNull(options, (o) => o.id == targetId);
    if (selected == null) {
      await prefs.remove(TrackingWidgetPrefs.selectedTarget);
      await ArinWidgetSync.clearTracking();
      return;
    }
    await pushSnapshot(selected.snapshot);
  }

  static Future<void> pushSnapshot(TrackingWidgetSnapshot snapshot) async {
    await ArinWidgetSync.pushTracking(
      title: snapshot.title,
      value: snapshot.value,
      note: snapshot.note,
      quotesJson: jsonEncode(snapshot.quotes),
      mode: snapshot.mode,
      startEpochMs: snapshot.startEpochMs,
      dayPrefix: snapshot.dayPrefix,
    );
  }

  static TrackingWidgetOption? _optionForHabit(
    HabitModel h,
    HabitRepository habitRepo,
    SalatLogRepository salatRepo,
    DateTime today,
  ) {
    if (h.templateId == WillpowerTemplates.salatDaily) {
      if (!h.onboardingCompleted) return null;
      final done = salatRepo.countDone(h.id, today);
      return TrackingWidgetOption(
        id: habitTargetId(h.id),
        title: 'Namaz takibi',
        subtitle: 'Bugünkü 5 vakit ilerlemesi',
        snapshot: TrackingWidgetSnapshot(
          title: 'Namaz takibi',
          value: 'Bugün $done/5 vakit',
          note: _quoteFor(_QuoteKind.salat, today),
          quotes: _quotesFor(_QuoteKind.salat),
        ),
      );
    }

    if (WillpowerTemplates.isFullQuitProgram(h.templateId)) {
      final iso = h.quitClockStartedAtIso;
      if (iso == null || iso.isEmpty) return null;
      final start = DateTime.tryParse(iso);
      if (start == null) return null;
      final kind = _quoteKindForTemplate(h.templateId);
      final prefix = _dayPrefixForTemplate(h.templateId);
      final title = _quitOptionTitle(h.templateId);
      return TrackingWidgetOption(
        id: habitTargetId(h.id),
        title: title,
        subtitle: 'Gün sayacı ve günlük motivasyon',
        snapshot: TrackingWidgetSnapshot(
          title: title,
          value: '$prefix ${habitRepo.elapsedQuitDays(h.id)}. gün',
          note: _quoteFor(kind, today),
          quotes: _quotesFor(kind),
          mode: 'quit_days',
          startEpochMs: start.millisecondsSinceEpoch,
          dayPrefix: prefix,
        ),
      );
    }

    if (h.isCustomTracked) {
      final title = h.title.trim().isEmpty ? 'Özel takip' : h.title.trim();
      if (h.type == HabitType.bad) {
        final start = DateTime.tryParse(h.startedAtIso) ?? DateTime.now();
        final days = DateTime.now().difference(start).inDays.clamp(0, 999999);
        return TrackingWidgetOption(
          id: habitTargetId(h.id),
          title: title,
          subtitle: 'Arınma gün sayacı',
          snapshot: TrackingWidgetSnapshot(
            title: title,
            value: 'Temiz $days. gün',
            note: _quoteFor(_QuoteKind.customQuit, today),
            quotes: _quotesFor(_QuoteKind.customQuit),
            mode: 'quit_days',
            startEpochMs: start.millisecondsSinceEpoch,
            dayPrefix: 'Temiz',
          ),
        );
      }
      final progress = habitRepo.todayProgressValue(h.id);
      final unit = h.customUnit.trim();
      final suffix = unit.isEmpty ? '' : ' $unit';
      return TrackingWidgetOption(
        id: habitTargetId(h.id),
        title: title,
        subtitle: 'Bugünkü hedef ilerlemesi',
        snapshot: TrackingWidgetSnapshot(
          title: title,
          value: 'Bugün $progress/${h.effectiveDailyTarget}$suffix',
          note: _quoteFor(_QuoteKind.customBuild, today),
          quotes: _quotesFor(_QuoteKind.customBuild),
        ),
      );
    }

    return null;
  }

  static _QuoteKind _quoteKindForTemplate(String templateId) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking => _QuoteKind.smoking,
      WillpowerTemplates.quitAlcohol => _QuoteKind.alcohol,
      WillpowerTemplates.quitScreen => _QuoteKind.screen,
      _ => _QuoteKind.customQuit,
    };
  }

  static String _dayPrefixForTemplate(String templateId) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking => 'Sigarasız',
      WillpowerTemplates.quitAlcohol => 'Temiz',
      WillpowerTemplates.quitScreen => 'Ekransız',
      _ => 'Temiz',
    };
  }

  static String _quitOptionTitle(String templateId) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking => 'Sigarasız gün sayacı',
      WillpowerTemplates.quitAlcohol => 'Temiz yaşam sayacı',
      WillpowerTemplates.quitScreen => 'Ekran sınırı sayacı',
      WillpowerTemplates.quitSubstance => 'Temiz gün sayacı',
      WillpowerTemplates.quitZina => 'Arınma gün sayacı',
      _ => 'Arınma gün sayacı',
    };
  }

  static String _quoteFor(_QuoteKind kind, DateTime day) {
    final quotes = _quotesFor(kind);
    final index = _daySeed(day) % quotes.length;
    return quotes[index];
  }

  static int _daySeed(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return d.difference(DateTime(day.year, 1, 1)).inDays;
  }

  static List<String> _quotesFor(_QuoteKind kind) {
    return switch (kind) {
      _QuoteKind.smoking => const [
        'Kriz geçer, kararın kalır.',
        'Bugün nefesin için güzel bir adım.',
        'Temiz kalan her saat bedenine iyilik yazar.',
        'Bir isteği ertelemek, iradeni büyütür.',
        'Nefesin hafifledikçe yolun da hafifler.',
        'Bugün de dumanı değil huzuru seç.',
        'Zor an kısa, kazancın uzun.',
        'Bir nefeslik sabır, bir gün daha kazandırır.',
        'Duman yerine ferahlığı seçiyorsun.',
        'Bugün kararın bedenine iyi gelir.',
        'İstek gelir geçer, sen kalırsın.',
        'Temiz saatler sessizce güç toplar.',
        'Nefsin ister, iraden yol gösterir.',
        'Bugün ciğerlerine iyilik yap.',
        'Bir paket değil, bir gelecek seçiyorsun.',
        'Temiz kalmak küçük anlarda kazanılır.',
        'Bugün hayır demen yarına güç olur.',
        'Daha hafif nefes için bir gün daha.',
        'Kararın tazeyse yolun da açıktır.',
        'Kendine verdiğin sözü bugün de koru.',
        'Sigara değil, sakinlik yanında olsun.',
        'Her temiz gün yeni bir başlangıçtır.',
        'Zorlanman normal, vazgeçmemen kıymetli.',
        'Bugün iraden dumanı dağıtıyor.',
        'Bir kriz daha geçecek, sen büyüyeceksin.',
        'Temiz nefes temiz niyetle başlar.',
        'Bedenin bugün teşekkür ediyor.',
        'Dumansız bir an bile değerlidir.',
        'Küçük direnç büyük dönüşüm getirir.',
        'Bugün nefesine alan aç.',
        'Dumanı bırak, ferahlığı büyüt.',
        'Her hayır cevabı iradeni parlatır.',
        'Bugün kendin için iyi bir seçim yaptın.',
        'Temiz kalışın sessiz bir zaferdir.',
        'Bir gün daha, daha güçlü bir nefes.',
        'İstek dalga gibidir, geçmesine izin ver.',
        'Bugün sigarasız duruşun bereket olsun.',
        'Kendine zarar değil, merhamet seç.',
        'Dumansız yol sabırla güzelleşir.',
        'Her temiz sabah yeni bir hediyedir.',
        'Bir nefes daha özgürleşiyorsun.',
        'Bugün eski alışkanlığa kapı açma.',
        'Kararını korudukça kalbin rahatlar.',
        'Temiz günlerin birikiyor.',
        'Nefesin için bugün de yanındasın.',
        'Duman eksildikçe umut artar.',
        'Güçlü olmak bazen sadece beklemektir.',
        'Bugün kendine temiz bir alan aç.',
        'Sigarasız kalmak, kendini önemsemektir.',
        'Her temiz an dönüşünün şahididir.',
      ],
      _QuoteKind.alcohol => const [
        'Bugün kendine iyi gelen yolu seçtin.',
        'Aklını ve kalbini koruyan bir gün.',
        'Temiz bir gün, güçlü bir başlangıçtır.',
        'Kararın bugün de yanında dursun.',
        'Sakinlik bazen hayır diyebilmekle başlar.',
        'Bugün bedenine ve ailene iyi geleni seç.',
        'Bir gün daha, daha berrak bir zihin.',
        'Temiz kalmak kalbine alan açar.',
        'Bugün huzuru ertelemiyorsun.',
        'Kararını korumak büyük bir iyiliktir.',
        'Bir hayır cevabı, yarına ferahlık taşır.',
        'Bugün aklına sahip çıkıyorsun.',
        'Sakin bir gece, temiz bir seçimle başlar.',
        'Kendine verdiğin değer bugün görünür.',
        'Temiz yaşam sessizce güç toplar.',
        'Bugün netlik senin yanında.',
        'Zor an geçer, temiz karar kalır.',
        'Kalbin hafiflesin diye bugün devam.',
        'Bir gün daha kendine emanet oldun.',
        'Temiz kalışın ailene de huzur taşır.',
        'Bugün pişmanlığı değil ferahlığı seç.',
        'Sabrın aklını berrak tutar.',
        'Kendini koruman kıymetli bir ibadettir.',
        'Bugün hayatına temiz bir sayfa ekle.',
        'İstek kısa, kazancın uzun.',
        'Temiz bir karar, güçlü bir duruştur.',
        'Bugün bedenine yumuşak davran.',
        'Sakinliğin büyüsün, yükün azalsın.',
        'Bir temiz gün daha istikamet demektir.',
        'Bugün kendini yarına taşıyorsun.',
        'Kararın sarsılsa da yolun durmasın.',
        'Temiz seçimler güveni geri getirir.',
        'Bugün daha berrak düşünmek için devam.',
        'Huzur küçük hayırlarla büyür.',
        'Kendini suçlama, yoluna sahip çık.',
        'Bugün temiz kalmak yeterli bir zafer.',
        'Aklına, bedenine, kalbine iyi bak.',
        'Temiz yaşam bugün bir adım daha yakın.',
        'Zorlanınca destek iste, yalnız değilsin.',
        'Bugün kontrolü geri alıyorsun.',
        'Sözünü korumak kalbini güçlendirir.',
        'Temiz kalan günler umut biriktirir.',
        'Bugün ferahlığı seçen tarafın kazansın.',
        'Kendine merhamet ederek devam et.',
        'Bir gün daha berraklık, bir gün daha güç.',
        'Bugün hayırlı olanı seçmek yeter.',
        'Temiz yol sabırla genişler.',
        'Kararınla birlikte yükün de hafifler.',
        'Bugün iç huzuruna yatırım yaptın.',
        'Temiz kalışın sessiz ama büyük bir adım.',
      ],
      _QuoteKind.screen => const [
        'Ekrana sınır, hayata alan açar.',
        'Bugün dikkatini korumak da ibadettir.',
        'Az ekran, daha derin bir nefes.',
        'Sessizlik bazen en güzel yenilenmedir.',
        'Vaktini korudukça kalbin toparlanır.',
        'Bir bakışı azalt, bir anı çoğalt.',
        'Bugün odak senin yanında.',
        'Ekranı kapatınca hayat konuşur.',
        'Bugün zihnine sakinlik ver.',
        'Dikkatini korumak vaktini korumaktır.',
        'Az bildirim, çok huzur.',
        'Bir ekran molası kalbine iyi gelir.',
        'Bugün gerçek ana yaklaş.',
        'Parmağın durdukça zihnin dinlenir.',
        'Ekrana değil, niyetine dön.',
        'Vaktin kıymetli, onu nazikçe koru.',
        'Bugün odak için küçük bir sınır koy.',
        'Daha az kaydır, daha çok yaşa.',
        'Sessiz anlar içini toparlar.',
        'Ekran azalınca dikkat çoğalır.',
        'Bugün kendine çevrim dışı bir nefes ver.',
        'Bir bakış eksilt, bir dua artır.',
        'Zihnin sadeleşsin diye devam et.',
        'Bugün ekran değil sen yön ver.',
        'Kısa mola, uzun huzur getirir.',
        'Dikkat dağılır, niyet toparlar.',
        'Bugün vaktini hayra sakla.',
        'Az ekran, güçlü irade.',
        'Kendine sessiz bir alan aç.',
        'Bir bildirim bekleyebilir, kalbin beklemesin.',
        'Bugün kaydırmayı değil yaşamayı seç.',
        'Sınır koymak özgürlük getirir.',
        'Ekransız anlar zihne ferahlık verir.',
        'Bugün odak kapını açık tut.',
        'Vaktini korudukça bereket artar.',
        'Ekranı azaltmak kendine dönmektir.',
        'Bugün daha az tüket, daha çok üret.',
        'Bir anlık duruş günü değiştirir.',
        'Zihin yorulunca sessizlik şifa olur.',
        'Bugün ekran sınırın kalbine iyi gelsin.',
        'Dikkatini emanet gibi koru.',
        'Az bak, derin gör.',
        'Bugün zamanını geri al.',
        'Ekransız birkaç dakika bile kıymetli.',
        'Kalbinin sesine yer aç.',
        'Bugün kendine sakin bir pencere aç.',
        'Sınırların huzurunu korur.',
        'Daha az ekran, daha temiz niyet.',
        'Bugün odağın bereketlensin.',
        'Ekranı değil hayatı takip et.',
      ],
      _QuoteKind.salat => const [
        'Bir vakit daha kalbine iyi gelir.',
        'Bugün namazla günün bereketlensin.',
        'Küçük bir yöneliş, büyük bir huzur taşır.',
        'Vakit geldikçe kalp de toparlanır.',
        'Secde, günün en sakin durağıdır.',
        'Bir vakit daha, Rabbine yakınlık.',
        'Bugün 5 vakte doğru güzel bir adım.',
        'Vakit çağırınca kalbin de davete uysun.',
        'Namaz günün merkezini toparlar.',
        'Bir secde, birçok yükü hafifletir.',
        'Bugün bir vakti daha özenle koru.',
        'Kalp namazla yönünü bulur.',
        'Vakitler gününe bereketli işaretlerdir.',
        'Bugün huzura birkaç dakika ayır.',
        'Namaz, dağınık günü toplar.',
        'Bir vakit daha, bir yakınlık daha.',
        'Secde kalbin nefesidir.',
        'Bugün namazla içini sakinleştir.',
        'Vaktini koruyan kalbini korur.',
        'Her vakit yeni bir dönüş kapısıdır.',
        'Bugün namaz sana yumuşaklık versin.',
        'Kalbin yorulunca seccade seni bekler.',
        'Bir ezan, bir davet, bir huzur.',
        'Bugün namazı ertelemeden sahiplen.',
        'Vakit geldiyse rahmet kapısı açıktır.',
        'Secdeyle günün yükü hafifler.',
        'Namaz küçük görünen büyük bir bağdır.',
        'Bugün kalbin kıbleye dönsün.',
        'Bir vakit daha istikamet demektir.',
        'Namazla başlayan an bereket taşır.',
        'Bugün Rabbine yakın bir adım at.',
        'Vakitler seni toparlamak için gelir.',
        'Secde, kalbin en güvenli yeridir.',
        'Bugün namazla kendine dön.',
        'Bir vakti koru, günün güzelleşsin.',
        'Namaz ruhun düzenidir.',
        'Bugün huzuru vakit vakit yaşa.',
        'Ezan duyulunca kalbin hatırlasın.',
        'Bir namaz daha içini aydınlatır.',
        'Bugün seccadeye kısa bir dönüş yeter.',
        'Vakti kaçırmamak kalbe disiplin verir.',
        'Namazla günün dağınıklığı azalır.',
        'Bugün bir vakte daha sadakat göster.',
        'Secdede kalbin yükünü bırak.',
        'Vakitler rahmetin randevusudur.',
        'Bugün namazla niyetini yenile.',
        'Bir vakit daha sabrını güçlendirir.',
        'Kalp namazla sakinleşir.',
        'Bugün 5 vakte doğru kararlı kal.',
        'Namaz, günün içinde saklı bir ferahlıktır.',
      ],
      _QuoteKind.kaza => const [
        'Azalan her borç, hafifleyen bir yoldur.',
        'Bugün küçük bir kaza, yarına büyük ferahlık.',
        'Bir adım eksiltmek de istikamettir.',
        'Sabırla azalan yük, kalbi rahatlatır.',
        'Telafi yolu acele değil, devam ister.',
        'Bugün bir borcu daha hafiflet.',
        'Her kaza, dönüş yolunda bir işarettir.',
        'Bir kaza daha, bir yük daha hafif.',
        'Telafi küçük adımlarla güzelleşir.',
        'Bugün geçmişe güzel bir iyilik yap.',
        'Azaltılan her borç kalbe ferahlık verir.',
        'Devam ettikçe yol kısalır.',
        'Bir vakit telafi, bir niyet yenileme.',
        'Bugün kaza yükünden biraz daha eksilt.',
        'Sabırla yapılan telafi kıymetlidir.',
        'Her adım dönüşünü güçlendirir.',
        'Bugün küçük bir eksiltme bile yeter.',
        'Kaza takibi acele değil sebat ister.',
        'Bir borcu daha hatırlayıp sahiplen.',
        'Telafi eden kalp umut taşır.',
        'Bugün geçmişin yükünü azalt.',
        'Azalan sayı, büyüyen ferahlıktır.',
        'Bir kaza daha istikamet demektir.',
        'Yavaş da olsa devam etmek kazançtır.',
        'Bugün telafi kapısından geç.',
        'Kalanlar azalır, niyet güçlenir.',
        'Bir vakit daha kalbine hafiflik verir.',
        'Telafi yolunda küçük adım büyüktür.',
        'Bugün borcuna sadakat göster.',
        'Her eksilen sayı sabrının şahididir.',
        'Kaza namazı düzenle hafifler.',
        'Bugün bir adım, yarın daha rahat bir kalp.',
        'Telafi ettikçe yolun aydınlanır.',
        'Bir vakit daha, bir ferahlık daha.',
        'Bugün kalan yükü biraz azalt.',
        'Sabırla eksilen borç güzeldir.',
        'Kaza takibi kalbe sorumluluk öğretir.',
        'Bugün dönüş niyetini diri tut.',
        'Az da olsa eksiltmek berekettir.',
        'Bir kaza daha geçmişe güzel cevap.',
        'Bugün telafiyle kalbini rahatlat.',
        'Kalan sayı seni korkutmasın, adım at.',
        'Her gün biraz eksilirse yol biter.',
        'Telafi, umudun düzenli halidir.',
        'Bugün bir vakit daha tamamla.',
        'Sabrınla yükün hafifliyor.',
        'Kaza yolunda istikrar en büyük yardımdır.',
        'Bugün eksilen sayı sana güç versin.',
        'Her telafi yeni bir başlangıçtır.',
        'Bir adım daha, daha hafif bir kalp.',
      ],
      _QuoteKind.customBuild => const [
        'Bugünkü küçük ilerleme yarına güç verir.',
        'Hedefe giden yol tek adımla açılır.',
        'Az da olsa devam eden kazanır.',
        'Bugün ölçtüğün şey, yarın büyür.',
        'İstikrar, küçük tekrarlarla kurulur.',
        'Bir adım daha, alışkanlık biraz daha sağlam.',
        'Bugün hedefinle aranı yakın tut.',
        'Küçük ilerleme de ilerlemedir.',
        'Bugün hedefin için bir taş koy.',
        'Devam etmek mükemmel olmaktan kıymetlidir.',
        'Bir tekrar daha, daha sağlam bir düzen.',
        'Bugün emeğin yarına iz bırakır.',
        'Hedef küçük adımlarla yakınlaşır.',
        'İstikrar sessizce güç biriktirir.',
        'Bugün kendine verdiğin sözü besle.',
        'Az ama düzenli olan büyür.',
        'Bir adım hedefini canlı tutar.',
        'Bugün ölç, gör, devam et.',
        'Küçük kazanımlar büyük güven doğurur.',
        'Hedefin bugün senden bir adım bekliyor.',
        'Devam eden yolunu bulur.',
        'Bugün ilerlemen yeterli.',
        'Bir sayfa, bir dakika, bir adım kıymetli.',
        'İstikrarın bugünkü hali bu adım.',
        'Hedefe saygı, bugünkü emekle başlar.',
        'Bugün yaptığın küçük iş seni büyütür.',
        'Biraz daha devam, biraz daha güç.',
        'Gelişim acele değil yön ister.',
        'Bugün hedefinle bağını koparma.',
        'Küçük tekrarlar karaktere dönüşür.',
        'İlerlemeni görmek motivasyonunu artırır.',
        'Bugün kendine yatırım yap.',
        'Hedefe yakınlık düzenle kurulur.',
        'Bir adım daha, alışkanlık biraz daha yerleşir.',
        'Bugün küçük emeğini küçümseme.',
        'Devamlılık başarının sade halidir.',
        'Hedefin için bugün de hazır ol.',
        'Az ilerle, ama bırakma.',
        'Bugün yaptığın şey yarının temelidir.',
        'Küçük başarılar güven inşa eder.',
        'Hedefinle aranı iyi tut.',
        'Bugün başladığın kadar kazanırsın.',
        'Gelişim günlük emek ister.',
        'Bir tekrar daha seni güçlendirir.',
        'Bugün hedefini hatırla ve ilerle.',
        'İstikrar küçük zaferlerden oluşur.',
        'Az da olsa tamamlanan değerlidir.',
        'Bugün bir adım daha kendine yaklaştın.',
        'Hedefine bugün nazikçe dön.',
        'Küçük ölçüm büyük farkındalık getirir.',
      ],
      _QuoteKind.customQuit => const [
        'Temiz bir gün, yeni bir güçtür.',
        'Bugün kendine verdiğin sözü koru.',
        'Zor an geçer, niyetin kalır.',
        'Her temiz gün kalbine ferahlık taşır.',
        'Bir gün daha, daha güçlü bir sen.',
        'Bugün hayrı seçmek için yeterli.',
        'İrade tekrar ettikçe güçlenir.',
        'Temiz kalmak küçük anlarda kazanılır.',
        'Bugün eski alışkanlığa kapı açma.',
        'Bir hayır cevabı kalbini korur.',
        'Zorlanman yolun bittiği anlamına gelmez.',
        'Bugün kendini temiz tarafta tut.',
        'İstek geçer, kararın kalır.',
        'Her temiz an dönüşünü güçlendirir.',
        'Bugün kendine merhametle devam et.',
        'Temiz seçimler huzur biriktirir.',
        'Bir gün daha niyetini diri tut.',
        'Eski yola değil, yeni güce bak.',
        'Bugün sabrın sana destek olsun.',
        'Temiz kalışın sessiz bir başarıdır.',
        'Bir kriz daha geçecek.',
        'Bugün kendin için iyi olanı seç.',
        'Niyetini koru, adımını küçümseme.',
        'Temiz bir gün kalbe umut verir.',
        'Bugün alışkanlığın değil sen yönet.',
        'Bir anlık sabır günü değiştirir.',
        'Temiz yol her gün biraz güçlenir.',
        'Bugün kararını nazikçe koru.',
        'Zor anlarda nefes al ve bekle.',
        'Her hayır cevabı iradeni büyütür.',
        'Bugün kendine temiz bir sayfa aç.',
        'Eski döngüye dönmemek büyük adımdır.',
        'Temiz kalmak kendine saygıdır.',
        'Bugün kalbini hafif tut.',
        'Bir gün daha özgürleşiyorsun.',
        'İrade sabırla kök salar.',
        'Bugün niyetin davranışına yön versin.',
        'Temiz seçimler seni güçlendirir.',
        'Kendine verdiğin sözü küçük görme.',
        'Bugün hayırlı olana yakın dur.',
        'Zor an kısa, temiz kazanç uzun.',
        'Bir adım daha, daha ferah bir yol.',
        'Bugün kendini korumayı seç.',
        'Temiz kalışın yarına umut taşır.',
        'Eski alışkanlık seslenir, sen yoluna bak.',
        'Bugün sabırla yeni bir güç kur.',
        'Bir temiz gün daha kıymetlidir.',
        'Kendine dönmek güzel bir başlangıçtır.',
        'Bugün niyetin temiz, yolun açık olsun.',
        'Her temiz gün yeni bir güven verir.',
      ],
    };
  }

  static T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}

enum _QuoteKind {
  smoking,
  alcohol,
  screen,
  salat,
  kaza,
  customBuild,
  customQuit,
}
