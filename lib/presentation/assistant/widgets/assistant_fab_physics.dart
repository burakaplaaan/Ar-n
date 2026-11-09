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
    return Offset(
      _clampFinite(raw.dx, minX, maxX),
      _clampFinite(raw.dy, minY, maxY),
    );
  }
}

/// `num.clamp` alt sınır üstten büyükse [ArgumentError] fırlatır.
/// Aralık tersse düzeltilir. NaN alt uca, sonsuzlar ilgili uca çekilir.
double _clampFinite(double value, double lower, double upper) {
  var lo = lower.isFinite ? lower : 0.0;
  var hi = upper.isFinite ? upper : lo;
  if (lo > hi) {
    final swap = lo;
    lo = hi;
    hi = swap;
  }
  if (value.isNaN || value <= lo) return lo;
  if (value >= hi) return hi;
  return value;
}

double _finiteNonNegative(double value) {
  if (!value.isFinite || value <= 0) return 0;
  return value;
}

/// Inset, ait olduğu kenardan uzunsa o kenarın içinde değildir.
double _insetInsideEdge(double raw, double edge) {
  final inset = _finiteNonNegative(raw);
  final limit = _finiteNonNegative(edge);
  if (limit > 0 && inset >= limit) return 0;
  return inset;
}

/// Sol üst köşenin bir eksendeki aralığı.
///
/// Inset balonla birlikte kutuya sığıyorsa sonuç eski formülle aynıdır:
/// `leading + margin` .. `extent - trailing - child - margin`.
/// Sığmayan uç, balon kutu içinde kalacak şekilde daraltılır.
(double, double) _topLeftSpan({
  required double extent,
  required double child,
  required double leading,
  required double trailing,
  required double margin,
}) {
  final box = _finiteNonNegative(extent);
  final size = _finiteNonNegative(child);
  final pad = _finiteNonNegative(margin);
  final lead = _finiteNonNegative(leading);
  final trail = _finiteNonNegative(trailing);
  final minBound = lead + pad;
  final rawMax = box - trail - size - pad;
  if (minBound <= box) {
    final maxBound = rawMax < minBound
        ? minBound
        : (rawMax > box ? box : rawMax);
    final topLeftLimit = box - size;
    // Eski formül balonu kutuda tutuyorsa sayı aynı kalır.
    if (maxBound >= minBound && minBound >= 0 && maxBound <= topLeftLimit) {
      return (minBound, maxBound);
    }
  }
  return _topLeftSpanInside(
    box: box,
    child: size,
    leading: lead,
    trailing: trail,
    margin: pad,
  );
}

/// [leading] + pay kutunun dışında. Kesişmeyen inset düşer; balon içeride kalır.
(double, double) _topLeftSpanInside({
  required double box,
  required double child,
  required double leading,
  required double trailing,
  required double margin,
}) {
  final size = child <= box ? child : box;
  final hardMax = box - size;
  if (hardMax <= 0) return (0, 0);

  // Bu uçta balonun durabileceği yer yoksa inset bu kutuya ait değildir.
  var lead = leading >= hardMax ? 0.0 : leading;
  var trail = trailing;
  final room = hardMax - 2 * margin;
  if (room < 0) return (0, hardMax);

  if (lead + trail > room) {
    var overflow = lead + trail - room;
    if (lead >= trail) {
      final cut = lead < overflow ? lead : overflow;
      lead -= cut;
      overflow -= cut;
      if (overflow > 0 && trail > 0) {
        trail = trail > overflow ? trail - overflow : 0;
      }
    } else {
      final cut = trail < overflow ? trail : overflow;
      trail -= cut;
      overflow -= cut;
      if (overflow > 0 && lead > 0) {
        lead = lead > overflow ? lead - overflow : 0;
      }
    }
  }

  final minBound = lead + margin;
  final maxBound = hardMax - trail - margin;
  if (minBound <= maxBound) return (minBound, maxBound);
  final point = minBound <= 0
      ? 0.0
      : (minBound >= hardMax ? hardMax : minBound);
  return (point, point);
}

/// Kenarları yığın boyutuna göre hesaplar.
///
/// [paddingBottom] kullanılmaz — Scaffold/SafeArea şişirmesi orta noktayı
/// yanlışlıkla "alt köşe" yapmasın. Yalnızca [viewBottom] (home indicator)
/// ve bilinen alt çubuk yüksekliği alınır. Yığın zaten kısa ise nav tekrar
/// çıkarılmaz. Kenardan uzun inset (HyperOS'un bildirdiği yüzlerce px'lik
/// üst boşluk gibi) o kenara uygulanmaz; `clamp` ters aralıkta patlamaz.
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
  final stackW = _finiteNonNegative(stack.width);
  final stackH = _finiteNonNegative(stack.height);
  final screenH = _finiteNonNegative(fullScreenHeight);
  final verticalEdge = screenH > 0 ? screenH : stackH;
  final left = _insetInsideEdge(viewLeft, stackW);
  final right = _insetInsideEdge(viewRight, stackW);
  final top = _insetInsideEdge(viewTop, verticalEdge);
  final bottom = _insetInsideEdge(viewBottom, verticalEdge);
  final reserve = _finiteNonNegative(navReserve);
  final stackBottomGap = math.max(0.0, screenH - stackH);
  final extraBottom = math.max(0.0, bottom + reserve - stackBottomGap);
  final x = _topLeftSpan(
    extent: stackW,
    child: bubble.width,
    leading: left,
    trailing: right,
    margin: margin,
  );
  final y = _topLeftSpan(
    extent: stackH,
    child: bubble.height,
    leading: top,
    trailing: extraBottom,
    margin: margin,
  );
  return AssistantFabBounds(minX: x.$1, maxX: x.$2, minY: y.$1, maxY: y.$2);
}

const double kAssistantFabFlingThreshold = 650;

const Duration kAssistantFabIdleDockDelay = Duration(seconds: 6);

/// Kenara çekilmiş balonda ekranda kalan hilal payı.
const double kAssistantFabPeekVisible = 22;

enum AssistantFabEdge { left, right, top, bottom }

/// Yapıştığı kenar — köşede yatay kenar tercih edilir.
AssistantFabEdge assistantFabEdgeFor(
  Offset position,
  AssistantFabBounds bounds,
) {
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
  return snapAssistantFabToNearestEdge(projected, bounds, velocity: velocity);
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
      final toLeft =
          velocity.dx < -1 || (velocity.dx.abs() <= 1 && left < right);
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
