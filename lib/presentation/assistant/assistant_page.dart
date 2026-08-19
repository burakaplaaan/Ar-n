import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/product_metric_features.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/product_metrics_service.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/user_profile_providers.dart';
import '../shared/widgets/arin_shell_layout.dart';
import 'assistant_calendar.dart';
import 'assistant_context_builder.dart';
import 'assistant_prayer_countdown.dart';
import 'assistant_destinations.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_session.dart';
import 'assistant_tool_executor.dart';
import 'widgets/assistant_hilal_mark.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository();
});

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  AssistantSession get _chat => ref.read(assistantSessionProvider);
  List<AssistantChatTurn> get _turns => _chat.turns;
  bool get _sending => _chat.sending;
  set _sending(bool value) => _chat.sending = value;
  String? get _banner => _chat.banner;
  set _banner(String? value) => _chat.banner = value;
  int get _seq => _chat.seq;
  set _seq(int value) => _chat.seq = value;
  int? get _streamingId => _chat.streamingId;
  set _streamingId(int? value) => _chat.streamingId = value;
  Set<int> get _revealed => _chat.revealed;

  static const _maxUserChars = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProductMetricsService.featureOpen(ProductMetricFeatures.assistant);
      if (_turns.isNotEmpty) _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  int get _charCount => _input.text.characters.length;

  bool get _overLimit => _charCount > _maxUserChars;

  Future<void> _send() => _sendPrompt(_input.text);

  Future<void> _sendPrompt(String raw) async {
    final l10n = AppLocalizations.of(context)!;
    final text = raw.trim();
    if (text.isEmpty || _sending || text.characters.length > _maxUserChars) {
      return;
    }
    _focus.unfocus();
    final local = resolveAssistantLocalRoute(text);
    setState(() {
      _sending = true;
      _banner = null;
      _turns.add(AssistantChatTurn(role: 'user', text: text, id: ++_seq));
      _input.clear();
    });
    _scrollToEnd();

    if (isRamadanCountdownAsk(text)) {
      final locale = Localizations.localeOf(context).languageCode;
      final reply = formatRamadanAssistantReply(
        l10n: l10n,
        locale: locale,
        now: DateTime.now(),
      );
      setState(() {
        final id = ++_seq;
        _streamingId = id;
        _turns.add(AssistantChatTurn(role: 'model', text: reply, id: id));
        _sending = false;
      });
      _scrollToEnd();
      return;
    }

    final prayerTarget = matchAssistantPrayerTarget(text);
    if (prayerTarget != null) {
      final reply = formatPrayerCountdownReply(
        l10n: l10n,
        times: ref.read(prayerTimesProvider).asData?.value,
        now: DateTime.now(),
        target: prayerTarget,
      );
      setState(() {
        final id = ++_seq;
        _streamingId = id;
        _turns.add(
          AssistantChatTurn(role: 'model', text: reply ?? l10n.assistantPrayerTimesMissing, id: id),
        );
        _sending = false;
      });
      _scrollToEnd();
      return;
    }

    if (local != null) {
      final reply = local.kind == AssistantLocalKind.lockVerseGuide
          ? l10n.assistantLockVerseGuide
          : l10n.assistantNavigatingThere;
      setState(() {
        final id = ++_seq;
        _streamingId = id;
        _turns.add(AssistantChatTurn(role: 'model', text: reply, id: id));
        _sending = false;
      });
      _scrollToEnd();
      if (!mounted) return;
      await AssistantToolExecutor(ref, context).run(
        AssistantAction(name: 'open_page', args: {'page': local.page}),
      );
      return;
    }

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final history = _turns.length <= 1
          ? const <AssistantChatTurn>[]
          : _turns.sublist(0, _turns.length - 1);
      final result = await ref.read(assistantRepositoryProvider).send(
        message: text,
        history: history.length > 8 ? history.sublist(history.length - 8) : history,
        context: buildAssistantContext(ref: ref, locale: locale),
      );
      if (!mounted) return;
      var reply = result.reply;
      if (result.actions.isNotEmpty) {
        final executor = AssistantToolExecutor(ref, context);
        for (final action in result.actions) {
          if (!mounted) return;
          final note = await executor.run(action);
          if (note != null && note.isNotEmpty) {
            final failed = note != result.reply &&
                (action.name == 'mark_prayer' ||
                    action.name == 'create_alarm' ||
                    action.name == 'set_notifications');
            reply = (reply.isEmpty || failed) ? note : reply;
          }
          if (action.name == 'open_page') break;
        }
      }
      final inferred = matchAssistantPage(text);
      final opened = result.actions.any((a) => a.name == 'open_page');
      if (!opened &&
          inferred != null &&
          isExplicitAssistantNavigation(text) &&
          mounted) {
        await AssistantToolExecutor(ref, context).run(
          AssistantAction(name: 'open_page', args: {'page': inferred}),
        );
      }
      if (!mounted) return;
      setState(() {
        if (reply.isNotEmpty) {
          final id = ++_seq;
          _streamingId = id;
          _turns.add(AssistantChatTurn(role: 'model', text: reply, id: id));
        }
      });
      _scrollToEnd();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        if (_turns.isNotEmpty && _turns.last.isUser) {
          _turns.removeLast();
        }
        _banner = _mapError(l10n, e);
        _input.text = text;
        _input.selection = TextSelection.collapsed(offset: text.length);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_turns.isNotEmpty && _turns.last.isUser) {
          _turns.removeLast();
        }
        _banner = l10n.assistantGenericError;
        _input.text = text;
      });
    } finally {
      _sending = false;
      if (mounted) setState(() {});
    }
  }

  String _mapError(AppLocalizations l10n, FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return l10n.assistantNeedSignIn;
      case 'permission-denied':
        return l10n.assistantNeedPremium;
      case 'resource-exhausted':
        return l10n.assistantQuotaReached;
      case 'invalid-argument':
        return l10n.assistantMessageTooLong;
      case 'failed-precondition':
        return l10n.assistantNotReady;
      default:
        return l10n.assistantGenericError;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onRevealDone(int id) {
    if (!mounted) return;
    setState(() {
      _revealed.add(id);
      if (_streamingId == id) _streamingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final authAsync = ref.watch(authUserProvider);
    final premiumState = ref.watch(premiumAccessStateProvider);
    final adminAsync = ref.watch(isCurrentUserAdminProvider);
    final signedIn = authAsync.asData?.value != null;
    final premium = premiumState == PremiumAccessState.premium;
    final admin = adminAsync.asData?.value == true;
    final resolving = authAsync.isLoading ||
        premiumState == PremiumAccessState.loading ||
        adminAsync.isLoading;
    final allowed = signedIn && (premium || admin);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomPad = keyboardOpen
        ? 12.0
        : ArinShellLayout.bottomContentPadding(context);

    return SizedBox.expand(
      child: ArinShellBackground.buildLayered(
        context,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: _AssistantHeader(
                onDark: onDark,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
            ),
            if (resolving)
              const Expanded(child: Center(child: ArinLoader()))
            else if (!allowed)
              Expanded(child: _AssistantGate(signedIn: signedIn, onDark: onDark))
            else ...[
              if (_banner != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _BannerNote(text: _banner!, onDark: onDark),
                ),
              Expanded(
                child: _turns.isEmpty
                    ? _EmptyState(
                        hide: _charCount > 0,
                        enabled: !_sending,
                        onAsk: _sendPrompt,
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _turns.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _turns.length) {
                            return _TypingDots(onDark: onDark);
                          }
                          final turn = _turns[index];
                          return _ChatLine(
                            key: ValueKey(turn.id),
                            turn: turn,
                            onDark: onDark,
                            animate: !turn.isUser &&
                                turn.id == _streamingId &&
                                !_revealed.contains(turn.id),
                            onTick: _scrollToEnd,
                            onComplete: () => _onRevealDone(turn.id),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
                child: _Composer(
                  controller: _input,
                  focusNode: _focus,
                  onDark: onDark,
                  sending: _sending,
                  charCount: _charCount,
                  overLimit: _overLimit,
                  onChanged: () => setState(() {}),
                  onSend: _send,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.onDark,
    required this.onBack,
  });

  final bool onDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;
    final bronze = onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: title.withValues(alpha: 0.88),
            ),
          ),
          AssistantHilalMark(size: 18, color: bronze),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.qiblaHubAiTitle,
              style: GoogleFonts.plusJakartaSans(
                color: title,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantGate extends StatelessWidget {
  const _AssistantGate({required this.signedIn, required this.onDark});

  final bool signedIn;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = onDark ? Colors.white : AppColors.emeraldDark;
    final bronze = onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AssistantHilalMark(size: 36, color: bronze),
          const SizedBox(height: 16),
          Text(
            signedIn ? l10n.assistantNeedPremium : l10n.assistantNeedSignIn,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: title,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.assistantGateHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.62)
                  : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => context.push(AppRoutes.premium),
            style: FilledButton.styleFrom(
              backgroundColor: onDark
                  ? AppColors.accentNeonGreen
                  : AppColors.emeraldDark,
              foregroundColor: onDark ? const Color(0xFF06210F) : Colors.white,
            ),
            child: Text(signedIn ? l10n.assistantOpenPremium : l10n.assistantSignIn),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({
    required this.hide,
    required this.enabled,
    required this.onAsk,
  });

  final bool hide;
  final bool enabled;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final bronze = onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
    final locale = Localizations.localeOf(context).languageCode;
    final name = _prettyHelloName(
      ref.watch(userProfileProvider).name,
      l10n,
      locale,
    );
    final helloStyle = GoogleFonts.plusJakartaSans(
      color: onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.8,
    );
    final prompts = [
      l10n.assistantPromptLockVerse,
      l10n.assistantPromptInshirah,
      l10n.assistantPromptRamadan,
    ];
    return AnimatedSlide(
      offset: hide ? const Offset(0, -0.22) : Offset.zero,
      duration: const Duration(milliseconds: 460),
      curve: hide ? Curves.easeInCubic : Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: hide ? 0 : 1,
        duration: const Duration(milliseconds: 380),
        curve: hide ? Curves.easeIn : Curves.easeOut,
        child: IgnorePointer(
          ignoring: hide || !enabled,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssistantHilalMark(size: 42, color: bronze.withValues(alpha: 0.9)),
                  const SizedBox(height: 18),
                  Text(
                    l10n.assistantHello,
                    textAlign: TextAlign.center,
                    style: helloStyle,
                  ),
                  if (name != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: helloStyle.copyWith(
                        color: bronze,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    l10n.assistantEmptyBody,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.62)
                          : AppColors.textSecondary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < prompts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _PromptChip(
                      label: prompts[i],
                      onDark: onDark,
                      bronze: bronze,
                      onTap: () => onAsk(prompts[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.onDark,
    required this.bronze,
    required this.onTap,
  });

  final String label;
  final bool onDark;
  final Color bronze;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = bronze.withValues(alpha: onDark ? 0.42 : 0.38);
    final fill = onDark
        ? const Color(0xFF0C1812).withValues(alpha: 0.72)
        : AppColors.creamSurface.withValues(alpha: 0.92);
    return Material(
      color: fill,
      shape: StadiumBorder(side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : AppColors.emeraldDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

String? _prettyHelloName(String? raw, AppLocalizations l10n, String locale) {
  final collapsed = (raw ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.length < 2) return null;
  if (collapsed.toLowerCase() == l10n.homeGuestUser.toLowerCase()) return null;
  final clipped = collapsed.length > 24
      ? '${collapsed.substring(0, 24).trimRight()}…'
      : collapsed;
  return clipped
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => _titleCaseWord(part, locale))
      .join(' ');
}

String _titleCaseWord(String word, String locale) {
  if (word.isEmpty) return word;
  final first = word.substring(0, 1);
  final rest = word.substring(1);
  if (locale == 'tr') {
    return '${_trUpperFirst(first)}${_trLowerRest(rest)}';
  }
  return '${first.toUpperCase()}${rest.toLowerCase()}';
}

String _trUpperFirst(String ch) {
  if (ch == 'i') return 'İ';
  if (ch == 'ı') return 'I';
  return ch.toUpperCase();
}

String _trLowerRest(String text) {
  return text
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase();
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({
    super.key,
    required this.turn,
    required this.onDark,
    required this.animate,
    required this.onTick,
    required this.onComplete,
  });

  final AssistantChatTurn turn;
  final bool onDark;
  final bool animate;
  final VoidCallback onTick;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final mine = turn.isUser;
    final userBg = onDark
        ? const Color(0xFF1C3D2C)
        : AppColors.emeraldDark.withValues(alpha: 0.92);
    final userFg = Colors.white.withValues(alpha: 0.96);
    final modelFg = onDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.textPrimary;
    final style = GoogleFonts.plusJakartaSans(
      color: mine ? userFg : modelFg,
      height: 1.45,
      fontSize: mine ? 14.5 : 16,
      fontWeight: mine ? FontWeight.w500 : FontWeight.w400,
    );

    if (!mine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18, right: 28),
        child: _RevealText(
          text: turn.text,
          style: style,
          animate: animate,
          onTick: onTick,
          onComplete: onComplete,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: userBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(turn.text, style: style),
      ),
    );
  }
}

class _RevealText extends StatefulWidget {
  const _RevealText({
    required this.text,
    required this.style,
    required this.animate,
    required this.onTick,
    required this.onComplete,
  });

  final String text;
  final TextStyle style;
  final bool animate;
  final VoidCallback onTick;
  final VoidCallback onComplete;

  @override
  State<_RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<_RevealText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    final chars = widget.text.characters.length;
    final ms = widget.animate ? (420 + chars * 15).clamp(520, 2600) : 0;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    if (widget.animate) {
      _c.addListener(widget.onTick);
      _c.addStatusListener(_onStatus);
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _c.removeListener(widget.onTick);
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(widget.text, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final n = (widget.text.characters.length * Curves.easeOut.transform(_c.value))
            .round()
            .clamp(0, widget.text.characters.length);
        return Text(
          widget.text.characters.take(n).toString(),
          style: widget.style,
        );
      },
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 2),
      child: Row(
        children: [
          _Dot(delay: 0, color: bronze),
          const SizedBox(width: 5),
          _Dot(delay: 120, color: bronze),
          const SizedBox(width: 5),
          _Dot(delay: 240, color: bronze),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay, required this.color});
  final int delay;
  final Color color;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: DelayTween(begin: 0.25, end: 1, delay: widget.delay / 700).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  DelayTween({required super.begin, required super.end, required this.delay});
  final double delay;

  @override
  double lerp(double t) {
    final shifted = ((t + delay) % 1.0);
    return super.lerp(shifted);
  }
}

class _BannerNote extends StatelessWidget {
  const _BannerNote({required this.text, required this.onDark});
  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A65).withValues(alpha: onDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: onDark ? const Color(0xFFFFCCBC) : const Color(0xFFBF360C),
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onDark,
    required this.sending,
    required this.charCount,
    required this.overLimit,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool onDark;
  final bool sending;
  final int charCount;
  final bool overLimit;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _sendPulse;
  late final Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _sendPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sendScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.84), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 25),
    ]).animate(CurvedAnimation(parent: _sendPulse, curve: Curves.easeOut));
    if (widget.charCount > 0) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = widget.charCount > 0 && !widget.overLimit;
    if (active && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!active && _glow.isAnimating) {
      _glow
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    _sendPulse.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (widget.sending || widget.overLimit || widget.controller.text.trim().isEmpty) {
      return;
    }
    _sendPulse.forward(from: 0);
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bronze = widget.onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
    final fill = widget.onDark ? const Color(0xFF0E1812) : AppColors.creamSurface;
    final neon = widget.onDark ? AppColors.accentNeonGreen : AppColors.emeraldMid;
    final canSend =
        !widget.sending && !widget.overLimit && widget.controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.charCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 6),
            child: Text(
              l10n.assistantWordCount(widget.charCount, 100),
              style: TextStyle(
                color: widget.overLimit
                    ? const Color(0xFFE57373)
                    : (widget.onDark ? Colors.white38 : AppColors.textSecondary),
                fontSize: 11,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: Listenable.merge([_glow, _sendPulse]),
          builder: (context, child) {
            final pulse = Curves.easeOut.transform(_glow.value);
            final typing = widget.charCount > 0;
            final glowColor = Color.lerp(bronze, neon, 0.55)!;
            final sendScale = _sendScale.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: typing
                      ? glowColor.withValues(alpha: 0.28 + pulse * 0.42)
                      : bronze.withValues(alpha: widget.onDark ? 0.22 : 0.28),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: widget.onDark ? 0.22 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  if (typing)
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.16 + pulse * 0.28),
                      blurRadius: 14 + pulse * 16,
                      spreadRadius: 0.4 + pulse * 1.6,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: ColoredBox(
                  color: fill,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: child!),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 5, 5, 5),
                        child: Transform.scale(
                          scale: sendScale,
                          child: Material(
                            color: canSend
                                ? (widget.onDark
                                    ? AppColors.accentNeonGreen
                                    : AppColors.emeraldDark)
                                : fill,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: canSend ? _handleSend : null,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: widget.sending
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: ArinLoader(strokeWidth: 2),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 20,
                                        color: canSend
                                            ? (widget.onDark
                                                ? const Color(0xFF06210F)
                                                : Colors.white)
                                            : bronze.withValues(alpha: 0.55),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            minLines: 1,
            maxLines: 4,
            maxLength: 100,
            enabled: !widget.sending,
            textInputAction: TextInputAction.send,
            onChanged: (_) => widget.onChanged(),
            onSubmitted: (_) => _handleSend(),
            cursorColor: bronze,
            style: GoogleFonts.plusJakartaSans(
              color: widget.onDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : AppColors.textPrimary,
              fontSize: 15,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: l10n.assistantInputHint,
              hintStyle: TextStyle(
                color: widget.onDark ? Colors.white38 : AppColors.textSecondary,
              ),
              isCollapsed: false,
              filled: true,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.fromLTRB(18, 13, 4, 13),
            ),
          ),
        ),
      ],
    );
  }
}
