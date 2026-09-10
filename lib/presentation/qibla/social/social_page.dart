import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/product_metric_features.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/services/product_metrics_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/arin_back_button.dart';
import '../../shared/widgets/arin_loader.dart';
import '../../shared/widgets/arin_pressable.dart';
import '../../shared/widgets/arin_shell_layout.dart';
import '../../shared/widgets/arin_top_toast.dart';
import 'social_models.dart';
import 'social_motion.dart';
import 'social_post_page.dart';
import 'social_repository.dart';
import 'social_share.dart';
import 'social_text.dart';
import 'social_widgets.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> {
  late final SocialRepository _repo;
  SocialProfile? _profile;
  SocialFeedSort _sort = SocialFeedSort.popular;
  List<SocialPost> _posts = const [];
  bool _loading = true;
  bool _claiming = false;
  bool _posting = false;
  Object? _error;
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _bioFocus = FocusNode();
  final _composeCtrl = TextEditingController();
  final _composeFocus = FocusNode();
  final _composerKey = GlobalKey();
  final _knownBios = <String, String>{};
  final _knownAvatars = <String, int>{};
  int _claimAvatarId = 0;
  String? _freshPostId;
  bool _persistDraft = false;
  bool _draftHydrated = false;
  bool _ignoreHydrate = false;
  bool _avatarsPrecached = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(socialRepositoryProvider);
    _composeCtrl.addListener(_markDraftDirty);
    unawaited(
      ProductMetricsService.featureOpen(ProductMetricFeatures.social),
    );
    unawaited(_bootstrap());
    unawaited(_hydrateDraft());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_avatarsPrecached) return;
    _avatarsPrecached = true;
    for (final path in kSocialAvatarAssets) {
      unawaited(precacheImage(AssetImage(path), context));
    }
  }

  void _markDraftDirty() {
    _persistDraft = _composeCtrl.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _composeCtrl.removeListener(_markDraftDirty);
    if (_ignoreHydrate) {
      unawaited(_repo.saveDraft(''));
    } else if (_persistDraft || _draftHydrated) {
      unawaited(_repo.saveDraft(_composeCtrl.text));
    }
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _bioFocus.dispose();
    _composeCtrl.dispose();
    _composeFocus.dispose();
    super.dispose();
  }

  Future<void> _hydrateDraft() async {
    final draft = await _repo.loadDraft();
    if (!mounted || _ignoreHydrate) {
      _draftHydrated = true;
      return;
    }
    if (draft != null &&
        draft.isNotEmpty &&
        _composeCtrl.text.trim().isEmpty) {
      _composeCtrl.text = draft;
    }
    _draftHydrated = true;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sort = await _repo.loadSort();
      final profile = await _repo.loadProfile();
      if (!mounted) return;
      _sort = sort;
      _profile = profile;
      _claimAvatarId = profile.avatarId;
      if (profile.hasUsername && (profile.hasBio || profile.banned)) {
        final posts = await _repo.loadFeed(sort: sort);
        if (!mounted) return;
        _indexBios(posts);
        setState(() {
          _posts = posts;
          _loading = false;
        });
        _focusComposeIfEmpty();
      } else {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _refresh({bool force = true}) async {
    try {
      final posts = await _repo.loadFeed(sort: _sort, force: force);
      if (!mounted) return;
      _indexBios(posts);
      setState(() {
        _posts = posts;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _pullToRefresh() async {
    final profileFuture = _repo.loadProfile();
    try {
      final posts = await _repo.loadFeed(sort: _sort, force: true);
      SocialProfile? profile;
      try {
        profile = await profileFuture;
      } catch (_) {}
      if (!mounted) return;
      _indexBios(posts);
      setState(() {
        if (profile != null) {
          _profile = profile;
          _claimAvatarId = profile.avatarId;
        }
        _posts = posts;
        _error = null;
      });
    } catch (error) {
      try {
        final profile = await profileFuture;
        if (mounted) setState(() => _profile = profile);
      } catch (_) {}
      if (!mounted) return;
      if (_posts.isEmpty) {
        setState(() => _error = error);
      }
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  Future<void> _changeSort(SocialFeedSort sort) async {
    if (sort == _sort) return;
    HapticFeedback.selectionClick();
    setState(() {
      _sort = sort;
      _loading = true;
    });
    await _repo.saveSort(sort);
    try {
      final posts = await _repo.loadFeed(sort: sort);
      if (!mounted) return;
      _indexBios(posts);
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _indexBios(Iterable<SocialPost> posts) {
    for (final post in posts) {
      if (post.authorUid.isEmpty) continue;
      if (post.authorBio.isNotEmpty) {
        _knownBios[post.authorUid] = post.authorBio;
      }
      if (post.authorAvatarId > 0) {
        _knownAvatars[post.authorUid] = post.authorAvatarId;
      }
    }
  }

  int _peekAvatar(String uid, int stamped) {
    return socialPeekAvatar(
      authorUid: uid,
      stampedAvatarId: stamped,
      myUid: _profile?.uid,
      myAvatarId: _profile?.avatarId ?? 0,
      knownAvatars: _knownAvatars,
    );
  }

  Future<String> _saveOwnBio(String bio) async {
    final profile = await _repo.setBio(bio);
    if (mounted) {
      setState(() {
        _profile = profile;
        _claimAvatarId = profile.avatarId;
        if (profile.uid.isNotEmpty && profile.hasBio) {
          _knownBios[profile.uid] = profile.bio!.trim();
        }
      });
    }
    return profile.bio ?? bio;
  }

  Future<int> _saveOwnAvatar(int avatarId) async {
    final profile = await _repo.setAvatar(avatarId);
    if (mounted) {
      setState(() {
        _profile = profile;
        _claimAvatarId = profile.avatarId;
        if (profile.uid.isNotEmpty) {
          if (profile.avatarId > 0) {
            _knownAvatars[profile.uid] = profile.avatarId;
          } else {
            _knownAvatars.remove(profile.uid);
          }
        }
      });
    }
    return profile.avatarId;
  }

  void _showAuthor({
    required String uid,
    required String username,
    required bool premium,
    required String stampedBio,
    int stampedAvatarId = 0,
  }) {
    final mine = uid == _profile?.uid;
    showSocialProfilePeek(
      context: context,
      username: username,
      bio: socialPeekBio(
        authorUid: uid,
        stampedBio: stampedBio,
        myUid: _profile?.uid,
        myBio: _profile?.bio,
        knownBios: _knownBios,
      ),
      avatarId: _peekAvatar(uid, stampedAvatarId),
      premium: premium,
      mine: mine,
      onSaveBio: mine && _profile?.banned != true ? _saveOwnBio : null,
      onSaveAvatar: mine && _profile?.banned != true ? _saveOwnAvatar : null,
    );
  }

  Future<void> _claim() async {
    final name = _usernameCtrl.text.trim();
    final bio = normalizeSocialBody(_bioCtrl.text);
    final updatingBio = _profile?.hasUsername == true;
    if (containsSocialInsult(bio)) {
      showArinTopToast(
        context,
        AppLocalizations.of(context)!.socialProfanity,
        tone: ArinTopToastTone.error,
      );
      return;
    }
    if (!isSocialBioValid(bio) || _claiming) return;
    if (!updatingBio && !isSocialUsernameValid(name)) return;
    setState(() => _claiming = true);
    try {
      final profile = updatingBio
          ? await _repo.setBio(bio, avatarId: _claimAvatarId)
          : await _repo.claimUsername(name, bio, avatarId: _claimAvatarId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _claimAvatarId = profile.avatarId;
        _claiming = false;
        _loading = true;
      });
      await _refresh();
      if (!mounted) return;
      setState(() => _loading = false);
      _focusComposeIfEmpty();
    } catch (error) {
      if (!mounted) return;
      setState(() => _claiming = false);
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  void _applyPost(SocialPost post) {
    if (!mounted) return;
    _indexBios([post]);
    setState(() {
      _posts = _posts
          .map((row) => row.id == post.id ? post : row)
          .toList(growable: false);
    });
    _repo.rememberFeed(_sort, _posts);
  }

  Future<void> _toggleLike(SocialPost post) async {
    if (_profile?.banned == true) return;
    final next = !post.liked;
    socialLikeHaptic(liking: next);
    final updated = post.copyWith(
      liked: next,
      likeCount: (post.likeCount + (next ? 1 : -1)).clamp(0, 1 << 30),
    );
    _applyPost(updated);
    try {
      final result = await _repo.like(targetId: post.id, liked: next);
      _applyPost(
        updated.copyWith(liked: result.liked, likeCount: result.likeCount),
      );
    } catch (error) {
      _applyPost(post);
      if (!mounted) return;
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  void _focusComposeIfEmpty() {
    if (_posts.isNotEmpty ||
        _profile?.hasUsername != true ||
        _profile?.hasBio != true ||
        _profile?.banned == true ||
        _loading) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composeFocus.requestFocus();
    });
  }

  void _dismissComposeOutside(Offset globalPosition) {
    if (_composeFocus.hasFocus) {
      socialUnfocusIfOutside(
        focus: _composeFocus,
        areaKey: _composerKey,
        globalPosition: globalPosition,
      );
      return;
    }
    socialUnfocusFocusedFieldIfOutside(globalPosition);
  }

  Future<void> _openPost(SocialPost post, {bool focusComment = false}) async {
    _composeFocus.unfocus();
    HapticFeedback.selectionClick();
    final deleted = await Navigator.of(context).push<bool>(
      SocialOpenRoute(
        page: SocialPostPage(
          repository: _repo,
          post: post,
          myUid: _profile?.uid ?? '',
          myBio: _profile?.bio ?? '',
          myUsername: _profile?.username ?? '',
          myAvatarId: _profile?.avatarId ?? 0,
          knownBios: Map<String, String>.from(_knownBios),
          knownAvatars: Map<String, int>.from(_knownAvatars),
          isAdmin: _profile?.admin == true,
          isBanned: _profile?.banned == true,
          autofocusComment: focusComment && _profile?.banned != true,
          onPostChanged: _applyPost,
          onBioChanged: (bio) {
            final current = _profile;
            if (current == null) return;
            setState(() {
              _profile = current.copyWith(bio: bio);
              if (current.uid.isNotEmpty) {
                _knownBios[current.uid] = bio;
              }
            });
          },
          onAvatarChanged: (avatarId) {
            final current = _profile;
            if (current == null) return;
            setState(() {
              _profile = current.copyWith(avatarId: avatarId);
              _claimAvatarId = avatarId;
              if (current.uid.isNotEmpty) {
                if (avatarId > 0) {
                  _knownAvatars[current.uid] = avatarId;
                } else {
                  _knownAvatars.remove(current.uid);
                }
              }
            });
          },
        ),
      ),
    );
    if (deleted == true && mounted) {
      setState(() {
        _posts = _posts.where((row) => row.id != post.id).toList();
      });
      await _refresh();
    }
  }

  Future<void> _more(SocialPost post) async {
    final l10n = AppLocalizations.of(context)!;
    final mine = post.authorUid == _profile?.uid;
    final action = await showSocialPostSheet(
      context: context,
      mine: mine,
      isAdmin: _profile?.admin == true,
    );
    if (!mounted || action == null) return;
    try {
      switch (action) {
        case SocialPostSheetAction.copy:
          await Clipboard.setData(ClipboardData(text: post.text));
          if (!mounted) return;
          showArinTopToast(context, l10n.socialCopied);
        case SocialPostSheetAction.share:
          await Future<void>.delayed(const Duration(milliseconds: 220));
          if (!mounted) return;
          await shareSocialText(context, post.text);
        case SocialPostSheetAction.delete:
          await _repo.deletePost(post.id);
          if (!mounted) return;
          setState(() {
            _posts = _posts.where((row) => row.id != post.id).toList();
          });
        case SocialPostSheetAction.report:
          final report = await _repo.reportPost(post.id);
          if (!mounted) return;
          if (report.hidden) {
            setState(() {
              _posts = _posts.where((row) => row.id != post.id).toList();
            });
          }
          showArinTopToast(context, l10n.socialReported);
        case SocialPostSheetAction.ban:
          final hours = await pickSocialBanHours(context);
          if (!mounted || hours == null) return;
          await _repo.banUser(
            targetUid: post.authorUid,
            durationHours: hours,
          );
          if (!mounted) return;
          setState(() {
            _posts = _posts
                .where((row) => row.authorUid != post.authorUid)
                .toList();
          });
          showArinTopToast(context, l10n.socialBanned);
          await _refresh();
      }
    } catch (error) {
      if (!mounted) return;
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  Future<void> _submitPost() async {
    final text = normalizeSocialBody(_composeCtrl.text);
    if (containsSocialInsult(text)) {
      showArinTopToast(
        context,
        AppLocalizations.of(context)!.socialProfanity,
        tone: ArinTopToastTone.error,
      );
      return;
    }
    if (!isSocialPostValid(text) || _posting) return;
    _composeFocus.unfocus();
    setState(() => _posting = true);
    HapticFeedback.lightImpact();
    try {
      final post = await _repo.createPost(text);
      _ignoreHydrate = true;
      _persistDraft = false;
      _composeCtrl.clear();
      await _repo.saveDraft('');
      if (!mounted) return;
      _indexBios([post]);
      setState(() {
        _posts = [post, ..._posts.where((row) => row.id != post.id)];
        _posting = false;
        _freshPostId = post.id;
      });
      _repo.rememberFeed(_sort, _posts);
      final showToast = await _repo.shouldShowFirstPostToast();
      if (!mounted) return;
      if (showToast) {
        showArinTopToast(
          context,
          AppLocalizations.of(context)!.socialPostedToBoard,
        );
        await _repo.markFirstPostToastShown();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _posting = false);
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    final ready = _profile?.hasUsername == true &&
        (_profile?.hasBio == true || _profile?.banned == true);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          bottom: false,
          child: Listener(
            onPointerDown: (event) =>
                _dismissComposeOutside(event.position),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                socialUnfocusOnUserScroll(notification, _composeFocus);
                return false;
              },
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    ArinBackButton(onPressed: () => Navigator.maybePop(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.socialTitle,
                        style: TextStyle(
                          color: onDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    if (ready)
                      SocialAuthorHit(
                        onTap: () => _showAuthor(
                          uid: _profile!.uid,
                          username: _profile!.username!,
                          premium: _profile!.premium,
                          stampedBio: _profile!.bio ?? '',
                          stampedAvatarId: _profile!.avatarId,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SocialAvatar(
                              username: _profile!.username!,
                              premium: _profile!.premium,
                              avatarId: _profile!.avatarId,
                              radius: 13,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: SocialHandle(
                                username: _profile!.username!,
                                premium: _profile!.premium,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: !ready
                    ? _UsernameGate(
                        usernameController: _usernameCtrl,
                        bioController: _bioCtrl,
                        bioFocus: _bioFocus,
                        username: _profile?.username ?? _usernameCtrl.text,
                        premium: _profile?.premium == true,
                        avatarId: _claimAvatarId,
                        onAvatarChanged: (id) =>
                            setState(() => _claimAvatarId = id),
                        showUsername: _profile?.hasUsername != true,
                        claiming: _claiming,
                        loading: _loading,
                        error: _error,
                        banned: _profile?.banned == true,
                        onRetry: _bootstrap,
                        onChanged: () => setState(() {}),
                        onClaim: _claim,
                      )
                    : RefreshIndicator(
                        color: AppColors.accentNeonGreen,
                        backgroundColor: onDark
                            ? AppColors.homeCardSurface
                            : AppColors.creamSurface,
                        displacement: 40,
                        onRefresh: _pullToRefresh,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            if (_profile!.banned)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Text(
                                    l10n.socialBannedBanner,
                                    style: TextStyle(
                                      color: onDark
                                          ? AppColors.textOnDarkMuted
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverToBoxAdapter(
                                child: KeyedSubtree(
                                  key: _composerKey,
                                  child: SocialComposerBox(
                                  controller: _composeCtrl,
                                  focusNode: _composeFocus,
                                  username: _profile!.username!,
                                  premium: _profile!.premium,
                                  avatarId: _profile!.avatarId,
                                  sending: _posting,
                                  onSubmit: _submitPost,
                                  onAvatarTap: () => _showAuthor(
                                    uid: _profile!.uid,
                                    username: _profile!.username!,
                                    premium: _profile!.premium,
                                    stampedBio: _profile!.bio ?? '',
                                    stampedAvatarId: _profile!.avatarId,
                                  ),
                                ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: SocialSortToggle(
                                sort: _sort,
                                onChanged: _changeSort,
                              ),
                            ),
                            if (_loading && _posts.isEmpty)
                              const SliverToBoxAdapter(
                                child: _SocialSkeleton(),
                              )
                            else if (_error != null && _posts.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 48,
                                    bottom:
                                        ArinShellLayout.bottomContentPadding(
                                      context,
                                    ),
                                  ),
                                  child: _EmptyState(
                                    title: l10n.socialLoadFailed,
                                    body: socialUserError(
                                      _error!,
                                      l10n.userGenericError,
                                    ),
                                    action: l10n.socialTryAgain,
                                    onTap: _bootstrap,
                                  ),
                                ),
                              )
                            else if (_posts.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 36,
                                    bottom:
                                        ArinShellLayout.bottomContentPadding(
                                      context,
                                    ),
                                  ),
                                  child: _EmptyState(
                                    title: l10n.socialEmptyTitle,
                                    body: l10n.socialEmptyBody,
                                    showThreadPlaceholder: true,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  ArinShellLayout.bottomContentPadding(
                                    context,
                                  ),
                                ),
                                sliver: SliverList.separated(
                                  itemCount: _posts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final post = _posts[index];
                                    final card = SocialPostCard(
                                      post: post,
                                      mine: post.authorUid == _profile?.uid,
                                      avatarId: _peekAvatar(
                                        post.authorUid,
                                        post.authorAvatarId,
                                      ),
                                      myUsername: _profile?.username ?? '',
                                      myAvatarId: _profile?.avatarId ?? 0,
                                      onOpen: () => _openPost(post),
                                      onLike: () => _toggleLike(post),
                                      onComment: () => _openPost(
                                        post,
                                        focusComment: true,
                                      ),
                                      onMore: () => _more(post),
                                      onAuthorTap: () => _showAuthor(
                                        uid: post.authorUid,
                                        username: post.authorUsername,
                                        premium: post.authorPremium,
                                        stampedBio: post.authorBio,
                                        stampedAvatarId: post.authorAvatarId,
                                      ),
                                    );
                                    if (post.id != _freshPostId) {
                                      return card;
                                    }
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      onEnd: () {
                                        if (_freshPostId == post.id &&
                                            mounted) {
                                          setState(
                                            () => _freshPostId = null,
                                          );
                                        }
                                      },
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              10 * (1 - value),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: card,
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
        ),
      ),
    );
  }
}

class _UsernameGate extends StatelessWidget {
  const _UsernameGate({
    required this.usernameController,
    required this.bioController,
    required this.bioFocus,
    required this.username,
    required this.premium,
    required this.avatarId,
    required this.onAvatarChanged,
    required this.showUsername,
    required this.claiming,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onChanged,
    required this.onClaim,
    this.banned = false,
  });

  final TextEditingController usernameController;
  final TextEditingController bioController;
  final FocusNode bioFocus;
  final String username;
  final bool premium;
  final int avatarId;
  final ValueChanged<int> onAvatarChanged;
  final bool showUsername;
  final bool claiming;
  final bool loading;
  final bool banned;
  final Object? error;
  final Future<void> Function() onRetry;
  final VoidCallback onChanged;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    if (loading) {
      return const Center(child: ArinLoader(color: AppColors.accentNeonGreen));
    }
    final loadError = error;
    if (loadError != null) {
      return RefreshIndicator(
        color: AppColors.accentNeonGreen,
        onRefresh: onRetry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            _EmptyState(
              title: l10n.socialLoadFailed,
              body: socialUserError(loadError, l10n.userGenericError),
              action: l10n.socialTryAgain,
              onTap: onRetry,
            ),
          ],
        ),
      );
    }
    if (banned) {
      return _EmptyState(
        title: l10n.socialTitle,
        body: l10n.socialBannedBanner,
      );
    }
    final nameOk = !showUsername || isSocialUsernameValid(usernameController.text);
    final bioOk = isSocialBioValid(bioController.text);
    final valid = nameOk && bioOk;
    final titleColor = onDark ? AppColors.textOnDark : AppColors.textPrimary;
    final bodyColor = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    return RefreshIndicator(
      color: AppColors.accentNeonGreen,
      onRefresh: onRetry,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Text(
          showUsername ? l10n.socialUsernameTitle : l10n.socialBioTitle,
          style: TextStyle(
            color: titleColor,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          showUsername ? l10n.socialUsernameBody : l10n.socialBioBody,
          style: TextStyle(
            color: bodyColor,
            height: 1.4,
          ),
        ),
        if (showUsername) ...[
          const SizedBox(height: 22),
          TextField(
            controller: usernameController,
            maxLength: kSocialUsernameMax,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => bioFocus.requestFocus(),
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: l10n.socialUsernameHint,
              prefixText: '@',
              counterText:
                  '${usernameController.text.trim().length}/$kSocialUsernameMax',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.socialBioTitle,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.socialBioBody,
            style: TextStyle(
              color: bodyColor,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: bioController,
          focusNode: bioFocus,
          minLines: 2,
          maxLines: 4,
          maxLength: kSocialBioMax,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onClaim(),
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
          decoration: InputDecoration(
            hintText: l10n.socialBioHint,
            counterText:
                '${normalizeSocialBody(bioController.text).length}/$kSocialBioMax',
          ),
        ),
        const SizedBox(height: 20),
        SocialAvatarPicker(
          username: showUsername
              ? usernameController.text.trim()
              : username,
          premium: premium,
          selectedId: avatarId,
          onSelected: onAvatarChanged,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: valid && !claiming ? onClaim : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: onDark
                ? AppColors.emeraldMid
                : AppColors.emeraldDark,
          ),
          child: claiming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.socialSaveUsername),
        ),
      ],
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    this.action,
    this.onTap,
    this.showThreadPlaceholder = false,
  });

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTap;
  final bool showThreadPlaceholder;

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    return Column(
      children: [
        if (showThreadPlaceholder) ...[
          const _SocialConversationPlaceholder(count: 2),
          const SizedBox(height: 18),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onDark ? AppColors.textOnDark : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onDark
                    ? AppColors.textOnDarkMuted
                    : AppColors.textSecondary,
              ),
            ),
          ],
          if (action != null && onTap != null) ...[
            const SizedBox(height: 16),
            ArinPressable(
              onTap: onTap,
              child: Text(
                action!,
                style: TextStyle(
                  color: onDark
                      ? AppColors.accentNeonGreen
                      : AppColors.accentGreenOnLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialSkeleton extends StatelessWidget {
  const _SocialSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: _SocialConversationPlaceholder(count: 3),
    );
  }
}

class _SocialConversationPlaceholder extends StatelessWidget {
  const _SocialConversationPlaceholder({this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final bar = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final line = onDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.creamDark.withValues(alpha: 0.85);
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: line)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: bar,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 11,
                              width: 88,
                              decoration: BoxDecoration(
                                color: bar,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 9,
                              width: 44,
                              decoration: BoxDecoration(
                                color: bar.withValues(alpha: onDark ? 0.7 : 1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bar,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 180,
                    decoration: BoxDecoration(
                      color: bar,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: bar,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: bar,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: bar,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 10,
                            width: 140,
                            decoration: BoxDecoration(
                              color: bar,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
