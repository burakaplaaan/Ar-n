import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/product_metric_features.dart';
import '../../core/ads/admob_ids.dart';
import '../../data/models/inspiration_card_model.dart';
import '../../data/services/ad_gate_service.dart';
import '../../data/services/admob_service.dart';
import '../../data/services/product_metrics_service.dart';
import '../shared/mixins/review_prompt_on_exit_mixin.dart';
import '../shared/providers/ad_gate_providers.dart';
import '../shared/providers/admob_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/widgets/arin_back_button.dart';
import '../shared/widgets/arin_skeleton.dart';
import 'explore_bgm_controller.dart';
import 'inspiration_catalog_provider.dart';
import 'inspiration_search.dart';
import 'inspire_viewer_session_provider.dart';
import 'widgets/explore_bgm_app_bar_actions.dart';
import 'widgets/inspiration_slide.dart';

/// Tam ekran dikey akış (Reels); görseller aynı viewport’ta, `BoxFit.cover` + ortala.
class InspireViewerPage extends ConsumerStatefulWidget {
  const InspireViewerPage({
    super.key,
    required this.initialIndex,
    this.deckOverride,
    this.originRect,
  });

  final int initialIndex;

  /// Arama sonrası ızgara; null ise tüm karışık katalog kullanılır.
  final List<InspirationCardModel>? deckOverride;

  /// Tıklanan ızgara hücresi — açılış/kapanış bu dikdörtgene doğru küçülür.
  final Rect? originRect;

  @override
  ConsumerState<InspireViewerPage> createState() => _InspireViewerPageState();
}

class _InspireViewerPageState extends ConsumerState<InspireViewerPage> {
  late final StateController<InspireViewerDeckExtra?> _deckSessionController;
  InspireViewerDeckExtra? _ownedDeckSession;

  @override
  void initState() {
    super.initState();
    _deckSessionController = ref.read(
      inspireViewerDeckSessionProvider.notifier,
    );
    final session = _deckSessionController.state;
    if (session != null &&
        widget.deckOverride != null &&
        identical(session.cards, widget.deckOverride)) {
      _ownedDeckSession = session;
    }
  }

  @override
  void dispose() {
    final ownedSession = _ownedDeckSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ownedSession != null &&
          identical(_deckSessionController.state, ownedSession)) {
        _deckSessionController.state = null;
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final override = widget.deckOverride;
    final initial = widget.initialIndex;

    final originRect =
        widget.originRect ??
        ref.watch(inspireViewerDeckSessionProvider)?.originRect;

    if (override != null) {
      if (override.isEmpty) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ColoredBox(
            color: Colors.black,
            child: _ViewerEmpty(onClose: () => context.pop()),
          ),
        );
      }
      final safe = initial.clamp(0, override.length - 1);
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _ViewerBody(
          cards: override,
          initialIndex: safe,
          originRect: originRect,
        ),
      );
    }

    final async = ref.watch(inspirationShuffledGridProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: async.when(
        data: (cards) {
          if (cards.isEmpty) {
            return ColoredBox(
              color: Colors.black,
              child: _ViewerEmpty(onClose: () => context.pop()),
            );
          }
          return _ViewerBody(
            cards: cards,
            initialIndex: widget.initialIndex.clamp(
              0,
              cards.isEmpty ? 0 : cards.length - 1,
            ),
            originRect: originRect,
          );
        },
        loading: () => const ColoredBox(
          color: Colors.black,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: ArinSkeletonCard(height: 520, borderRadius: 24),
          ),
        ),
        error: (e, _) => ColoredBox(
          color: Colors.black,
          child: _ViewerError(
            message: '$e',
            onClose: () => context.pop(),
            onRetry: () => ref.invalidate(inspirationCatalogProvider),
          ),
        ),
      ),
    );
  }
}

class _ViewerBody extends ConsumerStatefulWidget {
  const _ViewerBody({
    required this.cards,
    required this.initialIndex,
    this.originRect,
  });

  final List<InspirationCardModel> cards;
  final int initialIndex;
  final Rect? originRect;

  @override
  ConsumerState<_ViewerBody> createState() => _ViewerBodyState();
}

