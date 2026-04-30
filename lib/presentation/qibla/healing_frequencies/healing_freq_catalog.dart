// Frekans meta verisi — başlık ve kısa açıklamalar (UI + seçim listesi).

import 'package:flutter/widgets.dart';

import '../../../core/localization/locale_text.dart';

/// Hub kartında gösterilen kısa rol etiketi (büyük daire altı).
abstract final class HealingFreqCatalog {
  static const List<int> orderedHz = <int>[
    174,
    285,
    396,
    417,
    528,
    639,
    741,
    852,
  ];

  static String toneAssetPath(int hz) =>
      'sounds/healing/tones/tone_${hz}hz.wav';

  static String shortTitle(BuildContext context, int hz) {
    switch (hz) {
      case 174:
        return trEnAr(context, tr: 'Terapi Frekansı', en: 'Therapy Frequency', ar: 'تردد علاجي');
      case 285:
        return trEnAr(context, tr: 'Direnç ve Metanet', en: 'Resilience', ar: 'الصبر والثبات');
      case 396:
        return trEnAr(context, tr: 'Yenilenme', en: 'Renewal', ar: 'تجدد');
      case 417:
        return trEnAr(context, tr: 'İç güç', en: 'Inner strength', ar: 'قوة داخلية');
      case 528:
        return trEnAr(context, tr: 'Huzur', en: 'Peace', ar: 'سكينة');
      case 639:
        return trEnAr(context, tr: 'Arınma', en: 'Purification', ar: 'تزكية');
      case 741:
        return trEnAr(context, tr: 'Tefekkür', en: 'Contemplation', ar: 'تفكر');
      case 852:
        return trEnAr(context, tr: 'Sekîne', en: 'Tranquility', ar: 'سكينة عميقة');
      default:
        return '$hz Hz';
    }
  }

  /// “Tüm Frekanslar” yatay liste altı — başlıktaki “Hz - ” sonrası tam metin.
  static String listCaption(BuildContext context, int hz) {
    final full = heading(context, hz);
    const sep = ' - ';
    final i = full.indexOf(sep);
    if (i >= 0) {
      return full.substring(i + sep.length);
    }
    return shortTitle(context, hz);
  }

  static String heading(BuildContext context, int hz) {
    switch (hz) {
      case 174:
        return trEnAr(context, tr: '174 Hz - Şifa ve Rahatlama', en: '174 Hz - Healing and Relaxation', ar: '174 هرتز - شفاء واسترخاء');
      case 285:
        return trEnAr(context, tr: '285 Hz - Sabır ve Sebat', en: '285 Hz - Patience and Steadiness', ar: '285 هرتز - صبر وثبات');
      case 396:
        return trEnAr(context, tr: '396 Hz - Bereket ve Başlangıç', en: '396 Hz - Blessing and New Start', ar: '396 هرتز - بركة وبداية');
      case 417:
        return trEnAr(context, tr: '417 Hz - İç Güç ve İman', en: '417 Hz - Inner Strength and Faith', ar: '417 هرتز - قوة داخلية وإيمان');
      case 528:
        return trEnAr(context, tr: '528 Hz - Huzur ve Sükûnet', en: '528 Hz - Peace and Calm', ar: '528 هرتز - سكينة وهدوء');
      case 639:
        return trEnAr(context, tr: '639 Hz - Arınma ve Temizlik', en: '639 Hz - Purification and Cleansing', ar: '639 هرتز - تزكية وتنقية');
      case 741:
        return trEnAr(context, tr: '741 Hz - Tefekkür ve Dikkat', en: '741 Hz - Reflection and Focus', ar: '741 هرتز - تفكر وتركيز');
      case 852:
        return trEnAr(context, tr: '852 Hz - Sekîne (Derin Huzur)', en: '852 Hz - Tranquility (Deep Peace)', ar: '852 هرتز - سكينة (طمأنينة عميقة)');
      default:
        return '$hz Hz';
    }
  }

  static String body(BuildContext context, int hz) {
    switch (hz) {
      case 174:
        return trEnAr(context, tr: 'Bedensel ve ruhsal yorgunlukta sükûnete yönelme; şifa Allah’tandır.', en: 'Turn toward calm in physical and spiritual fatigue; healing is from Allah.', ar: 'اتجه إلى السكون عند التعب الجسدي والروحي؛ الشفاء من الله.');
      case 285:
        return trEnAr(context, tr: 'Zorlukta kalbi yumuşatma; Allah’a tevekkül ile devam etme niyeti.', en: 'Soften the heart in hardship; continue with trust in Allah.', ar: 'تليين القلب وقت الشدة؛ الاستمرار بالتوكل على الله.');
      case 396:
        return trEnAr(context, tr: 'Yeni bir sayfa açma; günahtan arınma ve affa yönelme duası.', en: 'Open a new page; a prayer for repentance and forgiveness.', ar: 'فتح صفحة جديدة؛ دعاء للتوبة وطلب المغفرة.');
      case 417:
        return trEnAr(context, tr: 'Kalbi güçlendirme; imanı tazeleme ve istikamet hatırlaması.', en: 'Strengthen the heart; renew faith and remember right direction.', ar: 'تقوية القلب؛ تجديد الإيمان وتذكّر الاستقامة.');
      case 528:
        return trEnAr(context, tr: 'Gönül sükûneti; şükür ve teslimiyetle nefes alma.', en: 'Inner calm; breathe with gratitude and surrender.', ar: 'سكون القلب؛ تنفّس بالشكر والتسليم.');
      case 639:
        return trEnAr(context, tr: 'Kalbi kirleten düşüncelerden uzaklaşma; bağışlanma dileği.', en: 'Step away from thoughts that cloud the heart; seek forgiveness.', ar: 'الابتعاد عن الأفكار التي تكدّر القلب؛ طلب المغفرة.');
      case 741:
        return trEnAr(context, tr: 'Ayete ve yaratılışa odaklanma; dağılan zihni toplama.', en: 'Focus on verses and creation; gather a scattered mind.', ar: 'التركيز على الآيات والخلق؛ جمع الذهن المشتت.');
      case 852:
        return trEnAr(context, tr: 'Kalbe ferahlık veren sükûnet; Allah’ın rahmetine sığınma.', en: 'A calm that brings relief to the heart; seek Allah’s mercy.', ar: 'سكينة تشرح الصدر؛ الالتجاء إلى رحمة الله.');
      default:
        return '';
    }
  }

}
