import 'dart:async';

import 'package:arin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/product_metric_features.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/services/product_metrics_service.dart';
import '../../shared/providers/admob_providers.dart';
import '../../shared/providers/user_profile_providers.dart';
import '../../shared/widgets/arin_permission_dialog.dart';
import '../qibla_hub_navigator_key.dart';
import '../qibla_hub_page.dart';
import 'hilal_duel_controller.dart';
import 'hilal_duel_level.dart';
import 'hilal_duel_repository.dart';
import 'hilal_duel_sync.dart';

/// 0 can: eşleşme ekranına girmeden uyarı; isterse reklam izlet.
Future<void> _promptNeedHeartDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required HilalDuelController controller,
}) async {
  final watch = await showArinPermissionDialog(
    context: context,
    title: l10n.hilalDuelNeedHeartTitle,
    body: l10n.hilalDuelNeedHeartHint,
    icon: Icons.favorite_rounded,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.hilalDuelNeedHeartCta,
  );
  if (watch && context.mounted) {
    unawaited(controller.watchHeartAd());
  }
}

final hilalDuelRepositoryProvider = Provider<HilalDuelRepository>((ref) {
  return HilalDuelRepository();
});

class HilalDuelPage extends ConsumerStatefulWidget {
  const HilalDuelPage({super.key});

  @override
  ConsumerState<HilalDuelPage> createState() => _HilalDuelPageState();
}