class _ViewerBodyState extends ConsumerState<_ViewerBody>
    with ReviewPromptOnExitMixin, SingleTickerProviderStateMixin {
  PageController? _pc;
  late final AnimationController _dismissController;
  late int _settledPage;
  bool _adGateShowing = false;
  int _pendingExploreAdGateViews = 0;
  bool _initialPrecacheDone = false;
  bool _warmedAds = false;
  bool _isDismissing = false;
  bool _lockVerticalScroll = false;

  static const double _dismissCommitProgress = 0.22;
  static const double _dismissFlickVelocity = 700;

  @override
  void initState() {
    super.initState();
    startReviewPromptTracking();
    final safe = widget.initialIndex.clamp(0, widget.cards.length - 1);
    _settledPage = safe;
    _pc = PageController(initialPage: safe, viewportFraction: 1);
    final hasOrigin = _usableOrigin(widget.originRect) != null;
    _dismissController = AnimationController(
      vsync: this,
      value: hasOrigin ? 1 : 0,
    );
    _lockVerticalScroll = hasOrigin;
    _dismissController.addListener(_syncVerticalScrollLock);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordView(safe);
      _maybeShowExploreAdGate();
      _playOpenFromOrigin();
    });
  }

  void _recordView(int index) {
    if (index < 0 || index >= widget.cards.length) return;
    unawaited(ProductMetricsService.contentView(widget.cards[index].id));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialPrecacheDone) return;
    _initialPrecacheDone = true;
    // Viewer açılışında komşu slide'ların görsellerini ısıt — kullanıcı hızlı
    // dikey swipe yapınca ilk frame decode jank'i olmasın. `initState`'te
    // context henüz hazır değil, `didChangeDependencies` ilk çağrıda güvenli.
    final safe = widget.initialIndex.clamp(0, widget.cards.length - 1);
    _precacheNeighbors(safe);
  }

  @override
  void dispose() {
    maybeRequestReviewOnExit();
    _dismissController.removeListener(_syncVerticalScrollLock);
    _dismissController.dispose();
    _pc?.dispose();
    super.dispose();
  }

  /// Yakın komşuları hafızaya al. Aynı path tekrar gelirse Flutter'ın kendi
  /// image cache'i idempotent davranır. Error'lar sessizce yutulur — slide
  /// rendering sırasında zaten `errorBuilder` placeholder gösteriyor.
  void _precacheNeighbors(int currentIndex) {
    if (!mounted) return;
    final cards = widget.cards;
    for (final offset in const [-1, 1, 2]) {
      final target = currentIndex + offset;
      if (target < 0 || target >= cards.length) continue;
      final path = cards[target].resolvedImageAssetPath;
      if (path.isEmpty) continue;
      precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  void _syncVerticalScrollLock() {
    final lock = _isDismissing || _dismissController.value > 0.02;
    if (lock == _lockVerticalScroll || !mounted) return;
    setState(() => _lockVerticalScroll = lock);
  }

  Rect? _usableOrigin(Rect? raw) {
    if (raw == null || raw.width < 8 || raw.height < 8) return null;
    return raw;
  }

  Rect _localOriginRect(
    BuildContext context,
    Size screen, {
    required bool rtl,
  }) {
    final raw = _usableOrigin(widget.originRect);
    if (raw != null) {
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final local = Rect.fromPoints(
          box.globalToLocal(raw.topLeft),
          box.globalToLocal(raw.bottomRight),
        );
        final bounds = (Offset.zero & screen).inflate(80);
        if (local.width >= 8 && local.height >= 8 && local.overlaps(bounds)) {
          return local;
        }
      } else if (raw.overlaps((Offset.zero & screen).inflate(80))) {
        return raw;
      }
    }
    final w = screen.width * 0.78;
    final h = screen.height * 0.78;
    final left = rtl ? screen.width * -0.08 : screen.width * 0.30;
    return Rect.fromLTWH(left, (screen.height - h) / 2, w, h);
  }

  void _playOpenFromOrigin() {
    if (!mounted || _isDismissing) return;
    if (_usableOrigin(widget.originRect) == null) return;
    if (_dismissController.value <= 0) return;
    unawaited(
      _dismissController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _signedDelta(double dx, bool rtl) => rtl ? -dx : dx;

  void _updateDismissDrag(DragUpdateDetails details, double width) {
    if (_isDismissing || width <= 0) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next =
        _dismissController.value + _signedDelta(details.delta.dx, rtl) / width;
    _dismissController.value = next.clamp(0.0, 1.0);
  }

  void _endDismissDrag(DragEndDetails details, double width) {
    if (_isDismissing || width <= 0) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final velocity = _signedDelta(details.primaryVelocity ?? 0, rtl);
    final progress = _dismissController.value;
    final shouldDismiss =
        progress >= _dismissCommitProgress || velocity >= _dismissFlickVelocity;

    if (shouldDismiss) {
      unawaited(_completeDismiss());
      return;
    }
    _restoreDismissPosition(velocity / width);
  }

  void _restoreDismissPosition([double progressVelocity = 0]) {
    if (_isDismissing) return;
    _dismissController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 460, damping: 44),
        _dismissController.value,
        0,
        progressVelocity,
      ),
    );
  }

  Future<void> _completeDismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    _syncVerticalScrollLock();
    HapticFeedback.lightImpact();
    final remaining = (1 - _dismissController.value).clamp(0.0, 1.0);
    try {
      await _dismissController.animateTo(
        1,
        duration: Duration(
          milliseconds: (240 * remaining).round().clamp(90, 260),
        ),
        curve: Curves.easeOutCubic,
      );
    } on TickerCanceled {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _maybeShowExploreAdGate() {
    if (!mounted) return;
    _pendingExploreAdGateViews += 1;
    if (_adGateShowing) return;
    unawaited(_drainExploreAdGateViews());
  }

  Future<void> _drainExploreAdGateViews() async {
    if (_adGateShowing || !mounted) return;
    _adGateShowing = true;
    try {
      final adGate = ref.read(adGateServiceProvider);
      while (mounted && _pendingExploreAdGateViews > 0) {
        _pendingExploreAdGateViews -= 1;
        var isPremium = false;
        var premiumKnown = false;
        try {
          final entitlement = await ref.read(premiumEntitlementProvider.future);
          isPremium = entitlement.isActive;
          premiumKnown = true;
        } catch (_) {
          // Premium durumu bilinmiyorsa kullanıcıyı free kabul edip reklam
          // göstermiyoruz; bir sonraki swipe'ta tekrar deneriz.
          isPremium = false;
          premiumKnown = false;
        }
        if (!mounted) return;
        if (!premiumKnown) {
          _pendingExploreAdGateViews += 1;
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        // Premium OLMAYAN kullanıcı için keşfet geçiş reklamını arka planda
        // bir kez ısıt; ilk gösterim anında hazır olsun. (Keşfet yalnızca
        // geçiş reklamı gösterir → yalnızca interstitial ısıtılır.)
        if (!isPremium && !_warmedAds) {
          _warmedAds = true;
          AdMobService.preloadInterstitial();
        }
        final shouldShow = await adGate.recordExploreViewAndShouldShowAd(
          isPremium: isPremium,
        );
        if (!mounted) return;
        if (!shouldShow) continue;

        await adGate.markPending(AdGatePlacement.exploreSwipe);
        if (!mounted) return;
        if (isPremium) {
          await adGate.clearPending(AdGatePlacement.exploreSwipe);
          _pendingExploreAdGateViews = 0;
          return;
        }
        if (!adGate.isPending(AdGatePlacement.exploreSwipe)) continue;
        if (!mounted) return;
        final shown = await ref
            .read(adMobServiceProvider)
            .showInterstitial(ArinAdUnit.exploreInterstitial);
        if (!mounted) return;
        unawaited(
          ref.read(exploreBgmNotifierProvider.notifier).resumeAfterAdGate(),
        );
        if (shown) {
          await adGate.recordRewardedUnlock(AdGatePlacement.exploreSwipe);
          unawaited(
            ProductMetricsService.adWatch(ProductMetricFeatures.explore),
          );
        } else {
          await adGate.clearPending(AdGatePlacement.exploreSwipe);
        }
        return;
      }
    } finally {
      _adGateShowing = false;
      if (mounted && _pendingExploreAdGateViews > 0) {
        unawaited(_drainExploreAdGateViews());
      }
    }
  }

  Widget _buildViewerContent(List<InspirationCardModel> cards) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pc,
            itemCount: cards.length,
            allowImplicitScrolling: false,
            dragStartBehavior: DragStartBehavior.down,
            physics: _lockVerticalScroll
                ? const NeverScrollableScrollPhysics()
                : _InstagramLikePageScrollPhysics(
                    settledPage: () => _settledPage,
                    parent: const BouncingScrollPhysics(),
                  ),
            onPageChanged: (page) {
              _settledPage = page;
              _recordView(page);
              _precacheNeighbors(page);
              _maybeShowExploreAdGate();
            },
            itemBuilder: (context, i) {
              return InspirationSlide(
                card: cards[i],
                reelsLayout: true,
                viewerZoom: 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBgmActions(double opacity) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 4, 0),
          child: Opacity(
            opacity: opacity,
            child: IgnorePointer(
              ignoring: opacity < 0.08,
              child: const ExploreBgmAppBarActions(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(double opacity) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
          child: Opacity(
            opacity: opacity,
            child: IgnorePointer(
              ignoring: opacity < 0.08,
              child: ArinBackButton(
                onPressed: () => unawaited(_completeDismiss()),
                semanticLabel: AppLocalizations.of(context)!.viewerBackAction,
                variant: ArinBackButtonVariant.overlaySubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(inspireViewerCloseRequestProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_completeDismiss());
    });
    final cards = widget.cards;
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isDismissing) return;
        unawaited(_completeDismiss());
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          if (!_isDismissing) _dismissController.stop();
        },
        onHorizontalDragUpdate: (details) => _updateDismissDrag(details, width),
        onHorizontalDragEnd: (details) => _endDismissDrag(details, width),
        onHorizontalDragCancel: _restoreDismissPosition,
        child: AnimatedBuilder(
          animation: _dismissController,
          child: _buildViewerContent(cards),
          builder: (context, child) {
            final progress = _dismissController.value.clamp(0.0, 1.0);
            final easedProgress = Curves.easeOutCubic.transform(progress);
            final origin = _localOriginRect(context, size, rtl: rtl);
            final frame = Rect.lerp(Offset.zero & size, origin, easedProgress)!;
            final radius = 12 * easedProgress;
            final backgroundOpacity = (1 - (0.92 * easedProgress)).clamp(
              0.0,
              1.0,
            );
            final chromeOpacity = (1 - (easedProgress * 2.2)).clamp(0.0, 1.0);
            final backOpacity = (1 - (easedProgress * 3.2)).clamp(0.0, 1.0);

            return InspirationViewerChromeScope(
              opacity: chromeOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black.withValues(alpha: backgroundOpacity),
                  ),
                  Positioned.fromRect(
                    rect: frame,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: child,
                    ),
                  ),
                  _buildBackButton(backOpacity),
                  _buildBgmActions(backOpacity),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InstagramLikePageScrollPhysics extends PageScrollPhysics {
  const _InstagramLikePageScrollPhysics({
    required this.settledPage,
    super.parent,
  });

  final int Function() settledPage;

  static const double _commitFraction = 0.02;
  static const double _flickCommitFraction = 0.008;
  static const double _flickVelocity = 40;

  @override
  _InstagramLikePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _InstagramLikePageScrollPhysics(
      settledPage: settledPage,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  double _targetPixels(ScrollMetrics position, double velocity) {
    final viewport = position.viewportDimension;
    if (viewport <= 0) return position.pixels;

    final currentPage = position.pixels / viewport;
    final anchorPage = settledPage().toDouble();
    final pageDelta = currentPage - anchorPage;
    double targetPage = anchorPage;

    if (velocity.abs() > _flickVelocity &&
        pageDelta.abs() >= _flickCommitFraction) {
      targetPage = velocity > 0 ? anchorPage + 1 : anchorPage - 1;
    } else if (pageDelta >= _commitFraction) {
      targetPage = anchorPage + 1;
    } else if (pageDelta <= -_commitFraction) {
      targetPage = anchorPage - 1;
    }

    return (targetPage * viewport).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }
}

class _ViewerEmpty extends StatelessWidget {
  const _ViewerEmpty({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: onClose, child: Text(l10n.viewerBackAction)),
            const SizedBox(height: 12),
            Text(
              l10n.viewerNoCard,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({
    required this.message,
    required this.onClose,
    this.onRetry,
  });

  final String message;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.cloud_off_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.inspireLoadFailedTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.asyncErrorDefaultMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.asyncErrorRetryAction),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emeraldMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
