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
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/user_profile_providers.dart';
import '../../shared/widgets/arin_permission_dialog.dart';
import '../../shared/widgets/arin_shell_layout.dart';
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
                      // İptal → lobi geçişi kısa tutulsun (anlık tepki).
                      duration: const Duration(milliseconds: 120),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
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
            HapticFeedback.lightImpact();
            // await yok: controller zaten senkron lobiye alır; RPC arkada.
            if (c.phase == HilalDuelPhase.cancelRetry) {
              unawaited(c.retryCancel());
              return;
            }
            unawaited(c.cancelMatchmaking());
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
  if (lower.contains('müderris') ||
      lower.contains('muderris') ||
      lower.contains('mudarris') ||
      lower.contains('مدر')) {
    return l10n.hilalDuelTitleMuderris;
  }
  if (lower.contains('talebe') || lower.contains('student') || lower.contains('طالب')) {
    return l10n.hilalDuelTitleTalebe;
  }
  return raw;
}

String _localizedTitleForLevel(
  AppLocalizations l10n,
  int level, {
  bool isBot = false,
}) {
  if (isBot) return '';
  return _localizedHilalTitle(l10n, titleForLevel(level));
}

Color _hilalNameColor({
  required int level,
  required bool onDark,
  required Color bronze,
  bool isBot = false,
  Color? fullOverride,
}) {
  final cosmetics = cosmeticsForLevel(level, isBot: isBot);
  switch (cosmetics.nameAccent) {
    case HilalDuelNameAccent.full:
      return fullOverride ?? bronze;
    case HilalDuelNameAccent.soft:
      return Color.lerp(
        _HilalPalette.ink(onDark),
        bronze,
        onDark ? 0.52 : 0.64,
      )!;
    case HilalDuelNameAccent.faint:
      return Color.lerp(
        _HilalPalette.ink(onDark),
        bronze,
        onDark ? 0.30 : 0.36,
      )!;
    case HilalDuelNameAccent.none:
      return _HilalPalette.ink(onDark);
  }
}

String _hilalDifficultyLabel(AppLocalizations l10n, int difficulty) {
  switch (difficulty) {
    case 1:
      return l10n.hilalDuelDifficultyEasy;
    case 3:
      return l10n.hilalDuelDifficultyHard;
    default:
      return l10n.hilalDuelDifficultyMedium;
  }
}

