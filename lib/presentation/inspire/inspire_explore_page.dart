import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../shared/widgets/arin_pressable.dart';
import '../../core/constants/product_metric_features.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/models/inspiration_card_model.dart';
import '../../data/models/inspiration_content_kind.dart';
import '../../data/repositories/inspiration_firestore_repository.dart';
import '../../data/services/product_metrics_service.dart';
import '../onboarding/app_tour/app_tour_anchor.dart';
import '../onboarding/app_tour/app_tour_keys.dart';
import '../shared/widgets/arin_skeleton.dart';
import 'explore_content_filter_provider.dart';
import 'inspiration_catalog_provider.dart';
import 'inspire_viewer_session_provider.dart';
import 'inspiration_search.dart';
import 'widgets/explore_bgm_app_bar_actions.dart';
import 'widgets/explore_header_veil.dart';
import 'widgets/inspiration_grid_tile.dart';

/// Instagram Keşfet tarzı ızgara — ara kutusu, Türkçe uyumlu arama, shell + alt bar.
class InspireExplorePage extends ConsumerStatefulWidget {
  const InspireExplorePage({super.key, this.shellTab = false});

  /// Shell [PageView] içindeki asıl ızgara. GoRouter kopyası viewer açıkken
  /// boyanmaz; böylece shrink animasyonu tıklanan kareye oturur.
  final bool shellTab;

  @override
  ConsumerState<InspireExplorePage> createState() => _InspireExplorePageState();
}

