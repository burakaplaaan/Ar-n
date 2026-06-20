// lib/presentation/home/home_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/extensions/date_extensions.dart';
import '../../data/models/prayer_times_model.dart';
import '../../data/services/diyanet_district_matcher.dart';
import '../../data/services/location_service.dart';
import '../settings/widgets/district_picker_sheet.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/user_profile_providers.dart';
import '../shared/widgets/ornate_frame.dart';
import 'widgets/daily_namaz_wisdom_card.dart';
import 'widgets/home_namaz_ritual_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = DateTime.now();
      if (!mounted) return;
      if (next.hour == _now.hour && next.minute == _now.minute) return;
      setState(() => _now = next);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  /// Yerel saate göre selam. Gece yarısı–05:59 [hour < 6] sabah değil, gece sayılır.
  String _greeting(AppLocalizations l10n) {
    final hour = _now.hour;
    if (hour < 6) return l10n.homeGreetingNight;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingNoon;
    if (hour < 21) return l10n.homeGreetingEvening;
    return l10n.homeGreetingNight;
  }

  @override
  Widget build(BuildContext context) {
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
    final isPremium = ref.watch(isPremiumProvider);
    // "İmsak çıkıyor": fajr ≤ şimdi < sunrise ise true; kartı kırmızımsı
    // amber vurguyla göstereceğiz, namaz kaçmasın.
    final urgentFajr = ref.watch(nextPrayerUrgentFajrProvider);

    final ornament = isDarkShell
        ? AppColors.ornamentGold
        : AppColors.ornamentGoldDeep;
    final titleC = isDarkShell ? Colors.white : AppColors.emeraldDark;
    final badgeTextC = isDarkShell
        ? Colors.white.withValues(alpha: 0.95)
        : AppColors.emeraldDark;

    // Android'de selamlama başlığı dar/iri-fontlu cihazlarda 28px sabit punto
    // ile sığmayıp 2-3 satıra kırılıyor ve sayaç kartıyla çakışıyordu. iOS
    // (App Store'da onaylı) yerleşimine DOKUNMUYORUZ; yalnızca Android'de
    // FittedBox ile tek satıra sığdırıp tutarlı hale getiriyoruz.
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final greetingStyle = TextStyle(
      fontFamily: 'Georgia',
      color: titleC,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ).copyWith(
      fontFamilyFallback: const ['Times New Roman', 'serif'],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -18,
            child: IgnorePointer(
              child: Icon(
                Icons.mosque_rounded,
                size: 112,
                color: isDarkShell
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.emeraldDark.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 6,
            child: IgnorePointer(
              child: Icon(
                Icons.nightlight_round,
                size: 16,
                color: ornament.withValues(
                  alpha: isDarkShell ? 0.34 : 0.45,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAndroid)
                      // scaleDown: sığmazsa fontu küçültür, asla 28px üstüne
                      // çıkmaz → her Android cihazda tek satır, çakışma yok.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          greeting,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          textScaler: TextScaler.noScaling,
                          style: greetingStyle,
                        ),
                      )
                    else
                      Text(greeting, style: greetingStyle),
                    const SizedBox(height: 6),
                    Text(
                      userName,
                      style: TextStyle(
                        color: ornament.withValues(alpha: 0.8),
                        fontSize:
                            Theme.of(context).platform == TargetPlatform.iOS
                            ? 18
                            : 16,
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push(AppRoutes.premium),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ornament.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ornament.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: ornament,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'PREMIUM' : 'Premium',
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
                  child: OrnateFrame(
                    borderRadius: 20,
                    inset: 5,
                    armLength: 11,
                    bottomAccent: true,
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: urgentFajr
                              ? const Color(0xFFFFA726).withValues(alpha: 0.75)
                              : ornament.withValues(alpha: 0.56),
                          width: urgentFajr ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: urgentFajr
                                ? const Color(0xFFFFA726).withValues(alpha: 0.22)
                                : ornament.withValues(alpha: 0.18),
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: (urgentFajr
                                            ? const Color(0xFFFFA726)
                                            : AppColors.accentNeonGreen)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
),
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
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
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
                Expanded(
                  child: Text(
                    l10n.homePrayerTimesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleC,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
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
            const SizedBox(height: 14),
            // Vakit kutuları sabit en/boy oranlı; cihazda büyük sistem yazı
            // ölçeği seçiliyse hücre içeriği (ikon + ad + "Sıradaki vakit" +
            // saat) kutuya sığmayıp üst üste biniyordu. Bu gridi sabit ölçekle
            // render ederek her cihazda aynı, taşmasız görünmesini sağlıyoruz.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.0,
              child: GridView.builder(
                itemCount: model.orderedPrayers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.81,
                ),
                itemBuilder: (context, i) {
                  final p = model.orderedPrayers[i];
                  return _PrayerTimeRow(
                    index: i,
                    name: p.name,
                    time: p.time,
                    isNext: p.name == nextName,
                    isDarkShell: isDarkShell,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  final int index;
  final String name;
  final String time;
  final bool isNext;
  final bool isDarkShell;

  const _PrayerTimeRow({
    required this.index,
    required this.name,
    required this.time,
    required this.isNext,
    required this.isDarkShell,
  });

  IconData _iconForPrayer() {
    switch (index) {
      case 0:
        return Icons.wb_twilight_outlined;
      case 1:
        return Icons.wb_sunny_outlined;
      case 2:
        return Icons.sunny;
      case 3:
        return Icons.brightness_medium_outlined;
      case 4:
        return Icons.wb_twilight;
      default:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;
    final borderColor = isNext
        ? accent.withValues(alpha: 0.78)
        : accent.withValues(alpha: isDarkShell ? 0.2 : 0.3);
    final bg = isNext
        ? AppColors.accentGlowGreen.withValues(alpha: isDarkShell ? 0.16 : 0.2)
        : (isDarkShell
              ? AppColors.homeCardSurface.withValues(alpha: 0.52)
              : AppColors.creamMist.withValues(alpha: 0.72));
    final nameC = isDarkShell
        ? Colors.white.withValues(alpha: isNext ? 0.98 : 0.82)
        : AppColors.emeraldDark.withValues(alpha: isNext ? 0.95 : 0.8);
    final timeMuted = isDarkShell
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textSecondary.withValues(alpha: 0.9);
    // Çok hafif kahverengi/bronz vurgu — yeşil paleti bozmadan sıcaklık katar.
    final ornament = isDarkShell
        ? AppColors.ornamentGold
        : AppColors.ornamentGoldDeep;
    final iconColor = isNext
        ? accent
        : ornament.withValues(alpha: isDarkShell ? 0.62 : 0.7);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withValues(alpha: isNext ? 0.95 : 0.9),
            bg.withValues(alpha: isNext ? 0.72 : 0.62),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext
              ? borderColor
              : Color.lerp(borderColor, ornament, 0.35)!.withValues(
                  alpha: isDarkShell ? 0.3 : 0.4,
                ),
          width: isNext ? 1.35 : 0.95,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.accentGlowGreen.withValues(alpha: 0.14),
                  blurRadius: 10,
                  spreadRadius: 0.2,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNext
                    ? accent.withValues(alpha: 0.14)
                    : ornament.withValues(alpha: isDarkShell ? 0.1 : 0.12),
                border: Border.all(
                  color: isNext
                      ? accent.withValues(alpha: 0.4)
                      : ornament.withValues(alpha: isDarkShell ? 0.32 : 0.4),
                  width: 0.9,
                ),
              ),
              child: Center(
                child: Icon(_iconForPrayer(), color: iconColor, size: 17),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nameC,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                if (isNext)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.homePrayerNextRowHint,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.88),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 14,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: ornament.withValues(
                          alpha: isDarkShell ? 0.38 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                maxLines: 1,
                style: TextStyle(
                  color: isNext ? accent : timeMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
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
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
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
                Expanded(
                  child: Text(
                    l10n.homePrayerTimesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.92)
                          : AppColors.emeraldDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              itemCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.81,
              ),
              itemBuilder: (context, i) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.homeCardSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
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
                );
              },
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
    if (diff.inHours < 1) {
      return l10n.homeLocationFreshMinutesAgo(diff.inMinutes);
    }
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
