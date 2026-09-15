import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/arin_back_button.dart';
import '../../shared/widgets/arin_loader.dart';
import '../../shared/widgets/arin_pressable.dart';
import '../../shared/widgets/arin_shell_layout.dart';
import '../../shared/widgets/arin_top_toast.dart';
import 'social_models.dart';
import 'social_motion.dart';
import 'social_repository.dart';
import 'social_share.dart';
import 'social_text.dart';
import 'social_widgets.dart';

class SocialPostPage extends StatefulWidget {
  const SocialPostPage({
    super.key,
    required this.repository,
    required this.post,
    required this.myUid,
    this.myBio = '',
    this.myUsername = '',
    this.myAvatarId = 0,
    this.knownBios = const {},
    this.knownAvatars = const {},
    required this.onPostChanged,
    this.onBioChanged,
    this.onAvatarChanged,
    this.isAdmin = false,
    this.isBanned = false,
    this.autofocusComment = false,
  });

  final SocialRepository repository;
  final SocialPost post;
  final String myUid;
  final String myBio;
  final String myUsername;
  final int myAvatarId;
  final Map<String, String> knownBios;
  final Map<String, int> knownAvatars;
  final ValueChanged<SocialPost> onPostChanged;
  final ValueChanged<String>? onBioChanged;
  final ValueChanged<int>? onAvatarChanged;
  final bool isAdmin;
  final bool isBanned;
  final bool autofocusComment;

  @override
  State<SocialPostPage> createState() => _SocialPostPageState();
}

