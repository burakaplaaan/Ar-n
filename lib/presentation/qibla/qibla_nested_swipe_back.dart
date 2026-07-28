import 'package:flutter/material.dart';

/// Kıble hub içi sayfalarda: **geri kenarından** başlayıp içeri doğru kaydırınca
/// [Navigator.pop]. Ana shell [PageView] zaten bu rotalarda kilitli.
class QiblaNestedSwipeBack extends StatefulWidget {
  const QiblaNestedSwipeBack({super.key, required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  State<QiblaNestedSwipeBack> createState() => _QiblaNestedSwipeBackState();
}

class _QiblaNestedSwipeBackState extends State<QiblaNestedSwipeBack> {
  bool _startedFromBackEdge = false;
  double _accumDx = 0;

  bool _isFromBackEdge(Offset global, BuildContext context) {
    final m = MediaQuery.of(context);
    final w = m.size.width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final inset = rtl ? m.padding.right : m.padding.left;
    final slop = 28 + inset;
    if (rtl) {
      return global.dx > w - slop;
    }
    return global.dx < slop;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final onBack = widget.onBack;
        if (onBack != null) {
          onBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          final route = ModalRoute.of(context);
          if (route == null || !route.isCurrent) {
            _startedFromBackEdge = false;
            _accumDx = 0;
            return;
          }
          _startedFromBackEdge = _isFromBackEdge(
            details.globalPosition,
            context,
          );
          _accumDx = 0;
        },
        onHorizontalDragUpdate: (details) {
          if (!_startedFromBackEdge) return;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          _accumDx += rtl ? -details.delta.dx : details.delta.dx;
        },
        onHorizontalDragEnd: (details) {
          if (!_startedFromBackEdge) {
            _accumDx = 0;
            return;
          }
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final vx = details.velocity.pixelsPerSecond.dx;
          final towardBack = rtl ? -vx : vx;
          final farEnough = _accumDx > 56;
          final flingBack = towardBack > 400;
          _startedFromBackEdge = false;
          _accumDx = 0;
          if ((farEnough || flingBack) && context.mounted) {
            final onBack = widget.onBack;
            if (onBack != null) {
              onBack();
            } else {
              Navigator.of(context).maybePop();
            }
          }
        },
        onHorizontalDragCancel: () {
          _startedFromBackEdge = false;
          _accumDx = 0;
        },
        child: widget.child,
      ),
    );
  }
}
