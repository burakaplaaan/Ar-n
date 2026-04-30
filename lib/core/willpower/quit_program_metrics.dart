import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/willpower_templates.dart';
import 'recovery_progress.dart';

/// Ana program “İlerleme” sekmesindeki dört çubuk (şablona göre).
class QuitMetricRowUi {
  const QuitMetricRowUi({
    required this.icon,
    required this.label,
    required this.percent,
    required this.barColor,
  });

  final IconData icon;
  final String label;
  final double percent;
  final Color barColor;
}

List<QuitMetricRowUi> quitMetricRowsFor({
  required String templateId,
  required int elapsedDays,
  required Color tabAccent,
}) {
  final d = elapsedDays;
  switch (templateId) {
    case WillpowerTemplates.quitSmoking:
      return [
        QuitMetricRowUi(
          icon: Icons.air_rounded,
          label: 'Ciğer / solunum',
          percent: RecoveryProgress.smokingLungPercent(d),
          barColor: AppColors.emeraldMid.withValues(alpha: 0.9),
        ),
        QuitMetricRowUi(
          icon: Icons.monitor_heart_outlined,
          label: 'Kalp-damar',
          percent: RecoveryProgress.smokingHeartPercent(d),
          barColor: tabAccent.withValues(alpha: 0.75),
        ),
        QuitMetricRowUi(
          icon: Icons.health_and_safety_outlined,
          label: 'Diş ve ağız',
          percent: RecoveryProgress.smokingTeethPercent(d),
          barColor: AppColors.creamBase.withValues(alpha: 0.4),
        ),
        QuitMetricRowUi(
          icon: Icons.spa_outlined,
          label: 'Koku ve tat',
          percent: RecoveryProgress.smokingSmellTastePercent(d),
          barColor: AppColors.emeraldLight.withValues(alpha: 0.75),
        ),
      ];
    case WillpowerTemplates.quitScreen:
      return [
        QuitMetricRowUi(
          icon: Icons.center_focus_strong_outlined,
          label: 'Odak ve derinlik',
          percent: RecoveryProgress.screenFocusPercent(d),
          barColor: AppColors.emeraldMid.withValues(alpha: 0.9),
        ),
        QuitMetricRowUi(
          icon: Icons.bedtime_outlined,
          label: 'Uyku düzeni',
          percent: RecoveryProgress.screenSleepRhythmPercent(d),
          barColor: tabAccent.withValues(alpha: 0.75),
        ),
        QuitMetricRowUi(
          icon: Icons.visibility_outlined,
          label: 'Ekran farkındalığı',
          percent: RecoveryProgress.screenAwarenessPercent(d),
          barColor: AppColors.creamBase.withValues(alpha: 0.4),
        ),
        QuitMetricRowUi(
          icon: Icons.self_improvement_rounded,
          label: 'İç huzur',
          percent: RecoveryProgress.screenInnerCalmPercent(d),
          barColor: AppColors.emeraldLight.withValues(alpha: 0.75),
        ),
      ];
    case WillpowerTemplates.quitAlcohol:
      return [
        QuitMetricRowUi(
          icon: Icons.water_drop_outlined,
          label: 'Karaciğer toparlanması',
          percent: RecoveryProgress.alcoholLiverRecoveryPercent(d),
          barColor: AppColors.emeraldMid.withValues(alpha: 0.9),
        ),
        QuitMetricRowUi(
          icon: Icons.nights_stay_outlined,
          label: 'Uyku istikrarı',
          percent: RecoveryProgress.alcoholSleepStabilityPercent(d),
          barColor: tabAccent.withValues(alpha: 0.75),
        ),
        QuitMetricRowUi(
          icon: Icons.psychology_alt_outlined,
          label: 'Ruh hali dengesi',
          percent: RecoveryProgress.alcoholMoodBalancePercent(d),
          barColor: AppColors.creamBase.withValues(alpha: 0.4),
        ),
        QuitMetricRowUi(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Zihin berraklığı',
          percent: RecoveryProgress.alcoholClarityPercent(d),
          barColor: AppColors.emeraldLight.withValues(alpha: 0.75),
        ),
      ];
    case WillpowerTemplates.quitSubstance:
      return [
        QuitMetricRowUi(
          icon: Icons.favorite_outline_rounded,
          label: 'Beden dengesi',
          percent: RecoveryProgress.substanceBodyStabilizationPercent(d),
          barColor: AppColors.emeraldMid.withValues(alpha: 0.9),
        ),
        QuitMetricRowUi(
          icon: Icons.bedtime_outlined,
          label: 'Uyku ritmi',
          percent: RecoveryProgress.substanceSleepRhythmPercent(d),
          barColor: tabAccent.withValues(alpha: 0.75),
        ),
        QuitMetricRowUi(
          icon: Icons.shield_outlined,
          label: 'İstek yönetimi',
          percent: RecoveryProgress.substanceUrgeControlPercent(d),
          barColor: AppColors.creamBase.withValues(alpha: 0.4),
        ),
        QuitMetricRowUi(
          icon: Icons.groups_2_outlined,
          label: 'Destek ve takip',
          percent: RecoveryProgress.substanceSupportPathPercent(d),
          barColor: AppColors.emeraldLight.withValues(alpha: 0.75),
        ),
      ];
    case WillpowerTemplates.quitZina:
      return [
        QuitMetricRowUi(
          icon: Icons.gavel_rounded,
          label: 'Nefis disiplini',
          percent: RecoveryProgress.zinaDisciplinePercent(d),
          barColor: AppColors.emeraldMid.withValues(alpha: 0.9),
        ),
        QuitMetricRowUi(
          icon: Icons.vertical_split_rounded,
          label: 'Sınır gücü',
          percent: RecoveryProgress.zinaBoundaryStrengthPercent(d),
          barColor: tabAccent.withValues(alpha: 0.75),
        ),
        QuitMetricRowUi(
          icon: Icons.favorite_border_rounded,
          label: 'Kalp sükûnu',
          percent: RecoveryProgress.zinaHeartCalmPercent(d),
          barColor: AppColors.creamBase.withValues(alpha: 0.4),
        ),
        QuitMetricRowUi(
          icon: Icons.mosque_outlined,
          label: 'Tövbe istikameti',
          percent: RecoveryProgress.zinaTawbaSteadfastPercent(d),
          barColor: AppColors.emeraldLight.withValues(alpha: 0.75),
        ),
      ];
    default:
      return [];
  }
}

