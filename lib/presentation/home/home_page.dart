// lib/presentation/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/extensions/date_extensions.dart';
import '../../data/models/prayer_times_model.dart';
import '../../data/services/diyanet_district_matcher.dart';
import '../../data/services/location_service.dart';
import '../settings/widgets/district_picker_sheet.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/user_profile_providers.dart';
import 'widgets/daily_namaz_wisdom_card.dart';
import 'widgets/home_namaz_ritual_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Yerel saate göre selam. Gece yarısı–05:59 [hour < 6] sabah değil, gece sayılır.
  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 6) return l10n.homeGreetingNight;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingNoon;
    if (hour < 21) return l10n.homeGreetingEvening;
    return l10n.homeGreetingNight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Tek Scaffold ArinShell'de; iç içe Scaffold + extendBody bazı cihazlarda boş gövde verebiliyor.
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SizedBox.expand(
      child: ArinShellBackground.buildLayered(
        context,
        child: RefreshIndicator(
          color: ArinShellBackground.isLight(context)
              ? AppColors.accentGreenOnLight
              : AppColors.accentNeonGreen,
          backgroundColor: ArinShellBackground.isLight(context)
              ? AppColors.creamSurface
              : AppColors.homeCardSurface,
          onRefresh: () async {
            await ref
                .read(locationServiceProvider)
                .clearPrayerLocationThrottle();
            ref.invalidate(prayerTimesProvider);
            await ref.read(prayerTimesProvider.future);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderSection(
                          greeting: _greeting(l10n),
                          isDarkShell: !ArinShellBackground.isLight(context),
                        ),
                        const SizedBox(height: 16),
                        const DailyNamazWisdomCard(),
                        const SizedBox(height: 12),
                        const HomeNamazRitualSection(),
                        const SizedBox(height: 12),
                        const _PrayerTimesBlock(),
                        SizedBox(height: 72 + bottomPad),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _HeaderSection extends ConsumerWidget {
  final String greeting;
  final bool isDarkShell;
  const _HeaderSection({required this.greeting, required this.isDarkShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileName = ref.watch(userProfileProvider).name?.trim();
    final authName = ref
        .watch(authUserProvider)
        .asData
        ?.value
        ?.displayName
        ?.trim();
    final userName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (authName != null && authName.isNotEmpty)
            ? authName
            : l10n.homeGuestUser;
    final remaining = ref.watch(countdownProvider);
    final nextName = ref.watch(nextPrayerNameProvider);
    // "İmsak çıkıyor": fajr ≤ şimdi < sunrise ise true; kartı kırmızımsı
    // amber vurguyla göstereceğiz, namaz kaçmasın.
    final urgentFajr = ref.watch(nextPrayerUrgentFajrProvider);

    final titleC = isDarkShell ? Colors.white : AppColors.emeraldDark;
    final subtitleC = isDarkShell
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;
    final badgeTextC = isDarkShell
        ? Colors.white.withValues(alpha: 0.95)
        : AppColors.emeraldDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: titleC,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userName,
                style: TextStyle(
                  color: subtitleC,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.accentNeonGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ARIN',
                    style: TextStyle(
                      color: badgeTextC,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Namaz sayacı kartı — TalkBack/VoiceOver kullanıcısı tek
                // cümle duyuyor: "Sıradaki namaz İkindi, kalan 1 saat 23
                // dakika". FittedBox içinde ayrı ayrı okutmak yerine
                // Semantics.container ile merge ediyoruz.
                Semantics(
                  container: true,
                  label: urgentFajr
                      ? l10n.homePrayerUrgentSemanticsLabel(
                          _humanRemaining(remaining, l10n),
                        )
                      : l10n.homePrayerNextSemanticsLabel(
                          nextName,
                          _humanRemaining(remaining, l10n),
                        ),
                  excludeSemantics: true,
                  child: Container(
                    width: 124,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: urgentFajr
                          ? (isDarkShell
                                ? const Color(
                                    0xFF2A1710,
                                  ).withValues(alpha: 0.92)
                                : const Color(
                                    0xFFFFF3E0,
                                  ).withValues(alpha: 0.96))
                          : (isDarkShell
                                ? AppColors.homeCardSurface.withValues(
                                    alpha: 0.85,
                                  )
                                : Colors.white.withValues(alpha: 0.92)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: urgentFajr
                            ? const Color(0xFFFFA726).withValues(alpha: 0.75)
                            : AppColors.accentNeonGreen.withValues(alpha: 0.45),
                        width: urgentFajr ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: urgentFajr
                              ? const Color(0xFFFFA726).withValues(alpha: 0.22)
                              : AppColors.accentGlowGreen.withValues(
                                  alpha: 0.12,
                                ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          urgentFajr
                              ? l10n.homePrayerUrgentBadge
                              : l10n.homePrayerNextBadge,
                          style: TextStyle(
                            color: urgentFajr
                                ? const Color(0xFFFFB74D)
                                : (isDarkShell
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : AppColors.textSecondary),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: urgentFajr ? 0.4 : 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextName,
                          style: TextStyle(
                            color: urgentFajr
                                ? const Color(0xFFFFCC80)
                                : (isDarkShell
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : AppColors.emeraldDark),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            remaining.countdownText,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: urgentFajr
                                  ? const Color(0xFFFFA726)
                                  : AppColors.accentNeonGreen,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Erişilebilirlik için "01:23:45" yerine "1 saat 23 dakika" gibi okunabilir
  /// biçim. Saniye eklemedik — TalkBack her saniye tekrar okumasın; dakika
  /// çözünürlüğü pratikte yeterli.
  String _humanRemaining(Duration d, AppLocalizations l10n) {
    if (d.isNegative || d == Duration.zero) return l10n.homeRemainingPassed;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return l10n.homeRemainingHoursMinutes(h, m);
    if (h > 0) return l10n.homeRemainingHoursOnly(h);
    if (m > 0) return l10n.homeRemainingMinutesOnly(m);
    return l10n.homeRemainingFewSeconds;
  }
}

// ─── Namaz vakitleri ─────────────────────────────────────────────────────────

class _PrayerTimesBlock extends ConsumerWidget {
  const _PrayerTimesBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerTimesProvider);
    return async.when(
      data: (pt) => _PrayerTimesList(
        model: pt,
        isDarkShell: !ArinShellBackground.isLight(context),
      ),
      loading: () => const _PrayerTimesSkeleton(),
      error: (_, __) => const _PrayerTimesError(),
    );
  }
}

class _PrayerTimesList extends StatelessWidget {
  final PrayerTimesModel model;
  final bool isDarkShell;
  const _PrayerTimesList({required this.model, required this.isDarkShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final next = model.nextPrayer(now);
    final nextName = next?.name;
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(now);

    final meta = isDarkShell
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textMuted;
    const accent = AppColors.accentNeonGreen;
    final borderC = accent.withValues(alpha: isDarkShell ? 0.38 : 0.45);
    final titleC = isDarkShell
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.emeraldDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkShell
                ? [
                    AppColors.homeCardSurface.withValues(alpha: 0.88),
                    const Color(0xFF0A120E).withValues(alpha: 0.94),
                  ]
                : [
                    AppColors.creamSurface,
                    AppColors.creamMist.withValues(alpha: 0.95),
                  ],
          ),
          border: Border.all(color: borderC, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGlowGreen.withValues(
                alpha: isDarkShell ? 0.14 : 0.1,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: accent.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.homePrayerTimesTitle,
                  style: TextStyle(
                    color: titleC,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LocationRow(
              fallbackCity: model.city,
              dateLabel: dateLabel,
              meta: meta,
              isDarkShell: isDarkShell,
            ),
            const SizedBox(height: 12),
            ...model.orderedPrayers.asMap().entries.map((e) {
              final p = e.value;
              final isNext = p.name == nextName;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: e.key == model.orderedPrayers.length - 1 ? 0 : 6,
                ),
                child: _PrayerTimeRow(
                  name: p.name,
                  time: p.time,
                  isNext: isNext,
                  isDarkShell: isDarkShell,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  final String name;
  final String time;
  final bool isNext;
  final bool isDarkShell;

  const _PrayerTimeRow({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isDarkShell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;
    final borderColor = isNext
        ? accent.withValues(alpha: 0.75)
        : accent.withValues(alpha: isDarkShell ? 0.22 : 0.28);
    final bg = isNext
        ? AppColors.accentGlowGreen.withValues(alpha: 0.12)
        : (isDarkShell
              ? AppColors.homeCardSurface.withValues(alpha: 0.55)
              : AppColors.creamMist.withValues(alpha: 0.65));
    final nameC = isDarkShell
        ? Colors.white.withValues(alpha: isNext ? 1.0 : 0.88)
        : AppColors.emeraldDark.withValues(alpha: isNext ? 1.0 : 0.88);
    final timeMuted = isDarkShell
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isNext ? 1.5 : 1),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.accentGlowGreen.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNext
                    ? accent.withValues(alpha: 0.18)
                    : (isDarkShell
                          ? Colors.white.withValues(alpha: 0.05)
                          : accent.withValues(alpha: 0.08)),
                border: Border.all(
                  color: isNext
                      ? accent.withValues(alpha: 0.4)
                      : accent.withValues(alpha: isDarkShell ? 0.08 : 0.18),
                ),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: isNext
                    ? accent
                    : accent.withValues(alpha: isDarkShell ? 0.35 : 0.45),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: nameC,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isNext)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.homePrayerNextRowHint,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isNext) const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                color: isNext ? accent : timeMuted,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesSkeleton extends StatelessWidget {
  const _PrayerTimesSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = !ArinShellBackground.isLight(context);
    const accent = AppColors.accentNeonGreen;
    final borderC = accent.withValues(alpha: isDark ? 0.38 : 0.45);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.homeCardSurface.withValues(alpha: 0.88),
                    const Color(0xFF0A120E).withValues(alpha: 0.94),
                  ]
                : [
                    AppColors.creamSurface,
                    AppColors.creamMist.withValues(alpha: 0.95),
                  ],
          ),
          border: Border.all(color: borderC, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGlowGreen.withValues(
                alpha: isDark ? 0.14 : 0.1,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: accent.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.homePrayerTimesTitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.emeraldDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...List.generate(
              5,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i < 4 ? 6 : 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.homeCardSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Center(
                    child: i == 0
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentNeonGreen,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesError extends ConsumerWidget {
  const _PrayerTimesError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Future<void> pickDistrict() async {
      final picked = await showDistrictPickerSheet(context);
      if (picked == null || !context.mounted) return;
      await ref.read(locationServiceProvider).saveManualDistrict(picked);
      ref.invalidate(prayerTimesProvider);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.homeCardSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homePrayerLoadFailedTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homePrayerLoadFailedBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(locationServiceProvider)
                      .clearPrayerLocationThrottle();
                  ref.invalidate(prayerTimesProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.homeRetryAction),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emeraldMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: pickDistrict,
                icon: const Icon(Icons.place_outlined, size: 18),
                label: Text(l10n.homeChangeDistrictAction),
              ),
              OutlinedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.homeOpenSettingsAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Namaz Vakitleri kartının ikinci satırı: konum ikonu + yer etiketi +
/// tarih. Tamamen tıklanır: dokununca Diyanet ilçe picker sheet'i açılır,
/// seçim sonrası `LocationService.saveManualDistrict` + `invalidate` ile
/// dashboard anında güncel Diyanet vakitlerine geçer.
///
/// Etiket önceliği:
///   1. TR + savedDistrictId → `DiyanetDistrict.displayLabel`
///      (örn. "Gebze / Kocaeli", il merkezi ise yalnız "Kocaeli")
///   2. Diğer tüm durumlar → `model.city` (Aladhan fallback veya henüz
///      çözülmemiş TR konum)
///
/// Chevron ikonu satırın "değiştirilebilir" olduğunu görsel olarak iletir;
/// ayrı bir "değiştir" metin etiketi yerine küçük bir `chevron_right` daha
/// sade ve uluslararasıdır.
class _LocationRow extends ConsumerWidget {
  final String fallbackCity;
  final String dateLabel;
  final Color meta;
  final bool isDarkShell;

  const _LocationRow({
    required this.fallbackCity,
    required this.dateLabel,
    required this.meta,
    required this.isDarkShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationServiceProvider);
    final districtId = location.savedDistrictId;
    final label = _resolveLabel(districtId);
    final freshness = _syncFreshnessLabel(context, location.lastPrayerSyncAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPicker(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: 14, color: meta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: meta,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: meta.withValues(alpha: 0.35),
                    decorationThickness: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: meta.withValues(alpha: 0.7),
              ),
              if (freshness != null) ...[
                const SizedBox(width: 6),
                Text(
                  freshness,
                  style: TextStyle(
                    color: meta.withValues(alpha: 0.78),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: TextStyle(
                  color: meta.withValues(alpha: isDarkShell ? 0.9 : 1.0),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveLabel(int? districtId) {
    if (districtId == null) return fallbackCity;
    final d = DiyanetDistrictMatcher.byId(districtId);
    if (d == null) return fallbackCity;
    return d.displayLabel;
  }

  String? _syncFreshnessLabel(BuildContext context, DateTime? lastSyncAt) {
    if (lastSyncAt == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(lastSyncAt);
    if (diff.inMinutes < 2) return l10n.homeLocationFreshNow;
    if (diff.inHours < 1) return l10n.homeLocationFreshMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.homeLocationFreshHoursAgo(diff.inHours);
    return l10n.homeLocationFreshDaysAgo(diff.inDays);
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final picked = await showDistrictPickerSheet(context);
    if (picked == null || !context.mounted) return;
    await ref.read(locationServiceProvider).saveManualDistrict(picked);
    ref.invalidate(prayerTimesProvider);
  }
}
