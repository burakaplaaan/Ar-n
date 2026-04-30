// lib/data/models/habit_model.dart
// İyi / kötü alışkanlık programları; İrade şablonları için genişletilmiş alanlar.

import 'package:hive/hive.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/utils/hive_boxes.dart';

/// Alışkanlık türü: iyi edinmek (good) veya kötü bırakmak (bad)
@HiveType(typeId: HiveTypeIds.habitType)
enum HabitType {
  @HiveField(0)
  good,
  @HiveField(1)
  bad,
}

@HiveType(typeId: HiveTypeIds.habit)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  HabitType type;

  @HiveField(3)
  String emoji;

  @HiveField(4)
  String createdAt; // ISO 8601

  @HiveField(5)
  bool isArchived;

  /// Örn. quran_daily, quit_smoking, custom
  @HiveField(6)
  String templateId;

  /// Program başlangıcı (streak / gün sayacı)
  @HiveField(7)
  String startedAtIso;

  @HiveField(8)
  String commitmentText;

  @HiveField(9)
  String? quitSubtype;

  @HiveField(10)
  String? quitMethod;

  /// Bırakma onboarding + söz akışı tamamlandı mı
  @HiveField(11)
  bool onboardingCompleted;

  /// Sigara vb. için "bıraktım" anı — takvim günü ve sağlık çubukları bu tarihe göre
  @HiveField(12)
  String? quitClockStartedAtIso;

  /// Özel alışkanlık notu (boş olabilir)
  @HiveField(13)
  String note;

  /// Günlük hedef (sayı, dakika veya yüzde üst sınırı)
  @HiveField(14)
  int customTarget;

  /// Birim etiketi: kez, dakika, saat, % …
  @HiveField(15)
  String customUnit;

  /// 0: sayı, 1: süre, 2: yüzde
  @HiveField(16)
  int customTrackingKind;

  /// Esnek hedef: [customMinTarget, customTarget] aralığı (tamamlama customTarget’ta)
  @HiveField(17)
  bool customFlexible;

  /// Esnek modda alt sınır (bilgi / halka için)
  @HiveField(18)
  int customMinTarget;

  /// Özel takip: 0 günlük, 1 haftalık (haftanın başı Pazartesi), 2 aylık
  @HiveField(19)
  int customRepeatCycle;

  HabitModel({
    required this.id,
    required this.title,
    required this.type,
    required this.emoji,
    required this.createdAt,
    this.isArchived = false,
    this.templateId = '',
    String? startedAtIso,
    this.commitmentText = '',
    this.quitSubtype,
    this.quitMethod,
    this.onboardingCompleted = true,
    this.quitClockStartedAtIso,
    this.note = '',
    this.customTarget = 1,
    this.customUnit = 'kez',
    this.customTrackingKind = 0,
    this.customFlexible = false,
    this.customMinTarget = 0,
    this.customRepeatCycle = 0,
  }) : startedAtIso = startedAtIso ?? createdAt;

  bool get isBuildProgram => type == HabitType.good;
  bool get isQuitProgram => type == HabitType.bad;

  /// Özel takip formu + detay sayacı
  bool get isCustomTracked => templateId == WillpowerTemplates.customTracked;

  int get effectiveDailyTarget =>
      customTarget < 1 ? 1 : customTarget.clamp(1, 999999);
}
