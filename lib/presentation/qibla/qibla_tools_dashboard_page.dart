// lib/presentation/qibla/qibla_tools_dashboard_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../assistant/assistant_entry.dart';
import '../onboarding/app_tour/app_tour_anchor.dart';
import '../onboarding/app_tour/app_tour_keys.dart';
import '../shared/navigation/once_open.dart';
import '../shared/widgets/arin_premium_mark.dart';
import '../shared/widgets/arin_pressable.dart';
import '../shared/widgets/arin_shell_layout.dart';
import 'qibla_hub_assets.dart';
import 'qibla_hub_page.dart';

abstract final class _HubRow {
  static const double radius = 18;
  static const double icon = 64;
  static const double gap = 10;
  static const double titleSize = 16;
  static const double subtitleSize = 12.5;
}

class QiblaToolsDashboardPage extends ConsumerStatefulWidget {
  const QiblaToolsDashboardPage({super.key});

  @override
  ConsumerState<QiblaToolsDashboardPage> createState() =>
      _QiblaToolsDashboardPageState();
}

class _QiblaToolsDashboardPageState
    extends ConsumerState<QiblaToolsDashboardPage> {
  late final OnceOpen _openGate = OnceOpen(
    onBusyChanged: (_) {
      if (mounted) setState(() {});
    },
  );
  bool _precacheStarted = false;

  bool get _canOpen {
    if (_openGate.isBusy) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  Future<void> _openOnce(Future<void> Function() action) async {
    if (!_canOpen) return;
    await _openGate.run(action);
  }

  Future<void> _openTool({required String route}) {
    return _openOnce(() async {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      await Navigator.of(context).pushNamed(route);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;
    _precacheStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      QiblaHubAssets.precache(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = ArinShellLayout.bottomContentPadding(context);

    final rows = <_HubItem>[
      _HubItem(
        tourId: AppTourTargetId.qiblaAi,
        asset: QiblaHubAssets.tilePaths[0],
        title: l10n.qiblaHubAiTitle,
        subtitle: l10n.qiblaHubAiSubtitle,
        premium: true,
        badge: l10n.qiblaHubPremiumBadge,
        onTap: () => _openOnce(() async {
          HapticFeedback.lightImpact();
          if (!mounted) return;
          await openAssistantOrPaywall(context: context, ref: ref);
        }),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaSocial,
        socialArt: true,
        title: l10n.qiblaHubSocialTitle,
        subtitle: l10n.qiblaHubSocialSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.social),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaCompass,
        asset: QiblaHubAssets.tilePaths[1],
        title: l10n.qiblaHubCompassTitle,
        subtitle: l10n.qiblaHubCompassSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.compass),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaZikir,
        asset: QiblaHubAssets.tilePaths[2],
        title: l10n.qiblaHubZikirTitle,
        subtitle: l10n.qiblaHubZikirFeatureSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.zikir),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaQuran,
        asset: QiblaHubAssets.tilePaths[3],
        title: l10n.qiblaHubQuranTitle,
        subtitle: l10n.qiblaHubQuranSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.quran),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaHilal,
        asset: QiblaHubAssets.tilePaths[4],
        title: l10n.qiblaHubHilalDuelTitle,
        subtitle: l10n.qiblaHubHilalDuelSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.hilalDuel),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaPrayerCircle,
        asset: QiblaHubAssets.tilePaths[5],
        title: l10n.qiblaHubPrayerCircleTitle,
        subtitle: l10n.qiblaHubPrayerCircleSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.prayerCircle),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaHealing,
        asset: QiblaHubAssets.tilePaths[6],
        title: l10n.qiblaHubHealingTitle,
        subtitle: l10n.qiblaHubHealingSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.healing),
      ),
      _HubItem(
        tourId: AppTourTargetId.qiblaBreathing,
        asset: QiblaHubAssets.tilePaths[7],
        title: l10n.qiblaHubBreathingTitle,
        subtitle: l10n.qiblaHubBreathingSubtitle,
        onTap: () => _openTool(route: QiblaHubRoutes.breathing),
      ),
    ];

    return SizedBox.expand(
      child: ArinShellBackground.buildLayered(
        context,
        child: AbsorbPointer(
          absorbing: _openGate.isBusy,
          child: CustomScrollView(
            key: const PageStorageKey<String>('qiblaToolsScroll'),
            physics: defaultTargetPlatform == TargetPlatform.android
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == rows.length - 1 ? 0 : _HubRow.gap,
                          ),
                          child: RepaintBoundary(
                            child: _HubListCard(onDark: onDark, item: rows[i]),
                          ),
                        );
                      },
                      childCount: rows.length,
                      addAutomaticKeepAlives: false,
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

class _HubItem {
  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.asset,
    this.socialArt = false,
    this.premium = false,
    this.badge,
    this.tourId,
  });

  final String? asset;
  final bool socialArt;
  final bool premium;
  final String? badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final AppTourTargetId? tourId;
}

class _HubListCard extends StatelessWidget {
  const _HubListCard({required this.onDark, required this.item});

