import '../constants/willpower_templates.dart';

/// Onboarding “Kendine sözün” örnek cümle chip’leri (şablona göre).
Map<String, String> quitCommitmentChipsFor(
  String templateId, {
  String localeCode = 'tr',
}) {
  final isAr = localeCode.toLowerCase().startsWith('ar');
  final isEn = localeCode.toLowerCase().startsWith('en');
  switch (templateId) {
    case WillpowerTemplates.quitSmoking:
      if (isAr) {
        return const {
          'روحي': 'سأفي بالعهد الذي قطعته مع الله.',
          'شخصي': 'أتركه احترامًا لنفسي.',
          'العائلة': 'سأكون أقوى من أجل أحبتي.',
          'المستقبل': 'لا مكان للتدخين في مستقبلي.',
        };
      }
      if (isEn) {
        return const {
          'Spiritual': 'I will keep the promise I made to Allah.',
          'Personal': 'I am quitting out of respect for myself.',
          'Family': 'I will be stronger for my loved ones.',
          'Future': 'There is no smoking in my future.',
        };
      }
      return const {
        'Manevi': 'Allah\'a verdiğim sözü tutacağım.',
        'Kişisel': 'Kendime saygım için bırakıyorum.',
        'Aile': 'Sevdiklerim için daha güçlü olacağım.',
        'Gelecek': 'Geleceğimde sigara yok.',
      };
    case WillpowerTemplates.quitScreen:
      if (isAr) {
        return const {
          'نية': 'سأصرف وقتي في الخير.',
          'حدود': 'أضع حدودًا واعية للشاشة.',
          'العائلة': 'سأزيد الوقت وجهًا لوجه.',
          'سكينة': 'أفسح مجالًا للتفكر والهدوء.',
        };
      }
      if (isEn) {
        return const {
          'Intention': 'I will spend my time in good deeds.',
          'Boundaries': 'I set conscious screen limits.',
          'Family': 'I will increase face-to-face time.',
          'Calm': 'I make room for reflection and calm.',
        };
      }
      return const {
        'Niyet': 'Vaktimi hayırla harcayacağım.',
        'Sınır': 'Ekrana bilinçli sınır koyuyorum.',
        'Aile': 'Yüz yüze vakit artıracağım.',
        'Sükûnet': 'Tefekkür ve dinginlik için yer açıyorum.',
      };
    case WillpowerTemplates.quitAlcohol:
      if (isAr) {
        return const {
          'روحي': 'أترك الخمر ابتغاء رضى الله.',
          'أمانة': 'سأبتعد عما يضر جسدي وعقلي.',
          'العائلة': 'سأكون موثوقًا لأحبتي.',
          'المستقبل': 'أريد عقلًا صافيًا وأيامًا صحية.',
        };
      }
      if (isEn) {
        return const {
          'Spiritual': 'I quit alcohol for the sake of Allah.',
          'Trust': 'I will stay away from what harms my body and mind.',
          'Family': 'I will be reliable for my loved ones.',
          'Future': 'I want a clear mind and healthy days.',
        };
      }
      return const {
        'Manevi': 'İçkiyi Allah rızası için bırakıyorum.',
        'Emanet': 'Beden ve aklıma zarar verenden uzak duracağım.',
        'Aile': 'Sevdiklerime güvenilir olacağım.',
        'Gelecek': 'Berrak zihin ve sağlıklı günler istiyorum.',
      };
    case WillpowerTemplates.quitSubstance:
      if (isAr) {
        return const {
          'شفاء': 'في طريق الشفاء أتمسك بالأسباب والدعم.',
          'توبة': 'أختار البقاء نظيفًا والابتعاد عن الضرر.',
          'دعم': 'سأطلب مساعدة مختص عند الحاجة.',
          'صبر': 'كل يوم نظيف هو انتصار.',
        };
      }
      if (isEn) {
        return const {
          'Healing': 'On the path to healing, I hold onto support.',
          'Repentance': 'I choose to stay clean and turn away from harm.',
          'Support': 'I will seek professional help when needed.',
          'Patience': 'Every clean day is a victory.',
        };
      }
      return const {
        'Şifa': 'Şifa yolunda sebeplere ve desteğe sarılıyorum.',
        'Tövbe': 'Zarardan yüz çevirip temiz kalmayı seçiyorum.',
        'Destek': 'Gerekirse uzman yardımı alacağım.',
        'Sabır': 'Her temiz gün bir zaferdir.',
      };
    case WillpowerTemplates.quitZina:
      if (isAr) {
        return const {
          'عفة': 'نويت حفظ بصري وقلبي.',
          'حدود': 'ملتزم بحدود العفة والشرع.',
          'توبة': 'إن ضعفت أعود بالتوبة من جديد.',
          'رضا': 'سأزكي نفسي ابتغاء رضى الله.',
        };
      }
      if (isEn) {
        return const {
          'Chastity': 'I intend to guard my eyes and heart.',
          'Boundaries': 'I commit to healthy and halal boundaries.',
          'Repentance': 'If I stumble, I return with repentance.',
          'Purpose': 'I will discipline my nafs for Allah’s pleasure.',
        };
      }
      return const {
        'İffet': 'Gözümü ve kalbimi korumaya niyet ettim.',
        'Sınır': 'Mahremiyetime ve helal çerçeveye bağlıyım.',
        'Tövbe': 'Kırıldığımda tövbe edip yeniden başlarım.',
        'Rızık': 'Allah’ın rızası için nefsimi terbiye edeceğim.',
      };
    default:
      if (isAr) {
        return const {
          'نية': 'أنا عازم على ترك هذه العادة.',
          'صبر': 'سأستمر بالصبر والدعاء.',
        };
      }
      if (isEn) {
        return const {
          'Intention': 'I am determined to quit this habit.',
          'Patience': 'I will continue with patience and prayer.',
        };
      }
      return const {
        'Niyet': 'Kötü alışkanlığı bırakmaya kararlıyım.',
        'Sabır': 'Sabırla ve dua ile devam edeceğim.',
      };
  }
}

/// İbadet (günlük namaz) mührü öncesi örnek cümleler.
Map<String, String> namazIbadetCommitmentChipsFor({
  String localeCode = 'tr',
}) {
  final isAr = localeCode.toLowerCase().startsWith('ar');
  final isEn = localeCode.toLowerCase().startsWith('en');
  if (isAr) {
    return const {
      'خشوع': 'سأجتهد أن أصلي بخشوع.',
      'استقامة': 'سأعود بالتوبة عند فوات الصلاة.',
      'إخلاص': 'سأضع العلامات ابتغاء مرضاة الله فقط.',
      'رحمة': 'سأتعامل برحمة مع التقصير وبالشكر مع التمام.',
    };
  }
  if (isEn) {
    return const {
      'Khushu': 'I will strive to pray with khushu.',
      'Steadfastness': 'I will return with repentance when I miss a prayer.',
      'Sincerity': 'I will mark ticks only for Allah’s sake.',
      'Mercy': 'I will show mercy in shortcomings and gratitude in completion.',
    };
  }
  return const {
    'Huşû': 'Huşû ile kılmaya gayret edeceğim.',
    'İstikamet': 'Kaçırdığım vakitlere tövbe edip döneceğim.',
    'Samimiyet': 'Tikleri yalnızca Allah rızası için işaretleyeceğim.',
    'Merhamet': 'Eksiklikte merhamet, tamda şükür edeceğim.',
  };
}
