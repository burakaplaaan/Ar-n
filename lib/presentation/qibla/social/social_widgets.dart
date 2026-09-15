import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/arin_popup.dart';
import '../../shared/widgets/arin_pressable.dart';
import 'social_models.dart';
import 'social_motion.dart';
import 'social_repository.dart';
import 'social_text.dart';

class SocialAuthorHit extends StatelessWidget {
  const SocialAuthorHit({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => ArinDialogOrigin.remember(event.position),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: child,
      ),
    );
  }
}

Future<void> showSocialProfilePeek({
  required BuildContext context,
  required String username,
  required String bio,
  required bool premium,
  bool mine = false,
  int avatarId = 0,
  Future<String> Function(String bio)? onSaveBio,
  Future<int> Function(int avatarId)? onSaveAvatar,
}) {
  return showArinPopup<void>(
    context: context,
    builder: (dialogContext) => _SocialProfilePeek(
      username: username,
      bio: bio,
      premium: premium,
      mine: mine,
      avatarId: avatarId,
      onSaveBio: onSaveBio,
      onSaveAvatar: onSaveAvatar,
    ),
  );
}

class SocialPremiumTick extends StatelessWidget {
  const SocialPremiumTick({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified_rounded,
      size: size,
      color: AppColors.goldAccent,
    );
  }
}

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.username,
    this.premium = false,
    this.radius = 16,
    this.avatarId = 0,
  });

  final String username;
  final bool premium;
  final double radius;
  final int avatarId;

  static const _palette = <Color>[
    Color(0xFF2D7A5F),
    Color(0xFF3D6B8C),
    Color(0xFF8B5E3C),
    Color(0xFF6B4C7A),
    Color(0xFF4A6B4F),
    Color(0xFF8A5A4A),
    Color(0xFF3F6B6B),
    Color(0xFF6B5A3F),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[socialAvatarColorIndex(username, _palette.length)];
    final asset = socialAvatarAsset(avatarId);
    final size = radius * 2;
    final initial = username.isEmpty
        ? '?'
        : username.characters.first.toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (asset == null)
            CircleAvatar(
              radius: radius,
              backgroundColor: color,
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.82,
                ),
              ),
            )
          else
            ClipOval(
              child: ColoredBox(
                color: const Color(0xFFF6EFE4),
                child: Image.asset(
                  asset,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.16),
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: radius,
                    backgroundColor: color,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w800,
                        fontSize: radius * 0.82,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (premium)
            Positioned(
              right: -3,
              bottom: -2,
              child: SocialPremiumTick(size: radius * 0.72),
            ),
        ],
      ),
    );
  }
}

class SocialAvatarPicker extends StatelessWidget {
  const SocialAvatarPicker({
    super.key,
    required this.username,
    required this.selectedId,
    required this.onSelected,
    this.premium = false,
  });