class _InspireExplorePageState extends ConsumerState<InspireExplorePage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';

  // _filtered önbelleği — input değişmediğinde tekrar hesaplama yapmaz.
  List<InspirationCardModel>? _filteredCache;
  List<InspirationCardModel>? _filteredCacheCards;
  ExploreContentFilter? _filteredCacheFilter;
  String? _filteredCacheQuery;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    unawaited(ProductMetricsService.featureOpen(ProductMetricFeatures.explore));
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await InspirationFirestoreRepository.resetFetchThrottle(
      ref.read(sharedPreferencesProvider),
    );
    ref.read(exploreGridShuffleSeedProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;
    ref.invalidate(inspirationCatalogProvider);
    await ref.read(inspirationCatalogProvider.future);
  }

  List<InspirationCardModel> _filtered(
    List<InspirationCardModel> cards,
    ExploreContentFilter filter,
  ) {
    // Giriş değişmediyse önbellekten döndür — build başına O(n log n) sort kalkıyor.
    if (identical(_filteredCacheCards, cards) &&
        _filteredCacheFilter == filter &&
        _filteredCacheQuery == _query &&
        _filteredCache != null) {
      return _filteredCache!;
    }

    final list = cards.where((c) {
      if (!inspirationCardMatchesQuery(c, _query)) return false;
      switch (filter) {
        case ExploreContentFilter.mixed:
          return true;
        case ExploreContentFilter.soz:
          return c.contentKind == InspirationContentKind.quote;
        case ExploreContentFilter.ayet:
          return c.contentKind == InspirationContentKind.verse;
        case ExploreContentFilter.hadis:
          return c.contentKind == InspirationContentKind.hadith;
      }
    }).toList();

    final q = _query.trim();
    if (q.isNotEmpty) {
      list.sort((a, b) {
        final sa = inspirationSearchRelevanceScore(a, _query);
        final sb = inspirationSearchRelevanceScore(b, _query);
        return sb.compareTo(sa);
      });
    }

    _filteredCacheCards = cards;
    _filteredCacheFilter = filter;
    _filteredCacheQuery = _query;
    _filteredCache = list;
    return list;
  }

  List<InspirationCardModel> _mixedViewerCards(
    List<InspirationCardModel> filtered,
    int pickedIndex,
    int openNonce,
  ) {
    if (filtered.isEmpty) return const [];
    if (filtered.length == 1) return [filtered.first];

    final picked = filtered[pickedIndex % filtered.length];
    final rest = <InspirationCardModel>[
      for (var i = 0; i < filtered.length; i++)
        if (i != pickedIndex) filtered[i],
    ]..shuffle(Random(openNonce));

    final cycle = <InspirationCardModel>[picked, ...rest];
    return List<InspirationCardModel>.generate(
      2000,
      (i) => cycle[i % cycle.length],
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shellTab) {
      final path = GoRouterState.of(context).uri.path;
      if (path.contains('/inspire/view')) {
        return const SizedBox.shrink();
      }
    }
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(inspirationShuffledGridProvider);
    final filter = ref.watch(exploreContentFilterProvider);
    final canPop = context.canPop();
    final onLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: onLight
                ? [AppColors.creamMist, AppColors.creamShellDeep]
                : [AppColors.homeGradientTop, AppColors.homeGradientBottom],
            stops: const [0.0, 0.65],
          ),
        ),
        child: async.when(
          data: (cards) {
            if (cards.isEmpty) {
              return RefreshIndicator(
                color: AppColors.accentNeonGreen,
                backgroundColor: onLight
                    ? AppColors.creamSurface
                    : AppColors.homeGradientTop,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _exploreHeader(
                      l10n: l10n,
                      onLight: onLight,
                      canPop: canPop,
                      filter: filter,
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ExploreEmpty(
                        onClose: canPop ? () => context.pop() : null,
                      ),
                    ),
                  ],
                ),
              );
            }
            final filtered = _filtered(cards, filter);
            final searchActive = _query.trim().isNotEmpty;
            return RefreshIndicator(
              color: AppColors.accentNeonGreen,
              backgroundColor: onLight
                  ? AppColors.creamSurface
                  : AppColors.homeGradientTop,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                key: const PageStorageKey<String>('inspireExploreScroll'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _exploreHeader(
                    l10n: l10n,
                    onLight: onLight,
                    canPop: canPop,
                    filter: filter,
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.inspireSearchNoResults,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onLight
                                  ? AppColors.textSecondary
                                  : Colors.white.withValues(alpha: 0.55),
                              height: 1.45,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                              childAspectRatio: 0.75,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final pickedIndex = searchActive
                                ? index
                                : index % filtered.length;
                            final card = filtered[pickedIndex];
                            return InspirationGridTile(
                              card: card,
                              onTap: (originRect) {
                                final openNonce =
                                    DateTime.now().microsecondsSinceEpoch;
                                final viewerCards =
                                    filter == ExploreContentFilter.mixed
                                    ? _mixedViewerCards(
                                        filtered,
                                        pickedIndex,
                                        openNonce,
                                      )
                                    : filtered;
                                final deck = InspireViewerDeckExtra(
                                  cards: viewerCards,
                                  initialIndex:
                                      filter == ExploreContentFilter.mixed
                                      ? 0
                                      : pickedIndex,
                                  originRect: originRect,
                                );
                                ref
                                        .read(
                                          inspireViewerDeckSessionProvider
                                              .notifier,
                                        )
                                        .state =
                                    deck;
                                context.push(
                                  AppRoutes.inspireView(
                                    filter == ExploreContentFilter.mixed
                                        ? 0
                                        : pickedIndex,
                                    openNonce: openNonce,
                                  ),
                                  extra: deck,
                                );
                              },
                            );
                          },
                          // Arama açıkken sonuçlar tekrarsız listelenir.
                          // Arama yokken keşfet akışı sonsuz gibi hissettirsin;
                          // 10_000 × katalog scroll metrics / float hassasiyetini korur.
                          childCount: searchActive
                              ? filtered.length
                              : filtered.length * 10000,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => CustomScrollView(
            slivers: [
              _exploreHeader(
                l10n: l10n,
                onLight: onLight,
                canPop: canPop,
                filter: filter,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ArinSkeleton(
                      height: double.infinity,
                      borderRadius: 16,
                    ),
                    childCount: 6,
                  ),
                ),
              ),
            ],
          ),
          error: (e, _) => RefreshIndicator(
            color: AppColors.accentNeonGreen,
            backgroundColor: onLight
                ? AppColors.creamSurface
                : AppColors.homeGradientTop,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _exploreHeader(
                  l10n: l10n,
                  onLight: onLight,
                  canPop: canPop,
                  filter: filter,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ExploreError(
                    message: '$e',
                    onClose: canPop ? () => context.pop() : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _exploreHeader({
    required AppLocalizations l10n,
    required bool onLight,
    required bool canPop,
    required ExploreContentFilter filter,
  }) {
    return SliverAppBar(
      pinned: true,
      primary: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: ExploreHeaderMetrics.toolbarHeight,
      titleSpacing: 8,
      leadingWidth: canPop ? 40 : 0,
      leading: canPop
          ? ArinPressable(
              scale: 0.90,
              onTap: () => context.pop(),
              child: SizedBox(
                width: 40,
                height: 34,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: onLight
                      ? AppColors.emeraldDark.withValues(alpha: 0.78)
                      : Colors.white.withValues(alpha: 0.78),
                ),
              ),
            )
          : null,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: const ExploreHeaderVeil(),
      title: Text(
        l10n.inspireExploreTitle,
        style: TextStyle(
          color: onLight
              ? AppColors.emeraldDark
              : Colors.white.withValues(alpha: 0.94),
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.35,
          height: 1.1,
        ),
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 2),
          child: ExploreBgmAppBarActions(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          ExploreHeaderMetrics.searchRowHeight,
        ),
        child: _ExploreSearchRow(
          controller: _searchController,
          query: _query,
          filter: filter,
          onLight: onLight,
          onFilterSelected: (v) {
            ref.read(exploreContentFilterProvider.notifier).state = v;
          },
        ),
      ),
    );
  }
}

