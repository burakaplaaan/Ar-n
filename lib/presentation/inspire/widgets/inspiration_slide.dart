import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspiration_card_model.dart';
import '../../../data/services/inspiration_asset_discovery.dart';
import '../inspiration_catalog_provider.dart';
import '../inspiration_share_service.dart';
import '../inspiration_text_layouts.dart';
import 'inspiration_reels_layer.dart';

/// Viewer kapanış/açılış progress'ine göre söz ve aksiyonları soldurur.
class InspirationViewerChromeScope extends InheritedWidget {
  const InspirationViewerChromeScope({
    super.key,
    required this.opacity,
    required super.child,
  });

  final double opacity;

  static double opacityOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<InspirationViewerChromeScope>()
            ?.opacity ??
        1;
  }

  @override
  bool updateShouldNotify(InspirationViewerChromeScope oldWidget) {
    return (oldWidget.opacity - opacity).abs() > 0.01;
  }
}

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
  bool _isRemixingBackground = false;

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

  Future<void> _remixBackground() async {
    if (_isRemixingBackground) return;
    _isRemixingBackground = true;
    final requestedCardId = _displayCard.id;
    HapticFeedback.selectionClick();

    try {
      var pool = await InspirationAssetDiscovery.discoverConsecutiveJpeg();
      if (pool.isEmpty) {
        final catalog = ref.read(inspirationCatalogProvider).valueOrNull;
        pool =
            catalog
                ?.map((card) => card.imageIndex)
                .where((index) => index >= 1)
                .toSet()
                .toList() ??
            const [];
      }

      final alternatives =
          pool.where((index) => index != _displayCard.imageIndex).toList()
            ..shuffle(Random());
      if (!mounted || _displayCard.id != requestedCardId) return;
      if (alternatives.isEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Başka bir arka plan bulunamadı.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _displayCard = _displayCard.copyWith(
          imageIndex: alternatives.first,
          clearUseLightTextOnImage: true,
        );
      });
    } finally {
      _isRemixingBackground = false;
    }
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

  Widget _gradientOverlay(bool lightTxt) {
    return DecoratedBox(
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
    );
  }

  Widget _watermark(bool lightTxt) {
    return Positioned(
      top: 132,
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

  Widget _chromeLayer({
    required double opacity,
    required List<Widget> children,
  }) {
    final layer = Stack(fit: StackFit.expand, children: children);
    if (opacity >= 0.999) return layer;
    return Opacity(
      opacity: opacity,
      child: IgnorePointer(ignoring: opacity < 0.05, child: layer),
    );
  }

  Widget _buildReelsStack(bool lightTxt, Alignment textAnchor) {
    final chromeOpacity = InspirationViewerChromeScope.opacityOf(
      context,
    ).clamp(0.0, 1.0);
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
              _chromeLayer(
                opacity: chromeOpacity,
                children: [
                  Positioned.fill(child: _gradientOverlay(lightTxt)),
                  _watermark(lightTxt),
                  InspirationReelsQuoteBlock(
                    card: _displayCard,
                    useLightTextOnImage: lightTxt,
                    textAnchor: textAnchor,
                    scrollEnabled: widget.reelsTextScrollEnabled,
                  ),
                ],
              ),
            ],
          ),
        ),
        _chromeLayer(
          opacity: chromeOpacity,
          children: [
            InspirationReelsActionRail(
              card: _displayCard,
              lightOnImage: lightTxt,
              onRemixBackground: _remixBackground,
              onShare: _onSharePressed,
            ),
          ],
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
    final forced = _displayCard.useLightTextOnImage;

    if (!widget.reelsLayout) {
      final light = forced ?? true;
      final body = Stack(
        fit: StackFit.expand,
        children: [
          _SlideBackground(card: widget.card, useLightPlaceholder: light),
          Positioned.fill(child: _gradientOverlay(light)),
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