  final String username;
  final int selectedId;
  final bool premium;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final ring = onDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight;
    final titleColor = onDark ? AppColors.textOnDark : AppColors.textPrimary;
    final inset = onDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.socialAvatarNone,
          style: TextStyle(
            color: titleColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.socialAvatarLetterHint,
          style: TextStyle(color: muted, height: 1.35, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ArinPressable(
          scale: 0.98,
          sink: 0,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(0);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: inset,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedId == 0 ? ring : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  SocialAvatar(
                    username: username,
                    avatarId: 0,
                    premium: premium && selectedId == 0,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.socialAvatarNone,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.socialAvatarTitle,
          style: TextStyle(
            color: titleColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.socialAvatarHint,
          style: TextStyle(color: muted, height: 1.35, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var id = 1; id <= kSocialAvatarAssets.length; id++)
              _AvatarChoice(
                username: username,
                avatarId: id,
                premium: premium && id == selectedId,
                selected: id == selectedId,
                ring: ring,
                onTap: () => onSelected(id),
              ),
          ],
        ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.username,
    required this.avatarId,
    required this.selected,
    required this.ring,
    required this.onTap,
    this.premium = false,
  });

  final String username;
  final int avatarId;
  final bool selected;
  final bool premium;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArinPressable(
      scale: 0.94,
      sink: 0,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? ring : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SocialAvatar(
                username: username,
                avatarId: avatarId,
                premium: premium,
                radius: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialHandle extends StatelessWidget {
  const SocialHandle({
    super.key,
    required this.username,
    required this.premium,
    this.mine = false,
    this.compact = false,
    this.time,
  });

  final String username;
  final bool premium;
  final bool mine;
  final bool compact;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final nameStyle = TextStyle(
      color: onDark ? AppColors.textOnDark : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 13.5 : 14.5,
      letterSpacing: -0.2,
      height: 1.1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        if (premium) ...[
          const SizedBox(width: 4),
          SocialPremiumTick(size: compact ? 13 : 15),
        ],
        if (time != null && time!.trim().isNotEmpty) ...[
          Text(
            ' · ${time!.trim()}',
            style: TextStyle(
              color: onDark ? AppColors.textOnDarkMuted : AppColors.textMuted,
              fontSize: compact ? 12 : 12.5,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
        if (mine) ...[
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.socialYou,
            style: TextStyle(
              color: onDark
                  ? AppColors.accentNeonGreen
                  : AppColors.accentGreenOnLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialProfilePeek extends StatefulWidget {
  const _SocialProfilePeek({
    required this.username,
    required this.bio,
    required this.premium,
    required this.mine,
    this.avatarId = 0,
    this.onSaveBio,
    this.onSaveAvatar,
  });

  final String username;
  final String bio;
  final bool premium;
  final bool mine;
  final int avatarId;
  final Future<String> Function(String bio)? onSaveBio;
  final Future<int> Function(int avatarId)? onSaveAvatar;

  @override
  State<_SocialProfilePeek> createState() => _SocialProfilePeekState();
}

class _SocialProfilePeekState extends State<_SocialProfilePeek> {
  late final TextEditingController _bioCtrl;
  late String _bio;
  late int _avatarId;
  late int _savedAvatarId;
  bool _editing = false;
  bool _saving = false;
  bool _savingAvatar = false;
  String? _error;

  bool get _canEdit => widget.mine && widget.onSaveBio != null;
  bool get _canEditAvatar => widget.mine && widget.onSaveAvatar != null;
  bool get _avatarDirty => _avatarId != _savedAvatarId;

  @override
  void initState() {
    super.initState();
    _bio = widget.bio.trim();
    _bioCtrl = TextEditingController(text: _bio);
    _avatarId = socialNormalizeAvatarId(widget.avatarId);
    _savedAvatarId = _avatarId;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  void _pickAvatar(int id) {
    if (!_canEditAvatar) return;
    setState(() {
      _avatarId = socialNormalizeAvatarId(id);
      _error = null;
    });
  }

  bool get _bioDirty =>
      _editing && normalizeSocialBody(_bioCtrl.text) != _bio;

  bool get _canCommit =>
      !_saving && !_savingAvatar && (_avatarDirty || _bioDirty);

  Future<bool> _persistAvatar() async {
    final onSave = widget.onSaveAvatar;
    if (onSave == null || _avatarId == _savedAvatarId) return true;
    _savingAvatar = true;
    if (mounted) setState(() => _error = null);
    try {
      final saved = socialNormalizeAvatarId(await onSave(_avatarId));
      if (!mounted) return false;
      setState(() {
        _avatarId = saved;
        _savedAvatarId = saved;
        _savingAvatar = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _savingAvatar = false;
        _error = socialUserError(
          error,
          AppLocalizations.of(context)!.userGenericError,
        );
      });
      return false;
    }
  }

  Future<bool> _persistBio() async {
    final onSave = widget.onSaveBio;
    final next = normalizeSocialBody(_bioCtrl.text);
    if (onSave == null) return true;
    if (containsSocialInsult(next)) {
      setState(() => _error = AppLocalizations.of(context)!.socialProfanity);
      return false;
    }
    if (!isSocialOptionalBioValid(next)) return false;
    if (next == _bio) {
      setState(() {
        _editing = false;
        _error = null;
      });
      return true;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = (await onSave(next)).trim();
      if (!mounted) return false;
      setState(() {
        _bio = saved.isEmpty ? next : saved;
        _bioCtrl.text = _bio;
        _editing = false;
        _saving = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _error = socialUserError(
          error,
          AppLocalizations.of(context)!.userGenericError,
        );
      });
      return false;
    }
  }

  Future<void> _commitAndClose() async {
    if (!_canCommit) return;
    if (_avatarDirty && !await _persistAvatar()) return;
    if (!mounted) return;
    if (_bioDirty && !await _persistBio()) return;
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final surface = onDark ? AppColors.homeCardSurface : AppColors.creamSurface;
    final border = onDark
        ? AppColors.emeraldMid.withValues(alpha: 0.38)
        : AppColors.creamDark;
    final titleColor = onDark ? AppColors.textOnDark : AppColors.textPrimary;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final inset = onDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final empty = _bio.isEmpty;
    final draftOk = isSocialOptionalBioValid(_bioCtrl.text);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Semantics(
      label: l10n.socialProfileTitle,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, keyboard),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: SingleChildScrollView(
              child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: onDark ? 0.42 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SocialAvatar(
                      username: widget.username,
                      premium: widget.premium,
                      avatarId: _avatarId,
                      radius: 28,
                    ),
                    const SizedBox(height: 12),
                    SocialHandle(
                      username: widget.username,
                      premium: widget.premium,
                      mine: widget.mine,
                    ),
                    if (_canEditAvatar) ...[
                      const SizedBox(height: 16),
                      SocialAvatarPicker(
                        username: widget.username,
                        premium: widget.premium,
                        selectedId: _avatarId,
                        onSelected: _pickAvatar,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.socialBioTitle,
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (_canEdit && !_editing)
                          ArinPressable(
                            scale: 0.97,
                            sink: 0,
                            onTap: () => setState(() {
                              _editing = true;
                              _error = null;
                            }),
                            child: Text(
                              l10n.socialBioEdit,
                              style: TextStyle(
                                color: onDark
                                    ? AppColors.accentNeonGreen
                                    : AppColors.accentGreenOnLight,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: inset,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: _editing
                            ? TextField(
                                controller: _bioCtrl,
                                autofocus: true,
                                minLines: 2,
                                maxLines: 4,
                                maxLength: kSocialBioMax,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 14.5,
                                  height: 1.45,
                                ),
                                decoration: socialPlainInputDecoration(
                                  hintText: l10n.socialBioHint,
                                  hintStyle: TextStyle(color: muted),
                                  counterText:
                                      '${normalizeSocialBody(_bioCtrl.text).length}/$kSocialBioMax',
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: Text(
                                  empty ? l10n.socialBioEmpty : _bio,
                                  style: TextStyle(
                                    color: empty ? muted : titleColor,
                                    fontSize: 14.5,
                                    height: 1.45,
                                    fontStyle: empty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    if (_editing) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ArinPressable(
                              scale: 0.98,
                              sink: 0,
                              onTap: _saving
                                  ? null
                                  : () => setState(() {
                                        _bioCtrl.text = _bio;
                                        _editing = false;
                                        _error = null;
                                      }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  l10n.socialCancel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ArinPressable(
                              enabled: draftOk && _canCommit,
                              scale: 0.98,
                              sink: 0,
                              onTap: draftOk && _canCommit
                                  ? _commitAndClose
                                  : null,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: onDark
                                      ? AppColors.emeraldMid
                                      : AppColors.emeraldDark,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  child: Center(
                                    child: _saving
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            l10n.socialSaveUsername,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_canEditAvatar) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _canCommit && draftOk ? _commitAndClose : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: onDark
                              ? AppColors.emeraldMid
                              : AppColors.emeraldDark,
                        ),
                        child: _savingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.socialSaveUsername),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class SocialComposerBox extends StatefulWidget {
  const SocialComposerBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.username,
    required this.premium,
    required this.sending,
    required this.onSubmit,
    this.avatarId = 0,
    this.onAvatarTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String username;
  final bool premium;
  final int avatarId;
  final bool sending;
  final VoidCallback onSubmit;
  final VoidCallback? onAvatarTap;

  @override
  State<SocialComposerBox> createState() => _SocialComposerBoxState();
}

class _SocialComposerBoxState extends State<SocialComposerBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant SocialComposerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
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
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final used = widget.controller.text.characters.length;
    final canSend = isSocialPostValid(widget.controller.text) && !widget.sending;
    final line = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.8);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.onAvatarTap == null
                    ? SocialAvatar(
                        username: widget.username,
                        premium: widget.premium,
                        avatarId: widget.avatarId,
                        radius: 20,
                      )
                    : SocialAuthorHit(
                        onTap: widget.onAvatarTap!,
                        child: SocialAvatar(
                          username: widget.username,
                          premium: widget.premium,
                          avatarId: widget.avatarId,
                          radius: 20,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    minLines: 2,
                    maxLines: 8,
                    maxLength: kSocialPostMax,
                    style: TextStyle(
                      color: onDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: socialPlainInputDecoration(
                      hintText: l10n.socialComposeHint,
                      hintStyle: TextStyle(
                        color: onDark
                            ? AppColors.textOnDarkMuted.withValues(alpha: 0.62)
                            : AppColors.textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                _SocialCharMeter(used: used, max: kSocialPostMax),
                const SizedBox(width: 10),
                ArinPressable(
                  enabled: canSend,
                  scale: 0.96,
                  sink: 0,
                  onTap: canSend ? widget.onSubmit : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: canSend ? 1 : 0.38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: onDark
                            ? AppColors.emeraldMid
                            : AppColors.emeraldDark,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        child: widget.sending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.socialCompose,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialCharMeter extends StatelessWidget {
  const _SocialCharMeter({required this.used, required this.max});

  final int used;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (used <= 0) return const SizedBox(width: 22, height: 22);
    final remaining = max - used;
    final progress = (used / max).clamp(0.0, 1.0);
    final warn = remaining <= 20;
    final danger = remaining < 0;
    final color = danger
        ? AppColors.error
        : warn
            ? AppColors.warning
            : AppColors.accentNeonGreen;
    final size = warn ? 26.0 : 22.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CharRingPainter(progress: progress, color: color),
        child: warn
            ? Center(
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CharRingPainter extends CustomPainter {
  const _CharRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57079632679,
      6.28318530718 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CharRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class SocialSortToggle extends StatelessWidget {
  const SocialSortToggle({
    super.key,
    required this.sort,
    required this.onChanged,
  });

  final SocialFeedSort sort;
  final ValueChanged<SocialFeedSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final popular = sort == SocialFeedSort.popular;
    return Align(
      alignment: Alignment.centerLeft,
      child: ArinPressable(
        scale: 0.98,
        sink: 0,
        onTap: () => onChanged(
          popular ? SocialFeedSort.latest : SocialFeedSort.popular,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                popular ? l10n.socialSortPopular : l10n.socialSortNewest,
                style: TextStyle(
                  color: onDark
                      ? AppColors.textOnDarkMuted.withValues(alpha: 0.55)
                      : AppColors.textMuted.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.unfold_more_rounded,
                size: 15,
                color: onDark
                    ? AppColors.textOnDarkMuted.withValues(alpha: 0.45)
                    : AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialCountAction extends StatefulWidget {
  const SocialCountAction({
    super.key,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
    this.activeColor,
    this.popOnActivate = false,
  });

  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool popOnActivate;

  @override
  State<SocialCountAction> createState() => _SocialCountActionState();
}

class _SocialCountActionState extends State<SocialCountAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant SocialCountAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.popOnActivate && !oldWidget.active && widget.active) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final idle = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final color = widget.active
        ? (widget.activeColor ??
              (onDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight))
        : idle;
    return ArinPressable(
      scale: 0.92,
      sink: 0,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                final rest = widget.active ? 1.08 : 1.0;
                final burst =
                    1.0 + (0.38 * (1 - (2 * _pop.value - 1).abs()));
                final scale = _pop.isAnimating ? rest * burst : rest;
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(widget.icon, size: 18, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              widget.count == 0 ? '' : '${widget.count}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialPostCard extends StatefulWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.mine,
    required this.onOpen,
    required this.onLike,
    required this.onComment,
    required this.onMore,
    this.onAuthorTap,
    this.avatarId = 0,
    this.myUsername = '',
    this.myAvatarId = 0,
  });

  final SocialPost post;
  final bool mine;
  final int avatarId;
  final String myUsername;
  final int myAvatarId;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onMore;
  final VoidCallback? onAuthorTap;

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heart;
  DateTime? _lastPointerAt;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_heart.isAnimating) return;
    _heart.forward(from: 0);
    if (widget.post.liked) {
      HapticFeedback.lightImpact();
      return;
    }
    widget.onLike();
  }

  void _onCardPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final previous = _lastPointerAt;
    _lastPointerAt = now;
    if (previous != null &&
        now.difference(previous) <= const Duration(milliseconds: 280)) {
      _lastPointerAt = null;
      _onDoubleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final mine = widget.mine;
    final onDark = !ArinShellBackground.isLight(context);
    final border = mine
        ? (onDark
              ? AppColors.accentNeonGreen.withValues(alpha: 0.4)
              : AppColors.accentGreenOnLight.withValues(alpha: 0.42))
        : (onDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.creamDark.withValues(alpha: 0.85));
    final fill = mine
        ? Color.lerp(
            onDark ? AppColors.homeCardSurface : AppColors.creamSurface,
            onDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight,
            onDark ? 0.07 : 0.06,
          )!
        : (onDark
              ? AppColors.homeCardSurface.withValues(alpha: 0.72)
              : AppColors.creamSurface.withValues(alpha: 0.92));
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 1.18).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
    ]).animate(_heart);
    final fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
      TweenSequenceItem(tween: ConstantTween(1), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 34),
    ]).animate(_heart);

    return Hero(
      tag: 'social-post-${post.id}',
      flightShuttleBuilder: (context, animation, direction, from, to) =>
          to.widget,
      child: Material(
        color: Colors.transparent,
        child: Listener(
          onPointerDown: _onCardPointerDown,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border, width: mine ? 1.2 : 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SocialAuthorHit(
                              onTap: widget.onAuthorTap ?? widget.onOpen,
                              child: Row(
                                children: [
                                  SocialAvatar(
                                    username: post.authorUsername,
                                    premium: post.authorPremium,
                                    avatarId: widget.avatarId,
                                    radius: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SocialHandle(
                                      username: post.authorUsername,
                                      premium: post.authorPremium,
                                      mine: mine,
                                      time: socialRelativeTime(
                                        post.createdAt,
                                        DateTime.now(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onMore,
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: onDark
                                  ? AppColors.textOnDarkMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ArinPressable(
                        scale: 0.99,
                        sink: 0.4,
                        onTap: widget.onOpen,
                        onLongPress: widget.onMore,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SocialPostBody(
                                text: post.text,
                                onDark: onDark,
                              ),
                              if (post.previewComments.isNotEmpty)
                                _SocialCommentThread(
                                  comments: post.previewComments
                                      .take(2)
                                      .toList(growable: false),
                                  onDark: onDark,
                                  myUsername: widget.myUsername,
                                  myAvatarId: widget.myAvatarId,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          SocialCountAction(
                            icon: post.liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            count: post.likeCount,
                            active: post.liked,
                            activeColor: const Color(0xFFFF2D55),
                            popOnActivate: true,
                            onTap: widget.onLike,
                          ),
                          const SizedBox(width: 8),
                          SocialCountAction(
                            icon: Icons.mode_comment_outlined,
                            count: post.commentCount,
                            active: false,
                            onTap: widget.onComment,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _heart,
                  builder: (context, child) {
                    if (_heart.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: fade.value,
                      child: Transform.scale(
                        scale: scale.value,
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 72,
                    color: Color(0xFFFF2D55),
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

class _SocialPostBody extends StatelessWidget {
  const _SocialPostBody({required this.text, required this.onDark});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final parts = socialLeadLine(text);
    final color = onDark ? AppColors.textOnDark : AppColors.textPrimary;
    final lead = TextStyle(
      color: color,
      fontSize: 17.5,
      height: 1.32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    final rest = TextStyle(
      color: color,
      fontSize: 15,
      height: 1.38,
      fontWeight: FontWeight.w400,
    );
    if (parts.rest == null) {
      return Text(parts.lead, style: lead);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parts.lead, style: lead),
        const SizedBox(height: 4),
        Text(parts.rest!, style: rest),
      ],
    );
  }
}

class _SocialCommentThread extends StatelessWidget {
  const _SocialCommentThread({
    required this.comments,
    required this.onDark,
    this.myUsername = '',
    this.myAvatarId = 0,
  });

  final List<SocialCommentPreview> comments;
  final bool onDark;
  final String myUsername;
  final int myAvatarId;

  @override
  Widget build(BuildContext context) {
    final rail = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.creamDark.withValues(alpha: 0.95);
    final nameColor = onDark ? AppColors.textOnDark : AppColors.textPrimary;
    final bodyColor = onDark
        ? AppColors.textOnDarkMuted.withValues(alpha: 0.88)
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
              decoration: BoxDecoration(
                color: rail,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < comments.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SocialAvatar(
                          username: comments[i].username,
                          avatarId: comments[i].username == myUsername &&
                                  myUsername.isNotEmpty
                              ? myAvatarId
                              : comments[i].avatarId,
                          radius: 9,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${comments[i].username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: nameColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comments[i].text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: bodyColor,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
