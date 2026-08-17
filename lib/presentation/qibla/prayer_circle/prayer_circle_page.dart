import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/admob_ids.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/product_metric_features.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/services/admob_service.dart';
import '../../../data/services/product_metrics_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/providers/admob_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/premium_providers.dart';
import '../../shared/widgets/arin_back_button.dart';
import '../../shared/widgets/arin_shell_layout.dart';
import '../../shared/widgets/arin_top_toast.dart';
import 'prayer_circle_repository.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

/// Mirrors server-side `_validatedPrayerText` contact/link checks (pre-ad).
bool _prayerTextFailsContentPolicy(String value) {
  final forbiddenPatterns = <RegExp>[
    RegExp(r'https?:\/\/|www\.', caseSensitive: false),
    RegExp(r'\bTR\d{24}\b', caseSensitive: false),
    RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false),
    RegExp(r'(?:^|\s)@[A-Za-z0-9_.-]{2,}'),
    RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)'),
    RegExp(
      r'(?<![\p{L}\p{N}_])(?:iban|whatsapp|telegram|instagram|telefon|phone|ödeme|payment)(?![\p{L}\p{N}_])',
      caseSensitive: false,
      unicode: true,
    ),
    RegExp(
      r'(?<![\p{L}\p{N}_])(?:adresim|address|sokak|mahallesi|caddesi|apartmanı)(?![\p{L}\p{N}_])',
      caseSensitive: false,
      unicode: true,
    ),
    RegExp(
      r'(?<![\p{L}\p{N}_])(?:orospu|sikik|sikeyim|sik|amına|piç|ibne|kahpe|fuck|bitch|nigger|cunt|whore|faggot|قحبة|كس|شرموطة|منيوك|كافر)(?![\p{L}\p{N}_])',
      caseSensitive: false,
      unicode: true,
    ),
  ];
  return forbiddenPatterns.any((pattern) => pattern.hasMatch(value));
}

final _prayerCircleRepositoryProvider = Provider<PrayerCircleRepository>(
  (ref) => PrayerCircleRepository(),
);

enum _PrayerAdGateChoice { ad, premium, cancelled }