  final bool onDark;
  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    final premium = item.premium;
    final gold = onDark ? AppColors.goldAccent : AppColors.ornamentGoldDeep;
    final bronze = onDark ? AppColors.ornamentGold : AppColors.ornamentGoldDeep;
    final green = onDark
        ? AppColors.accentNeonGreen
        : AppColors.accentGreenOnLight;
    final titleC = onDark
        ? Colors.white.withValues(alpha: 0.95)
        : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    final border = premium
        ? gold.withValues(alpha: onDark ? 0.82 : 0.72)
        : Color.lerp(green, bronze, 0.32)!.withValues(
            alpha: onDark ? 0.42 : 0.4,
          );
    final badge = item.badge;
    final semanticsLabel = premium && badge != null && badge.isNotEmpty
        ? '${item.title}. $badge. ${item.subtitle}'
        : '${item.title}. ${item.subtitle}';
    final List<Color> fill = premium
        ? (onDark
            ? [
                const Color(0xFF2A2414).withValues(alpha: 0.96),
                const Color(0xFF141008).withValues(alpha: 0.98),
              ]
            : [
                const Color(0xFFFFF6D8),
                const Color(0xFFF4E4B0).withValues(alpha: 0.96),
              ])
        : (onDark
            ? [
                AppColors.homeCardSurface.withValues(alpha: 0.92),
                const Color(0xFF0A120E).withValues(alpha: 0.96),
              ]
            : [
                AppColors.creamSurface,
                AppColors.creamMist.withValues(alpha: 0.98),
              ]);
    final glow = premium ? AppColors.goldAccent : AppColors.accentGlowGreen;
    final glowAlpha = premium
        ? (onDark ? 0.22 : 0.16)
        : (onDark ? 0.10 : 0.06);

    final card = Semantics(
      button: true,
      label: semanticsLabel,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: ArinPressable(
          onTap: item.onTap,
          haptic: false,
          scale: 0.98,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_HubRow.radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fill,
              ),
              border: Border.all(color: border, width: premium ? 1.7 : 1.1),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: glowAlpha),
                  blurRadius: premium ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  _HubGlyph(
                    onDark: onDark,
                    asset: item.asset,
                    socialArt: item.socialArt,
                    goldRing: premium,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleC,
                                  fontSize: _HubRow.titleSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ),
                            if (premium && badge != null && badge.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _PremiumChip(onDark: onDark, label: badge),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subC,
                            fontSize: _HubRow.subtitleSize,
                            height: 1.32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tourId = item.tourId;
    if (tourId == null) return card;
    return AppTourAnchor(id: tourId, child: card);
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip({required this.onDark, required this.label});

  final bool onDark;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gold = onDark ? AppColors.goldAccent : AppColors.ornamentGoldDeep;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gold.withValues(alpha: onDark ? 0.18 : 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArinPremiumMark(color: gold, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: gold,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubGlyph extends StatelessWidget {
  const _HubGlyph({
    required this.onDark,
    required this.socialArt,
    this.asset,
    this.goldRing = false,
  });

  final bool onDark;
  final bool socialArt;
  final bool goldRing;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final green = onDark
        ? AppColors.accentNeonGreen
        : AppColors.accentGreenOnLight;
    final gold = onDark ? AppColors.goldAccent : AppColors.ornamentGoldDeep;
    final cacheWidth = QiblaHubAssets.glyphCacheWidth(
      MediaQuery.devicePixelRatioOf(context),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onDark ? AppColors.homeCardSurface : const Color(0xFF1B4D3E),
        border: Border.all(
          color: goldRing
              ? gold.withValues(alpha: 0.86)
              : green.withValues(alpha: 0.32),
          width: goldRing ? 1.6 : 1,
        ),
      ),
      child: SizedBox(
        width: _HubRow.icon,
        height: _HubRow.icon,
        child: ClipOval(
          child: socialArt
              ? const _SocialGlyph()
              : Image.asset(
                  asset!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  cacheWidth: cacheWidth,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

class _SocialGlyph extends StatelessWidget {
  const _SocialGlyph();

  static const _faces = QiblaHubAssets.socialPreviewPaths;

  /// Fotoğrafları hub'ın mat şampanya ikonlarıyla aynı solukluğa çeker.
  static const _hubMute = ColorFilter.matrix(<double>[
    0.508, 0.320, 0.032, 0, 8,
    0.095, 0.733, 0.032, 0, 6,
    0.095, 0.320, 0.445, 0, 4,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    final cacheWidth = QiblaHubAssets.socialPreviewCacheWidth(
      MediaQuery.devicePixelRatioOf(context),
    );
    return Center(
      child: SizedBox(
        width: 48,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _faces.length; i++)
              Positioned(
                left: i * 11.0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: AppColors.homeCardSurface,
                        width: 1.6,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: ClipOval(
                      child: ColorFiltered(
                        colorFilter: _hubMute,
                        child: Image.asset(
                          _faces[i],
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          cacheWidth: cacheWidth,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: AppColors.homeCardSurface,
                          ),
                        ),
                      ),
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
