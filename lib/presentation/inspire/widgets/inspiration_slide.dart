import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspiration_card_model.dart';
import '../inspiration_catalog_provider.dart';
import '../inspiration_share_service.dart';
import '../inspiration_text_layouts.dart';
import 'inspiration_reels_layer.dart';

class InspirationSlide extends ConsumerStatefulWidget {
  const InspirationSlide({
    super.key,
    required this.card,
    this.reelsLayout = false,
    this.viewerZoom = 1,
    this.reelsTextScrollEnabled = false,
  });

  final InspirationCardModel card;
  final bool reelsLayout;

  /// Keşfet detayında hafif büyütme (kırpma yine cover + ortala).
  final double viewerZoom;

  /// Tam ekran akışta metin alanının dikey gesture'ı PageView'den çalmasını önler.
  final bool reelsTextScrollEnabled;

  @override
  ConsumerState<InspirationSlide> createState() => _InspirationSlideState();
}

class _InspirationSlideState extends ConsumerState<InspirationSlide> {
  late InspirationCardModel _displayCard;
  final GlobalKey _shareBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _displayCard = widget.card;
  }

  @override
  void didUpdateWidget(covariant InspirationSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _displayCard = widget.card;
    }
  }

  void _remixBackground() {
    final catalog = ref.read(inspirationCatalogProvider).valueOrNull;
    if (catalog == null || catalog.isEmpty) return;
    final pool = catalog
        .map((c) => c.imageIndex)
        .where((i) => i >= 1)
        .toSet()
        .toList();
    if (pool.isEmpty) return;
    if (pool.length == 1) return;
    pool.shuffle(Random());
    final next = pool.firstWhere(
      (i) => i != _displayCard.imageIndex,
      orElse: () => pool.first,
    );
    setState(() {
      _displayCard = _displayCard.copyWith(imageIndex: next);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _onSharePressed(Rect? shareAnchor) async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final err = await InspirationShareService.shareCapture(
      _shareBoundaryKey,
      context,
      sharePositionOrigin: shareAnchor,
    );
    if (!mounted) return;
    if (err != null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// Uzun basma: doğrudan Stories paylaşımı bottom sheet.
  Future<void> _onShareLongPress() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<_StoriesTarget>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const _StoriesShareSheet(),
    );
    if (choice == null || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    // Service metodları iç mounted kontrolü yapıyor; linter sessizleştirme
    // nedeni: state.mounted zaten switch öncesi garanti.
    final ctx = context;
    final outcome = switch (choice) {
      _StoriesTarget.instagram =>
        await InspirationShareService
        // ignore: use_build_context_synchronously
        .shareToInstagramStories(_shareBoundaryKey, ctx),
      _StoriesTarget.facebook =>
        await InspirationShareService
        // ignore: use_build_context_synchronously
        .shareToFacebookStories(_shareBoundaryKey, ctx),
      _StoriesTarget.system => null,
    };
    if (!mounted) return;

    if (outcome == null) {
      // Sistem paylaşımı seçildi → klasik yol.
      await _onSharePressed(null);
      return;
    }

    final message = switch (outcome) {
      DeepShareSuccess() => null,
      DeepShareNotInstalled() =>
        choice == _StoriesTarget.instagram
            ? 'Instagram cihazınızda yüklü değil.'
            : 'Facebook cihazınızda yüklü değil.',
      DeepShareFailed(:final message) => message,
    };
    if (message != null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _gradientOverlay(bool lightTxt) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: lightTxt
                ? [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.36),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.12),
                  ],
            stops: const [0.35, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _watermark(bool lightTxt) {
    return Positioned(
      top: 114,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Text(
            'ARINAPP',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              letterSpacing: 9,
              color: lightTxt
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.22),
              shadows: lightTxt
                  ? const [
                      Shadow(
                        blurRadius: 12,
                        offset: Offset(0, 1),
                        color: Color(0x66000000),
                      ),
                    ]
                  : const [
                      Shadow(
                        blurRadius: 8,
                        offset: Offset(0, 1),
                        color: Color(0x33FFFFFF),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReelsStack(bool lightTxt, Alignment textAnchor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _shareBoundaryKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SlideBackground(
                card: _displayCard,
                useLightPlaceholder: lightTxt,
              ),
              _gradientOverlay(lightTxt),
              _watermark(lightTxt),
              InspirationReelsQuoteBlock(
                card: _displayCard,
                useLightTextOnImage: lightTxt,
                textAnchor: textAnchor,
                scrollEnabled: widget.reelsTextScrollEnabled,
              ),
            ],
          ),
        ),
        InspirationReelsActionRail(
          card: _displayCard,
          lightOnImage: lightTxt,
          onRemixBackground: _remixBackground,
          onShare: _onSharePressed,
          onShareLongPress: _onShareLongPress,
        ),
      ],
    );
  }

  Widget _maybeZoom(Widget body) {
    if (widget.viewerZoom != 1 && widget.viewerZoom > 1) {
      return ClipRect(
        child: Transform.scale(
          scale: widget.viewerZoom,
          alignment: Alignment.center,
          child: body,
        ),
      );
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final forced = widget.card.useLightTextOnImage;

    if (!widget.reelsLayout) {
      final light = forced ?? true;
      final body = Stack(
        fit: StackFit.expand,
        children: [
          _SlideBackground(card: widget.card, useLightPlaceholder: light),
          _gradientOverlay(light),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: buildInspirationTextOverlay(
                    context: context,
                    card: widget.card,
                  ),
                );
              },
            ),
          ),
        ],
      );
      return _maybeZoom(body);
    }

    final async = ref.watch(
      inspirationReelsHintsProvider(_displayCard.imageIndex),
    );
    return async.when(
      data: (h) {
        final light = forced ?? h.lightText;
        return _maybeZoom(_buildReelsStack(light, h.textAnchor));
      },
      loading: () =>
          _maybeZoom(_buildReelsStack(forced ?? true, Alignment.center)),
      error: (_, __) =>
          _maybeZoom(_buildReelsStack(forced ?? true, Alignment.center)),
    );
  }
}