String _nextRewardLabel(AppLocalizations l10n, int level, bool maxLevel) {
  if (maxLevel) return l10n.hilalDuelMaxLevel;
  final next = nextRewardAfterLevel(level);
  if (next == null) return l10n.hilalDuelMaxLevel;
  switch (next.kind) {
    case HilalDuelRewardKind.frame:
      return l10n.hilalDuelNextRewardFrame(next.level);
    case HilalDuelRewardKind.frameSilver:
      return l10n.hilalDuelNextRewardFrameSilver(next.level);
    case HilalDuelRewardKind.titleTalebe:
      return l10n.hilalDuelNextRewardTitle(
        l10n.hilalDuelTitleTalebe,
        next.level,
      );
    case HilalDuelRewardKind.avatarGlow:
      return l10n.hilalDuelNextRewardGlow(next.level);
    case HilalDuelRewardKind.nameAccentSoft:
      return l10n.hilalDuelNextRewardNameAccent(next.level);
    case HilalDuelRewardKind.specialHilal:
      return l10n.hilalDuelNextRewardHilalIcon(next.level);
    case HilalDuelRewardKind.titleMuderris:
      return l10n.hilalDuelNextRewardTitle(
        l10n.hilalDuelTitleMuderris,
        next.level,
      );
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

class _LobbyBody extends ConsumerStatefulWidget {
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
  ConsumerState<_LobbyBody> createState() => _LobbyBodyState();
}

class _LobbyBodyState extends ConsumerState<_LobbyBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartsNudge;
  Timer? _heartsNudgeTimer;
  bool _challengeSentDialogQueued = false;

  @override
  void initState() {
    super.initState();
    _heartsNudge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    widget.controller.addListener(_onLobbyController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowChallengeSentDialog();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLobbyController);
    _heartsNudgeTimer?.cancel();
    _heartsNudge.dispose();
    super.dispose();
  }

  void _onLobbyController() {
    if (!mounted) return;
    _maybeShowChallengeSentDialog();
  }

  void _maybeShowChallengeSentDialog() {
    if (_challengeSentDialogQueued) return;
    if (widget.controller.challengeSentNoticeOpponentName == null) return;
    _challengeSentDialogQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final name = widget.controller.consumeChallengeSentNotice();
      _challengeSentDialogQueued = false;
      if (name == null || !mounted) return;
      final onDark = widget.onDark;
      final bronze = _HilalPalette.bronze(onDark);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: onDark ? const Color(0xFF101814) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: bronze.withValues(alpha: 0.45)),
          ),
          icon: Icon(Icons.hourglass_top_rounded, color: bronze, size: 32),
          title: Text(
            widget.l10n.hilalDuelChallengeSentTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HilalPalette.ink(onDark),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          content: Text(
            widget.l10n.hilalDuelChallengeSentBody(name),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HilalPalette.muted(onDark),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                widget.l10n.hilalDuelChallengeSentOk,
                style: TextStyle(
                  color: bronze,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    });
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

  Future<void> _openChallengePicker() async {
    final profile = widget.controller.profile;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeeklyLeaderSheet(
        controller: widget.controller,
        l10n: widget.l10n,
        onDark: widget.onDark,
        fallbackWeekly: profile?.weeklyHilals ?? 0,
        fallbackRank: profile?.weeklyRank ?? 0,
        challengePickMode: true,
      ),
    );
  }

  Future<void> _promptAdminGrantHilals() async {
    final onDark = widget.onDark;
    final bronze = _HilalPalette.bronze(onDark);
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: onDark ? const Color(0xFF101814) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: bronze.withValues(alpha: 0.45)),
        ),
        title: Text(
          'Admin · Hilal ekle',
          style: TextStyle(
            color: _HilalPalette.ink(onDark),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Kendi toplam ve haftalık puanına eklenir.',
          style: TextStyle(
            color: _HilalPalette.muted(onDark),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          for (final n in const [10, 50, 100])
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(n),
              child: Text(
                '+$n',
                style: TextStyle(
                  color: bronze,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.l10n.commonCancel,
              style: TextStyle(
                color: _HilalPalette.muted(onDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (amount == null || !mounted) return;
    HapticFeedback.mediumImpact();
    await widget.controller.adminGrantSelfHilals(amount);
  }

  Future<void> _promptAdminSetLevel() async {
    final onDark = widget.onDark;
    final bronze = _HilalPalette.bronze(onDark);
    final current = widget.controller.profile?.level ?? 1;
    final level = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: onDark ? const Color(0xFF101814) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: bronze.withValues(alpha: 0.45)),
        ),
        title: Text(
          'Admin · Seviye ayarla',
          style: TextStyle(
            color: _HilalPalette.ink(onDark),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Toplam hilal seviye tabanına çekilir. Haftalık skor değişmez.',
              style: TextStyle(
                color: _HilalPalette.muted(onDark),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var n = 1; n <= kHilalDuelMaxLevel; n += 1)
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: n == current
                          ? bronze.withValues(alpha: 0.22)
                          : null,
                      foregroundColor: bronze,
                      minimumSize: const Size(44, 40),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(n),
                    child: Text(
                      'LV$n',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: bronze,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.l10n.commonCancel,
              style: TextStyle(
                color: _HilalPalette.muted(onDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (level == null || !mounted) return;
    HapticFeedback.mediumImpact();
    await widget.controller.adminSetSelfLevel(level);
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
    final isAdmin =
        ref.watch(isCurrentUserAdminProvider).asData?.value ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.hilalDuelLanguageNote,
                    style: TextStyle(
                      color: _HilalPalette.muted(onDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.03).animate(
            CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size.square(44),
              painter: _CrescentPainter(color: bronze, stroke: false),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeTransition(
          opacity: Tween(begin: 0.75, end: 1.0).animate(pulse),
          child: CustomPaint(
            painter: _ArchMotifPainter(bronze: bronze, onDark: onDark),
            child: const SizedBox(height: 18, width: double.infinity),
          ),
        ),
        const SizedBox(height: 10),
        if (profile != null)
          _GamePlayerBanner(
            profile: profile,
            playerName: playerName,
            l10n: l10n,
            onDark: onDark,
            heartsAttention: _heartsNudge,
            onHilalsTap: isAdmin
                ? () => unawaited(_promptAdminGrantHilals())
                : null,
            onLevelTap: isAdmin
                ? () => unawaited(_promptAdminSetLevel())
                : null,
            onHeartsTap: profile.premium
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    unawaited(controller.watchHeartAd());
                  },
          ),
        const SizedBox(height: 10),
        _RulesCard(
          text: l10n.hilalDuelRulesSummary,
          onDark: onDark,
        ),
        if (controller.errorMessage != null &&
            controller.errorMessage !=
                HilalDuelController.needHeartErrorToken) ...[
          const SizedBox(height: 8),
          _LobbyErrorBanner(
            message: controller.errorMessage!,
            onDark: onDark,
          ),
        ],
        const SizedBox(height: 14),
        _PrimaryButton(
          label: l10n.hilalDuelPlay.toUpperCase(),
          busy: controller.busy,
          onDark: onDark,
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
        const SizedBox(height: 8),
        _ChallengeLobbyButton(
          label: l10n.hilalDuelChallengeAction.toUpperCase(),
          busy: controller.busy,
          onDark: onDark,
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
            unawaited(_openChallengePicker());
          },
        ),
        if (profile != null && !profile.premium) ...[
          const SizedBox(height: 8),
          _SecondaryButton(
            label: l10n.hilalDuelWatchAdForHeart,
            busy: controller.busy,
            onDark: onDark,
            onTap: () => unawaited(controller.watchHeartAd()),
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: l10n.hilalDuelUpgradePremium,
            busy: controller.busy,
            onDark: onDark,
            onTap: () => context.push(AppRoutes.premium),
          ),
        ],
        if (profile?.premium == true) ...[
          const SizedBox(height: 10),
          Text(
            l10n.hilalDuelPremiumUnlimited,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bronze,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (controller.challenges.any((c) => c.isInboxVisible)) ...[
          const SizedBox(height: 14),
          _ChallengeInboxCard(
            controller: controller,
            l10n: l10n,
            onDark: onDark,
            onNeedHeart: _nudgeEmptyHearts,
          ),
        ],
        if (profile != null) ...[
          const SizedBox(height: 14),
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

class _ChallengeInboxCard extends StatelessWidget {
  const _ChallengeInboxCard({
    required this.controller,
    required this.l10n,
    required this.onDark,
    required this.onNeedHeart,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;
  final VoidCallback onNeedHeart;

  String _statusLabel(HilalDuelChallengeSummary item) {
    if (item.status == 'expired') return l10n.hilalDuelChallengeExpired;
    if (item.status == 'completed') {
      switch (item.outcome) {
        case 'won':
          return l10n.hilalDuelResultWin;
        case 'lost':
          return l10n.hilalDuelResultLose;
        case 'draw':
          return l10n.hilalDuelResultDraw;
        default:
          return l10n.hilalDuelChallengeSeeResult;
      }
    }
    if (item.canAccept) return l10n.hilalDuelChallengeAccept;
    if (item.myTurn) return l10n.hilalDuelChallengeYourTurn;
    return l10n.hilalDuelChallengeWaiting;
  }

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    final open = controller.challenges.where((c) => c.isInboxVisible).toList();
    if (open.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bronze.withValues(alpha: 0.45)),
        color: onDark
            ? const Color(0xFF101814)
            : Colors.white.withValues(alpha: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.hilalDuelChallengeInboxTitle,
            style: TextStyle(
              color: _HilalPalette.ink(onDark),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...open.take(5).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.opponentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _HilalPalette.ink(onDark),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _statusLabel(item),
                          style: TextStyle(
                            color: bronze,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.canAccept || item.myTurn || item.status == 'completed')
                    TextButton(
                      onPressed: controller.busy
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              final p = controller.profile;
                              if (item.canAccept &&
                                  p != null &&
                                  !p.premium &&
                                  p.hearts <= 0) {
                                onNeedHeart();
                                unawaited(
                                  _promptNeedHeartDialog(
                                    context: context,
                                    l10n: l10n,
                                    controller: controller,
                                  ),
                                );
                                return;
                              }
                              unawaited(controller.openChallenge(item.id));
                            },
                      child: Text(
                        item.status == 'completed'
                            ? l10n.hilalDuelChallengeSeeResult
                            : item.canAccept
                            ? l10n.hilalDuelChallengeAccept
                            : l10n.hilalDuelChallengeContinue,
                        style: TextStyle(
                          color: bronze,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Seviye kozmetiği: bronz çerçeve (3), gümüş çift halka (4), hale (6).
class _HilalRankAvatar extends StatelessWidget {
  const _HilalRankAvatar({
    required this.level,
    required this.size,
    required this.child,
    required this.onDark,
    required this.fillColors,
    this.answeredGlow,
    this.fallbackBorder,
  });

  final int level;
  final double size;
  final Widget child;
  final bool onDark;
  final List<Color> fillColors;
  final Color? answeredGlow;
  final Color? fallbackBorder;

  static const _gold = Color(0xFFE0B35A);
  static const _silver = Color(0xFFB0BEC5);

  @override
  Widget build(BuildContext context) {
    final cosmetics = cosmeticsForLevel(level);
    final bronze = _HilalPalette.bronze(onDark);
    final shadows = <BoxShadow>[
      if (cosmetics.avatarGlow)
        BoxShadow(
          color: _gold.withValues(alpha: onDark ? 0.62 : 0.48),
          blurRadius: size * 0.42,
          spreadRadius: 1.2,
        )
      else if (cosmetics.frameTier >= 1)
        BoxShadow(
          color: (cosmetics.frameTier >= 2 ? _gold : bronze)
              .withValues(alpha: 0.45),
          blurRadius: 10,
        ),
      if (answeredGlow != null)
        BoxShadow(
          color: answeredGlow!,
          blurRadius: 12,
        ),
    ];

    final fill = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fillColors,
        ),
      ),
      child: Center(child: child),
    );

    if (cosmetics.frameTier >= 2) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _silver, width: 2),
          boxShadow: shadows.isEmpty ? null : shadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 2),
            ),
            child: ClipOval(child: fill),
          ),
        ),
      );
    }

    final borderColor = cosmetics.frameTier >= 1
        ? _gold
        : (fallbackBorder ?? bronze);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: cosmetics.frameTier >= 1 ? 3.2 : (fallbackBorder != null ? 1.5 : 2),
        ),
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: ClipOval(child: fill),
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
    this.onHilalsTap,
    this.onLevelTap,
  });

  final HilalDuelProfile profile;
  final String playerName;
  final AppLocalizations l10n;
  final bool onDark;
  final AnimationController heartsAttention;
  final VoidCallback? onHeartsTap;
  final VoidCallback? onHilalsTap;
  final VoidCallback? onLevelTap;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    const emerald = AppColors.emeraldMid;
    final progress = profile.levelProgress.clamp(0.0, 1.0);
    final cosmetics = cosmeticsForLevel(profile.level);
    final title = _localizedTitleForLevel(
      l10n,
      profile.level,
    );
    final nameColor = _hilalNameColor(
      level: profile.level,
      onDark: onDark,
      bronze: bronze,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
        border: Border.all(color: bronze.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: emerald.withValues(alpha: onDark ? 0.18 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  _HilalRankAvatar(
                    level: profile.level,
                    size: 52,
                    onDark: onDark,
                    fillColors: [
                      emerald.withValues(alpha: 0.55),
                      bronze.withValues(alpha: 0.45),
                      const Color(0xFF0E1A14),
                    ],
                    child: CustomPaint(
                      size: const Size.square(22),
                      painter: _CrescentPainter(
                        color: cosmetics.specialHilalIcon
                            ? const Color(0xFFE0B35A)
                            : bronze,
                        stroke: false,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLevelTap == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onLevelTap!();
                              },
                        borderRadius: BorderRadius.circular(99),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: bronze,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: onDark
                                  ? const Color(0xFF0B1611)
                                  : Colors.white,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'LV ${profile.level}',
                            style: TextStyle(
                              color: onDark
                                  ? const Color(0xFF1A1208)
                                  : Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
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
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(
                          color: bronze,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatChip(
                          label: l10n.hilalDuelHilalsLabel(profile.hilals),
                          onDark: onDark,
                          accent: bronze,
                          onTap: onHilalsTap,
                          leading: cosmetics.specialHilalIcon
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

class _WeeklyLeaderCard extends ConsumerStatefulWidget {
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
  ConsumerState<_WeeklyLeaderCard> createState() => _WeeklyLeaderCardState();
}

class _WeeklyLeaderCardState extends ConsumerState<_WeeklyLeaderCard> {
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
    final isAdmin =
        ref.watch(isCurrentUserAdminProvider).asData?.value ?? false;
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
              const SizedBox(height: 4),
              Text(
                l10n.hilalDuelWeeklyPremiumRewardHint,
                style: TextStyle(
                  color: _HilalPalette.muted(onDark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<HilalDuelWeeklyBoard>(
                future: _previewFuture,
                builder: (context, snap) {
                  final board = snap.data;
                  final top = board?.top.take(3).toList(growable: false) ??
                      const <HilalDuelWeeklyEntry>[];
                  final winners = board?.lastWeekWinners ??
                      const <HilalDuelWeeklyLastWinner>[];
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
                  if (snap.hasError) {
                    return Text(
                      l10n.hilalDuelRetry,
                      style: TextStyle(
                        color: _HilalPalette.muted(onDark),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }
                  if (top.isEmpty && winners.isEmpty) {
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
                      if (winners.isNotEmpty) ...[
                        _LastWeekWinnersPromo(
                          winners: winners,
                          onDark: onDark,
                          l10n: l10n,
                          compact: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (top.isNotEmpty) ...[
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
                              boardSize: board?.top.length ?? 0,
                              showPremiumBadge: isAdmin && entry.premium,
                            ),
                          ),
                        ),
                      ],
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

bool _isWeeklyMaxLevel(HilalDuelWeeklyEntry entry) =>
    !entry.isBot && entry.level >= kHilalDuelMaxLevel;

/// Seviye 10 — sıralamada altın parıltı.
abstract final class _MaxLevelShine {
  static const gold = Color(0xFFE0B35A);
  static const goldDeep = Color(0xFFC4892A);
  static const goldSoft = Color(0xFFF0D080);

  static BoxDecoration rowDecoration({
    required bool onDark,
    required bool isSelf,
    BorderRadius? radius,
  }) {
    return BoxDecoration(
      borderRadius: radius ?? BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: onDark
            ? [
                gold.withValues(alpha: 0.28),
                goldDeep.withValues(alpha: 0.14),
                const Color(0xFF1A1408).withValues(alpha: 0.9),
              ]
            : [
                goldSoft.withValues(alpha: 0.55),
                gold.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.95),
              ],
      ),
      border: Border.all(
        color: gold.withValues(alpha: isSelf ? 0.95 : 0.75),
        width: isSelf ? 1.7 : 1.35,
      ),
      boxShadow: [
        BoxShadow(
          color: gold.withValues(alpha: onDark ? 0.42 : 0.28),
          blurRadius: 14,
          spreadRadius: 0.5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _MaxLevelBadge extends StatelessWidget {
  const _MaxLevelBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [_MaxLevelShine.goldSoft, _MaxLevelShine.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: _MaxLevelShine.gold.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 9 : 10,
            color: const Color(0xFF1A1208),
          ),
          SizedBox(width: compact ? 2 : 3),
          Text(
            'LV$kHilalDuelMaxLevel',
            style: TextStyle(
              color: const Color(0xFF1A1208),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 8.5 : 9.5,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

String _lastWeekWinnerPrize(AppLocalizations l10n, int rank) {
  switch (rank) {
    case 1:
      return l10n.hilalDuelWeeklyLastWinnerPrize1;
    case 2:
      return l10n.hilalDuelWeeklyLastWinnerPrize2;
    case 3:
      return l10n.hilalDuelWeeklyLastWinnerPrize3;
    default:
      return '';
  }
}

/// Pazartesi sonrası: geçen haftanın kazananlarını tüm hafta gösterir.
class _LastWeekWinnersPromo extends StatelessWidget {
  const _LastWeekWinnersPromo({
    required this.winners,
    required this.onDark,
    required this.l10n,
    this.compact = false,
  });

  final List<HilalDuelWeeklyLastWinner> winners;
  final bool onDark;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (winners.isEmpty) return const SizedBox.shrink();
    const gold = Color(0xFFE0B35A);
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 10 : 12,
        compact ? 10 : 12,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? [
                  gold.withValues(alpha: 0.22),
                  const Color(0xFF1A1408).withValues(alpha: 0.85),
                ]
              : [
                  gold.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.92),
                ],
        ),
        border: Border.all(color: gold.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.celebration_rounded,
                size: compact ? 14 : 16,
                color: gold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.hilalDuelWeeklyLastWinnersTitle,
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11.5 : 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          ...winners.map((winner) {
            final prize = winner.grantDays > 0
                ? _lastWeekWinnerPrize(l10n, winner.rank)
                : '';
            final accent = winner.rank == 1
                ? gold
                : winner.rank == 2
                    ? const Color(0xFFB0BEC5)
                    : const Color(0xFFC48A5A);
            return Padding(
              padding: EdgeInsets.only(bottom: compact ? 4 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: compact ? 28 : 32,
                    child: Text(
                      '#${winner.rank}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: winner.name,
                            style: TextStyle(
                              color: _HilalPalette.ink(onDark),
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 12 : 13,
                            ),
                          ),
                          if (prize.isNotEmpty)
                            TextSpan(
                              text: ' — $prize',
                              style: TextStyle(
                                color: _HilalPalette.muted(onDark),
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 10.5 : 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Haftalık birincilik rozeti (sayaç).
class _ChampionBadge extends StatelessWidget {
  const _ChampionBadge({required this.count, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = count < 1 ? 1 : count;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFE0B35A)],
        ),
        border: Border.all(color: const Color(0xFFC4892A).withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: compact ? 9 : 11,
            color: const Color(0xFF1A1208),
          ),
          SizedBox(width: compact ? 2 : 3),
          Text(
            '×$n',
            style: TextStyle(
              color: const Color(0xFF1A1208),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 8.5 : 9.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPreviewRow extends StatelessWidget {
  const _WeeklyPreviewRow({
    required this.entry,
    required this.onDark,
    required this.boardSize,
    this.showPremiumBadge = false,
  });

  final HilalDuelWeeklyEntry entry;
  final bool onDark;
  final int boardSize;
  final bool showPremiumBadge;

  @override
  Widget build(BuildContext context) {
    final theme = _WeeklyRankTheme.forRank(
      entry.rank,
      onDark,
      boardSize: boardSize,
    );
    final maxLevel = _isWeeklyMaxLevel(entry);
    final podium = maxLevel
        ? _MaxLevelShine.gold
        : entry.rank == 1
            ? const Color(0xFFE0B35A)
            : entry.rank == 2
                ? const Color(0xFFB0BEC5)
                : entry.rank == 3
                    ? const Color(0xFFC48A5A)
                    : theme.accent;
    final nameColor = maxLevel || entry.isSelf
        ? podium
        : _hilalNameColor(
            level: entry.level,
            onDark: onDark,
            bronze: _HilalPalette.bronze(onDark),
            isBot: entry.isBot,
            fullOverride: podium,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: maxLevel
          ? _MaxLevelShine.rowDecoration(
              onDark: onDark,
              isSelf: entry.isSelf,
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: podium.withValues(alpha: onDark ? 0.14 : 0.12),
              border: Border.all(color: podium.withValues(alpha: 0.55)),
            ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '#${entry.rank}',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: podium,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _leaderboardEntryName(entry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nameColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (maxLevel) ...[
                  const SizedBox(width: 6),
                  const _MaxLevelBadge(compact: true),
                ],
                if (!entry.isBot && entry.championWeeks > 0) ...[
                  const SizedBox(width: 6),
                  _ChampionBadge(count: entry.championWeeks, compact: true),
                ],
                if (showPremiumBadge) ...[
                  const SizedBox(width: 6),
                  const _AdminPremiumBadge(compact: true),
                ],
              ],
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

/// Admin-only: sıralamada premium oyuncu işareti.
class _AdminPremiumBadge extends StatelessWidget {
  const _AdminPremiumBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0B35A), Color(0xFFC4892A)],
        ),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: const Color(0xFF1A1208),
          fontWeight: FontWeight.w900,
          fontSize: compact ? 9 : 10,
          letterSpacing: 0.4,
          height: 1.1,
        ),
      ),
    );
  }
}

class _WeeklyLeaderSheet extends ConsumerStatefulWidget {
  const _WeeklyLeaderSheet({
    required this.controller,
    required this.l10n,
    required this.onDark,
    required this.fallbackWeekly,
    required this.fallbackRank,
    this.challengePickMode = false,
  });

  final HilalDuelController controller;
  final AppLocalizations l10n;
  final bool onDark;
  final int fallbackWeekly;
  final int fallbackRank;
  final bool challengePickMode;

  @override
  ConsumerState<_WeeklyLeaderSheet> createState() => _WeeklyLeaderSheetState();
}

class _WeeklyLeaderSheetState extends ConsumerState<_WeeklyLeaderSheet> {
  late Future<HilalDuelWeeklyBoard> _future;
  final _removingHashes = <String>{};

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadWeeklyLeaderboard();
  }

  void _reloadBoard() {
    setState(() {
      _future = widget.controller.loadWeeklyLeaderboard();
    });
  }

  Future<void> _adminRemoveEntry(HilalDuelWeeklyEntry entry) async {
    final name = _leaderboardEntryName(entry);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.l10n.hilalDuelAdminRemoveTitle),
        content: Text(widget.l10n.hilalDuelAdminRemoveBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.l10n.hilalDuelAdminRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removingHashes.add(entry.ownerHash));
    try {
      await widget.controller.adminRemoveWeeklyEntry(entry.ownerHash);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.hilalDuelAdminRemoved)),
      );
      _reloadBoard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _removingHashes.remove(entry.ownerHash));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(isCurrentUserAdminProvider).asData?.value ?? false;
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
            child: Column(
              children: [
                Text(
                  widget.challengePickMode
                      ? widget.l10n.hilalDuelChallengePickTitle
                      : widget.l10n.hilalDuelWeeklyTitle,
                  style: TextStyle(
                    color: _HilalPalette.ink(widget.onDark),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (widget.challengePickMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.l10n.hilalDuelChallengePickHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _HilalPalette.muted(widget.onDark),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
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
                // Shell alt nav SafeArea'ya dahil değil; son sıra bar altında kalmasın.
                final bottomPad =
                    ArinShellLayout.bottomContentPadding(context) + 12;
                return ListView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
                  children: [
                    if (!widget.challengePickMode) ...[
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
                      const SizedBox(height: 10),
                      Text(
                        widget.l10n.hilalDuelWeeklyPremiumRewardHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _HilalPalette.muted(widget.onDark),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (board.lastWeekWinners.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _LastWeekWinnersPromo(
                          winners: board.lastWeekWinners,
                          onDark: widget.onDark,
                          l10n: widget.l10n,
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
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
                        final title = _localizedTitleForLevel(
                          widget.l10n,
                          entry.level,
                          isBot: entry.isBot,
                        );
                        final rankTheme = _WeeklyRankTheme.forRank(
                          entry.rank,
                          widget.onDark,
                          boardSize: board.top.length,
                        );
                        final maxLevel = _isWeeklyMaxLevel(entry);
                        final accent = maxLevel
                            ? _MaxLevelShine.gold
                            : rankTheme.accent;
                        final nameColor = maxLevel
                            ? accent
                            : _hilalNameColor(
                                level: entry.level,
                                onDark: widget.onDark,
                                bronze: bronze,
                                isBot: entry.isBot,
                                fullOverride: accent,
                              );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: maxLevel
                              ? _MaxLevelShine.rowDecoration(
                                  onDark: widget.onDark,
                                  isSelf: entry.isSelf,
                                  radius: BorderRadius.circular(14),
                                )
                              : BoxDecoration(
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
                                        ? rankTheme.accent.withValues(
                                            alpha: 0.9,
                                          )
                                        : rankTheme.accent.withValues(
                                            alpha: 0.45,
                                          ),
                                    width: entry.isSelf ? 1.6 : 1,
                                  ),
                                ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '#${entry.rank}',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _leaderboardEntryName(entry),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: nameColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                        if (maxLevel) ...[
                                          const SizedBox(width: 6),
                                          const _MaxLevelBadge(),
                                        ],
                                        if (!entry.isBot &&
                                            entry.championWeeks > 0) ...[
                                          const SizedBox(width: 6),
                                          _ChampionBadge(
                                            count: entry.championWeeks,
                                          ),
                                        ],
                                        if (isAdmin && entry.premium) ...[
                                          const SizedBox(width: 6),
                                          const _AdminPremiumBadge(),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      [
                                        widget.l10n.hilalDuelLevelLabel(
                                          entry.level,
                                        ),
                                        if (title.isNotEmpty) title,
                                      ].join(' · '),
                                      style: TextStyle(
                                        color: maxLevel
                                            ? accent.withValues(alpha: 0.85)
                                            : _HilalPalette.muted(
                                                widget.onDark,
                                              ),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin &&
                                  entry.ownerHash.isNotEmpty &&
                                  !entry.isSelf)
                                IconButton(
                                  tooltip:
                                      widget.l10n.hilalDuelAdminRemoveTitle,
                                  visualDensity: VisualDensity.compact,
                                  onPressed:
                                      _removingHashes.contains(entry.ownerHash)
                                      ? null
                                      : () => unawaited(
                                          _adminRemoveEntry(entry),
                                        ),
                                  icon: _removingHashes.contains(
                                        entry.ownerHash,
                                      )
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: rankTheme.accent,
                                          ),
                                        )
                                      : Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.9,
                                          ),
                                          size: 22,
                                        ),
                                ),
                              Text(
                                '${entry.weeklyHilals}',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              if (!entry.isSelf &&
                                  entry.ownerHash.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _ChallengeActionButton(
                                  label: widget.l10n.hilalDuelChallengeAction,
                                  accent: accent,
                                  enabled: !widget.controller.busy,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    final p = widget.controller.profile;
                                    if (p != null &&
                                        !p.premium &&
                                        p.hearts <= 0) {
                                      unawaited(
                                        _promptNeedHeartDialog(
                                          context: context,
                                          l10n: widget.l10n,
                                          controller: widget.controller,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.of(context).pop();
                                    unawaited(
                                      widget.controller.createChallenge(
                                        entry.ownerHash,
                                      ),
                                    );
                                  },
                                ),
                              ],
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

class _ChallengeActionButton extends StatelessWidget {
  const _ChallengeActionButton({
    required this.label,
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF06140F);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      accent,
                      Color.lerp(accent, Colors.white, 0.18) ?? accent,
                    ]
                  : [
                      accent.withValues(alpha: 0.35),
                      accent.withValues(alpha: 0.22),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.22 : 0.1),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 15,
                color: enabled ? fg : fg.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? fg : fg.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  letterSpacing: -0.1,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
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
    this.onTap,
  });

  final String label;
  final bool onDark;
  final Color accent;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
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
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.add_rounded, size: 14, color: accent),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: child,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bronze.withValues(alpha: onDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bronze.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.quiz_rounded, color: bronze, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _HilalPalette.ink(onDark),
                fontSize: 11.5,
                height: 1.35,
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

    final revealRound = resolution?.round;
    final opponentAnsweredHud = match.opponentAnswered ||
        (showReveal &&
            revealRound != null &&
            controller.opponentChoiceForRevealRound(revealRound) != null);
    final activeRoundHud = showReveal
        ? (revealRound ?? match.currentRound)
        : match.currentRound;

    return ListView(
      // Yan isim baloncukları taşabilsin diye yatay pay bırakılır.
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      clipBehavior: Clip.none,
      children: [
        _DigitalMatchHud(
          self: match.self,
          opponent: match.opponent,
          selfLabel: selfName,
          opponentLabel: opponentName,
          selfAnswered:
              match.selfAnswered || controller.selectedChoice != null,
          opponentAnswered: opponentAnsweredHud,
          selfMarks: controller.selfRoundMarks,
          opponentMarks: controller.opponentRoundMarks,
          totalRounds: match.totalRounds,
          activeRound: activeRoundHud,
          seconds: seconds,
          revealing: showReveal,
          questionProgressLabel:
              l10n.hilalDuelQuestionProgress(displayRound, match.totalRounds),
          l10n: l10n,
          onDark: onDark,
        ),
        const SizedBox(height: 14),
        if (question != null) ...[
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: bronze.withValues(alpha: onDark ? 0.22 : 0.14),
                border: Border.all(color: bronze.withValues(alpha: 0.45)),
              ),
              child: Text(
                _hilalDifficultyLabel(l10n, question.difficulty),
                style: TextStyle(
                  color: bronze,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
                    color: bronze.withValues(alpha: 0.85),
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
            final opponentChoice = controller.opponentChoiceForRevealRound(
              resolution.round,
            );
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
          // Süre bitince yerel tap'i kapat — sunucu grace'i poll timeout ile yarışmasın.
          final locked = match.selfAnswered ||
              controller.selectedChoice != null ||
              controller.busy ||
              remainingMs <= 0;
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

/// Maç içi skorboard: cam panel + avatar halkaları + LED tur şeritleri + dijital süre.
class _DigitalMatchHud extends StatelessWidget {
  const _DigitalMatchHud({
    required this.self,
    required this.opponent,
    required this.selfLabel,
    required this.opponentLabel,
    required this.selfAnswered,
    required this.opponentAnswered,
    required this.selfMarks,
    required this.opponentMarks,
    required this.totalRounds,
    required this.activeRound,
    required this.seconds,
    required this.revealing,
    required this.questionProgressLabel,
    required this.l10n,
    required this.onDark,
  });

  final HilalDuelPlayer self;
  final HilalDuelPlayer opponent;
  final String selfLabel;
  final String opponentLabel;
  final bool selfAnswered;
  final bool opponentAnswered;
  final List<HilalDuelRoundMark> selfMarks;
  final List<HilalDuelRoundMark> opponentMarks;
  final int totalRounds;
  final int activeRound;
  final int seconds;
  final bool revealing;
  final String questionProgressLabel;
  final AppLocalizations l10n;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    final panelFill = onDark
        ? const Color(0xFF0B1A14).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);
    final edge = bronze.withValues(alpha: onDark ? 0.42 : 0.32);
    final gridLine = onDark
        ? const Color(0xFF3DDC84).withValues(alpha: 0.06)
        : bronze.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? [
                  const Color(0xFF10261C).withValues(alpha: 0.95),
                  panelFill,
                  const Color(0xFF0A1611).withValues(alpha: 0.96),
                ]
              : [
                  Colors.white.withValues(alpha: 0.88),
                  panelFill,
                  const Color(0xFFF3EFE6).withValues(alpha: 0.9),
                ],
        ),
        border: Border.all(color: edge, width: 1.15),
        boxShadow: [
          BoxShadow(
            color: (onDark ? const Color(0xFF3DDC84) : bronze)
                .withValues(alpha: onDark ? 0.12 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HudGridPainter(color: gridLine),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HudPlayerSide(
                      player: self,
                      displayName: selfLabel,
                      answered: selfAnswered,
                      alignEnd: false,
                      accent: const Color(0xFF3DDC84),
                      l10n: l10n,
                      onDark: onDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: _HudVsBadge(
                      bronze: bronze,
                      onDark: onDark,
                    ),
                  ),
                  Expanded(
                    child: _HudPlayerSide(
                      player: opponent,
                      displayName: opponentLabel,
                      answered: opponentAnswered,
                      alignEnd: true,
                      accent: const Color(0xFFE8B86D),
                      l10n: l10n,
                      onDark: onDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RoundMarksBoard(
                selfMarks: selfMarks,
                opponentMarks: opponentMarks,
                totalRounds: totalRounds,
                activeRound: activeRound,
                onDark: onDark,
                selfLabel: selfLabel,
                opponentLabel: opponentLabel,
                digital: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: _HudMetaChip(
                      icon: Icons.grid_view_rounded,
                      label: questionProgressLabel,
                      tone: bronze,
                      onDark: onDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DigitalTimerReadout(
                    seconds: seconds,
                    revealing: revealing,
                    onDark: onDark,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudVsBadge extends StatelessWidget {
  const _HudVsBadge({required this.bronze, required this.onDark});

  final Color bronze;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                bronze.withValues(alpha: onDark ? 0.38 : 0.28),
                bronze.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: bronze.withValues(alpha: 0.7), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: bronze.withValues(alpha: 0.28),
                blurRadius: 12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(22),
            painter: _CrescentPainter(color: bronze),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'VS',
          style: TextStyle(
            color: bronze.withValues(alpha: 0.95),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _HudPlayerSide extends StatelessWidget {
  const _HudPlayerSide({
    required this.player,
    required this.displayName,
    required this.answered,
    required this.alignEnd,
    required this.accent,
    required this.l10n,
    required this.onDark,
  });

  final HilalDuelPlayer player;
  final String displayName;
  final bool answered;
  final bool alignEnd;
  final Color accent;
  final AppLocalizations l10n;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = _HilalPalette.bronze(onDark);
    final title = _localizedTitleForLevel(
      l10n,
      player.level,
    );
    final initial = _nameInitial(displayName, fallback: alignEnd ? 'R' : 'S');
    final meta = [
      l10n.hilalDuelLevelLabel(player.level),
      if (title.isNotEmpty) title,
    ].join(' · ');

    final avatar = _HilalRankAvatar(
      level: player.level,
      size: 40,
      onDark: onDark,
      answeredGlow: accent.withValues(alpha: answered ? 0.45 : 0.18),
      fallbackBorder: accent.withValues(alpha: 0.9),
      fillColors: [
        accent.withValues(alpha: onDark ? 0.34 : 0.22),
        (onDark ? const Color(0xFF0B1A14) : Colors.white)
            .withValues(alpha: 0.9),
      ],
      child: Text(
        initial,
        style: TextStyle(
          color: _HilalPalette.ink(onDark),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          height: 1,
        ),
      ),
    );

    final nameStyle = TextStyle(
      color: _hilalNameColor(
        level: player.level,
        onDark: onDark,
        bronze: bronze,
      ),
      fontWeight: FontWeight.w800,
      fontSize: 13.5,
      height: 1.1,
      letterSpacing: 0.1,
    );
    // İsim satırı yüksekliği sabit — "Cevapladı" soruyu kaydırmaz.
    final texts = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: alignEnd
                ? [
                    _AnsweredInlineMark(
                      visible: answered,
                      label: l10n.hilalDuelAnsweredBubble,
                      onDark: onDark,
                    ),
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: nameStyle,
                      ),
                    ),
                  ]
                : [
                    Flexible(
                      child: Text(
                        displayName,
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
                  ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: _HilalPalette.muted(onDark),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Row(
      children: alignEnd
          ? [
              Expanded(child: texts),
              const SizedBox(width: 8),
              avatar,
            ]
          : [
              avatar,
              const SizedBox(width: 8),
              Expanded(child: texts),
            ],
    );
  }
}

class _HudMetaChip extends StatelessWidget {
  const _HudMetaChip({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onDark,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: onDark
            ? Colors.black.withValues(alpha: 0.34)
            : Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: tone.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _HilalPalette.ink(onDark).withValues(alpha: 0.88),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalTimerReadout extends StatelessWidget {
  const _DigitalTimerReadout({
    required this.seconds,
    required this.revealing,
    required this.onDark,
  });

  final int seconds;
  final bool revealing;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final urgent = !revealing && seconds <= 5;
    final tone = urgent
        ? const Color(0xFFFF6B6B)
        : _HilalPalette.bronze(onDark);
    final label = revealing
        ? '--'
        : seconds.toString().padLeft(2, '0');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: onDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: tone.withValues(alpha: urgent ? 0.95 : 0.55),
          width: urgent ? 1.4 : 1.1,
        ),
        boxShadow: urgent
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: tone,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudGridPainter extends CustomPainter {
  const _HudGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 14.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Tur tahtası: LED şerit (dijital) veya klasik nokta.
class _RoundMarksBoard extends StatelessWidget {
  const _RoundMarksBoard({
    required this.selfMarks,
    required this.opponentMarks,
    required this.totalRounds,
    required this.activeRound,
    required this.onDark,
    required this.selfLabel,
    required this.opponentLabel,
    this.onAccentCard = false,
    this.digital = false,
  });

  final List<HilalDuelRoundMark> selfMarks;
  final List<HilalDuelRoundMark> opponentMarks;
  final int totalRounds;
  final int activeRound;
  final bool onDark;
  final bool onAccentCard;
  final bool digital;
  final String selfLabel;
  final String opponentLabel;

  HilalDuelRoundMark _markAt(List<HilalDuelRoundMark> marks, int index) {
    if (index < 0 || index >= marks.length) return HilalDuelRoundMark.pending;
    return marks[index];
  }

  @override
  Widget build(BuildContext context) {
    final rounds = totalRounds > 0 ? totalRounds : 7;
    final labelColor = onAccentCard
        ? Colors.white.withValues(alpha: 0.78)
        : _HilalPalette.muted(onDark);

    Widget row({
      required String label,
      required List<HilalDuelRoundMark> marks,
      required Color sideAccent,
    }) {
      return Row(
        children: [
          SizedBox(
            width: digital ? 40 : 52,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: digital ? 10 : 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: digital ? 0.4 : 0,
              ),
            ),
          ),
          Expanded(
            child: digital
                ? Row(
                    children: List.generate(rounds, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 3,
                          ),
                          child: _RoundMarkDot(
                            mark: _markAt(marks, index),
                            active: index == activeRound,
                            onAccentCard: onAccentCard,
                            onDark: onDark,
                            digital: true,
                            sideAccent: sideAccent,
                          ),
                        ),
                      );
                    }),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(rounds, (index) {
                      return _RoundMarkDot(
                        mark: _markAt(marks, index),
                        active: index == activeRound,
                        onAccentCard: onAccentCard,
                        onDark: onDark,
                      );
                    }),
                  ),
          ),
        ],
      );
    }

    return Semantics(
      label: '$selfLabel / $opponentLabel',
      child: Column(
        children: [
          row(
            label: selfLabel,
            marks: selfMarks,
            sideAccent: const Color(0xFF3DDC84),
          ),
          SizedBox(height: digital ? 7 : 5),
          row(
            label: opponentLabel,
            marks: opponentMarks,
            sideAccent: const Color(0xFFE8B86D),
          ),
        ],
      ),
    );
  }
}

class _RoundMarkDot extends StatelessWidget {
  const _RoundMarkDot({
    required this.mark,
    required this.active,
    required this.onAccentCard,
    required this.onDark,
    this.digital = false,
    this.sideAccent,
  });

  final HilalDuelRoundMark mark;
  final bool active;
  final bool onAccentCard;
  final bool onDark;
  final bool digital;
  final Color? sideAccent;

  @override
  Widget build(BuildContext context) {
    const correct = Color(0xFF3DDC84);
    const wrong = Color(0xFFFF6B6B);
    const missed = Color(0xFF9AA5A0);
    final pendingBorder = onAccentCard
        ? Colors.white.withValues(alpha: 0.45)
        : (sideAccent ?? _HilalPalette.bronze(onDark))
            .withValues(alpha: active ? 0.85 : 0.4);
    final pendingFill = onAccentCard
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: onDark ? 0.28 : 0.06);

    Color fill;
    Color border;
    switch (mark) {
      case HilalDuelRoundMark.correct:
        fill = correct;
        border = correct;
      case HilalDuelRoundMark.wrong:
        fill = wrong;
        border = wrong;
      case HilalDuelRoundMark.missed:
        fill = missed.withValues(alpha: 0.85);
        border = missed;
      case HilalDuelRoundMark.pending:
        fill = pendingFill;
        border = pendingBorder;
    }

    if (digital) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 10,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: fill,
          border: Border.all(
            color: border,
            width: active ? 1.4 : 1,
          ),
          boxShadow: mark == HilalDuelRoundMark.correct ||
                  mark == HilalDuelRoundMark.wrong ||
                  active
              ? [
                  BoxShadow(
                    color: (active && mark == HilalDuelRoundMark.pending
                            ? (sideAccent ?? border)
                            : border)
                        .withValues(alpha: active ? 0.55 : 0.35),
                    blurRadius: active ? 8 : 5,
                  ),
                ]
              : null,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 12 : 10,
      height: active ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: active ? 1.6 : 1.1),
        boxShadow: mark == HilalDuelRoundMark.correct ||
                mark == HilalDuelRoundMark.wrong
            ? [
                BoxShadow(
                  color: border.withValues(alpha: 0.35),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
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
    final isExpired = result?.expired == true || match?.status == 'expired';
    final isDraw = !isExpired && winnerId == null;
    final isWin = !isExpired && !isDraw && winnerId == match?.self.id;
    final title = isExpired
        ? l10n.hilalDuelChallengeExpired
        : isDraw
            ? l10n.hilalDuelResultDraw
            : isWin
                ? l10n.hilalDuelResultWin
                : l10n.hilalDuelResultLose;
    final cardColor = isExpired || isDraw
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
                      const SizedBox(height: 12),
                      _RoundMarksBoard(
                        selfMarks: controller.selfRoundMarks,
                        opponentMarks: controller.opponentRoundMarks,
                        totalRounds: match?.totalRounds ?? 7,
                        activeRound: -1,
                        onDark: true,
                        onAccentCard: true,
                        digital: true,
                        selfLabel: l10n.hilalDuelYouLabel,
                        opponentLabel: _shortPlayerName(
                          match?.opponent.name ?? '',
                          fallback: l10n.hilalDuelOpponentLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
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
            if (!controller.challengeMode &&
                controller.profile?.premium != true &&
                !controller.doubledThisMatch &&
                match?.doubled != true &&
                (self?.hilalsAwarded ?? 0) > 0)
              _SecondaryButton(
                label: l10n.hilalDuelDoubleReward,
                busy: controller.busy,
                onDark: onDark,
                onTap: () => unawaited(controller.watchDoubleAd()),
              )
            else if (!controller.challengeMode &&
                (controller.doubledThisMatch || match?.doubled == true))
              Text(
                l10n.hilalDuelDoubled,
                textAlign: TextAlign.center,
                style: TextStyle(color: bronze, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            if (!controller.challengeMode)
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
            if (!controller.challengeMode) const SizedBox(height: 10),
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

/// Bot satırlarında soyadı gösterme — tam isim botluğu ele veriyor.
String _leaderboardEntryName(HilalDuelWeeklyEntry entry) {
  if (!entry.isBot) return entry.name;
  return _shortPlayerName(entry.name, fallback: entry.name);
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
      height: tall ? 50 : 44,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldMid,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: bronze.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: tall ? 14.5 : 13.5,
                  letterSpacing: tall ? 0.8 : 0.3,
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
      height: 42,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _HilalPalette.ink(onDark),
          side: BorderSide(color: bronze.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Lobideki ana "Meydan oku" — altın dolgu, rekabetçi vurgu (canlı yeşilden ayrı).
class _ChallengeLobbyButton extends StatelessWidget {
  const _ChallengeLobbyButton({
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
    final accent = onDark
        ? const Color(0xFFE0B35A)
        : const Color(0xFFC4892A);
    const fg = Color(0xFF1A1208);
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: busy
                    ? [
                        accent.withValues(alpha: 0.45),
                        accent.withValues(alpha: 0.32),
                      ]
                    : [
                        accent,
                        Color.lerp(accent, const Color(0xFFF0D080), 0.35) ??
                            accent,
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: busy ? 0.12 : 0.28),
              ),
              boxShadow: busy
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg.withValues(alpha: 0.7),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 18, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: 0.6,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
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
