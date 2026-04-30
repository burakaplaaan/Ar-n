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

  static List<Map<String, dynamic>> zikirDailyReflections() {
    const rows = <({String tr, String en, String ar})>[
      (
        tr: 'Zikir, kalbin yorulmak bilmeyen o bitmek bilmeyen uğultusunu dindirme sanatıdır.',
        en: 'Zikir, kalbin yorulmak bilmeyen o bitmek bilmeyen uğultusunu dindirme sanatıdır.',
        ar: 'Zikir, kalbin yorulmak bilmeyen o bitmek bilmeyen uğultusunu dindirme sanatıdır.',
      ),
      (
        tr: 'Dile düşen her kelime, ruhun üzerindeki tozları birer birer temizleyen bir yağmur damlasıdır.',
        en: 'Dile düşen her kelime, ruhun üzerindeki tozları birer birer temizleyen bir yağmur damlasıdır.',
        ar: 'Dile düşen her kelime, ruhun üzerindeki tozları birer birer temizleyen bir yağmur damlasıdır.',
      ),
      (
        tr: 'Dünyanın karmaşasında kaybolduğunda, kendi ismini değil, O\'nun ismini hatırlayarak kendini bulursun.',
        en: 'Dünyanın karmaşasında kaybolduğunda, kendi ismini değil, O\'nun ismini hatırlayarak kendini bulursun.',
        ar: 'Dünyanın karmaşasında kaybolduğunda, kendi ismini değil, O\'nun ismini hatırlayarak kendini bulursun.',
      ),
      (
        tr: 'Zikir, sessizliğin içinde yankılanan en samimi ve en derin fısıltıdır.',
        en: 'Zikir, sessizliğin içinde yankılanan en samimi ve en derin fısıltıdır.',
        ar: 'Zikir, sessizliğin içinde yankılanan en samimi ve en derin fısıltıdır.',
      ),
      (
        tr: 'Kalbin vuruşlarını birer tesbihe dönüştürmek, hayatı ritimli bir huzura kavuşturur.',
        en: 'Kalbin vuruşlarını birer tesbihe dönüştürmek, hayatı ritimli bir huzura kavuşturur.',
        ar: 'Kalbin vuruşlarını birer tesbihe dönüştürmek, hayatı ritimli bir huzura kavuşturur.',
      ),
      (
        tr: 'Kelimeler dudaktan döküldükçe, içindeki o devasa boşluğun şefkatle dolduğunu hissedersin.',
        en: 'Kelimeler dudaktan döküldükçe, içindeki o devasa boşluğun şefkatle dolduğunu hissedersin.',
        ar: 'Kelimeler dudaktan döküldükçe, içindeki o devasa boşluğun şefkatle dolduğunu hissedersin.',
      ),
      (
        tr: 'Zikir, aklın labirentlerinden çıkıp kalbin geniş ovalarına ulaşmanın en kısa yoludur.',
        en: 'Zikir, aklın labirentlerinden çıkıp kalbin geniş ovalarına ulaşmanın en kısa yoludur.',
        ar: 'Zikir, aklın labirentlerinden çıkıp kalbin geniş ovalarına ulaşmanın en kısa yoludur.',
      ),
      (
        tr: 'Unutkanlıklar denizinde boğulurken, bir kelimeyle hatırlamak ruhun can simididir.',
        en: 'Unutkanlıklar denizinde boğulurken, bir kelimeyle hatırlamak ruhun can simididir.',
        ar: 'Unutkanlıklar denizinde boğulurken, bir kelimeyle hatırlamak ruhun can simididir.',
      ),
      (
        tr: 'İçindeki fırtınaları dindirmek istiyorsan, dilini huzurun zikrine alıştır.',
        en: 'İçindeki fırtınaları dindirmek istiyorsan, dilini huzurun zikrine alıştır.',
        ar: 'İçindeki fırtınaları dindirmek istiyorsan, dilini huzurun zikrine alıştır.',
      ),
      (
        tr: 'Her zikir, ruhun karanlık köşelerine bırakılan küçük ve zarif birer mum ışığıdır.',
        en: 'Her zikir, ruhun karanlık köşelerine bırakılan küçük ve zarif birer mum ışığıdır.',
        ar: 'Her zikir, ruhun karanlık köşelerine bırakılan küçük ve zarif birer mum ışığıdır.',
      ),
      (
        tr: 'Zamanın acımasız akışına karşı, kalbi ebediyete bağlayan kopmaz bir bağdır.',
        en: 'Zamanın acımasız akışına karşı, kalbi ebediyete bağlayan kopmaz bir bağdır.',
        ar: 'Zamanın acımasız akışına karşı, kalbi ebediyete bağlayan kopmaz bir bağdır.',
      ),
      (
        tr: 'Zikir, insanın kendine verdiği en anlamlı ve en dingin mola anıdır.',
        en: 'Zikir, insanın kendine verdiği en anlamlı ve en dingin mola anıdır.',
        ar: 'Zikir, insanın kendine verdiği en anlamlı ve en dingin mola anıdır.',
      ),
      (
        tr: 'Söylediğin her güzel kelime, ruhunun bahçesinde açan birer çiçek gibidir.',
        en: 'Söylediğin her güzel kelime, ruhunun bahçesinde açan birer çiçek gibidir.',
        ar: 'Söylediğin her güzel kelime, ruhunun bahçesinde açan birer çiçek gibidir.',
      ),
      (
        tr: 'Zihin düşüncelerin yüküyle ağırlaştığında, zikir tüm fazlalıkları bir kenara iter.',
        en: 'Zihin düşüncelerin yüküyle ağırlaştığında, zikir tüm fazlalıkları bir kenara iter.',
        ar: 'Zihin düşüncelerin yüküyle ağırlaştığında, zikir tüm fazlalıkları bir kenara iter.',
      ),
      (
        tr: 'Kelimelerin gücüyle kalbi parlatmak, dünyayı daha net görmeni sağlar.',
        en: 'Kelimelerin gücüyle kalbi parlatmak, dünyayı daha net görmeni sağlar.',
        ar: 'Kelimelerin gücüyle kalbi parlatmak, dünyayı daha net görmeni sağlar.',
      ),
      (
        tr: 'Zikir, yalnızlığın ortasında kimsesiz olmadığını fısıldayan gizli bir arkadaştır.',
        en: 'Zikir, yalnızlığın ortasında kimsesiz olmadığını fısıldayan gizli bir arkadaştır.',
        ar: 'Zikir, yalnızlığın ortasında kimsesiz olmadığını fısıldayan gizli bir arkadaştır.',
      ),
      (
        tr: 'Kalbin pasını silen, ruhun aynasını parlatan en naif temizliktir.',
        en: 'Kalbin pasını silen, ruhun aynasını parlatan en naif temizliktir.',
        ar: 'Kalbin pasını silen, ruhun aynasını parlatan en naif temizliktir.',
      ),
      (
        tr: 'Her nefeste O\'nu anmak, hayatın her saniyesini anlamlı bir şiire dönüştürür.',
        en: 'Her nefeste O\'nu anmak, hayatın her saniyesini anlamlı bir şiire dönüştürür.',
        ar: 'Her nefeste O\'nu anmak, hayatın her saniyesini anlamlı bir şiire dönüştürür.',
      ),
      (
        tr: 'Zikir, kaygının bittiği ve güvenin başladığı o ince çizgidir.',
        en: 'Zikir, kaygının bittiği ve güvenin başladığı o ince çizgidir.',
        ar: 'Zikir, kaygının bittiği ve güvenin başladığı o ince çizgidir.',
      ),
      (
        tr: 'Dilin damağınla buluştuğu her an, ruhun gökyüzüyle buluştuğu andır.',
        en: 'Dilin damağınla buluştuğu her an, ruhun gökyüzüyle buluştuğu andır.',
        ar: 'Dilin damağınla buluştuğu her an, ruhun gökyüzüyle buluştuğu andır.',
      ),
      (
        tr: 'Dünyanın sahte renklerinden yorulan gözler için zikir, en saf beyazdır.',
        en: 'Dünyanın sahte renklerinden yorulan gözler için zikir, en saf beyazdır.',
        ar: 'Dünyanın sahte renklerinden yorulan gözler için zikir, en saf beyazdır.',
      ),
      (
        tr: 'Kalbin her atışında bir "hu" bulmak, varlığın özüne dokunmaktır.',
        en: 'Kalbin her atışında bir "hu" bulmak, varlığın özüne dokunmaktır.',
        ar: 'Kalbin her atışında bir "hu" bulmak, varlığın özüne dokunmaktır.',
      ),
      (
        tr: 'Zikir, kalbin üzerine serilen yumuşak ve huzurlu bir kadife örtüdür.',
        en: 'Zikir, kalbin üzerine serilen yumuşak ve huzurlu bir kadife örtüdür.',
        ar: 'Zikir, kalbin üzerine serilen yumuşak ve huzurlu bir kadife örtüdür.',
      ),
      (
        tr: 'Kelimelerin ötesindeki o derin sessizliğe ulaşmak için zikir en emin köprüdür.',
        en: 'Kelimelerin ötesindeki o derin sessizliğe ulaşmak için zikir en emin köprüdür.',
        ar: 'Kelimelerin ötesindeki o derin sessizliğe ulaşmak için zikir en emin köprüdür.',
      ),
      (
        tr: 'İnsanın kendiyle barışması, dilinin sevgiyi zikretmesiyle başlar.',
        en: 'İnsanın kendiyle barışması, dilinin sevgiyi zikretmesiyle başlar.',
        ar: 'İnsanın kendiyle barışması, dilinin sevgiyi zikretmesiyle başlar.',
      ),
      (
        tr: 'Zikir, ruhun yarasını saran, kanayan yerlerini dindiren bir merhemdir.',
        en: 'Zikir, ruhun yarasını saran, kanayan yerlerini dindiren bir merhemdir.',
        ar: 'Zikir, ruhun yarasını saran, kanayan yerlerini dindiren bir merhemdir.',
      ),
      (
        tr: 'Gözle görülmeyen ama kalple hissedilen o en büyük güce tutunma halidir.',
        en: 'Gözle görülmeyen ama kalple hissedilen o en büyük güce tutunma halidir.',
        ar: 'Gözle görülmeyen ama kalple hissedilen o en büyük güce tutunma halidir.',
      ),
      (
        tr: 'Her tesbih tanesi, seni yoran bir endişeyi parmaklarının ucundan bırakıp gitmektir.',
        en: 'Her tesbih tanesi, seni yoran bir endişeyi parmaklarının ucundan bırakıp gitmektir.',
        ar: 'Her tesbih tanesi, seni yoran bir endişeyi parmaklarının ucundan bırakıp gitmektir.',
      ),
      (
        tr: 'Zikir, nefes almanın sadece biyolojik değil, ruhsal bir eylem olduğunu hatırlatır.',
        en: 'Zikir, nefes almanın sadece biyolojik değil, ruhsal bir eylem olduğunu hatırlatır.',
        ar: 'Zikir, nefes almanın sadece biyolojik değil, ruhsal bir eylem olduğunu hatırlatır.',
      ),
      (
        tr: 'Kalbin en derin odasında yankılanan o tek isim, tüm soruların en huzurlu cevabıdır.',
        en: 'Kalbin en derin odasında yankılanan o tek isim, tüm soruların en huzurlu cevabıdır.',
        ar: 'Kalbin en derin odasında yankılanan o tek isim, tüm soruların en huzurlu cevabıdır.',
      ),
    ];
    return rows
        .map(
          (e) => <String, dynamic>{
            'text_tr': e.tr,
            'text_en': e.en,
            'text_ar': e.ar,
            'text': e.tr,
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
