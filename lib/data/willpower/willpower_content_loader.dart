import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/willpower_templates.dart';

class QuranDailyContent {
  QuranDailyContent({
    required this.title,
    required this.subtitle,
    required this.tips,
    required this.milestones,
  });

  final String title;
  final String subtitle;
  final List<WillTipCard> tips;
  final List<WillMilestone> milestones;

  static Future<QuranDailyContent> load() async {
    final raw = await rootBundle
        .loadString('assets/data/willpower/build_quran_daily.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    return QuranDailyContent(
      title: j['title'] as String? ?? 'Kur\'an',
      subtitle: j['subtitle'] as String? ?? '',
      tips: (j['tips'] as List<dynamic>? ?? [])
          .map((e) => WillTipCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: (j['milestones'] as List<dynamic>? ?? [])
          .map((e) => WillMilestone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WillTipCard {
  WillTipCard({
    required this.title,
    required this.quote,
    required this.body,
  });

  final String title;
  final String quote;
  final String body;

  factory WillTipCard.fromJson(Map<String, dynamic> j) => WillTipCard(
        title: j['title'] as String? ?? '',
        quote: j['quote'] as String? ?? '',
        body: j['body'] as String? ?? '',
      );
}

class WillMilestone {
  WillMilestone({
    required this.day,
    required this.percent,
    required this.message,
  });

  final int day;
  final double percent;
  final String message;

  factory WillMilestone.fromJson(Map<String, dynamic> j) => WillMilestone(
        day: (j['day'] as num?)?.toInt() ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
        message: j['message'] as String? ?? '',
      );
}

/// Tüm tam Arınma şablonları için onboarding metinleri.
class QuitProgramOnboardingContent {
  QuitProgramOnboardingContent({
    required this.warningTitle,
    required this.warningSubtitle,
    required this.warningBody,
    required this.physicalTitle,
    required this.physicalItems,
    required this.spiritualTitle,
    required this.spiritualItems,
    required this.verseText,
    required this.verseRef,
  });

  final String warningTitle;
  final String warningSubtitle;
  final List<String> warningBody;
  final String physicalTitle;
  final List<QuitItem> physicalItems;
  final String spiritualTitle;
  final List<QuitItem> spiritualItems;
  final String verseText;
  final String verseRef;

  static Future<QuitProgramOnboardingContent> loadForTemplate(
    String templateId, {
    String localeCode = 'tr',
  }) async {
    if (!WillpowerTemplates.isFullQuitProgram(templateId)) {
      throw ArgumentError.value(templateId, 'templateId');
    }
    final raw = await rootBundle.loadString(
        'assets/data/willpower/${templateId}_onboarding.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    final w = j['warningBody'] as List<dynamic>? ?? [];
    final v = j['verse'] as Map<String, dynamic>? ?? {};
    final parsed = QuitProgramOnboardingContent(
      warningTitle: j['warningTitle'] as String? ?? 'Dikkat',
      warningSubtitle: j['warningSubtitle'] as String? ?? '',
      warningBody: w.map((e) => '$e').toList(),
      physicalTitle: j['physicalTitle'] as String? ?? '',
      physicalItems: (j['physicalItems'] as List<dynamic>? ?? [])
          .map((e) => QuitItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      spiritualTitle: j['spiritualTitle'] as String? ?? '',
      spiritualItems: (j['spiritualItems'] as List<dynamic>? ?? [])
          .map((e) => QuitItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      verseText: v['text'] as String? ?? '',
      verseRef: v['ref'] as String? ?? '',
    );
    return _localizedQuitOnboarding(parsed, templateId, localeCode);
  }
}

QuitProgramOnboardingContent _localizedQuitOnboarding(
  QuitProgramOnboardingContent source,
  String templateId,
  String localeCode,
) {
  final code = localeCode.toLowerCase();
  if (!code.startsWith('en') && !code.startsWith('ar')) return source;

  if (code.startsWith('ar')) {
    return switch (templateId) {
      WillpowerTemplates.quitScreen => QuitProgramOnboardingContent(
          warningTitle: 'تنبيه',
          warningSubtitle: 'الإفراط الرقمي يبطئ قلبك ويشتت تركيزك.',
          warningBody: const [
            'الوقت المفرط أمام الشاشة يشتت الانتباه ويؤثر في النوم.',
            'التمرير بلا وعي يرهق عقلك تدريجيًا.',
          ],
          physicalTitle: 'الجسد والعقل',
          physicalItems: const [
            QuitItem(iconKey: 'psychology', title: 'تشتت التركيز', subtitle: 'التنبيهات المستمرة تُرهق الدماغ'),
            QuitItem(iconKey: 'favorite', title: 'جودة النوم', subtitle: 'ضوء الليل قد يؤثر في الميلاتونين'),
            QuitItem(iconKey: 'bolt', title: 'إجهاد العين', subtitle: 'إطالة النظر قد تزيد التوتر والصداع'),
          ],
          spiritualTitle: 'القلب والنية',
          spiritualItems: const [
            QuitItem(iconKey: 'self_improvement', title: 'حضور القلب', subtitle: 'قلل الضجيج لتزيد الصفاء'),
            QuitItem(iconKey: 'mosque', title: 'حفظ الوقت', subtitle: 'اجعل لله نصيبًا أوضح من يومك'),
          ],
          verseText: 'وَالْعَصْرِ • إِنَّ الْإِنسَانَ لَفِي خُسْرٍ',
          verseRef: 'سورة العصر',
        ),
      _ => QuitProgramOnboardingContent(
          warningTitle: 'تنبيه',
          warningSubtitle: 'كل خطوة ترك هي خطوة نجاة ونقاء.',
          warningBody: const [
            'الانتكاسات واردة؛ المهم أن تعود فورًا.',
            'الاستمرار الهادئ أفضل من الاندفاع القصير.',
          ],
          physicalTitle: 'الجسد',
          physicalItems: const [
            QuitItem(iconKey: 'favorite', title: 'تعافٍ تدريجي', subtitle: 'جسدك يتجه للتعافي مع الاستمرار'),
            QuitItem(iconKey: 'bolt', title: 'طاقة أوضح', subtitle: 'الانضباط اليومي يرفع طاقتك'),
          ],
          spiritualTitle: 'الروح',
          spiritualItems: const [
            QuitItem(iconKey: 'mosque', title: 'توبة وتجدد', subtitle: 'العودة إلى الله بداية القوة'),
            QuitItem(iconKey: 'self_improvement', title: 'ثبات النية', subtitle: 'جدّد قصدك كل يوم'),
          ],
          verseText: 'كل يوم نظيف هو انتصار حقيقي.',
          verseRef: 'رسالة دعم يومية',
        ),
    };
  }

  return switch (templateId) {
    WillpowerTemplates.quitScreen => QuitProgramOnboardingContent(
        warningTitle: 'Warning',
        warningSubtitle: 'Excessive screen use slows your heart and blurs focus.',
        warningBody: const [
          'Excessive screen time distracts attention and harms sleep rhythm.',
          'Mindless scrolling gradually causes mental fatigue.',
        ],
        physicalTitle: 'Body and mind',
        physicalItems: const [
          QuitItem(iconKey: 'psychology', title: 'Attention fragmentation', subtitle: 'Constant notifications tire the brain'),
          QuitItem(iconKey: 'favorite', title: 'Sleep quality', subtitle: 'Night screen light may affect melatonin'),
          QuitItem(iconKey: 'bolt', title: 'Eye strain', subtitle: 'Long gaze can increase tension and headaches'),
        ],
        spiritualTitle: 'Heart and intention',
        spiritualItems: const [
          QuitItem(iconKey: 'self_improvement', title: 'Inner calm', subtitle: 'Less noise helps deeper reflection'),
          QuitItem(iconKey: 'mosque', title: 'Guarding time', subtitle: 'Reserve clearer time for what truly matters'),
        ],
        verseText: 'By Time. Surely humanity is in loss.',
        verseRef: 'Surah Al-Asr',
      ),
    _ => QuitProgramOnboardingContent(
        warningTitle: 'Warning',
        warningSubtitle: 'Each clean day is a real step toward freedom.',
        warningBody: const [
          'Relapses can happen; returning immediately is what matters.',
          'Calm consistency beats short bursts of motivation.',
        ],
        physicalTitle: 'Body',
        physicalItems: const [
          QuitItem(iconKey: 'favorite', title: 'Gradual recovery', subtitle: 'Your body trends toward healing with consistency'),
          QuitItem(iconKey: 'bolt', title: 'Clearer energy', subtitle: 'Daily discipline improves your energy rhythm'),
        ],
        spiritualTitle: 'Soul',
        spiritualItems: const [
          QuitItem(iconKey: 'mosque', title: 'Repentance and renewal', subtitle: 'Returning to Allah restores strength'),
          QuitItem(iconKey: 'self_improvement', title: 'Steady intention', subtitle: 'Renew your intention each day'),
        ],
        verseText: 'Every clean day is a real victory.',
        verseRef: 'Daily encouragement',
      ),
  };
}

class QuitItem {
  const QuitItem({
    required this.iconKey,
    required this.title,
    required this.subtitle,
  });

  final String iconKey;
  final String title;
  final String subtitle;

  factory QuitItem.fromJson(Map<String, dynamic> j) => QuitItem(
        iconKey: j['icon'] as String? ?? 'circle',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
      );
}

class QuitHomeTip {
  QuitHomeTip({required this.title, required this.body});

  final String title;
  final String body;

  factory QuitHomeTip.fromJson(Map<String, dynamic> j) => QuitHomeTip(
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
      );
}

class QuitWisdomItem {
  QuitWisdomItem({
    required this.kind,
    required this.body,
    required this.source,
  });

  final String kind;
  final String body;
  final String source;

  factory QuitWisdomItem.fromJson(Map<String, dynamic> j) => QuitWisdomItem(
        kind: j['kind'] as String? ?? 'not',
        body: j['body'] as String? ?? '',
        source: j['source'] as String? ?? '',
      );
}

class QuitProgramUiCopy {
  const QuitProgramUiCopy({
    required this.counterSubtitle,
    required this.metricsSectionTitle,
    required this.disclaimer,
    required this.encouragementBox,
    required this.clockHint,
  });

  final String counterSubtitle;
  final String metricsSectionTitle;
  final String disclaimer;
  final String encouragementBox;
  final String clockHint;

  static QuitProgramUiCopy merge(
    String templateId,
    Map<String, dynamic>? uiJson, {
    String localeCode = 'tr',
  }) {
    final m = uiJson ?? {};
    final d = _defaults(templateId, localeCode: localeCode);
    return QuitProgramUiCopy(
      counterSubtitle:
          m['counterSubtitle'] as String? ?? d.counterSubtitle,
      metricsSectionTitle:
          m['metricsSectionTitle'] as String? ?? d.metricsSectionTitle,
      disclaimer: m['disclaimer'] as String? ?? d.disclaimer,
      encouragementBox:
          m['encouragementBox'] as String? ?? d.encouragementBox,
      clockHint: m['clockHint'] as String? ?? d.clockHint,
    );
  }

  static QuitProgramUiCopy _defaults(
    String templateId, {
    String localeCode = 'tr',
  }) {
    final code = localeCode.toLowerCase();
    if (code.startsWith('en')) {
      return const QuitProgramUiCopy(
        counterSubtitle: 'clean streak',
        metricsSectionTitle: 'Recovery indicators',
        disclaimer:
            'These are motivational estimates, not medical diagnosis or treatment advice.',
        encouragementBox:
            'Every clean day strengthens your discipline and clarity. Keep your promise step by step.',
        clockHint: 'Tap to start/update the timer from this moment.',
      );
    }
    if (code.startsWith('ar')) {
      return const QuitProgramUiCopy(
        counterSubtitle: 'سلسلة نظيفة',
        metricsSectionTitle: 'مؤشرات التعافي',
        disclaimer:
            'هذه تقديرات تحفيزية وليست تشخيصًا طبيًا أو بديلاً عن العلاج.',
        encouragementBox:
            'كل يوم نظيف يقوي انضباطك وصفاءك. استمر خطوة بخطوة.',
        clockHint: 'اضغط لبدء/تحديث العداد من هذه اللحظة.',
      );
    }
    switch (templateId) {
      case WillpowerTemplates.quitSmoking:
        return const QuitProgramUiCopy(
          counterSubtitle: 'sigarasız',
          metricsSectionTitle: 'Şifa göstergeleri',
          disclaimer:
              'Tahmini iyileşme göstergesidir; tıbbi teşhis veya tedavi yerine geçmez.',
          encouragementBox:
              'Çevrendeki insanlarla geçirdiğin her an daha berrak bir nefes ve daha güvenilir bir söz demektir. İyi örnek olmak, kalplere dokunmaktır.',
          clockHint:
              'Tıkladığında süre ve sağlık çubukları bu ana göre ilerler.',
        );
      case WillpowerTemplates.quitScreen:
        return const QuitProgramUiCopy(
          counterSubtitle: 'dijital sınır',
          metricsSectionTitle: 'Dinginlik göstergeleri',
          disclaimer:
              'Motivasyon amaçlı tahmini çizgelerdir; tıbbi veya profesyonel tanı yerine geçmez.',
          encouragementBox:
              'Ekrandan kazandığın her dakika, tefekkür ve hayırlı iş için bir fırsattır. Vaktini koruyan, ruhunu zenginleştirir.',
          clockHint:
              'Tıkladığında süre ve göstergeler bu ana göre ilerler.',
        );
      case WillpowerTemplates.quitAlcohol:
        return const QuitProgramUiCopy(
          counterSubtitle: 'alkolsüz',
          metricsSectionTitle: 'Toparlanma göstergeleri',
          disclaimer:
              'Motivasyon amaçlı tahminidir; tıbbi teşhis veya tedavi yerine geçmez. Gerekirse uzmana danış.',
          encouragementBox:
              'Her temiz gün, beden emaneti ve aklın berraklığı için bir adımdır. Kendine ve sevdiklerine verdiğin söz değerlidir.',
          clockHint:
              'Tıkladığında süre ve göstergeler bu ana göre ilerler.',
        );
      case WillpowerTemplates.quitSubstance:
        return const QuitProgramUiCopy(
          counterSubtitle: 'temiz kalış',
          metricsSectionTitle: 'Yol göstergeleri',
          disclaimer:
              'Uygulama içi çizgeler yalnızca motivasyon içindir. Madde bağımlılığında mutlaka sağlık uzmanından destek alın.',
          encouragementBox:
              'Arınma yalnız değildir: dua, sabır ve güvenilir destek hatları seninle. Küçük adımlar büyük kurtuluşların başlangıcıdır.',
          clockHint:
              'Tıkladığında süre ve göstergeler bu ana göre ilerler.',
        );
      case WillpowerTemplates.quitZina:
        return const QuitProgramUiCopy(
          counterSubtitle: 'iffet yolunda',
          metricsSectionTitle: 'İstikamet göstergeleri',
          disclaimer:
              'Manevi disiplin ve motivasyon için yumuşak çizgelerdir; kişisel durumunda bir âlim veya danışmandan istişare edebilirsin.',
          encouragementBox:
              'Mahremiyetine ve sınırlarına saygı, kalbin sükûnuna ve iffetine yatırımdır. Her korunan an, Rabbine yakınlıktır.',
          clockHint:
              'Tıkladığında süre ve göstergeler bu ana göre ilerler.',
        );
      default:
        return const QuitProgramUiCopy(
          counterSubtitle: 'temiz',
          metricsSectionTitle: 'İlerleme göstergeleri',
          disclaimer: 'Motivasyon amaçlı göstergelerdir.',
          encouragementBox: 'Her temiz gün değerlidir.',
          clockHint: 'Tıkladığında süre bu ana göre ilerler.',
        );
    }
  }
}

/// Ana program — ipuçları, isteğe bağlı ilham kartları ve arayüz metinleri.
class QuitProgramHomeContent {
  QuitProgramHomeContent({
    required this.tips,
    required this.wisdom,
    required this.ui,
  });

  final List<QuitHomeTip> tips;
  final List<QuitWisdomItem> wisdom;
  final QuitProgramUiCopy ui;

  static Future<QuitProgramHomeContent> loadForTemplate(
    String templateId, {
    String localeCode = 'tr',
  }) async {
    if (!WillpowerTemplates.isFullQuitProgram(templateId)) {
      throw ArgumentError.value(templateId, 'templateId');
    }
    final code = localeCode.toLowerCase();
    if (!code.startsWith('tr')) {
      return QuitProgramHomeContent(
        tips: const [],
        wisdom: const [],
        ui: QuitProgramUiCopy.merge(templateId, null, localeCode: localeCode),
      );
    }
    final raw = await rootBundle
        .loadString('assets/data/willpower/${templateId}_home.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    final uiMap = j['ui'] as Map<String, dynamic>?;
    final wisdomList = j['wisdom'] as List<dynamic>? ?? [];
    return QuitProgramHomeContent(
      tips: (j['tips'] as List<dynamic>? ?? [])
          .map((e) => QuitHomeTip.fromJson(e as Map<String, dynamic>))
          .toList(),
      wisdom: wisdomList
          .map((e) => QuitWisdomItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ui: QuitProgramUiCopy.merge(templateId, uiMap, localeCode: localeCode),
    );
  }
}
