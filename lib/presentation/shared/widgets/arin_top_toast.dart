import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';

enum ArinTopToastTone { neutral, error }

/// Shell ile uyumlu, üstten kayan kısa bildirim.
///
/// Material 3'ün varsayılan SnackBar'ı koyu zeminde krem/inverse yüzey
/// kullanır ve alttan çıkar. Uygulama içi geri bildirimler kök overlay'de
/// kart yüzeyi + zümrüt çerçeve ile üstten gösterilir.
void showArinTopToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2800),
  ArinTopToastTone tone = ArinTopToastTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || message.trim().isEmpty) return;
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  final onDark = !ArinShellBackground.isLight(context);
  ArinTopToastController.show(
    overlay,
    message: message,
    onDark: onDark,
    duration: actionLabel != null && duration < const Duration(seconds: 4)
        ? const Duration(seconds: 4)
        : duration,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

@visibleForTesting
class ArinTopToastController {
  ArinTopToastController._();

  static OverlayEntry? _active;

  static void show(
    OverlayState overlay, {
    required String message,
    required bool onDark,
    Duration duration = const Duration(milliseconds: 2800),
    ArinTopToastTone tone = ArinTopToastTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ArinTopToast(
        message: message,
        onDark: onDark,
        duration: duration,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (identical(_active, entry)) hide();
        },
      ),
    );
    _active = entry;
    overlay.insert(entry);
  }

  static void hide() {
    final entry = _active;
    _active = null;
    if (entry == null) return;
    if (entry.mounted) entry.remove();
  }
}

class _ArinTopToast extends StatefulWidget {
  const _ArinTopToast({
    required this.message,
    required this.onDark,
    required this.duration,
    required this.tone,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool onDark;
  final Duration duration;
  final ArinTopToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_ArinTopToast> createState() => _ArinTopToastState();
}

class _ArinTopToastState extends State<_ArinTopToast>
    with SingleTickerProviderStateMixin {
  static const _animDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _holdTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(curve);
    _fade = curve;
    _controller.forward();
    _holdTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _holdTimer?.cancel();
    try {
      await _controller.reverse();
    } catch (_) {
      // Overlay, yeni bir toast ile değiştirilirken controller kapanabilir.
    }
    if (mounted) widget.onDismissed();
  }

  void _handleAction() {
    widget.onAction?.call();
    unawaited(_dismiss());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.tone == ArinTopToastTone.error;
    final Color surface;
    final Color foreground;
    final Color border;
    if (isError) {
      surface = widget.onDark
          ? const Color(0xFF2A1614)
          : const Color(0xFFF4E4E0);
      foreground = widget.onDark ? AppColors.textOnDark : AppColors.error;
      border = AppColors.error.withValues(alpha: widget.onDark ? 0.45 : 0.35);
    } else {
      surface = widget.onDark
          ? AppColors.homeCardSurface
          : AppColors.creamSurface;
      foreground = widget.onDark ? AppColors.textOnDark : AppColors.emeraldDark;
      border = widget.onDark
          ? AppColors.emeraldLight.withValues(alpha: 0.38)
          : AppColors.emeraldMid.withValues(alpha: 0.35);
    }
    final hasAction =
        widget.actionLabel != null && widget.actionLabel!.trim().isNotEmpty;

    return IgnorePointer(
      ignoring: !hasAction,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 32,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isError
                                        ? AppColors.error
                                        : AppColors.accentGlowGreen)
                                    .withValues(
                                      alpha: widget.onDark ? 0.18 : 0.1,
                                    ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  widget.message,
                                  textAlign: hasAction
                                      ? TextAlign.start
                                      : TextAlign.center,
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                            if (hasAction) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _handleAction,
                                style: TextButton.styleFrom(
                                  foregroundColor: widget.onDark
                                      ? AppColors.accentNeonGreen
                                      : AppColors.emeraldMid,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