String quitMotivationForTemplate(String templateId, int elapsedDays) {
  if (elapsedDays <= 0) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking =>
        'İlk günün en değerli adımı: başlamak. Her temiz saat kalbin ve damarların için anlamlıdır.',
      WillpowerTemplates.quitScreen =>
        'İlk adım: ekranı bırakmak değil, ona sınır koymak. Bir dakikalık duruş bile iradedir.',
      WillpowerTemplates.quitAlcohol =>
        'Bugün alkolsüz kalmak, emanete ve aklına verdiğin sözün ilk satırıdır.',
      WillpowerTemplates.quitSubstance =>
        'Temiz bir gün, şifa yolunda en güçlü taşlardan biridir; yalnız değilsin.',
      WillpowerTemplates.quitZina =>
        'İffet yolunda ilk gün: gözünü ve kalbini korumaya niyet — tövbe kapısı açıktır.',
      _ => 'İlk günün en değerli adımı: başlamak.',
    };
  }
  if (elapsedDays < 7) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking =>
        'İlk hafta bedenin kendini toparlıyor; karbon monoksit azalır, tat ve koku yavaş yavaş geri döner.',
      WillpowerTemplates.quitScreen =>
        'İlk hafta dikkat parçaları toparlanır; uyku ve sabah dinginliği için ekran kesintileri işe yarar.',
      WillpowerTemplates.quitAlcohol =>
        'İlk hafta beden kimyası dengelenir; uyku ve ruh hali dalgalanabilir, sabır ve su senin dostun.',
      WillpowerTemplates.quitSubstance =>
        'İlk günlerde destek hattı veya uzman yanında olması güvenli geçiş için önemlidir.',
      WillpowerTemplates.quitZina =>
        'İlk hafta tetikleyiciler belirginleşir; sınır koymak ve ortamı değiştirmek kalbini korur.',
      _ => 'İlk hafta sabır; küçük adımlar büyük değişim getirir.',
    };
  }
  if (elapsedDays < 30) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking =>
        'Bir ay yaklaşırken sirkülasyonun ve nefes kapasiten desteklenir; sabırla devam.',
      WillpowerTemplates.quitScreen =>
        'Bir aya yaklaşırken odak süreleri uzayabilir; tefekkür ve hayırlı işlere açılan pencere genişler.',
      WillpowerTemplates.quitAlcohol =>
        'Bir ay civarında karaciğer ve uyku lehine eğilim artabilir; rutin seni taşır.',
      WillpowerTemplates.quitSubstance =>
        'Bir ayda beden ve uyku ritmi toparlanmaya başlayabilir; takipte kal.',
      WillpowerTemplates.quitZina =>
        'Bir ayda sınır alışkanlığı güçlenir; iffet yolunda her temiz gün istikamettir.',
      _ => 'Bir aya yaklaşırken sabırla devam.',
    };
  }
  if (elapsedDays < 90) {
    return switch (templateId) {
      WillpowerTemplates.quitSmoking =>
        'Üç aylık süreçte öksürük ve nefes darlığı birçok kişide hafifler; kendine güven büyüyor.',
      WillpowerTemplates.quitScreen =>
        'Üç ayda dijital sınır alışkanlığı köklenir; vaktini koruyan biri olursun.',
      WillpowerTemplates.quitAlcohol =>
        'Üç ayda ruh hali ve berraklık birçok kişide belirginleşir; emanete yatırım sürüyor.',
      WillpowerTemplates.quitSubstance =>
        'Üç ay temiz kalış, beyin ve beden için birikimli bir iyileşme yoludur.',
      WillpowerTemplates.quitZina =>
        'Üç ay iffet yolunda kalp sükûnu ve tövbe istikameti derinleşir.',
      _ => 'Üç aylık süreçte sabır meyvesini gösterir.',
    };
  }
  return switch (templateId) {
    WillpowerTemplates.quitSmoking =>
      'Uzun solukta kalan temizlik, kalp ve akciğer sağlığı açısından birikimli bir yatırımdır.',
    WillpowerTemplates.quitScreen =>
      'Uzun vadede ekran sınırı, hayırlı iş ve huzur için sürekli bir sermayedir.',
    WillpowerTemplates.quitAlcohol =>
      'Uzun solukta alkolsüzlük, beden ve aile saadeti için birikimli bir emanettir.',
    WillpowerTemplates.quitSubstance =>
      'Uzun vadede temiz günler birikir; şifa Allah’tandır, sebeplere sarılmak kulluktur.',
    WillpowerTemplates.quitZina =>
      'Uzun yolda iffet, kalbin sükûnu ve Rabbine yakınlık biriktirir.',
    _ => 'Uzun solukta her temiz gün değerlidir.',
  };
}
