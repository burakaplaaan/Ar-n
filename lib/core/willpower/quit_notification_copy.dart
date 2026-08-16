import '../constants/willpower_templates.dart';
import '../localization/locale_text.dart';
import 'quit_milestones.dart';
import 'quit_notification_plan.dart';

class QuitNotificationCopy {
  const QuitNotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

class QuitNotificationWisdomSnippet {
  const QuitNotificationWisdomSnippet({
    required this.kind,
    required this.body,
    required this.source,
  });

  final String kind;
  final String body;
  final String source;
}

class QuitNotificationTipSnippet {
  const QuitNotificationTipSnippet({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

QuitNotificationCopy resolveQuitNotificationCopy({
  required QuitPlannedNotification event,
  required String localeCode,
  List<QuitNotificationWisdomSnippet> wisdom = const [],
  List<QuitNotificationTipSnippet> tips = const [],
}) {
  switch (event.kind) {
    case QuitNotificationKind.achievement:
      return _achievement(event, localeCode);
    case QuitNotificationKind.duration:
      return _duration(event, localeCode);
    case QuitNotificationKind.recovery:
      return _recovery(event, localeCode);
    case QuitNotificationKind.inspiration:
      return _inspiration(event, localeCode, wisdom);
    case QuitNotificationKind.tips:
      return _tips(event, localeCode, tips);
  }
}

String quitProgramShortTitle(String templateId, String localeCode) {
  return trEnArByCode(
    localeCode,
    tr: switch (templateId) {
      WillpowerTemplates.quitSmoking => 'Sigaradan arınma',
      WillpowerTemplates.quitScreen => 'Ekrandan arınma',
      WillpowerTemplates.quitAlcohol => 'Alkolden arınma',
      WillpowerTemplates.quitSubstance => 'Maddeden arınma',
      WillpowerTemplates.quitZina => 'İffet yolunda arınma',
      _ => 'Arınma',
    },
    en: switch (templateId) {
      WillpowerTemplates.quitSmoking => 'Quitting smoking',
      WillpowerTemplates.quitScreen => 'Screen detox',
      WillpowerTemplates.quitAlcohol => 'Quitting alcohol',
      WillpowerTemplates.quitSubstance => 'Quitting substances',
      WillpowerTemplates.quitZina => 'Chastity path',
      _ => 'Purification',
    },
    ar: switch (templateId) {
      WillpowerTemplates.quitSmoking => 'الإقلاع عن التدخين',
      WillpowerTemplates.quitScreen => 'التطهير من الشاشات',
      WillpowerTemplates.quitAlcohol => 'الإقلاع عن الكحول',
      WillpowerTemplates.quitSubstance => 'الإقلاع عن المواد',
      WillpowerTemplates.quitZina => 'طريق العفة',
      _ => 'التزكية',
    },
  );
}

QuitNotificationCopy _achievement(
  QuitPlannedNotification event,
  String localeCode,
) {
  final day = event.day ?? 0;
  final milestone = _milestoneCopy(day, localeCode);
  final program = quitProgramShortTitle(event.templateId, localeCode);
  return QuitNotificationCopy(
    title: '${milestone.$1} · $program',
    body: trEnArByCode(
      localeCode,
      tr: '${milestone.$2}. Tebrikler — bu eşiği geçtin, böyle devam et.',
      en: '${milestone.$2}. Well done — you crossed this threshold. Keep going.',
      ar: '${milestone.$2}. أحسنت — تجاوزت هذا الحد. واصل.',
    ),
  );
}

QuitNotificationCopy _duration(
  QuitPlannedNotification event,
  String localeCode,
) {
  final day = event.day ?? 0;
  final program = quitProgramShortTitle(event.templateId, localeCode);
  final title = QuitAchievementMilestones.days.contains(day)
      ? '${_milestoneCopy(day, localeCode).$1} · $program'
      : program;
  return QuitNotificationCopy(
    title: title,
    body: _durationBody(day, localeCode),
  );
}

QuitNotificationCopy _recovery(
  QuitPlannedNotification event,
  String localeCode,
) {
  final label = _metricLabel(event.templateId, event.metricId ?? '', localeCode);
  final pct = event.percent ?? 0;
  final program = quitProgramShortTitle(event.templateId, localeCode);
  return QuitNotificationCopy(
    title: '$label · $program',
    body: trEnArByCode(
      localeCode,
      tr: 'Toparlanma göstergesi %$pct’e ulaştı. Her temiz gün birikiyor.',
      en: 'Recovery is now at $pct%. Every clean day is adding up.',
      ar: 'مؤشر التعافي وصل إلى $pct٪. كل يوم نظيف يتراكم.',
    ),
  );
}

QuitNotificationCopy _inspiration(
  QuitPlannedNotification event,
  String localeCode,
  List<QuitNotificationWisdomSnippet> items,
) {
  final wanted = (event.wisdomKind ?? 'not').toLowerCase();
  QuitNotificationWisdomSnippet? match;
  for (final item in items) {
    if (item.kind.toLowerCase() == wanted && item.body.trim().isNotEmpty) {
      match = item;
      break;
    }
  }
  match ??= items.cast<QuitNotificationWisdomSnippet?>().firstWhere(
    (e) => (e?.body.trim().isNotEmpty ?? false),
    orElse: () => null,
  );
  final kindLabel = _wisdomKindLabel(wanted, localeCode);
  if (match != null) {
    final source = match.source.trim();
    final body = source.isEmpty ? match.body.trim() : '${match.body.trim()}\n$source';
    return QuitNotificationCopy(title: kindLabel, body: body);
  }
  return QuitNotificationCopy(
    title: kindLabel,
    body: _fallbackWisdom(event.templateId, wanted, localeCode),
  );
}

QuitNotificationCopy _tips(
  QuitPlannedNotification event,
  String localeCode,
  List<QuitNotificationTipSnippet> tips,
) {
  final program = quitProgramShortTitle(event.templateId, localeCode);
  if (tips.isNotEmpty) {
    final tip = tips[(event.tipIndex ?? 0).abs() % tips.length];
    final title = tip.title.trim().isEmpty
        ? trEnArByCode(
            localeCode,
            tr: 'İpuçlarına göz at',
            en: 'Take a look at the tips',
            ar: 'ألقِ نظرة على النصائح',
          )
        : tip.title.trim();
    final body = tip.body.trim().isEmpty
        ? trEnArByCode(
            localeCode,
            tr: '$program ipuçlarında bugün için bir hatırlatma var.',
            en: 'There is a reminder for you in the $program tips.',
            ar: 'هناك تذكير لك في نصائح $program.',
          )
        : tip.body.trim();
    return QuitNotificationCopy(title: title, body: body);
  }
  return QuitNotificationCopy(
    title: trEnArByCode(
      localeCode,
      tr: 'İpuçlarına göz at',
      en: 'Take a look at the tips',
      ar: 'ألقِ نظرة على النصائح',
    ),
    body: trEnArByCode(
      localeCode,
      tr: '$program açık. İpuçları sekmesinde bugün işine yarayacak bir yol var.',
      en: '$program is active. The Tips tab has something that can help today.',
      ar: '$program نشط. تبويب النصائح فيه ما يعينك اليوم.',
    ),
  );
}

String _durationBody(int day, String localeCode) {
  if (day >= 60 && day % 30 == 0) {
    final months = day ~/ 30;
    return trEnArByCode(
      localeCode,
      tr: '1 ay daha tamamladın. $months aydır arınman açık — sözün duruyor.',
      en: 'Another month done. Your purification has been on for $months months — your word stands.',
      ar: 'أكملّت شهرًا آخر. تزكيتك مستمرة منذ $months شهرًا — عهدك قائم.',
    );
  }
  return switch (day) {
    1 => trEnArByCode(
      localeCode,
      tr: '1. günü tamamladın. Böyle devam et — her temiz saat birikimdir.',
      en: 'You completed day 1. Keep going — every clean hour counts.',
      ar: 'أتممت اليوم الأول. واصل — كل ساعة نظيفة رصيد.',
    ),
    2 => trEnArByCode(
      localeCode,
      tr: '2. gün bitti. İstek gelebilir; sen sözünde duruyorsun.',
      en: 'Day 2 is done. Cravings may come; you are keeping your word.',
      ar: 'انتهى اليوم الثاني. قد يأتي الاشتياق؛ وأنت على عهدك.',
    ),
    3 => trEnArByCode(
      localeCode,
      tr: '3. gün tamam. Zirve geçiyor; sabrın görünüyor.',
      en: 'Day 3 complete. The peak is passing; your patience is showing.',
      ar: 'اكتمل اليوم الثالث. الذروة تمر؛ وصبرك يظهر.',
    ),
    4 => trEnArByCode(
      localeCode,
      tr: '4. gün geride. Rutin kırılıyor, sen ayaktasın.',
      en: 'Day 4 is behind you. The old routine is breaking; you are standing.',
      ar: 'اليوم الرابع خلفك. الروتين ينكسر وأنت ثابت.',
    ),
    5 => trEnArByCode(
      localeCode,
      tr: '5. günü tamamladın. İlk eşik aşıldı; yol açık.',
      en: 'You completed day 5. The first threshold is behind you; the path is open.',
      ar: 'أتممت اليوم الخامس. عُبر العتبة الأولى؛ والطريق مفتوح.',
    ),
    10 => trEnArByCode(
      localeCode,
      tr: '10. günü tamamladın. İraden güçleniyor — böyle devam et.',
      en: 'You completed day 10. Your will is getting stronger — keep going.',
      ar: 'أتممت اليوم العاشر. إرادتك تقوى — واصل.',
    ),
    20 => trEnArByCode(
      localeCode,
      tr: '20. günü tamamladın. Bakışın netleşiyor; birikimin görünüyor.',
      en: 'You completed day 20. Your outlook is clearer; the accumulation shows.',
      ar: 'أتممت اليوم العشرين. رؤيتك أصفى؛ وتراكمك ظاهر.',
    ),
    30 => trEnArByCode(
      localeCode,
      tr: '1 ayı tamamladın. Büyük bir eşik — sözün tuttu, böyle devam et.',
      en: 'You completed 1 month. A major threshold — you kept your word. Keep going.',
      ar: 'أتممت شهرًا. عتبة كبيرة — وفيّت بعهدك. واصل.',
    ),
    _ => trEnArByCode(
      localeCode,
      tr: '$day. günü tamamladın. Temiz günlerin birikiyor — böyle devam et.',
      en: 'You completed day $day. Your clean days are adding up — keep going.',
      ar: 'أتممت اليوم $day. أيامك النظيفة تتراكم — واصل.',
    ),
  };
}

(String, String) _milestoneCopy(int day, String localeCode) {
  return switch (day) {
    1 => (
      trEnArByCode(localeCode, tr: 'İlk nefes', en: 'First breath', ar: 'أول نفس'),
      trEnArByCode(localeCode, tr: 'Bir gün temiz', en: 'One clean day', ar: 'يوم نظيف واحد'),
    ),
    2 => (
      trEnArByCode(localeCode, tr: 'İlk seri', en: 'First streak', ar: 'أول سلسلة'),
      trEnArByCode(localeCode, tr: '48 saat', en: '48 hours', ar: '48 ساعة'),
    ),
    3 => (
      trEnArByCode(localeCode, tr: 'Üç gün', en: 'Three days', ar: 'ثلاثة أيام'),
      trEnArByCode(
        localeCode,
        tr: 'İstek zirvesi geçiyor',
        en: 'The craving peak is passing',
        ar: 'ذروة الاشتياق تمر',
      ),
    ),
    5 => (
      trEnArByCode(localeCode, tr: 'Beş gün', en: 'Five days', ar: 'خمسة أيام'),
      trEnArByCode(localeCode, tr: 'Rutin kırılıyor', en: 'The routine is breaking', ar: 'الروتين ينكسر'),
    ),
    7 => (
      trEnArByCode(localeCode, tr: 'Bir hafta', en: 'One week', ar: 'أسبوع'),
      trEnArByCode(localeCode, tr: 'İlk hafta tamam', en: 'First week complete', ar: 'اكتملت الأسبوع الأول'),
    ),
    10 => (
      trEnArByCode(localeCode, tr: 'On gün', en: 'Ten days', ar: 'عشرة أيام'),
      trEnArByCode(localeCode, tr: 'İrade güçleniyor', en: 'Willpower is growing', ar: 'الإرادة تقوى'),
    ),
    14 => (
      trEnArByCode(localeCode, tr: 'İki hafta', en: 'Two weeks', ar: 'أسبوعان'),
      trEnArByCode(localeCode, tr: 'Algı toparlanıyor', en: 'Perception is settling', ar: 'الإدراك يستقر'),
    ),
    21 => (
      trEnArByCode(localeCode, tr: 'Üç hafta', en: 'Three weeks', ar: 'ثلاثة أسابيع'),
      trEnArByCode(localeCode, tr: 'Alışkanlık döngüsü', en: 'Habit cycle', ar: 'دورة العادة'),
    ),
    30 => (
      trEnArByCode(localeCode, tr: 'Bir ay', en: 'One month', ar: 'شهر'),
      trEnArByCode(localeCode, tr: 'Önemli eşik', en: 'A major threshold', ar: 'عتبة مهمة'),
    ),
    45 => (
      trEnArByCode(localeCode, tr: 'Kırk beş gün', en: 'Forty-five days', ar: 'خمسة وأربعون يومًا'),
      trEnArByCode(localeCode, tr: 'Düzen oturuyor', en: 'A rhythm is forming', ar: 'ينتظم الإيقاع'),
    ),
    60 => (
      trEnArByCode(localeCode, tr: 'İki ay', en: 'Two months', ar: 'شهرين'),
      trEnArByCode(localeCode, tr: 'Beden adapte', en: 'The body is adapting', ar: 'الجسد يتكيف'),
    ),
    66 => (
      trEnArByCode(localeCode, tr: 'Alışkanlık ustası', en: 'Habit master', ar: 'سيد العادة'),
      trEnArByCode(localeCode, tr: '66 gün çizgisi', en: 'The 66-day line', ar: 'خط 66 يومًا'),
    ),
    90 => (
      trEnArByCode(localeCode, tr: 'Üç ay', en: 'Three months', ar: 'ثلاثة أشهر'),
      trEnArByCode(
        localeCode,
        tr: 'Sağlıkta belirgin dönem',
        en: 'A clearer health chapter',
        ar: 'مرحلة أوضح في العافية',
      ),
    ),
    120 => (
      trEnArByCode(localeCode, tr: 'Dört ay', en: 'Four months', ar: 'أربعة أشهر'),
      trEnArByCode(localeCode, tr: 'Kararlılık nişanı', en: 'A mark of resolve', ar: 'وسام الثبات'),
    ),
    180 => (
      trEnArByCode(localeCode, tr: 'Altı ay', en: 'Six months', ar: 'ستة أشهر'),
      trEnArByCode(localeCode, tr: 'Yarım yıl', en: 'Half a year', ar: 'نصف عام'),
    ),
    270 => (
      trEnArByCode(localeCode, tr: 'Dokuz ay', en: 'Nine months', ar: 'تسعة أشهر'),
      trEnArByCode(localeCode, tr: 'Uzun soluk', en: 'A long breath', ar: 'نفس طويل'),
    ),
    365 => (
      trEnArByCode(localeCode, tr: 'Bir yıl', en: 'One year', ar: 'سنة'),
      trEnArByCode(localeCode, tr: 'Büyük müjde', en: 'A great glad tiding', ar: 'بشرى عظيمة'),
    ),
    500 => (
      trEnArByCode(localeCode, tr: 'Beş yüz gün', en: 'Five hundred days', ar: 'خمسمائة يوم'),
      trEnArByCode(localeCode, tr: 'Azim tacı', en: 'A crown of perseverance', ar: 'تاج العزيمة'),
    ),
    730 => (
      trEnArByCode(localeCode, tr: 'İki yıl', en: 'Two years', ar: 'سنتان'),
      trEnArByCode(localeCode, tr: 'Kökten değişim', en: 'Deep change', ar: 'تغير راسخ'),
    ),
    1000 => (
      trEnArByCode(localeCode, tr: 'Bin gün', en: 'A thousand days', ar: 'ألف يوم'),
      trEnArByCode(localeCode, tr: 'Eşsiz seviye', en: 'A rare station', ar: 'مقام نادر'),
    ),
    _ => (
      trEnArByCode(localeCode, tr: '$day. gün', en: 'Day $day', ar: 'اليوم $day'),
      trEnArByCode(localeCode, tr: 'Yeni eşik', en: 'A new threshold', ar: 'عتبة جديدة'),
    ),
  };
}

String _metricLabel(String templateId, String metricId, String localeCode) {
  final key = '$templateId.$metricId';
  return switch (key) {
    'quit_smoking.lung' => trEnArByCode(
      localeCode,
      tr: 'Ciğer / solunum',
      en: 'Lungs / breathing',
      ar: 'الرئتان / التنفس',
    ),
    'quit_smoking.heart' => trEnArByCode(
      localeCode,
      tr: 'Kalp-damar',
      en: 'Cardiovascular',
      ar: 'القلب والأوعية',
    ),
    'quit_smoking.teeth' => trEnArByCode(
      localeCode,
      tr: 'Diş ve ağız',
      en: 'Teeth and mouth',
      ar: 'الأسنان والفم',
    ),
    'quit_smoking.smell' => trEnArByCode(
      localeCode,
      tr: 'Koku ve tat',
      en: 'Smell and taste',
      ar: 'الشم والتذوق',
    ),
    'quit_screen.focus' => trEnArByCode(
      localeCode,
      tr: 'Odak ve derinlik',
      en: 'Focus and depth',
      ar: 'التركيز والعمق',
    ),
    'quit_screen.sleep' => trEnArByCode(
      localeCode,
      tr: 'Uyku düzeni',
      en: 'Sleep rhythm',
      ar: 'إيقاع النوم',
    ),
    'quit_screen.awareness' => trEnArByCode(
      localeCode,
      tr: 'Ekran farkındalığı',
      en: 'Screen awareness',
      ar: 'وعي الشاشة',
    ),
    'quit_screen.calm' => trEnArByCode(
      localeCode,
      tr: 'İç huzur',
      en: 'Inner calm',
      ar: 'طمأنينة الداخل',
    ),
    'quit_alcohol.liver' => trEnArByCode(
      localeCode,
      tr: 'Karaciğer toparlanması',
      en: 'Liver recovery',
      ar: 'تعافي الكبد',
    ),
    'quit_alcohol.sleep' => trEnArByCode(
      localeCode,
      tr: 'Uyku istikrarı',
      en: 'Sleep stability',
      ar: 'استقرار النوم',
    ),
    'quit_alcohol.mood' => trEnArByCode(
      localeCode,
      tr: 'Ruh hali dengesi',
      en: 'Mood balance',
      ar: 'توازن المزاج',
    ),
    'quit_alcohol.clarity' => trEnArByCode(
      localeCode,
      tr: 'Zihin berraklığı',
      en: 'Mental clarity',
      ar: 'صفاء الذهن',
    ),
    'quit_substance.body' => trEnArByCode(
      localeCode,
      tr: 'Beden dengesi',
      en: 'Body balance',
      ar: 'توازن الجسد',
    ),
    'quit_substance.sleep' => trEnArByCode(
      localeCode,
      tr: 'Uyku ritmi',
      en: 'Sleep rhythm',
      ar: 'إيقاع النوم',
    ),
    'quit_substance.urge' => trEnArByCode(
      localeCode,
      tr: 'İstek yönetimi',
      en: 'Urge control',
      ar: 'ضبط الرغبة',
    ),
    'quit_substance.support' => trEnArByCode(
      localeCode,
      tr: 'Destek ve takip',
      en: 'Support and follow-up',
      ar: 'الدعم والمتابعة',
    ),
    'quit_zina.discipline' => trEnArByCode(
      localeCode,
      tr: 'Nefis disiplini',
      en: 'Self-discipline',
      ar: 'ضبط النفس',
    ),
    'quit_zina.boundary' => trEnArByCode(
      localeCode,
      tr: 'Sınır gücü',
      en: 'Boundary strength',
      ar: 'قوة الحدود',
    ),
    'quit_zina.heart' => trEnArByCode(
      localeCode,
      tr: 'Kalp sükûnu',
      en: 'Heart calm',
      ar: 'سكون القلب',
    ),
    'quit_zina.tawba' => trEnArByCode(
      localeCode,
      tr: 'Tövbe istikameti',
      en: 'Steadfast repentance',
      ar: 'استقامة التوبة',
    ),
    _ => trEnArByCode(
      localeCode,
      tr: 'Toparlanma',
      en: 'Recovery',
      ar: 'التعافي',
    ),
  };
}

String _wisdomKindLabel(String kind, String localeCode) {
  return switch (kind) {
    'ayet' => trEnArByCode(localeCode, tr: 'Ayet', en: 'Verse', ar: 'آية'),
    'sünnet' => trEnArByCode(localeCode, tr: 'Sünnet', en: 'Sunnah', ar: 'سنة'),
    'tıp' => trEnArByCode(localeCode, tr: 'Tıp', en: 'Health note', ar: 'طب'),
    _ => trEnArByCode(localeCode, tr: 'Not', en: 'Note', ar: 'ملاحظة'),
  };
}

String _fallbackWisdom(String _, String kind, String localeCode) {
  return trEnArByCode(
    localeCode,
    tr: switch (kind) {
      'ayet' => 'Her temiz gün, emanete ve söze bağlılıktır.',
      'sünnet' => 'Nefsi korumak, kalbi korumaktır. Bugün bir adım yeter.',
      'tıp' => 'Beden toparlanırken sabır ve düzen en yakın destektir.',
      _ => 'Arınman açık. Kısa bir mola: niyetini tazele, yola devam et.',
    },
    en: switch (kind) {
      'ayet' => 'Every clean day is loyalty to the trust and to your word.',
      'sünnet' => 'Guarding the self is guarding the heart. One step today is enough.',
      'tıp' => 'As the body recovers, patience and routine are your closest support.',
      _ => 'Your purification is on. Pause briefly, renew your intention, continue.',
    },
    ar: switch (kind) {
      'ayet' => 'كل يوم نظيف وفاء للأمانة وللعهد.',
      'sünnet' => 'حفظ النفس حفظ للقلب. خطوة واحدة اليوم تكفي.',
      'tıp' => 'بينما يتعافى الجسد، الصبر والنظام أقرب عون.',
      _ => 'تزكيتك قائمة. توقف لحظة، جدّد نيتك، وامض.',
    },
  );
}