class _SocialPostPageState extends State<SocialPostPage> {
  final _commentCtrl = TextEditingController();
  final _focus = FocusNode();
  final _composerKey = GlobalKey();
  late SocialPost _post;
  List<SocialComment> _comments = const [];
  late final Map<String, String> _knownBios;
  late final Map<String, int> _knownAvatars;
  late String _myBio;
  late int _myAvatarId;
  bool _loading = true;
  bool _sending = false;
  bool _likeInFlight = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _knownBios = Map<String, String>.from(widget.knownBios);
    _knownAvatars = Map<String, int>.from(widget.knownAvatars);
    _myBio = widget.myBio;
    _myAvatarId = widget.myAvatarId;
    _rememberBio(_post.authorUid, _post.authorBio);
    _rememberBio(widget.myUid, widget.myBio);
    _rememberAvatar(_post.authorUid, _post.authorAvatarId);
    _rememberAvatar(widget.myUid, widget.myAvatarId);
    unawaited(_load());
    if (widget.autofocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _rememberBio(String uid, String bio) {
    if (uid.isEmpty) return;
    final trimmed = bio.trim();
    if (trimmed.isEmpty) {
      if (uid == widget.myUid) _knownBios.remove(uid);
      return;
    }
    _knownBios[uid] = trimmed;
  }

  void _rememberAvatar(String uid, int avatarId) {
    if (uid.isEmpty) return;
    final id = socialNormalizeAvatarId(avatarId);
    if (id > 0) {
      _knownAvatars[uid] = id;
    } else if (uid == widget.myUid) {
      _knownAvatars.remove(uid);
    }
  }

  int _peekAvatar(String uid, int stamped) {
    return socialPeekAvatar(
      authorUid: uid,
      stampedAvatarId: stamped,
      myUid: widget.myUid,
      myAvatarId: _myAvatarId,
      knownAvatars: _knownAvatars,
    );
  }

  Future<String> _saveOwnBio(String bio) async {
    final profile = await widget.repository.setBio(bio);
    final saved = (profile.bio ?? bio).trim();
    if (mounted) {
      setState(() {
        _myBio = saved;
        _rememberBio(widget.myUid, saved);
      });
    }
    widget.onBioChanged?.call(saved);
    return saved;
  }

  Future<int> _saveOwnAvatar(int avatarId) async {
    final profile = await widget.repository.setAvatar(avatarId);
    final saved = socialNormalizeAvatarId(profile.avatarId);
    if (mounted) {
      setState(() {
        _myAvatarId = saved;
        _rememberAvatar(widget.myUid, saved);
      });
    }
    widget.onAvatarChanged?.call(saved);
    return saved;
  }

  void _showAuthor({
    required String uid,
    required String username,
    required bool premium,
    required String stampedBio,
    int stampedAvatarId = 0,
  }) {
    final mine = uid == widget.myUid;
    showSocialProfilePeek(
      context: context,
      username: username,
      bio: socialPeekBio(
        authorUid: uid,
        stampedBio: stampedBio,
        myUid: widget.myUid,
        myBio: _myBio,
        knownBios: _knownBios,
      ),
      avatarId: _peekAvatar(uid, stampedAvatarId),
      premium: premium,
      mine: mine,
      onSaveBio: mine && !widget.isBanned ? _saveOwnBio : null,
      onSaveAvatar: mine && !widget.isBanned ? _saveOwnAvatar : null,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.loadComments(postId: _post.id);
      if (!mounted) return;
      setState(() {
        _post = _likeInFlight
            ? page.post.copyWith(
                liked: _post.liked,
                likeCount: _post.likeCount,
              )
            : page.post.copyWith(liked: _post.liked);
        _comments = page.items;
        _rememberBio(page.post.authorUid, page.post.authorBio);
        _rememberAvatar(page.post.authorUid, page.post.authorAvatarId);
        for (final comment in page.items) {
          _rememberBio(comment.authorUid, comment.authorBio);
          _rememberAvatar(comment.authorUid, comment.authorAvatarId);
        }
        _loading = false;
      });
      if (!_likeInFlight) {
        widget.onPostChanged(_post);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _pullComments() async {
    try {
      final page = await widget.repository.loadComments(postId: _post.id);
      if (!mounted) return;
      setState(() {
        _post = _likeInFlight
            ? page.post.copyWith(
                liked: _post.liked,
                likeCount: _post.likeCount,
              )
            : page.post.copyWith(liked: _post.liked);
        _comments = page.items;
        _error = null;
        _rememberBio(page.post.authorUid, page.post.authorBio);
        _rememberAvatar(page.post.authorUid, page.post.authorAvatarId);
        for (final comment in page.items) {
          _rememberBio(comment.authorUid, comment.authorBio);
          _rememberAvatar(comment.authorUid, comment.authorAvatarId);
        }
      });
      if (!_likeInFlight) {
        widget.onPostChanged(_post);
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

  Future<void> _banAuthor(String targetUid) async {
    final hours = await pickSocialBanHours(context);
    if (!mounted || hours == null) return;
    try {
      await widget.repository.banUser(
        targetUid: targetUid,
        durationHours: hours,
      );
      if (!mounted) return;
      showArinTopToast(
        context,
        AppLocalizations.of(context)!.socialBanned,
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  Future<void> _toggleLike() async {
    if (widget.isBanned || _likeInFlight) return;
    final previous = _post;
    final next = !previous.liked;
    socialLikeHaptic(liking: next);
    _likeInFlight = true;
    setState(() {
      _post = previous.copyWith(
        liked: next,
        likeCount: (previous.likeCount + (next ? 1 : -1)).clamp(0, 1 << 30),
      );
    });
    widget.onPostChanged(_post);
    try {
      final result = await widget.repository.like(
        targetId: previous.id,
        liked: next,
      );
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(
          liked: result.liked,
          likeCount: result.likeCount,
        );
      });
      widget.onPostChanged(_post);
    } catch (error) {
      if (!mounted) return;
      setState(() => _post = previous);
      widget.onPostChanged(previous);
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    } finally {
      _likeInFlight = false;
    }
  }

  Future<void> _toggleCommentLike(SocialComment comment) async {
    if (widget.isBanned) return;
    HapticFeedback.selectionClick();
    final next = !comment.liked;
    setState(() {
      _comments = _comments
          .map(
            (row) => row.id == comment.id
                ? row.copyWith(
                    liked: next,
                    likeCount: (row.likeCount + (next ? 1 : -1)).clamp(
                      0,
                      1 << 30,
                    ),
                  )
                : row,
          )
          .toList(growable: false);
    });
    try {
      final result = await widget.repository.like(
        targetType: 'comment',
        targetId: comment.id,
        postId: _post.id,
        liked: next,
      );
      if (!mounted) return;
      setState(() {
        _comments = _comments
            .map(
              (row) => row.id == comment.id
                  ? row.copyWith(
                      liked: result.liked,
                      likeCount: result.likeCount,
                    )
                  : row,
            )
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _comments = _comments
            .map((row) => row.id == comment.id ? comment : row)
            .toList(growable: false);
      });
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  Future<void> _sendComment() async {
    final text = normalizeSocialBody(_commentCtrl.text);
    if (widget.isBanned) return;
    if (containsSocialInsult(text)) {
      showArinTopToast(
        context,
        AppLocalizations.of(context)!.socialProfanity,
        tone: ArinTopToastTone.error,
      );
      return;
    }
    if (!isSocialCommentValid(text) || _sending) return;
    _focus.unfocus();
    setState(() => _sending = true);
    try {
      final result = await widget.repository.addComment(
        postId: _post.id,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _rememberBio(result.comment.authorUid, result.comment.authorBio);
        _rememberAvatar(
          result.comment.authorUid,
          result.comment.authorAvatarId,
        );
        _comments = [..._comments, result.comment];
        _post = (result.post ?? _post).copyWith(
          liked: _post.liked,
          commentCount: (result.post ?? _post).commentCount,
        );
        _commentCtrl.clear();
        _sending = false;
      });
      widget.onPostChanged(_post);
      HapticFeedback.lightImpact();
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showArinTopToast(
        context,
        socialUserError(error, AppLocalizations.of(context)!.userGenericError),
        tone: ArinTopToastTone.error,
      );
    }
  }

  Future<void> _more() async {
    final l10n = AppLocalizations.of(context)!;
    final mine = _post.authorUid == widget.myUid;
    final action = await showSocialPostSheet(
      context: context,
      mine: mine,
      isAdmin: widget.isAdmin,
    );
    if (!mounted || action == null) return;
    try {
      switch (action) {
        case SocialPostSheetAction.copy:
          await Clipboard.setData(ClipboardData(text: _post.text));
          if (!mounted) return;
          showArinTopToast(context, l10n.socialCopied);
        case SocialPostSheetAction.share:
          await Future<void>.delayed(const Duration(milliseconds: 220));
          if (!mounted) return;
          await shareSocialText(context, _post.text);
        case SocialPostSheetAction.delete:
          await widget.repository.deletePost(_post.id);
          if (!mounted) return;
          Navigator.pop(context, true);
        case SocialPostSheetAction.report:
          final report = await widget.repository.reportPost(_post.id);
          if (!mounted) return;
          showArinTopToast(context, l10n.socialReported);
          if (report.hidden) Navigator.pop(context, true);
        case SocialPostSheetAction.ban:
          await _banAuthor(_post.authorUid);
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

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    final composerBottom = ArinShellLayout.composerBottomPadding(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          bottom: false,
          child: Listener(
            onPointerDown: (event) => socialUnfocusIfOutside(
              focus: _focus,
              areaKey: _composerKey,
              globalPosition: event.position,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                socialUnfocusOnUserScroll(notification, _focus);
                return false;
              },
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    ArinBackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.socialPostTitle,
                      style: TextStyle(
                        color: onDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentNeonGreen,
                  backgroundColor: onDark
                      ? AppColors.homeCardSurface
                      : AppColors.creamSurface,
                  onRefresh: _pullComments,
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  children: [
                    SocialPostCard(
                      post: _post,
                      mine: _post.authorUid == widget.myUid,
                      avatarId: _peekAvatar(
                        _post.authorUid,
                        _post.authorAvatarId,
                      ),
                      myUsername: widget.myUsername,
                      myAvatarId: _myAvatarId,
                      onOpen: _toggleLike,
                      onLike: _toggleLike,
                      onComment: () => _focus.requestFocus(),
                      onMore: _more,
                      onAuthorTap: () => _showAuthor(
                        uid: _post.authorUid,
                        username: _post.authorUsername,
                        premium: _post.authorPremium,
                        stampedBio: _post.authorBio,
                        stampedAvatarId: _post.authorAvatarId,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.socialCommentsHeading,
                      style: TextStyle(
                        color: onDark
                            ? AppColors.textOnDarkMuted
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: ArinLoader(color: AppColors.accentNeonGreen),
                        ),
                      )
                    else if (_error != null)
                      Text(
                        socialUserError(
                          _error!,
                          l10n.userGenericError,
                        ),
                        style: TextStyle(
                          color: onDark
                              ? AppColors.textOnDarkMuted
                              : AppColors.textSecondary,
                        ),
                      )
                    else if (_comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.socialCommentsEmpty,
                          style: TextStyle(
                            color: onDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      ..._comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommentTile(
                            comment: comment,
                            mine: comment.authorUid == widget.myUid,
                            avatarId: _peekAvatar(
                              comment.authorUid,
                              comment.authorAvatarId,
                            ),
                            onAuthorTap: () => _showAuthor(
                              uid: comment.authorUid,
                              username: comment.authorUsername,
                              premium: comment.authorPremium,
                              stampedBio: comment.authorBio,
                              stampedAvatarId: comment.authorAvatarId,
                            ),
                            onLike: () => _toggleCommentLike(comment),
                            onBan: widget.isAdmin &&
                                    comment.authorUid != widget.myUid
                                ? () => _banAuthor(comment.authorUid)
                                : null,
                            onDelete: comment.authorUid == widget.myUid ||
                                    widget.isAdmin
                                ? () async {
                                    try {
                                      final post = await widget.repository
                                          .deleteComment(
                                            postId: _post.id,
                                            commentId: comment.id,
                                          );
                                      if (!mounted) return;
                                      setState(() {
                                        _comments = _comments
                                            .where((row) => row.id != comment.id)
                                            .toList(growable: false);
                                        if (post != null) {
                                          _post = post.copyWith(
                                            liked: _post.liked,
                                          );
                                        }
                                      });
                                      widget.onPostChanged(_post);
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      showArinTopToast(
                                        context,
                                        socialUserError(
                                          error,
                                          l10n.userGenericError,
                                        ),
                                        tone: ArinTopToastTone.error,
                                      );
                                    }
                                  }
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
                ),
              ),
              if (widget.isBanned)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, composerBottom),
                  child: Text(
                    l10n.socialBannedBanner,
                    style: TextStyle(
                      color: onDark
                          ? AppColors.textOnDarkMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Padding(
                  key: _composerKey,
                  padding: EdgeInsets.fromLTRB(12, 8, 12, composerBottom),
                  child: _ComposerField(
                    controller: _commentCtrl,
                    focusNode: _focus,
                    hint: l10n.socialCommentHint,
                    maxLength: kSocialCommentMax,
                    sending: _sending,
                    onSend: _sendComment,
                    username: widget.myUsername,
                    avatarId: _myAvatarId,
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.mine,
    required this.onLike,
    required this.onAuthorTap,
    this.avatarId = 0,
    this.onDelete,
    this.onBan,
  });

  final SocialComment comment;
  final bool mine;
  final int avatarId;
  final VoidCallback onLike;
  final VoidCallback onAuthorTap;
  final VoidCallback? onDelete;
  final VoidCallback? onBan;

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: onDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SocialAuthorHit(
                    onTap: onAuthorTap,
                    child: Row(
                      children: [
                        SocialAvatar(
                          username: comment.authorUsername,
                          premium: comment.authorPremium,
                          avatarId: avatarId,
                          radius: 12,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SocialHandle(
                            username: comment.authorUsername,
                            premium: comment.authorPremium,
                            mine: mine,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  socialRelativeTime(comment.createdAt, DateTime.now()),
                  style: TextStyle(
                    color: onDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (onBan != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: AppLocalizations.of(context)!.socialBan,
                    onPressed: onBan,
                    icon: const Icon(
                      Icons.block_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: onDark
                          ? AppColors.textOnDarkMuted
                          : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            Text(
              comment.text,
              style: TextStyle(
                color: onDark ? AppColors.textOnDark : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            SocialCountAction(
              icon: comment.liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              count: comment.likeCount,
              active: comment.liked,
              activeColor: const Color(0xFFFF2D55),
              popOnActivate: true,
              onTap: onLike,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerField extends StatefulWidget {
  const _ComposerField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.maxLength,
    required this.sending,
    required this.onSend,
    this.username = '',
    this.avatarId = 0,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final int maxLength;
  final bool sending;
  final VoidCallback onSend;
  final String username;
  final int avatarId;

  @override
  State<_ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends State<_ComposerField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final canSend = isSocialCommentValid(widget.controller.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.homeCardSurface
            : AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.creamDark,
        ),
      ),
      child: Row(
        children: [
          if (widget.username.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SocialAvatar(
                username: widget.username,
                avatarId: widget.avatarId,
                radius: 16,
              ),
            ),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLength: widget.maxLength,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(
                color: onDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              decoration: socialPlainInputDecoration(
                hintText: widget.hint,
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                isCollapsed: false,
              ),
            ),
          ),
          ArinPressable(
            enabled: canSend && !widget.sending,
            onTap: widget.onSend,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: widget.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      color: canSend
                          ? (onDark
                                ? AppColors.accentNeonGreen
                                : AppColors.accentGreenOnLight)
                          : (onDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textMuted),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
