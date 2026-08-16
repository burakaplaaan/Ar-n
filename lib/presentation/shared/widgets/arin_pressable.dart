import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tüm tıklanabilir yüzeyler için basılı-tutunca göçük kalan gerçek buton hissi.
///
/// Material ripple / highlight doldurması kullanmaz. Parmak inince ölçek +
/// hafif aşağı kayma uygulanır; parmak kalkınca veya jest iptal olunca
/// (kaydırma) eski haline döner.
class ArinPressable extends StatefulWidget {
  const ArinPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.scale = 0.965,
    this.sink = 1.4,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double scale;
  final double sink;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<ArinPressable> createState() => _ArinPressableState();
}

class _ArinPressableState extends State<ArinPressable> {
  bool _pressed = false;

  bool get _canPress =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (!_canPress || _pressed == value) return;
    setState(() => _pressed = value);
    if (value && widget.haptic) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _canPress ? (_) => _setPressed(true) : null,
      onTapUp: _canPress ? (_) => _setPressed(false) : null,
      onTapCancel: _canPress ? () => _setPressed(false) : null,
      onTap: _canPress ? widget.onTap : null,
      onLongPress: _canPress ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: Duration(milliseconds: _pressed ? 70 : 160),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _pressed ? Offset(0, widget.sink / 140) : Offset.zero,
          duration: Duration(milliseconds: _pressed ? 70 : 160),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