class _SlideBackground extends StatelessWidget {
  const _SlideBackground({
    required this.card,
    required this.useLightPlaceholder,
  });

  final InspirationCardModel card;
  final bool useLightPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      card.resolvedImageAssetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          _PlaceholderGradient(useLight: useLightPlaceholder),
    );
  }
}

class _PlaceholderGradient extends StatelessWidget {
  const _PlaceholderGradient({required this.useLight});

  final bool useLight;

  @override
  Widget build(BuildContext context) {
    if (useLight) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0F12), Color(0xFF1A1520), Color(0xFF0A1210)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.creamMist,
            AppColors.creamSurface,
            AppColors.creamShellDeep,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stories paylaşım seçim ekranı — paylaş butonuna uzun basınca açılır.
// Glassmorphism + neon zümrüt vurgu; dark emerald shell diliyle aynı.
// ─────────────────────────────────────────────────────────────────────────

enum _StoriesTarget { instagram, facebook, system }

class _StoriesShareSheet extends StatelessWidget {
  const _StoriesShareSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.homeCardSurface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Nereye paylaşmak istersin?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hikâyeler için doğrudan, diğer uygulamalar için sistem menüsünü aç.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: AppColors.textOnDarkMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StoriesTile(
                      icon: Icons.camera_alt_rounded,
                      gradientColors: const [
                        Color(0xFFF58529),
                        Color(0xFFDD2A7B),
                        Color(0xFF8134AF),
                      ],
                      label: 'Instagram Hikâye',
                      subtitle: 'Uygulamayı tam ekran aç',
                      onTap: () =>
                          Navigator.pop(context, _StoriesTarget.instagram),
                    ),
                    const SizedBox(height: 10),
                    _StoriesTile(
                      icon: Icons.facebook_rounded,
                      gradientColors: const [
                        Color(0xFF1877F2),
                        Color(0xFF0A4FA0),
                      ],
                      label: 'Facebook Hikâye',
                      subtitle: 'Uygulamayı tam ekran aç',
                      onTap: () =>
                          Navigator.pop(context, _StoriesTarget.facebook),
                    ),
                    const SizedBox(height: 10),
                    _StoriesTile(
                      icon: Icons.ios_share_rounded,
                      gradientColors: const [
                        AppColors.emeraldDark,
                        AppColors.emeraldMid,
                      ],
                      label: 'Diğer uygulamalar',
                      subtitle: 'WhatsApp, Telegram, Twitter…',
                      onTap: () =>
                          Navigator.pop(context, _StoriesTarget.system),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoriesTile extends StatelessWidget {
  const _StoriesTile({
    required this.icon,
    required this.gradientColors,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.72),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
