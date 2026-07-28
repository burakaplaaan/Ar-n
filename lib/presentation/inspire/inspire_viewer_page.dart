import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
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
import 'inspire_viewer_session_provider.dart';
import 'widgets/inspiration_slide.dart';

/// Tam ekran dikey akış (Reels); görseller aynı viewport’ta, `BoxFit.cover` + ortala.
class InspireViewerPage extends ConsumerStatefulWidget {
  const InspireViewerPage({
    super.key,
    required this.initialIndex,
    this.deckOverride,
  });

  final int initialIndex;

  /// Arama sonrası ızgara; null ise tüm karışık katalog kullanılır.
  final List<InspirationCardModel>? deckOverride;

  @override
  ConsumerState<InspireViewerPage> createState() => _InspireViewerPageState();
}

class _InspireViewerPageState extends ConsumerState<InspireViewerPage> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(inspireViewerDeckSessionProvider);
    final override = widget.deckOverride ?? session?.cards;
    final initial = widget.deckOverride != null
        ? widget.initialIndex
        : (session?.initialIndex ?? widget.initialIndex);

    if (override != null) {
      if (override.isEmpty) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _ViewerEmpty(onClose: () => context.pop()),
        );
      }
      final safe = initial.clamp(0, override.length - 1);
      return Scaffold(
        backgroundColor: Colors.black,
        body: _ViewerBody(cards: override, initialIndex: safe),
      );
    }

    final async = ref.watch(inspirationShuffledGridProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: async.when(
        data: (cards) {
          if (cards.isEmpty) {
            return _ViewerEmpty(onClose: () => context.pop());
          }
          return _ViewerBody(
            cards: cards,
            initialIndex: widget.initialIndex.clamp(
              0,
              cards.isEmpty ? 0 : cards.length - 1,
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: ArinSkeletonCard(height: 520, borderRadius: 24),
        ),
        error: (e, _) => _ViewerError(
          message: '$e',
          onClose: () => context.pop(),
          onRetry: () => ref.invalidate(inspirationCatalogProvider),
        ),
      ),
    );
  }
}

class _ViewerBody extends ConsumerStatefulWidget {
  const _ViewerBody({required this.cards, required this.initialIndex});

  final List<InspirationCardModel> cards;
  final int initialIndex;

  @override
  ConsumerState<_ViewerBody> createState() => _ViewerBodyState();
}

class _ViewerBodyState extends ConsumerState<_ViewerBody>
    with ReviewPromptOnExitMixin {
  PageController? _pc;
  late int _settledPage;
  bool _adGateShowing = false;
  int _pendingExploreAdGateViews = 0;
  bool _initialPrecacheDone = false;
  bool _warmedAds = false;

  /// Sol kenar “geri” jesti: sağa doğru sürükleme mesafesi (px).
  double _edgeSwipeDx = 0;

  @override
  void initState() {
    super.initState();
    startReviewPromptTracking();
    final safe = widget.initialIndex.clamp(0, widget.cards.length - 1);
    _settledPage = safe;
    _pc = PageController(initialPage: safe, viewportFraction: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordView(safe);
      _maybeShowExploreAdGate();
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

  void _tryPopFromEdgeSwipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    // Sağa hızlı fırlatma veya yavaş ama yeterince sağa çekme
    if (v > 240 || _edgeSwipeDx > 56) {
      HapticFeedback.lightImpact();
      if (context.mounted) {
        context.pop();
      }
    }
    _edgeSwipeDx = 0;
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
        await ref.read(exploreBgmNotifierProvider.notifier).pauseForAdGate();
        if (!mounted) return;
        final shown = await ref
            .read(adMobServiceProvider)
            .showInterstitial(ArinAdUnit.exploreInterstitial);
        if (!mounted) return;
        if (shown) {
          await adGate.recordRewardedUnlock(AdGatePlacement.exploreSwipe);
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

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pc,
          itemCount: cards.length,
          allowImplicitScrolling: false,
          dragStartBehavior: DragStartBehavior.down,
          physics: _InstagramLikePageScrollPhysics(
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
        // Instagram benzeri: sol kenardan sağa çekerek çık (dikey akışa dokunmamak için dar şerit).
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: pad.left + 56,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _edgeSwipeDx = 0;
            },
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx > 0) {
                _edgeSwipeDx += details.delta.dx;
              }
            },
            onHorizontalDragEnd: _tryPopFromEdgeSwipe,
            onHorizontalDragCancel: () {
              _edgeSwipeDx = 0;
            },
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
              child: ArinBackButton(
                onPressed: () => context.pop(),
                semanticLabel: AppLocalizations.of(context)!.viewerBackAction,
                variant: ArinBackButtonVariant.overlaySubtle,
              ),
            ),
          ),
        ),
      ],
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