class _HilalDuelPageState extends ConsumerState<HilalDuelPage>
    with SingleTickerProviderStateMixin {
  HilalDuelController? _controller;
  late final AnimationController _pulse;
  Timer? _tick;
  /// PopScope(canPop:false) + maybePop yeniden _handleBack çağırır → donma.
  bool _backInFlight = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ProductMetricsService.featureOpen(ProductMetricFeatures.hilalDuel),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final c = _controller;
      if (c == null) return;
      if (c.phase == HilalDuelPhase.matchmaking ||
          c.phase == HilalDuelPhase.cancelRetry ||
          c.phase == HilalDuelPhase.playing) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureController());
  }

  void _ensureController() {
    if (_controller != null || !mounted) return;
    final controller = HilalDuelController(
      repository: ref.read(hilalDuelRepositoryProvider),
      adMob: ref.read(adMobServiceProvider),
      displayName: () {
        return _hilalPlayerName(ref.read(userProfileProvider).name, null);
      },
    );
    _controller = controller;
    controller.addListener(_onController);
    unawaited(controller.bootstrap());
    final locale = Localizations.localeOf(context).languageCode;
    unawaited(
      ref.read(hilalDuelRepositoryProvider).syncNotificationDevice(locale),
    );
    setState(() {});
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  /// canPop:false iken maybePop rotayı kapatmaz; bilinçli çıkışta pop şart.
  /// Önce Kıble hub Navigator, yoksa GoRouter / qibla fallback.
  void _popRoute() {
    if (!mounted) return;
    final hubNav = qiblaHubNavigatorKey.currentState;
    if (hubNav != null) {
      Route<dynamic>? top;
      hubNav.popUntil((route) {
        top = route;
        return true;
      });
      if (top != null &&
          !top!.isFirst &&
          top!.settings.name != QiblaHubRoutes.dashboard) {
        hubNav.pop();
        return;
      }
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.qibla);
  }

  Future<void> _handleBack() async {
    if (_backInFlight) return;
    _backInFlight = true;
    try {
      final c = _controller;
      if (c == null) {
        _popRoute();
        return;
      }
      // startInFlight / queueMayExist / cancelPending → iptal bitmeden pop yok.
      if (c.requiresCancelBeforeLeave ||
          c.phase == HilalDuelPhase.matchmaking ||
          c.phase == HilalDuelPhase.cancelRetry) {
        final wasCancelRetry = c.phase == HilalDuelPhase.cancelRetry;
        final settle = wasCancelRetry
            ? await c.retryCancel()
            : await c.requestLeave();
        if (!mounted) return;
        switch (settle) {
          case HilalDuelLeaveSettle.enteredMatch:
            return;
          case HilalDuelLeaveSettle.blockedRetry:
            // İlk hata: cancelRetry ekranında kal.
            // İkinci geri (zaten cancelRetry iken): kilitlenmeyi aç.
            if (wasCancelRetry) {
              await c.abandonCancelAndLeave();
              if (!mounted) return;
              _popRoute();
            }
            return;
          case HilalDuelLeaveSettle.poppedToLobby:
            _popRoute();
            return;
        }
      }
      if (c.phase == HilalDuelPhase.playing) {
        // Terk: kalan oyuncu kazanır, çıkan kişiye hilal cezası.
        await c.forfeitAndLeave();
        if (!mounted) return;
        _popRoute();
        return;
      }
      _popRoute();
    } finally {
      _backInFlight = false;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    _controller?.removeListener(_onController);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final c = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: _EdgeSwipeBack(
        onBack: _handleBack,
        child: Scaffold(
          // Saydam scaffold + fade pop = siyah flash; zemin her zaman dolu.
          backgroundColor:
              onDark ? const Color(0xFF0A1210) : const Color(0xFFF3F6F2),
          body: ArinShellBackground.buildLayered(
            context,
            child: SafeArea(
              child: c == null
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _buildPhase(context, l10n, onDark, c),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(
    BuildContext context,
    AppLocalizations l10n,
    bool onDark,
    HilalDuelController c,
  ) {
    switch (c.phase) {
      case HilalDuelPhase.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );
      case HilalDuelPhase.error:
        return _ErrorBody(
          key: const ValueKey('error'),
          message: c.errorMessage ?? l10n.hilalDuelRetry,
          onRetry: c.bootstrap,
          l10n: l10n,
          onDark: onDark,
        );
      case HilalDuelPhase.matchmaking:
      case HilalDuelPhase.cancelRetry:
        return _MatchmakingBody(
          key: ValueKey(
            c.phase == HilalDuelPhase.cancelRetry ? 'cancel-retry' : 'mm',
          ),
          progress: c.matchmakingProgress(),
          cancelFailed: c.phase == HilalDuelPhase.cancelRetry,
          errorMessage: c.errorMessage,
          onCancel: () async {
            if (c.phase == HilalDuelPhase.cancelRetry) {
              final settle = await c.retryCancel();
              if (!mounted) return;
              if (settle == HilalDuelLeaveSettle.poppedToLobby) {
                // Lobiye düştü; hub'a çıkma — kullanıcı lobide kalsın.
              }
              return;
            }
            await c.cancelMatchmaking();
          },
          l10n: l10n,
          onDark: onDark,
          pulse: _pulse,
        );
      case HilalDuelPhase.playing:
        return _PlayingBody(
          key: const ValueKey('play'),
          controller: c,
          l10n: l10n,
          onDark: onDark,
        );
      case HilalDuelPhase.result:
        return _ResultBody(
          key: const ValueKey('result'),
          controller: c,
          l10n: l10n,
          onDark: onDark,
          playerName: _hilalPlayerName(
            ref.watch(userProfileProvider).name,
            c.profile?.name,
          ),
        );
      case HilalDuelPhase.lobby:
        return _LobbyBody(
          key: const ValueKey('lobby'),
          controller: c,
          l10n: l10n,
          onDark: onDark,
          pulse: _pulse,
          playerName: _hilalPlayerName(
            ref.watch(userProfileProvider).name,
            c.profile?.name,
          ),
          onBack: _handleBack,
        );
    }
  }
}

/// Uygulama profilindeki isim öncelikli; yoksa sunucu / varsayılan.
String _hilalPlayerName(String? appName, String? serverName) {
  final app = (appName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (app.length >= 2) {
    return app.length > 32 ? app.substring(0, 32).trim() : app;
  }
  final server = (serverName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (server.length >= 2) return server;
  return 'Arın Oyuncusu';
}

String _localizedHilalTitle(AppLocalizations l10n, String? title) {
  final raw = (title ?? '').trim();
  if (raw.isEmpty) return '';
  final lower = raw.toLowerCase();
  if (lower.contains('ilim') || lower.contains('knowledge')) {
    return l10n.hilalDuelTitleIlimDostu;
  }
  if (lower.contains('talebe') || lower.contains('student') || lower.contains('طالب')) {
    return l10n.hilalDuelTitleTalebe;
  }
  return raw;
}

String _nextRewardLabel(AppLocalizations l10n, int level, bool maxLevel) {
  if (maxLevel) return l10n.hilalDuelMaxLevel;
  final next = nextRewardAfterLevel(level);
  if (next == null) return l10n.hilalDuelMaxLevel;
  switch (next.kind) {
    case HilalDuelRewardKind.frame:
      return l10n.hilalDuelNextRewardFrame(next.level);
    case HilalDuelRewardKind.titleTalebe:
      return l10n.hilalDuelNextRewardTitle(
        l10n.hilalDuelTitleTalebe,
        next.level,
      );
    case HilalDuelRewardKind.specialHilal:
      return l10n.hilalDuelNextRewardHilalIcon(next.level);
    case HilalDuelRewardKind.titleIlimDostu:
      return l10n.hilalDuelNextRewardTitle(
        l10n.hilalDuelTitleIlimDostu,
        next.level,
      );
  }
}

/// Hub NestedSwipeBack yerine: eşleşme iptalini atlamadan kenar kaydırma.
class _EdgeSwipeBack extends StatefulWidget {
  const _EdgeSwipeBack({required this.child, required this.onBack});

  final Widget child;
  final Future<void> Function() onBack;

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  bool _startedFromBackEdge = false;
  double _accumDx = 0;
  bool _busy = false;

  bool _isFromBackEdge(Offset global) {
    final m = MediaQuery.of(context);
    final w = m.size.width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final inset = rtl ? m.padding.right : m.padding.left;
    final slop = 28 + inset;
    if (rtl) return global.dx > w - slop;
    return global.dx < slop;
  }

  Future<void> _trigger() async {
    if (_busy) return;
    _busy = true;
    try {
      await widget.onBack();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        final route = ModalRoute.of(context);
        if (route == null || !route.isCurrent) {
          _startedFromBackEdge = false;
          _accumDx = 0;
          return;
        }
        _startedFromBackEdge = _isFromBackEdge(details.globalPosition);
        _accumDx = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_startedFromBackEdge) return;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        _accumDx += rtl ? -details.delta.dx : details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        if (!_startedFromBackEdge) {
          _accumDx = 0;
          return;
        }
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final vx = details.velocity.pixelsPerSecond.dx;
        final towardBack = rtl ? -vx : vx;
        final farEnough = _accumDx > 56;
        final flingBack = towardBack > 400;
        _startedFromBackEdge = false;
        _accumDx = 0;
        if (farEnough || flingBack) {
          unawaited(_trigger());
        }
      },
      onHorizontalDragCancel: () {
        _startedFromBackEdge = false;
        _accumDx = 0;
      },
      child: widget.child,
    );
  }
}

abstract final class _HilalPalette {
  static Color bronze(bool onDark) =>
      onDark ? const Color(0xFFD4A574) : const Color(0xFF8B5E3C);
  static Color ink(bool onDark) =>
      onDark ? Colors.white.withValues(alpha: 0.94) : AppColors.emeraldDark;
  static Color muted(bool onDark) =>
      onDark ? Colors.white.withValues(alpha: 0.62) : const Color(0xFF4A5C52);
}

String _nameInitial(String name, {required String fallback}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return fallback;
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

class _LobbyBody extends StatefulWidget {
  const _LobbyBody({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onDark,
    required this.pulse,
    required this.playerName,
    required this.onBack,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;
  final AnimationController pulse;
  final String playerName;
  final Future<void> Function() onBack;

  @override
  State<_LobbyBody> createState() => _LobbyBodyState();
}

class _LobbyBodyState extends State<_LobbyBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartsNudge;
  Timer? _heartsNudgeTimer;

  @override
  void initState() {
    super.initState();
    _heartsNudge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _heartsNudgeTimer?.cancel();
    _heartsNudge.dispose();
    super.dispose();
  }

  void _nudgeEmptyHearts() {
    _heartsNudgeTimer?.cancel();
    _heartsNudge.repeat(reverse: true);
    _heartsNudgeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _heartsNudge.stop();
      _heartsNudge.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = widget.l10n;
    final onDark = widget.onDark;
    final pulse = widget.pulse;
    final playerName = widget.playerName;
    final profile = controller.profile;
    final bronze = _HilalPalette.bronze(onDark);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => unawaited(widget.onBack()),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: bronze),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    l10n.hilalDuelTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _HilalPalette.ink(onDark),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.hilalDuelLanguageNote,
                    style: TextStyle(
                      color: _HilalPalette.muted(onDark),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 16),
        ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.04).animate(
            CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size.square(72),
              painter: _CrescentPainter(color: bronze, stroke: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: Tween(begin: 0.75, end: 1.0).animate(pulse),
          child: CustomPaint(
            painter: _ArchMotifPainter(bronze: bronze, onDark: onDark),
            child: const SizedBox(height: 28, width: double.infinity),
          ),
        ),
        const SizedBox(height: 18),
        if (profile != null)
          _GamePlayerBanner(
            profile: profile,
            playerName: playerName,
            l10n: l10n,
            onDark: onDark,
            heartsAttention: _heartsNudge,
            onHeartsTap: profile.premium
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    unawaited(controller.watchHeartAd());
                  },
          ),
        const SizedBox(height: 14),
        _RulesCard(
          text: l10n.hilalDuelRulesSummary,
          onDark: onDark,
        ),
        if (controller.errorMessage != null &&
            controller.errorMessage !=
                HilalDuelController.needHeartErrorToken) ...[
          const SizedBox(height: 12),
          _LobbyErrorBanner(
            message: controller.errorMessage!,
            onDark: onDark,
          ),
        ],
        const SizedBox(height: 26),
        _PrimaryButton(
          label: l10n.hilalDuelPlay.toUpperCase(),
          busy: controller.busy,
          onDark: onDark,
          tall: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            final p = controller.profile;
            if (p != null && !p.premium && p.hearts <= 0) {
              _nudgeEmptyHearts();
              unawaited(
                _promptNeedHeartDialog(
                  context: context,
                  l10n: l10n,
                  controller: controller,
                ),
              );
              return;
            }
            unawaited(controller.startMatchmaking());
          },
        ),
        if (profile != null && !profile.premium) ...[
          const SizedBox(height: 12),
          _SecondaryButton(
            label: l10n.hilalDuelWatchAdForHeart,
            busy: controller.busy,
            onDark: onDark,
            onTap: () => unawaited(controller.watchHeartAd()),
          ),
          const SizedBox(height: 10),
          _SecondaryButton(
            label: l10n.hilalDuelUpgradePremium,
            busy: controller.busy,
            onDark: onDark,
            onTap: () => context.push(AppRoutes.premium),
          ),
        ],
        if (profile?.premium == true) ...[
          const SizedBox(height: 14),
          Text(
            l10n.hilalDuelPremiumUnlimited,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bronze,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (profile != null) ...[
          const SizedBox(height: 22),
          _WeeklyLeaderCard(
            profile: profile,
            controller: controller,
            l10n: l10n,
            onDark: onDark,
          ),
        ],
      ],
    );
  }
}

/// Oyun lobisi oyuncu paneli — isim uygulama profilinden gelir.
class _GamePlayerBanner extends StatelessWidget {
  const _GamePlayerBanner({
    required this.profile,
    required this.playerName,
    required this.l10n,
    required this.onDark,
    required this.heartsAttention,
    this.onHeartsTap,
  });

  final HilalDuelProfile profile;
  final String playerName;
  final AppLocalizations l10n;
  final bool onDark;
  final AnimationController heartsAttention;
  final VoidCallback? onHeartsTap;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    const emerald = AppColors.emeraldMid;
    final progress = profile.levelProgress.clamp(0.0, 1.0);
    final title = _localizedHilalTitle(l10n, profile.title);
    final nameColor = profile.nameAccent
        ? bronze
        : _HilalPalette.ink(onDark);
    final frameColor = profile.avatarFrame
        ? const Color(0xFFE0B35A)
        : bronze;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? const [
                  Color(0xFF0B1611),
                  Color(0xFF142820),
                  Color(0xFF1C3428),
                ]
              : [AppColors.creamSurface, Colors.white.withValues(alpha: 0.94)],
        ),
        border: Border.all(color: bronze.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: emerald.withValues(alpha: onDark ? 0.22 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: frameColor,
                        width: profile.avatarFrame ? 3.2 : 2,
                      ),
                      boxShadow: profile.avatarFrame
                          ? [
                              BoxShadow(
                                color: frameColor.withValues(alpha: 0.45),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          emerald.withValues(alpha: 0.55),
                          bronze.withValues(alpha: 0.45),
                          const Color(0xFF0E1A14),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomPaint(
                      size: const Size.square(28),
                      painter: _CrescentPainter(
                        color: profile.specialHilalIcon
                            ? const Color(0xFFE0B35A)
                            : bronze,
                        stroke: false,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: bronze,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: onDark
                              ? const Color(0xFF0B1611)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'LV ${profile.level}',
                        style: TextStyle(
                          color: onDark
                              ? const Color(0xFF1A1208)
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: nameColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: TextStyle(
                          color: bronze,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(
                          label: l10n.hilalDuelHilalsLabel(profile.hilals),
                          onDark: onDark,
                          accent: bronze,
                          leading: profile.specialHilalIcon
                              ? Icon(
                                  Icons.brightness_2_rounded,
                                  size: 14,
                                  color: bronze,
                                )
                              : null,
                        ),
                        _HeartsChip(
                          hearts: profile.hearts,
                          premium: profile.premium,
                          label: profile.premium
                              ? l10n.hilalDuelPremiumUnlimited
                              : l10n.hilalDuelHeartsLabel(profile.hearts),
                          onDark: onDark,
                          attention: heartsAttention,
                          onTap: onHeartsTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: bronze.withValues(alpha: 0.16),
                    color: bronze,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                profile.maxLevel
                    ? 'MAX'
                    : '${(progress * 100).round()}%',
                style: TextStyle(
                  color: bronze,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _nextRewardLabel(l10n, profile.level, profile.maxLevel),
              style: TextStyle(
                color: _HilalPalette.muted(onDark),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sıra teması: 1–10 yeşil, orta bronz/gri, sonlar kırmızı.
class _WeeklyRankTheme {
  const _WeeklyRankTheme({
    required this.accent,
    required this.fillA,
    required this.fillB,
  });

  final Color accent;
  final Color fillA;
  final Color fillB;

  static _WeeklyRankTheme forRank(int rank, bool onDark, {int boardSize = 0}) {
    final isLastBand = rank > 0 &&
        ((boardSize >= 6 && rank >= boardSize - 2) || rank >= 18);
    if (rank > 0 && rank <= 10) {
      return _WeeklyRankTheme(
        accent: const Color(0xFF3CB371),
        fillA: onDark ? const Color(0xFF0E1F16) : const Color(0xFFE8F7EE),
        fillB: onDark ? const Color(0xFF163528) : const Color(0xFFD5F0E0),
      );
    }
    if (isLastBand) {
      return _WeeklyRankTheme(
        accent: const Color(0xFFE57373),
        fillA: onDark ? const Color(0xFF241314) : const Color(0xFFFFF0F0),
        fillB: onDark ? const Color(0xFF331A1C) : const Color(0xFFFFE2E2),
      );
    }
    final bronze = _HilalPalette.bronze(onDark);
    return _WeeklyRankTheme(
      accent: bronze,
      fillA: onDark ? const Color(0xFF1A140C) : const Color(0xFFFFF6E8),
      fillB: onDark ? const Color(0xFF2A2116) : const Color(0xFFFFF0D8),
    );
  }
}

class _WeeklyLeaderCard extends StatefulWidget {
  const _WeeklyLeaderCard({
    required this.profile,
    required this.controller,
    required this.l10n,
    required this.onDark,
  });

  final HilalDuelProfile profile;
  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;

  @override
  State<_WeeklyLeaderCard> createState() => _WeeklyLeaderCardState();
}

class _WeeklyLeaderCardState extends State<_WeeklyLeaderCard> {
  late Future<HilalDuelWeeklyBoard> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = widget.controller.loadWeeklyLeaderboard();
  }

  @override
  void didUpdateWidget(covariant _WeeklyLeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.weeklyHilals != widget.profile.weeklyHilals ||
        oldWidget.profile.weeklyRank != widget.profile.weeklyRank) {
      _previewFuture = widget.controller.loadWeeklyLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final l10n = widget.l10n;
    final onDark = widget.onDark;
    final selfRank = profile.weeklyRank;
    final theme = _WeeklyRankTheme.forRank(selfRank, onDark);
    final rankText = selfRank > 0
        ? l10n.hilalDuelWeeklyRank(selfRank)
        : l10n.hilalDuelWeeklyRankNone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => unawaited(_openBoard(context)),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.fillA, theme.fillB],
            ),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accent.withValues(alpha: onDark ? 0.22 : 0.18),
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.75),
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: theme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.hilalDuelWeeklyTitle,
                      style: TextStyle(
                        color: _HilalPalette.ink(onDark),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.accent.withValues(alpha: 0.85),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: theme.accent.withValues(alpha: onDark ? 0.28 : 0.2),
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.75),
                      ),
                    ),
                    child: Text(
                      rankText,
                      style: TextStyle(
                        color: onDark ? Colors.white : theme.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.hilalDuelWeeklyThisWeek(profile.weeklyHilals),
                      style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.hilalDuelWeeklyClimbHint,
                style: TextStyle(
                  color: _HilalPalette.muted(onDark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<HilalDuelWeeklyBoard>(
                future: _previewFuture,
                builder: (context, snap) {
                  final top = snap.data?.top.take(3).toList(growable: false) ??
                      const <HilalDuelWeeklyEntry>[];
                  if (snap.connectionState != ConnectionState.done) {
                    return SizedBox(
                      height: 72,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.accent,
                          ),
                        ),
                      ),
                    );
                  }
                  if (top.isEmpty) {
                    return Text(
                      l10n.hilalDuelWeeklyEmpty,
                      style: TextStyle(
                        color: _HilalPalette.muted(onDark),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.hilalDuelWeeklyTopPreview,
                        style: TextStyle(
                          color: theme.accent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...top.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _WeeklyPreviewRow(
                            entry: entry,
                            onDark: onDark,
                            boardSize: snap.data?.top.length ?? 0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                l10n.hilalDuelWeeklyTapHint,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: _HilalPalette.muted(onDark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBoard(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeeklyLeaderSheet(
        controller: widget.controller,
        l10n: widget.l10n,
        onDark: widget.onDark,
        fallbackWeekly: widget.profile.weeklyHilals,
        fallbackRank: widget.profile.weeklyRank,
      ),
    );
  }
}

class _WeeklyPreviewRow extends StatelessWidget {
  const _WeeklyPreviewRow({
    required this.entry,
    required this.onDark,
    required this.boardSize,
  });

  final HilalDuelWeeklyEntry entry;
  final bool onDark;
  final int boardSize;

  @override
  Widget build(BuildContext context) {
    final theme = _WeeklyRankTheme.forRank(
      entry.rank,
      onDark,
      boardSize: boardSize,
    );
    final podium = entry.rank == 1
        ? const Color(0xFFE0B35A)
        : entry.rank == 2
            ? const Color(0xFFB0BEC5)
            : entry.rank == 3
                ? const Color(0xFFC48A5A)
                : theme.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: podium.withValues(alpha: onDark ? 0.14 : 0.12),
        border: Border.all(color: podium.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: podium,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: entry.isSelf
                    ? podium
                    : _HilalPalette.ink(onDark),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${entry.weeklyHilals}',
            style: TextStyle(
              color: podium,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyLeaderSheet extends StatefulWidget {
  const _WeeklyLeaderSheet({
    required this.controller,
    required this.l10n,
    required this.onDark,
    required this.fallbackWeekly,
    required this.fallbackRank,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;
  final int fallbackWeekly;
  final int fallbackRank;

  @override
  State<_WeeklyLeaderSheet> createState() => _WeeklyLeaderSheetState();
}

class _WeeklyLeaderSheetState extends State<_WeeklyLeaderSheet> {
  late Future<HilalDuelWeeklyBoard> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadWeeklyLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(widget.onDark);
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: widget.onDark ? const Color(0xFF101814) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: bronze.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              widget.l10n.hilalDuelWeeklyTitle,
              style: TextStyle(
                color: _HilalPalette.ink(widget.onDark),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<HilalDuelWeeklyBoard>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || snap.data == null) {
                  return Center(
                    child: Text(
                      widget.l10n.hilalDuelRetry,
                      style: TextStyle(
                        color: _HilalPalette.muted(widget.onDark),
                      ),
                    ),
                  );
                }
                final board = snap.data!;
                final selfRank = board.selfRank > 0
                    ? board.selfRank
                    : widget.fallbackRank;
                final selfWeekly = board.top.isEmpty && board.selfWeeklyHilals == 0
                    ? widget.fallbackWeekly
                    : board.selfWeeklyHilals;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(
                      selfRank > 0
                          ? widget.l10n.hilalDuelWeeklyYourPlace(
                              selfRank,
                              selfWeekly,
                            )
                          : widget.l10n.hilalDuelWeeklyThisWeek(selfWeekly),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: bronze,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (board.top.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          widget.l10n.hilalDuelWeeklyEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _HilalPalette.muted(widget.onDark),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...board.top.map((entry) {
                        final title = _localizedHilalTitle(
                          widget.l10n,
                          entry.title,
                        );
                        final rankTheme = _WeeklyRankTheme.forRank(
                          entry.rank,
                          widget.onDark,
                          boardSize: board.top.length,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                rankTheme.fillA.withValues(
                                  alpha: widget.onDark ? 0.85 : 0.95,
                                ),
                                rankTheme.fillB.withValues(
                                  alpha: widget.onDark ? 0.7 : 0.85,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: entry.isSelf
                                  ? rankTheme.accent.withValues(alpha: 0.9)
                                  : rankTheme.accent.withValues(alpha: 0.45),
                              width: entry.isSelf ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  '#${entry.rank}',
                                  style: TextStyle(
                                    color: rankTheme.accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: entry.nameAccent
                                            ? rankTheme.accent
                                            : _HilalPalette.ink(widget.onDark),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      [
                                        widget.l10n.hilalDuelLevelLabel(
                                          entry.level,
                                        ),
                                        if (title.isNotEmpty) title,
                                      ].join(' · '),
                                      style: TextStyle(
                                        color: _HilalPalette.muted(
                                          widget.onDark,
                                        ),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.weeklyHilals}',
                                style: TextStyle(
                                  color: rankTheme.accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.onDark,
    required this.accent,
    this.leading,
  });

  final String label;
  final bool onDark;
  final Color accent;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: onDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _HilalPalette.ink(onDark),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Can chip: 0'da kırmızı (statik); Rakip Bul'da 2 sn dikkat animasyonu.
class _HeartsChip extends StatelessWidget {
  const _HeartsChip({
    required this.hearts,
    required this.premium,
    required this.label,
    required this.onDark,
    required this.attention,
    this.onTap,
  });

  final int hearts;
  final bool premium;
  final String label;
  final bool onDark;
  final AnimationController attention;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final empty = !premium && hearts <= 0;
    const red = Color(0xFFE53935);
    const rose = Color(0xFFFF6B6B);
    final tone = premium
        ? AppColors.emeraldMid
        : empty
        ? red
        : rose;
    final textColor = empty
        ? Colors.white
        : (onDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF5C1A1A));

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        splashColor: tone.withValues(alpha: 0.35),
        highlightColor: tone.withValues(alpha: 0.18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: empty
                  ? [
                      red.withValues(alpha: onDark ? 0.95 : 0.92),
                      const Color(0xFFB71C1C),
                    ]
                  : [
                      tone.withValues(alpha: onDark ? 0.42 : 0.28),
                      tone.withValues(alpha: onDark ? 0.28 : 0.16),
                    ],
            ),
            border: Border.all(
              color: tone.withValues(alpha: empty ? 0.95 : 0.75),
              width: empty ? 1.6 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: empty ? 0.55 : 0.28),
                blurRadius: empty ? 14 : 8,
                spreadRadius: empty ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                empty
                    ? Icons.heart_broken_rounded
                    : Icons.favorite_rounded,
                size: 14,
                color: empty ? Colors.white : tone,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: empty ? Colors.white : textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: empty ? Colors.white : tone,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Sadece dikkat animasyonu aktifken hareket eder (sürekli nabız yok).
    return AnimatedBuilder(
      animation: attention,
      builder: (context, child) {
        if (!attention.isAnimating && attention.value == 0) {
          return child!;
        }
        final t = Curves.easeInOut.transform(attention.value);
        final scale = 0.96 + (0.12 * t);
        return Transform.scale(scale: scale, child: child);
      },
      child: chip,
    );
  }
}

class _LobbyErrorBanner extends StatelessWidget {
  const _LobbyErrorBanner({
    required this.message,
    required this.onDark,
  });

  final String message;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFE57373).withValues(alpha: onDark ? 0.16 : 0.12),
        border: Border.all(
          color: const Color(0xFFE57373).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: const Color(0xFFE57373).withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: onDark ? Colors.white : const Color(0xFF7A2E2E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.text, required this.onDark});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bronze.withValues(alpha: onDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bronze.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.quiz_rounded, color: bronze, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _HilalPalette.ink(onDark),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchmakingBody extends StatelessWidget {
  const _MatchmakingBody({
    super.key,
    required this.progress,
    required this.onCancel,
    required this.l10n,
    required this.onDark,
    required this.pulse,
    this.cancelFailed = false,
    this.errorMessage,
  });

  final double progress;
  final Future<void> Function() onCancel;
  final AppLocalizations l10n;
  final bool onDark;
  final AnimationController pulse;
  final bool cancelFailed;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => unawaited(onCancel()),
              child: Text(
                cancelFailed ? l10n.hilalDuelRetry : l10n.hilalDuelCancelSearch,
              ),
            ),
          ),
          const Spacer(),
          ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.05).animate(pulse),
            child: CustomPaint(
              size: const Size.square(88),
              painter: _CrescentPainter(color: bronze, stroke: false),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            cancelFailed ? l10n.hilalDuelCancelFailed : l10n.hilalDuelSearching,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HilalPalette.ink(onDark),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
          if (!cancelFailed) ...[
            const SizedBox(height: 26),
            _MatchmakingProgressBar(
              progress: progress,
              bronze: bronze,
              onDark: onDark,
              pulse: pulse,
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 15).clamp(0, 15).floor()} / 15',
              style: TextStyle(
                color: _HilalPalette.muted(onDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Rakip arama süresi — yumuşak doluş, bronz→zümrüt gradient, hafif ışıltı.
class _MatchmakingProgressBar extends StatelessWidget {
  const _MatchmakingProgressBar({
    required this.progress,
    required this.bronze,
    required this.onDark,
    required this.pulse,
  });

  final double progress;
  final Color bronze;
  final bool onDark;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    const emerald = AppColors.emeraldLight;
    final target = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      // begin yalnızca ilk frame'de kullanılır; sonraki tick'lerde mevcut
      // değerden yeni hedefe yumuşak geçiş yapılır.
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final fillWidth = (width * value).clamp(0.0, width);
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: bronze.withValues(alpha: onDark ? 0.12 : 0.1),
                      border: Border.all(
                        color: bronze.withValues(alpha: onDark ? 0.28 : 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: onDark ? 0.28 : 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  // Soft outer glow of the fill
                  if (fillWidth > 0)
                    Container(
                      width: fillWidth,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: bronze.withValues(
                              alpha: onDark ? 0.45 : 0.28,
                            ),
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  // Gradient fill + shimmer
                  if (fillWidth > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        width: fillWidth,
                        height: 10,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    bronze.withValues(alpha: 0.85),
                                    bronze,
                                    emerald.withValues(alpha: 0.95),
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                            // Moving highlight tied to the crescent pulse.
                            AnimatedBuilder(
                              animation: pulse,
                              builder: (context, _) {
                                final t = pulse.value;
                                return FractionallySizedBox(
                                  alignment: Alignment(-1.2 + (t * 2.4), 0),
                                  widthFactor: 0.38,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(
                                            alpha: onDark ? 0.34 : 0.42,
                                          ),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Leading tip cap for a finished feel while filling
                  if (fillWidth > 4)
                    Positioned(
                      left: (fillWidth - 8).clamp(0.0, width),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: onDark ? 0.55 : 0.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: emerald.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayingBody extends StatelessWidget {
  const _PlayingBody({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onDark,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    if (match == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bronze = _HilalPalette.bronze(onDark);
    final now = DateTime.now().millisecondsSinceEpoch;
    final resolution = match.lastResolution;
    // Cihaz saatine bağlı değil; controller yerel timer ile yönetir.
    final showReveal =
        controller.revealingResolution && resolution != null;

    final HilalDuelQuestion? question = showReveal
        ? resolution.question
        : match.question;
    final displayRound = showReveal
        ? resolution.round + 1
        : match.currentRound + 1;

    final remainingMs = showReveal
        ? 0
        : (match.deadlineMs - now).clamp(0, 20000);
    final seconds = showReveal ? 0 : (remainingMs / 1000).ceil();

    final selfName = l10n.hilalDuelYouLabel;
    final opponentName = _shortPlayerName(
      match.opponent.name,
      fallback: l10n.hilalDuelOpponentLabel,
    );

    final waiting =
        !showReveal &&
        (controller.awaitingOpponent ||
            ((controller.selectedChoice != null || match.selfAnswered) &&
                !match.opponentAnswered));

    return ListView(
      // Yan isim baloncukları taşabilsin diye yatay pay bırakılır.
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniPlayer(
                player: match.self,
                l10n: l10n,
                onDark: onDark,
                alignEnd: false,
                answered: match.selfAnswered || controller.selectedChoice != null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                size: const Size.square(26),
                painter: _CrescentPainter(color: bronze),
              ),
            ),
            Expanded(
              child: _MiniPlayer(
                player: match.opponent,
                l10n: l10n,
                onDark: onDark,
                alignEnd: true,
                answered: match.opponentAnswered,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: onDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.55),
                border: Border.all(color: bronze.withValues(alpha: 0.35)),
              ),
              child: Text(
                l10n.hilalDuelQuestionProgress(displayRound, match.totalRounds),
                style: TextStyle(
                  color: _HilalPalette.muted(onDark),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const Spacer(),
            _AlarmClockTimer(
              seconds: seconds,
              revealing: showReveal,
              onDark: onDark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: onDark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.62),
            border: Border.all(color: bronze.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (question?.category.isNotEmpty == true) ...[
                Text(
                  question!.category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bronze,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                question?.text ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _HilalPalette.ink(onDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(question?.options.length ?? 0, (index) {
          if (showReveal) {
            final correct = resolution.question.correctIndex ?? -1;
            final selfChoice = controller.choiceForRevealRound(resolution.round);
            final opponentChoice = resolution.choices[match.opponent.id];
            final selfPicked =
                selfChoice != null && selfChoice >= 0 && selfChoice == index;
            final opponentPicked = opponentChoice != null &&
                opponentChoice >= 0 &&
                opponentChoice == index;
            final isCorrect = index == correct;
            _OptionVisualState visual;
            if (isCorrect) {
              visual = _OptionVisualState.correct;
            } else if (selfPicked || opponentPicked) {
              visual = _OptionVisualState.wrong;
            } else {
              visual = _OptionVisualState.idle;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: question!.options[index],
                visual: visual,
                enabled: false,
                onDark: onDark,
                leftLabel: selfPicked ? selfName : null,
                rightLabel: opponentPicked ? opponentName : null,
                // Sen / rakip rozetleri şık rengiyle aynı olmasın (yeşilde kaybolmasın).
                leftChipColor: selfPicked ? const Color(0xFF1B4332) : null,
                rightChipColor: opponentPicked ? const Color(0xFF6D2E4B) : null,
                onTap: () {},
              ),
            );
          }

          final selected = controller.selectedChoice == index;
          // roundStartedAtMs ile kilitleme: yeni soru görünürken ölü buton hissi.
          // Reveal sırasında zaten showReveal dalı enabled:false.
          final locked = match.selfAnswered ||
              controller.selectedChoice != null ||
              controller.busy;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              label: question!.options[index],
              visual: selected
                  ? _OptionVisualState.waiting
                  : _OptionVisualState.idle,
              enabled: !locked,
              onDark: onDark,
              leftLabel: selected ? selfName : null,
              onTap: () {
                HapticFeedback.selectionClick();
                unawaited(controller.submitChoice(index));
              },
            ),
          );
        }),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: waiting
              ? Padding(
                  key: const ValueKey('waiting-opponent'),
                  padding: const EdgeInsets.only(top: 4),
                  child: _WaitingOpponentBanner(
                    label: l10n.hilalDuelWaitingOpponent,
                    onDark: onDark,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('waiting-idle')),
        ),
        if (showReveal &&
            resolution.question.explanation != null &&
            resolution.question.explanation!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            resolution.question.explanation!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HilalPalette.muted(onDark),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Cevapların hemen altında: rakip beklerken yumuşak nabız + nokta animasyonu.
class _WaitingOpponentBanner extends StatefulWidget {
  const _WaitingOpponentBanner({
    required this.label,
    required this.onDark,
  });

  final String label;
  final bool onDark;

  @override
  State<_WaitingOpponentBanner> createState() => _WaitingOpponentBannerState();
}

class _WaitingOpponentBannerState extends State<_WaitingOpponentBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(widget.onDark);
    final ink = widget.onDark ? Colors.white : const Color(0xFF5C3A1E);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final glow = 0.14 + (0.12 * t);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                bronze.withValues(alpha: widget.onDark ? 0.34 : 0.22),
                bronze.withValues(alpha: widget.onDark ? 0.22 + glow : 0.12 + glow),
                bronze.withValues(alpha: widget.onDark ? 0.34 : 0.22),
              ],
            ),
            border: Border.all(
              color: bronze.withValues(alpha: 0.45 + (0.25 * t)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: bronze.withValues(alpha: widget.onDark ? 0.18 * t : 0.12 * t),
                blurRadius: 10 + (6 * t),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 16,
            color: ink.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _WaitingDots(color: ink, animation: _pulse),
        ],
      ),
    );
  }
}

class _WaitingDots extends StatelessWidget {
  const _WaitingDots({
    required this.color,
    required this.animation,
  });

  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (animation.value + (i * 0.22)) % 1.0;
            final lift = Curves.easeInOut.transform(phase);
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
              child: Opacity(
                opacity: 0.35 + (0.65 * lift),
                child: Transform.translate(
                  offset: Offset(0, -2.2 * lift),
                  child: Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

enum _OptionVisualState { idle, waiting, correct, wrong }

class _AlarmClockTimer extends StatelessWidget {
  const _AlarmClockTimer({
    required this.seconds,
    required this.revealing,
    required this.onDark,
  });

  final int seconds;
  final bool revealing;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    final urgent = !revealing && seconds <= 5;
    final tone = urgent ? const Color(0xFFE57373) : bronze;
    final label = revealing ? '—' : '$seconds';

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.alarm_rounded,
            size: 56,
            color: tone.withValues(alpha: 0.95),
          ),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: urgent
                  ? const Color(0xFFB71C1C)
                  : (onDark ? const Color(0xFF2A1A0C) : Colors.white),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: urgent || onDark ? Colors.white : const Color(0xFF5C3A1E),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatefulWidget {
  const _ResultBody({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onDark,
    required this.playerName,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;
  final String playerName;

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    unawaited(_anim.forward());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final onDark = widget.onDark;
    final controller = widget.controller;
    final match = controller.match;
    final result = match?.result;
    final self = result?.players
        .where((p) => p.id == match?.self.id)
        .firstOrNull;
    final opponent = result?.players
        .where((p) => p.id == match?.opponent.id)
        .firstOrNull;
    final bronze = _HilalPalette.bronze(onDark);
    final winnerId = result?.winnerId;
    final isDraw = winnerId == null;
    final isWin = !isDraw && winnerId == match?.self.id;
    final title = isDraw
        ? l10n.hilalDuelResultDraw
        : isWin
        ? l10n.hilalDuelResultWin
        : l10n.hilalDuelResultLose;
    final cardColor = isDraw
        ? bronze
        : isWin
        ? const Color(0xFF2E9B5E)
        : const Color(0xFFD64545);
    final selfScore = self?.correct ?? 0;
    final opponentScore = opponent?.correct ?? 0;

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: onDark ? 0.45 : 0.28),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  child: Text(
                                    _nameInitial(
                                      widget.playerName,
                                      fallback: 'S',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.playerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  child: Text(
                                    _nameInitial(
                                      match?.opponent.name ?? '',
                                      fallback: 'R',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _shortPlayerName(
                                    match?.opponent.name ?? '',
                                    fallback: l10n.hilalDuelOpponentLabel,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '$selfScore-$opponentScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.hilalDuelResultScoreCaption,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (self != null) ...[
              _StatLine(
                label: l10n.hilalDuelCorrectCount(self.correct),
                onDark: onDark,
              ),
              _StatLine(
                label: l10n.hilalDuelTotalSeconds((self.elapsedMs / 1000).round()),
                onDark: onDark,
              ),
              _StatLine(
                label: l10n.hilalDuelHilalsEarned(
                  (controller.doubledThisMatch || match?.doubled == true)
                      ? self.hilalsAwarded * 2
                      : self.hilalsAwarded,
                ),
                onDark: onDark,
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 16),
            if (controller.profile?.premium != true &&
                !controller.doubledThisMatch &&
                match?.doubled != true &&
                (self?.hilalsAwarded ?? 0) > 0)
              _SecondaryButton(
                label: l10n.hilalDuelDoubleReward,
                busy: controller.busy,
                onDark: onDark,
                onTap: () => unawaited(controller.watchDoubleAd()),
              )
            else if (controller.doubledThisMatch || match?.doubled == true)
              Text(
                l10n.hilalDuelDoubled,
                textAlign: TextAlign.center,
                style: TextStyle(color: bronze, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            _PrimaryButton(
              label: l10n.hilalDuelRematch,
              busy: controller.busy,
              onDark: onDark,
              onTap: () {
                final p = controller.profile;
                if (p != null && !p.premium && p.hearts <= 0) {
                  unawaited(
                    _promptNeedHeartDialog(
                      context: context,
                      l10n: l10n,
                      controller: controller,
                    ),
                  );
                  return;
                }
                unawaited(controller.rematch());
              },
            ),
            const SizedBox(height: 10),
            _SecondaryButton(
              label: l10n.hilalDuelLobby,
              busy: controller.busy,
              onDark: onDark,
              onTap: () =>
                  unawaited(controller.returnToLobby(maybeInterstitial: true)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.onDark});
  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _HilalPalette.ink(onDark),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.player,
    required this.l10n,
    required this.onDark,
    required this.alignEnd,
    this.answered = false,
  });

  final HilalDuelPlayer player;
  final AppLocalizations l10n;
  final bool onDark;
  final bool alignEnd;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    final title = _localizedHilalTitle(l10n, player.title);
    final nameStyle = TextStyle(
      color: player.nameAccent ? bronze : _HilalPalette.ink(onDark),
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1.15,
    );
    // İsim satırı yüksekliği sabit — "Cevapladı" alta satır eklemez, soru kaymaz.
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignEnd) ...[
                Flexible(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                ),
                _AnsweredInlineMark(
                  visible: answered,
                  label: l10n.hilalDuelAnsweredBubble,
                  onDark: onDark,
                ),
              ] else ...[
                _AnsweredInlineMark(
                  visible: answered,
                  label: l10n.hilalDuelAnsweredBubble,
                  onDark: onDark,
                ),
                Flexible(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: nameStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (title.isNotEmpty)
          Text(
            title,
            style: TextStyle(
              color: bronze,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          '${l10n.hilalDuelLevelLabel(player.level)} · ${l10n.hilalDuelHilalsLabel(player.hilals)}',
          style: TextStyle(color: _HilalPalette.muted(onDark), fontSize: 11),
        ),
        if (player.isBot || player.badge != null)
          Text(
            player.badge ?? l10n.hilalDuelFastOpponent,
            style: TextStyle(
              color: bronze,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// İsim yanında küçük "Cevapladı" — yatayda açılır; dikey yükseklik sabit kalır.
class _AnsweredInlineMark extends StatelessWidget {
  const _AnsweredInlineMark({
    required this.visible,
    required this.label,
    required this.onDark,
  });

  final bool visible;
  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    const tone = AppColors.emeraldLight;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: visible
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 5, end: 5),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(label),
                tween: Tween(begin: 0.82, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: tone.withValues(alpha: onDark ? 0.22 : 0.16),
                    border: Border.all(color: tone.withValues(alpha: 0.85)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 11, color: tone),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          color: tone,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: 0, height: 18),
    );
  }
}

class _SideNameChip extends StatelessWidget {
  const _SideNameChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.visual,
    required this.enabled,
    required this.onDark,
    required this.onTap,
    this.leftLabel,
    this.rightLabel,
    this.leftChipColor,
    this.rightChipColor,
  });

  final String label;
  final _OptionVisualState visual;
  final bool enabled;
  final bool onDark;
  final VoidCallback onTap;
  final String? leftLabel;
  final String? rightLabel;
  final Color? leftChipColor;
  final Color? rightChipColor;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    const green = Color(0xFF3CB371);
    const red = Color(0xFFE57373);
    final idleFill = onDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.72);

    final Color fill;
    final Color border;
    final Color chipColor;
    switch (visual) {
      case _OptionVisualState.waiting:
        fill = bronze.withValues(alpha: onDark ? 0.72 : 0.88);
        border = bronze;
        chipColor = bronze;
        break;
      case _OptionVisualState.correct:
        fill = green.withValues(alpha: onDark ? 0.78 : 0.9);
        border = green;
        chipColor = green;
        break;
      case _OptionVisualState.wrong:
        fill = red.withValues(alpha: onDark ? 0.78 : 0.9);
        border = red;
        chipColor = red;
        break;
      case _OptionVisualState.idle:
        fill = idleFill;
        border = bronze.withValues(alpha: 0.35);
        chipColor = bronze;
        break;
    }

    final emphasized = visual != _OptionVisualState.idle;
    final textColor = emphasized
        ? Colors.white
        : _HilalPalette.ink(onDark);

    return Opacity(
      opacity: !enabled && visual == _OptionVisualState.idle ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  leftLabel != null ? 22 : 14,
                  14,
                  rightLabel != null ? 22 : 14,
                  14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border,
                    width: emphasized ? 1.8 : 1,
                  ),
                  color: fill,
                  boxShadow: emphasized
                      ? [
                          BoxShadow(
                            color: border.withValues(alpha: onDark ? 0.35 : 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (leftLabel != null)
                Positioned(
                  left: -6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _SideNameChip(
                      label: leftLabel!,
                      color: leftChipColor ?? chipColor,
                    ),
                  ),
                ),
              if (rightLabel != null)
                Positioned(
                  right: -6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _SideNameChip(
                      label: rightLabel!,
                      color: rightChipColor ?? chipColor,
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

String _shortPlayerName(String name, {required String fallback}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.split(RegExp(r'\s+')).first;
}


class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.onDark,
    required this.busy,
    this.tall = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool onDark;
  final bool busy;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    return SizedBox(
      width: double.infinity,
      height: tall ? 56 : 48,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldMid,
          foregroundColor: Colors.white,
          elevation: tall ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tall ? 16 : 14),
            side: BorderSide(
              color: bronze.withValues(alpha: 0.65),
              width: tall ? 1.4 : 1,
            ),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: tall ? 16 : 14,
                  letterSpacing: tall ? 1.1 : 0.2,
                ),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
    required this.onDark,
    required this.busy,
  });

  final String label;
  final VoidCallback onTap;
  final bool onDark;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _HilalPalette.ink(onDark),
          side: BorderSide(color: bronze.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
    required this.l10n,
    required this.onDark,
  });

  final String message;
  final Future<void> Function() onRetry;
  final AppLocalizations l10n;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _HilalPalette.ink(onDark), fontSize: 15),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: l10n.hilalDuelRetry,
            onTap: () => unawaited(onRetry()),
            onDark: onDark,
            busy: false,
          ),
        ],
      ),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  const _CrescentPainter({required this.color, this.stroke = true});

  final Color color;
  final bool stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.shortestSide * 0.36;
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(c.dx + r * 0.38, c.dy - r * 0.06),
          radius: r * 0.78,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    final paint = Paint()
      ..color = color
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

class _ArchMotifPainter extends CustomPainter {
  const _ArchMotifPainter({required this.bronze, required this.onDark});

  final Color bronze;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bronze.withValues(alpha: onDark ? 0.55 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final mid = size.width / 2;
    final path = Path()
      ..moveTo(mid - 70, size.height)
      ..quadraticBezierTo(mid - 40, 4, mid, 4)
      ..quadraticBezierTo(mid + 40, 4, mid + 70, size.height);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(mid, 8), 2.2, Paint()..color = bronze);
  }

  @override
  bool shouldRepaint(covariant _ArchMotifPainter oldDelegate) =>
      oldDelegate.bronze != bronze || oldDelegate.onDark != onDark;
}