class _ExploreSearchRow extends StatelessWidget {
  const _ExploreSearchRow({
    required this.controller,
    required this.query,
    required this.filter,
    required this.onLight,
    required this.onFilterSelected,
  });

  final TextEditingController controller;
  final String query;
  final ExploreContentFilter filter;
  final bool onLight;
  final ValueChanged<ExploreContentFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fieldFill = onLight
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.07);
    final fieldBorder = onLight
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.08);
    final iconColor = onLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.48);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: AppTourAnchor(
              id: AppTourTargetId.inspireSearch,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: fieldBorder),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: onLight
                        ? AppColors.emeraldDark
                        : Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.5,
                    height: 1.2,
                  ),
                  cursorColor: AppColors.accentNeonGreen,
                  decoration: InputDecoration(
                    hintText: l10n.inspireSearchHint,
                    hintStyle: TextStyle(
                      color: onLight
                          ? AppColors.textSecondary
                          : Colors.white.withValues(alpha: 0.36),
                      fontSize: 14.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? ArinPressable(
                            scale: 0.88,
                            onTap: controller.clear,
                            child: Icon(
                              Icons.close_rounded,
                              color: iconColor,
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppTourAnchor(
            id: AppTourTargetId.inspireFilter,
            child: PopupMenuButton<ExploreContentFilter>(
              tooltip: l10n.inspireFilterTooltip,
              initialValue: filter,
              padding: EdgeInsets.zero,
              onSelected: onFilterSelected,
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: ExploreContentFilter.mixed,
                  checked: filter == ExploreContentFilter.mixed,
                  child: Text(l10n.inspireFilterMainFeed),
                ),
                CheckedPopupMenuItem(
                  value: ExploreContentFilter.soz,
                  checked: filter == ExploreContentFilter.soz,
                  child: Text(l10n.inspireFilterQuote),
                ),
                CheckedPopupMenuItem(
                  value: ExploreContentFilter.ayet,
                  checked: filter == ExploreContentFilter.ayet,
                  child: Text(l10n.inspireFilterVerse),
                ),
                CheckedPopupMenuItem(
                  value: ExploreContentFilter.hadis,
                  checked: filter == ExploreContentFilter.hadis,
                  child: Text(l10n.inspireFilterHadith),
                ),
              ],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: fieldBorder),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: onLight
                        ? AppColors.emeraldDark.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreEmpty extends StatelessWidget {
  const _ExploreEmpty({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onClose != null)
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: onClose,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.inspireEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.inspireEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.inspirePullToRefreshHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreError extends StatelessWidget {
  const _ExploreError({required this.message, this.onClose});

  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onClose != null)
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: onClose,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.inspireLoadFailedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.inspirePullToRetryHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
