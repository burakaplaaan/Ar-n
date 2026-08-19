import 'dart:math' as math;
import 'dart:ui';

/// Alt çubuk: iç pad + satır + orta üçgen dudağı + boşluk.
/// Home indicator [viewBottom] ile ayrıca eklenir.
const double kAssistantFabNavReserve = 8 + 50 + 12 + 12;

const double kAssistantFabEdgeMargin = 8;

/// Asistan balonunun sürüklenebilir dikdörtgeni.
class AssistantFabBounds {
  const AssistantFabBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  Offset clamp(Offset raw) {
    return Offset(raw.dx.clamp(minX, maxX), raw.dy.clamp(minY, maxY));
  }
}

/// Kenarları yığın boyutuna göre hesaplar.
///
/// [paddingBottom] kullanılmaz — Scaffold/SafeArea şişirmesi orta noktayı
/// yanlışlıkla "alt köşe" yapmasın. Yalnızca [viewBottom] (home indicator)
/// ve bilinen alt çubuk yüksekliği alınır. Yığın zaten kısa ise nav tekrar
/// çıkarılmaz.
AssistantFabBounds assistantFabBoundsFor({
  required Size stack,
  required Size bubble,
  required double viewLeft,
  required double viewTop,
  required double viewRight,
  required double viewBottom,
  required double fullScreenHeight,
  double navReserve = kAssistantFabNavReserve,
}) {
  const margin = kAssistantFabEdgeMargin;
  final stackBottomGap = (fullScreenHeight - stack.height).clamp(
    0.0,
    fullScreenHeight,
  );
  final extraBottom = math.max(0.0, viewBottom + navReserve - stackBottomGap);
  final minX = viewLeft + margin;
  final maxX = (stack.width - viewRight - bubble.width - margin).clamp(
    minX,
    stack.width,
  );
  final minY = viewTop + margin;
  final maxY = (stack.height - extraBottom - bubble.height - margin).clamp(
    minY,
    stack.height,
  );
  return AssistantFabBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
}

const double kAssistantFabFlingThreshold = 650;

const Duration kAssistantFabIdleDockDelay = Duration(seconds: 6);

/// Kenara çekilmiş balonda ekranda kalan hilal payı.
const double kAssistantFabPeekVisible = 22;

enum AssistantFabEdge { left, right, top, bottom }

/// Yapıştığı kenar — köşede yatay kenar tercih edilir.
AssistantFabEdge assistantFabEdgeFor(Offset position, AssistantFabBounds bounds) {
  final left = position.dx - bounds.minX;
  final right = bounds.maxX - position.dx;
  final top = position.dy - bounds.minY;
  final bottom = bounds.maxY - position.dy;
  final horizontal = left < right ? left : right;
  final vertical = top < bottom ? top : bottom;
  if (horizontal <= vertical) {
    return left <= right ? AssistantFabEdge.left : AssistantFabEdge.right;
  }
  return top <= bottom ? AssistantFabEdge.top : AssistantFabEdge.bottom;
}

/// Balonu kenarın içine kaydırır; yalnızca hilal payı görünür kalır.
Offset assistantFabPeekTranslation({
  required AssistantFabEdge edge,
  required Size bubble,
  double visiblePx = kAssistantFabPeekVisible,
}) {
  final hiddenX = (bubble.width - visiblePx).clamp(0.0, bubble.width);
  final hiddenY = (bubble.height - visiblePx).clamp(0.0, bubble.height);
  return switch (edge) {
    AssistantFabEdge.left => Offset(-hiddenX, 0),
    AssistantFabEdge.right => Offset(hiddenX, 0),
    AssistantFabEdge.top => Offset(0, -hiddenY),
    AssistantFabEdge.bottom => Offset(0, hiddenY),
  };
}

/// Fırlatma sonrası duracağı tahmini nokta, sonra en yakın kenara yapışır.
Offset settleAssistantFab({
  required Offset position,
  required Offset velocity,
  required AssistantFabBounds bounds,
  double coastSeconds = 0.28,
}) {
  var projected = position;
  if (velocity.distance >= kAssistantFabFlingThreshold) {
    projected = position + velocity * coastSeconds;
  }
  return snapAssistantFabToNearestEdge(
    projected,
    bounds,
    velocity: velocity,
  );
}

/// Ortada bırakılamaz; sol / sağ / üst / alt kenardan en yakınına gider.
Offset snapAssistantFabToNearestEdge(
  Offset raw,
  AssistantFabBounds bounds, {
  Offset velocity = Offset.zero,
}) {
  final p = bounds.clamp(raw);
  final left = p.dx - bounds.minX;
  final right = bounds.maxX - p.dx;
  final top = p.dy - bounds.minY;
  final bottom = bounds.maxY - p.dy;

  final horizontal = left < right ? left : right;
  final vertical = top < bottom ? top : bottom;
  const epsilon = 0.75;

  if (horizontal <= epsilon && vertical <= epsilon) {
    return p;
  }
  if (horizontal <= epsilon) {
    return Offset(left < right ? bounds.minX : bounds.maxX, p.dy);
  }
  if (vertical <= epsilon) {
    return Offset(p.dx, top < bottom ? bounds.minY : bounds.maxY);
  }

  if ((horizontal - vertical).abs() <= epsilon) {
    if (velocity.dx.abs() > velocity.dy.abs() && velocity.dx.abs() > 1) {
      return Offset(velocity.dx < 0 ? bounds.minX : bounds.maxX, p.dy);
    }
    if (velocity.dy.abs() > 1) {
      return Offset(p.dx, velocity.dy < 0 ? bounds.minY : bounds.maxY);
    }
    return Offset(bounds.maxX, p.dy);
  }

  if (horizontal < vertical) {
    if ((left - right).abs() <= epsilon) {
      final toLeft = velocity.dx < -1 || (velocity.dx.abs() <= 1 && left < right);
      return Offset(toLeft ? bounds.minX : bounds.maxX, p.dy);
    }
    return Offset(left < right ? bounds.minX : bounds.maxX, p.dy);
  }

  if ((top - bottom).abs() <= epsilon) {
    final toTop = velocity.dy < -1;
    return Offset(p.dx, toTop ? bounds.minY : bounds.maxY);
  }
  return Offset(p.dx, top < bottom ? bounds.minY : bounds.maxY);
}