class _PrayerFeedState {
  const _PrayerFeedState({
    this.requests = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final List<PrayerCircleRequest> requests;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;
}

class _PrayerFeedNotifier extends StateNotifier<_PrayerFeedState> {
  _PrayerFeedNotifier(this._repository, this._focusRequestId, this._mineOnly)
    : super(const _PrayerFeedState()) {
    unawaited(refresh());
  }

  final PrayerCircleRepository _repository;
  final String? _focusRequestId;
  final bool _mineOnly;
  int? _cursor;
  String? _cursorRequestId;

  Future<void> refresh() async {
    state = _PrayerFeedState(requests: state.requests);
    try {
      final page = await _repository.loadActiveRequests(
        focusRequestId: _focusRequestId,
        mineOnly: _mineOnly,
      );
      _cursor = page.nextCursorExpiresAtMs;
      _cursorRequestId = page.nextCursorRequestId;
      state = _PrayerFeedState(
        requests: page.items,
        loading: false,
        hasMore: _cursor != null,
      );
    } catch (error) {
      state = _PrayerFeedState(
        requests: state.requests,
        loading: false,
        hasMore: _cursor != null,
        error: error,
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = _cursor;
    final cursorRequestId = _cursorRequestId;
    if (cursor == null || cursorRequestId == null || state.loadingMore) return;
    state = _PrayerFeedState(
      requests: state.requests,
      loading: false,
      loadingMore: true,
      hasMore: true,
    );
    try {
      final page = await _repository.loadActiveRequests(
        cursorExpiresAtMs: cursor,
        cursorRequestId: cursorRequestId,
        mineOnly: _mineOnly,
      );
      _cursor = page.nextCursorExpiresAtMs;
      _cursorRequestId = page.nextCursorRequestId;
      final byId = <String, PrayerCircleRequest>{
        for (final request in state.requests) request.id: request,
        for (final request in page.items) request.id: request,
      };
      final merged = byId.values.toList(growable: false)
        ..sort((a, b) {
          final byExpiry = b.expiresAt.compareTo(a.expiresAt);
          return byExpiry != 0 ? byExpiry : b.id.compareTo(a.id);
        });
      state = _PrayerFeedState(
        requests: merged,
        loading: false,
        hasMore: _cursor != null,
      );
    } catch (error) {
      state = _PrayerFeedState(
        requests: state.requests,
        loading: false,
        hasMore: true,
        error: error,
      );
    }
  }

  void updatePrayerCount(String requestId, int prayerCount) {
    final updated = state.requests
        .map(
          (request) => request.id == requestId
              ? request.copyWith(prayerCount: prayerCount, isPrayed: true)
              : request,
        )
        .toList(growable: false);
    state = _PrayerFeedState(
      requests: updated,
      loading: state.loading,
      loadingMore: state.loadingMore,
      hasMore: state.hasMore,
      error: state.error,
    );
  }
}

final _prayerFeedProvider = StateNotifierProvider.autoDispose
    .family<
      _PrayerFeedNotifier,
      _PrayerFeedState,
      ({String? focusRequestId, bool mineOnly})
    >((ref, query) {
      return _PrayerFeedNotifier(
        ref.watch(_prayerCircleRepositoryProvider),
        query.focusRequestId,
        query.mineOnly,
      );
    });

enum _PrayerView { circle, mine }

class PrayerCirclePage extends ConsumerStatefulWidget {
  const PrayerCirclePage({super.key, this.focusRequestId});

  final String? focusRequestId;

  @override
  ConsumerState<PrayerCirclePage> createState() => _PrayerCirclePageState();
}

class _PrayerCirclePageState extends ConsumerState<PrayerCirclePage> {
  _PrayerView _view = _PrayerView.circle;
  final Set<String> _prayedThisSession = {};
  final Set<String> _pendingPrayerIds = {};
  bool _submitting = false;

  ({String? focusRequestId, bool mineOnly}) _feedQuery(_PrayerView view) => (
    focusRequestId: view == _PrayerView.circle ? widget.focusRequestId : null,
    mineOnly: view == _PrayerView.mine,
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      ProductMetricsService.featureOpen(ProductMetricFeatures.prayerCircle),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      unawaited(
        ref
            .read(_prayerCircleRepositoryProvider)
            .syncNotificationDevice(locale),
      );
      final premium = ref.read(premiumEntitlementProvider).asData?.value;
      if (premium?.isActive != true) AdMobService.preloadRewarded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final circleProvider = _prayerFeedProvider(_feedQuery(_PrayerView.circle));
    final mineProvider = _prayerFeedProvider(_feedQuery(_PrayerView.mine));
    final circleFeed = ref.watch(circleProvider);
    final mineFeed = ref.watch(mineProvider);
    final feedProvider = _view == _PrayerView.mine
        ? mineProvider
        : circleProvider;
    final feed = _view == _PrayerView.mine ? mineFeed : circleFeed;
    final requests = feed.requests;
    final visible = requests;
    final isAdmin = ref.watch(isCurrentUserAdminProvider).asData?.value ?? false;

    // ArinShell'in yüzen alt navigasyon çubuğu bu sayfanın kendi Scaffold'undan
    // habersiz; Scaffold'un varsayılan FAB kenar boşluğu bu ölçüyle üst üste
    // binmesin diye FAB'ı Positioned ile doğrudan ekran altına göre konumluyoruz
    // (bkz. willpower_hub_page.dart'taki aynı desen).
    final fabBottom = ArinShellLayout.fabCornerBottomFromScreenBottom(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ArinShellBackground.buildLayered(
            context,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _PrayerAppBar(onDark: onDark),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.accentNeonGreen,
                      onRefresh: ref.read(feedProvider.notifier).refresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                            sliver: SliverToBoxAdapter(
                              child: _PrayerCircleHero(onDark: onDark),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                            sliver: SliverToBoxAdapter(
                              child: _ViewSelector(
                                onDark: onDark,
                                selected: _view,
                                allCount: circleFeed.requests.length,
                                mineCount: mineFeed.requests.length,
                                onChanged: (value) =>
                                    setState(() => _view = value),
                              ),
                            ),
                          ),
                          if (feed.loading && requests.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: ArinLoader(
                                  color: AppColors.accentNeonGreen,
                                ),
                              ),
                            )
                          else if (feed.error != null && requests.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _PrayerEmptyState(
                                onDark: onDark,
                                icon: Icons.cloud_off_rounded,
                                title: l10n.prayerCircleLoadFailed,
                                body: l10n.prayerCircleTryAgain,
                                actionLabel: l10n.prayerCircleTryAgain,
                                action: ref.read(feedProvider.notifier).refresh,
                              ),
                            )
                          else if (visible.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _PrayerEmptyState(
                                onDark: onDark,
                                icon: _view == _PrayerView.mine
                                    ? Icons.auto_awesome_outlined
                                    : Icons.volunteer_activism_outlined,
                                title: _view == _PrayerView.mine
                                    ? l10n.prayerCircleMineEmptyTitle
                                    : l10n.prayerCircleEmptyTitle,
                                body: _view == _PrayerView.mine
                                    ? l10n.prayerCircleMineEmptyBody
                                    : l10n.prayerCircleEmptyBody,
                                actionLabel: l10n.prayerCircleCreate,
                                action: _openComposer,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                118,
                              ),
                              sliver: SliverList.separated(
                                itemCount:
                                    visible.length +
                                    (feed.hasMore || feed.loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 11),
                                itemBuilder: (context, index) {
                                  if (index == visible.length) {
                                    return Semantics(
                                      button: true,
                                      label: l10n.prayerCircleLoadMore,
                                      child: Center(
                                        child: TextButton.icon(
                                          onPressed: feed.loadingMore
                                              ? null
                                              : ref
                                                    .read(feedProvider.notifier)
                                                    .loadMore,
                                          icon: feed.loadingMore
                                              ? const SizedBox.square(
                                                  dimension: 15,
                                                  child:
                                                      ArinLoader(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.expand_more_rounded,
                                                ),
                                          label: Text(
                                            l10n.prayerCircleLoadMore,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final request = visible[index];
                                  return _PrayerRequestCard(
                                    request: request,
                                    onDark: onDark,
                                    prayed:
                                        _prayedThisSession.contains(
                                          request.id,
                                        ) ||
                                        request.isMine ||
                                        request.isPrayed,
                                    busy: _pendingPrayerIds.contains(
                                      request.id,
                                    ),
                                    onPray: () => _prayFor(request),
                                    onDelete: request.isMine
                                        ? () => _deleteRequest(request)
                                        : null,
                                    onReport: request.isMine
                                        ? null
                                        : () => _reportRequest(request),
                                    onAdminDelete:
                                        isAdmin && !request.isMine
                                        ? () => _adminDeleteRequest(request)
                                        : null,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: fabBottom,
            child: Center(
              child: _CreatePrayerButton(
                onDark: onDark,
                busy: _submitting,
                onPressed: _openComposer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openComposer() async {
    if (_submitting) return;
    HapticFeedback.lightImpact();
    final draft = await showModalBottomSheet<_PrayerDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PrayerComposerSheet(),
    );
    if (draft == null || !mounted) return;
    await _submitDraft(draft);
  }

  Future<void> _submitDraft(_PrayerDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final clientRequestId = const Uuid().v4().replaceAll('-', '_');
      final repository = ref.read(_prayerCircleRepositoryProvider);
      var gate = await repository.beginSubmission(
        text: draft.text,
        category: draft.category,
        locale: locale,
        clientRequestId: clientRequestId,
      );
      if (!mounted) return;
      if (!gate.premium) {
        // Sunucu bu gönderim için kullanıcının free olduğunu kesinleştirdi.
        // Auth/provider yenilenmesi sırasında eligibility kısa süre pending
        // kalmış olsa bile rewarded akışını burada güvenle etkinleştir.
        AdMobService.setRewardedPreloadEligible(true);
        AdMobService.preloadRewarded();
        var proofId = gate.proofId;
        var customData = gate.serverSideCustomData;
        if (proofId == null || customData == null) {
          throw StateError('Reklam doğrulaması hazırlanamadı.');
        }
        var choice = await _showAdGate();
        if (!mounted || choice == _PrayerAdGateChoice.cancelled) return;
        if (choice == _PrayerAdGateChoice.premium) {
          final rootContext = rootNavigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            await rootContext.push<void>(AppRoutes.premium);
          } else {
            if (!context.mounted) return;
            await context.push<void>(AppRoutes.premium);
          }
          if (!mounted) return;
          ref.invalidate(premiumEntitlementProvider);
          var premiumConfirmed = false;
          for (var attempt = 0; attempt < 8; attempt++) {
            premiumConfirmed = await repository.isPremiumForPrayer();
            if (premiumConfirmed) break;
            await Future<void>.delayed(const Duration(seconds: 1));
            if (!mounted) return;
          }
          if (premiumConfirmed) {
            await repository.createRequest(
              text: draft.text,
              category: draft.category,
              locale: locale,
              clientRequestId: clientRequestId,
            );
            await _finishSuccessfulSubmission(locale);
            return;
          }
          // Auth, premium ekranındaki hesap bağlama sırasında değişmiş olabilir.
          // Eski proof authUid/authHash'e bağlı olduğundan yeni oturum için gate
          // yeniden başlatılır; taslak ve clientRequestId aynı kalır.
          gate = await repository.beginSubmission(
            text: draft.text,
            category: draft.category,
            locale: locale,
            clientRequestId: clientRequestId,
          );
          if (gate.premium) {
            await repository.createRequest(
              text: draft.text,
              category: draft.category,
              locale: locale,
              clientRequestId: clientRequestId,
            );
            await _finishSuccessfulSubmission(locale);
            return;
          }
          proofId = gate.proofId;
          customData = gate.serverSideCustomData;
          if (proofId == null || customData == null) {
            throw StateError('Reklam doğrulaması hazırlanamadı.');
          }
          choice = await _showAdGate();
          if (!mounted || choice != _PrayerAdGateChoice.ad) return;
        }
        final result = await ref
            .read(adMobServiceProvider)
            .showRewardedDetailed(
              ArinAdUnit.rewardedUnlock,
              serverSideCustomData: customData,
            );
        if (!mounted) return;
        if (result != RewardedAdResult.rewarded) {
          if (result != RewardedAdResult.notRewarded) {
            _showMessage(l10n.prayerCircleAdFailed);
          }
          return;
        }
        unawaited(
          ProductMetricsService.adWatch(ProductMetricFeatures.prayerCircle),
        );
        await repository.createRequest(
          text: draft.text,
          category: draft.category,
          locale: locale,
          clientRequestId: clientRequestId,
          proofId: proofId,
        );
      } else {
        await repository.createRequest(
          text: draft.text,
          category: draft.category,
          locale: locale,
          clientRequestId: clientRequestId,
        );
      }
      await _finishSuccessfulSubmission(locale);
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _finishSuccessfulSubmission(String locale) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _view = _PrayerView.mine);
    await ref
        .read(_prayerFeedProvider(_feedQuery(_PrayerView.mine)).notifier)
        .refresh();
    if (!mounted) return;
    _showMessage(l10n.prayerCircleSent);
    unawaited(
      ref.read(_prayerCircleRepositoryProvider).syncNotificationDevice(locale),
    );
  }

  Future<_PrayerAdGateChoice> _showAdGate() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final onDark = !ArinShellBackground.isLight(context);
        final surface = onDark
            ? const Color(0xFF10231B)
            : AppColors.creamSurface;
        final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
        final secondary = onDark
            ? AppColors.textOnDarkMuted
            : AppColors.textSecondary;
        // ArinShell'in yüzen alt navigasyon çubuğu SafeArea'nın bilmediği bir
        // ek yükseklik ekliyor; butonların onun üstünde bitmesi için ortak
        // ölçüyü kullanıyoruz (bkz. FAB / composer fix).
        final bottomSafePad = ArinShellLayout.bottomContentPadding(context);
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(22, 18, 22, bottomSafePad),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: AppColors.ornamentGold.withValues(alpha: 0.35),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _HandsIcon(size: 54),
                  const SizedBox(height: 12),
                  Text(
                    l10n.prayerCircleAdGateTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    l10n.prayerCircleAdGateBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondary, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'ad'),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(l10n.prayerCircleWatchAd),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emeraldMid,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'premium'),
                    child: Text(l10n.prayerCirclePremiumOption),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return switch (result) {
      'ad' => _PrayerAdGateChoice.ad,
      'premium' => _PrayerAdGateChoice.premium,
      _ => _PrayerAdGateChoice.cancelled,
    };
  }

  Future<void> _prayFor(PrayerCircleRequest request) async {
    if (_pendingPrayerIds.contains(request.id) ||
        _prayedThisSession.contains(request.id) ||
        request.isMine ||
        request.isPrayed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pendingPrayerIds.add(request.id));
    try {
      final result = await ref
          .read(_prayerCircleRepositoryProvider)
          .prayFor(request.id);
      if (!mounted) return;
      ref
          .read(_prayerFeedProvider(_feedQuery(_view)).notifier)
          .updatePrayerCount(request.id, result.prayerCount);
      setState(() => _prayedThisSession.add(request.id));
      _showMessage(
        result.counted
            ? AppLocalizations.of(context)!.prayerCirclePrayedThanks
            : AppLocalizations.of(context)!.prayerCircleAlreadyPrayed,
      );
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _pendingPrayerIds.remove(request.id));
    }
  }

  Future<void> _deleteRequest(PrayerCircleRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.prayerCircleDeleteTitle),
        content: Text(l10n.prayerCircleDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.prayerCircleCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.prayerCircleDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pendingPrayerIds.add(request.id));
    try {
      await ref.read(_prayerCircleRepositoryProvider).deleteRequest(request.id);
      await ref.read(_prayerFeedProvider(_feedQuery(_view)).notifier).refresh();
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _pendingPrayerIds.remove(request.id));
    }
  }

  Future<void> _adminDeleteRequest(PrayerCircleRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.prayerCircleAdminDeleteTitle),
        content: Text(l10n.prayerCircleAdminDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.prayerCircleCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.prayerCircleAdminDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pendingPrayerIds.add(request.id));
    try {
      await ref
          .read(_prayerCircleRepositoryProvider)
          .adminDeleteRequest(request.id);
      if (!mounted) return;
      _showMessage(l10n.prayerCircleAdminDeleted);
      await ref.read(_prayerFeedProvider(_feedQuery(_view)).notifier).refresh();
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _pendingPrayerIds.remove(request.id));
    }
  }

  Future<void> _reportRequest(PrayerCircleRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.prayerCircleReportTitle),
        content: Text(l10n.prayerCircleReportBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.prayerCircleCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.prayerCircleReportAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pendingPrayerIds.add(request.id));
    try {
      await ref.read(_prayerCircleRepositoryProvider).reportRequest(request.id);
      if (!mounted) return;
      _showMessage(l10n.prayerCircleReported);
      await ref.read(_prayerFeedProvider(_feedQuery(_view)).notifier).refresh();
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _pendingPrayerIds.remove(request.id));
    }
  }

  String _friendlyError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is FirebaseFunctionsException) {
      if (error.code == 'resource-exhausted') {
        return l10n.prayerCircleSlowDown;
      }
      if (error.code == 'invalid-argument') {
        return l10n.prayerCircleContentRejected;
      }
      if (error.code == 'failed-precondition' || error.code == 'not-found') {
        return l10n.prayerCircleExpired;
      }
    }
    return l10n.prayerCircleGenericError;
  }

  void _showMessage(String text) {
    showArinTopToast(context, text);
  }
}

class _PrayerAppBar extends StatelessWidget {
  const _PrayerAppBar({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 6),
      child: Row(
        children: [
          ArinBackButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                context.go(AppRoutes.qibla);
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.prayerCircleTitle,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.ornamentGold.withValues(alpha: 0.9),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCircleHero extends StatelessWidget {
  const _PrayerCircleHero({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    final secondary = onDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? [const Color(0xFF17382B), const Color(0xFF0D1A14)]
              : [const Color(0xFFE8E3D6), const Color(0xFFD8E5DA)],
        ),
        border: Border.all(
          color: Color.lerp(
            AppColors.emeraldLight,
            AppColors.ornamentGold,
            0.35,
          )!.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlowGreen.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HandsIcon(size: 68),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.prayerCircleHeroTitle,
                  style: TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.prayerCircleHeroBody,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12.5,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.ornamentGold,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l10n.prayerCircleTwentyFourHours,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.onDark,
    required this.selected,
    required this.allCount,
    required this.mineCount,
    required this.onChanged,
  });

  final bool onDark;
  final _PrayerView selected;
  final int allCount;
  final int mineCount;
  final ValueChanged<_PrayerView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.emeraldLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorItem(
              selected: selected == _PrayerView.circle,
              label: l10n.prayerCircleAll,
              count: allCount,
              onTap: () => onChanged(_PrayerView.circle),
            ),
          ),
          Expanded(
            child: _SelectorItem(
              selected: selected == _PrayerView.mine,
              label: l10n.prayerCircleMine,
              count: mineCount,
              onTap: () => onChanged(_PrayerView.mine),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorItem extends StatelessWidget {
  const _SelectorItem({
    required this.selected,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.emeraldMid : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.ornamentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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

class _PrayerRequestCard extends StatelessWidget {
  const _PrayerRequestCard({
    required this.request,
    required this.onDark,
    required this.prayed,
    required this.busy,
    required this.onPray,
    required this.onDelete,
    required this.onReport,
    this.onAdminDelete,
  });

  final PrayerCircleRequest request;
  final bool onDark;
  final bool prayed;
  final bool busy;
  final VoidCallback onPray;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onAdminDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    final secondary = onDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 13),
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.homeCardSurface.withValues(alpha: 0.88)
            : AppColors.creamSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: request.isMine
              ? AppColors.ornamentGold.withValues(alpha: 0.46)
              : AppColors.emeraldLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _CategoryPill(
                      label: _categoryLabel(l10n, request.category),
                      onDark: onDark,
                    ),
                    if (request.isMine)
                      _CategoryPill(
                        label: l10n.prayerCircleYours,
                        onDark: onDark,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.schedule_rounded, size: 14, color: secondary),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Text(
                  _remainingLabel(l10n, request.remaining),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDelete != null || onReport != null || onAdminDelete != null)
                PopupMenuButton<String>(
                  tooltip: l10n.prayerCircleMoreActions,
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  color: onDark
                      ? const Color(0xFF173027)
                      : AppColors.creamSurface,
                  onSelected: (value) {
                    if (value == 'delete') onDelete?.call();
                    if (value == 'report') onReport?.call();
                    if (value == 'admin_delete') onAdminDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.prayerCircleDeleteAction),
                      ),
                    if (onReport != null)
                      PopupMenuItem(
                        value: 'report',
                        child: Text(l10n.prayerCircleReportAction),
                      ),
                    if (onAdminDelete != null)
                      PopupMenuItem(
                        value: 'admin_delete',
                        child: Text(
                          l10n.prayerCircleAdminDeleteAction,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.text,
            style: TextStyle(
              color: primary,
              height: 1.48,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.ornamentGold,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.prayerCirclePrayerCount(request.prayerCount),
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: FilledButton.icon(
                  onPressed: prayed || busy ? null : onPray,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 14,
                          child: ArinLoader(strokeWidth: 2),
                        )
                      : Icon(
                          prayed
                              ? Icons.check_circle_rounded
                              : Icons.volunteer_activism_outlined,
                          size: 17,
                        ),
                  label: Text(
                    request.isMine
                        ? l10n.prayerCircleOwnRequest
                        : prayed
                        ? l10n.prayerCirclePrayed
                        : l10n.prayerCirclePray,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emeraldMid,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.emeraldMid.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _remainingLabel(AppLocalizations l10n, Duration remaining) {
    if (remaining.inHours >= 1) {
      return l10n.prayerCircleHoursLeft(remaining.inHours);
    }
    return l10n.prayerCircleMinutesLeft(remaining.inMinutes.clamp(1, 59));
  }

  static String _categoryLabel(AppLocalizations l10n, String category) {
    return switch (category) {
      'health' => l10n.prayerCircleCategoryHealth,
      'family' => l10n.prayerCircleCategoryFamily,
      'peace' => l10n.prayerCircleCategoryPeace,
      'education' => l10n.prayerCircleCategoryEducation,
      'work' => l10n.prayerCircleCategoryWork,
      _ => l10n.prayerCircleCategoryGeneral,
    };
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.onDark});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ornamentGold.withValues(alpha: onDark ? 0.13 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.ornamentGold.withValues(alpha: 0.27),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onDark ? const Color(0xFFE7C899) : AppColors.ornamentGoldDeep,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CreatePrayerButton extends StatelessWidget {
  const _CreatePrayerButton({
    required this.onDark,
    required this.busy,
    required this.onPressed,
  });

  final bool onDark;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.prayerCircleCreate,
      child: Tooltip(
        message: l10n.prayerCircleCreate,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: busy ? null : onPressed,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: ArinLoader(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(l10n.prayerCircleCreate),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emeraldMid,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerEmptyState extends StatelessWidget {
  const _PrayerEmptyState({
    required this.onDark,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.action,
  });

  final bool onDark;
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    final secondary = onDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 22, 30, 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.ornamentGold),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary, height: 1.45),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: action, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _PrayerDraft {
  const _PrayerDraft({required this.text, required this.category});

  final String text;
  final String category;
}

class _PrayerComposerSheet extends StatefulWidget {
  const _PrayerComposerSheet();

  @override
  State<_PrayerComposerSheet> createState() => _PrayerComposerSheetState();
}

class _PrayerComposerSheetState extends State<_PrayerComposerSheet> {
  static const _kCategoryIcons = <String, IconData>{
    'general': Icons.auto_awesome_rounded,
    'health': Icons.favorite_rounded,
    'family': Icons.home_rounded,
    'peace': Icons.nightlight_round,
    'education': Icons.menu_book_rounded,
    'work': Icons.work_outline_rounded,
  };

  final _controller = TextEditingController();
  String _category = 'general';
  String? _error;
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final length = _controller.text.length;
      if (length != _length) setState(() => _length = length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    final secondary = onDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final categories = <(String, String)>[
      ('general', l10n.prayerCircleCategoryGeneral),
      ('health', l10n.prayerCircleCategoryHealth),
      ('family', l10n.prayerCircleCategoryFamily),
      ('peace', l10n.prayerCircleCategoryPeace),
      ('education', l10n.prayerCircleCategoryEducation),
      ('work', l10n.prayerCircleCategoryWork),
    ];
    final counterColor = _length > 400
        ? Theme.of(context).colorScheme.error
        : _length > 340
        ? AppColors.ornamentGold
        : secondary.withValues(alpha: 0.7);
    // ArinShell'in yüzen alt navigasyon çubuğu bu modal'ın barrier'ından
    // habersiz kaldığı için gövde altına aynı ölçüyü ekliyoruz (bkz. FAB fix).
    final bottomSafePad = ArinShellLayout.bottomContentPadding(context);
    return GestureDetector(
      // Kart dışındaki boşluğa (barrier üstü) dokununca modal'ı kapatır;
      // showModalBottomSheet'in kendi barrier'ı bu widget'ın "boş" alanına
      // güvenmek yerine burada açıkça garanti ediyoruz.
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight - viewInsets.top),
            child: GestureDetector(
              // Kartın kendisine dokununca dış GestureDetector'a taşıp
              // modal'ı kapatmasın.
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: onDark
                        ? const Color(0xFF10231B)
                        : AppColors.creamSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: AppColors.ornamentGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20, 10, 20, bottomSafePad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: secondary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            height: 1,
                            width: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.ornamentGold.withValues(alpha: 0),
                                  AppColors.ornamentGold.withValues(
                                    alpha: 0.55,
                                  ),
                                  AppColors.ornamentGold.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.emeraldMid,
                                    AppColors.emeraldDark,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: AppColors.ornamentGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  l10n.prayerCircleComposeTitle,
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: Text(
                            l10n.prayerCircleComposeBody,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 420,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(color: primary, height: 1.5),
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                maxLength,
                                required isFocused,
                              }) => null,
                          decoration: InputDecoration(
                            hintText: l10n.prayerCircleHint,
                            hintStyle: TextStyle(
                              color: secondary.withValues(alpha: 0.6),
                            ),
                            errorText: _error,
                            filled: true,
                            fillColor: onDark
                                ? Colors.black.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.45),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.emeraldLight.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.ornamentGold.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$_length/420',
                            style: TextStyle(
                              color: counterColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.prayerCircleCategory,
                          style: TextStyle(
                            color: primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .map(
                                (item) => _ComposerCategoryPill(
                                  label: item.$2,
                                  icon: _kCategoryIcons[item.$1]!,
                                  selected: _category == item.$1,
                                  onDark: onDark,
                                  onTap: () =>
                                      setState(() => _category = item.$1),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          decoration: BoxDecoration(
                            color: onDark
                                ? Colors.black.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.ornamentGold.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: AppColors.ornamentGold,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.prayerCirclePrivacyNote,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 10.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 20,
                                color: AppColors.ornamentGold.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.visibility_off_outlined,
                                    color: AppColors.emeraldMid,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        l10n.prayerCircleAcceptRulesLabel,
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 11.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ComposerSubmitButton(
                          enabled: true,
                          label: l10n.prayerCircleContinue,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length < 8) {
      setState(() => _error = l10n.prayerCircleTooShort);
      return;
    }
    if (_prayerTextFailsContentPolicy(text)) {
      setState(() => _error = l10n.prayerCircleContentRejected);
      return;
    }
    setState(() => _error = null);
    Navigator.pop(context, _PrayerDraft(text: text, category: _category));
  }
}

class _ComposerCategoryPill extends StatelessWidget {
  const _ComposerCategoryPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = onDark ? AppColors.textOnDark : AppColors.emeraldDark;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.emeraldMid : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.emeraldMid
                    : primary.withValues(alpha: 0.22),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.emeraldMid.withValues(alpha: 0.28),
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
                  icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : primary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerSubmitButton extends StatelessWidget {
  const _ComposerSubmitButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.emeraldMid, AppColors.emeraldDark],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.emeraldMid.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? onPressed : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

class _HandsIcon extends StatelessWidget {
  const _HandsIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.emeraldMid.withValues(alpha: 0.24),
            AppColors.ornamentGold.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.ornamentGold.withValues(alpha: 0.4),
        ),
      ),
      child: Icon(
        Icons.volunteer_activism_rounded,
        color: AppColors.ornamentGold,
        size: size * 0.48,
      ),
    );
  }
}
