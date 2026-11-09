import 'package:arin/presentation/assistant/widgets/assistant_fab_physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = AssistantFabBounds(minX: 8, maxX: 254, minY: 55, maxY: 682);

  test('ortadan bırakınca sağ veya sol kenara yapışır', () {
    const center = Offset(131, 368.5);
    final settled = snapAssistantFabToNearestEdge(center, bounds);
    expect(settled.dy, closeTo(center.dy, 0.01));
    expect(settled.dx == bounds.minX || settled.dx == bounds.maxX, isTrue);
  });

  test('sola yakınsa sola, sağa yakınsa sağa gider', () {
    expect(
      snapAssistantFabToNearestEdge(const Offset(40, 300), bounds),
      const Offset(8, 300),
    );
    expect(
      snapAssistantFabToNearestEdge(const Offset(220, 300), bounds),
      const Offset(254, 300),
    );
  });

  test('üste yakınsa üste, alta yakınsa alta gider', () {
    expect(
      snapAssistantFabToNearestEdge(const Offset(131, 70), bounds),
      const Offset(131, 55),
    );
    expect(
      snapAssistantFabToNearestEdge(const Offset(131, 660), bounds),
      const Offset(131, 682),
    );
  });

  test('sınır dışına taşanı önce kıstırır', () {
    expect(
      snapAssistantFabToNearestEdge(const Offset(-40, 300), bounds),
      const Offset(8, 300),
    );
    expect(
      snapAssistantFabToNearestEdge(const Offset(131, 2000), bounds),
      const Offset(131, 682),
    );
  });

  test('köşedeyse yerinde kalır', () {
    expect(
      snapAssistantFabToNearestEdge(const Offset(8, 682), bounds),
      const Offset(8, 682),
    );
  });

  test('hızlı fırlatınca gittiği yöne yakın kenara oturur', () {
    const start = Offset(131, 368.5);
    final right = settleAssistantFab(
      position: start,
      velocity: const Offset(1800, 80),
      bounds: bounds,
    );
    expect(right.dx, bounds.maxX);

    final left = settleAssistantFab(
      position: start,
      velocity: const Offset(-1800, 40),
      bounds: bounds,
    );
    expect(left.dx, bounds.minX);
  });

  test('şişmiş padding alt köşeyi ekranın ortasına çekmez', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 844),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.maxY, greaterThan(844 * 0.65));
    expect(bounds.maxY, lessThan(844 - 42 - 90));
  });

  test('yığın zaten kısaysa nav yüksekliği iki kez düşülmez', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 750),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.maxY, greaterThan(600));
  });

  test('yavaş bırakınca fırlatmadan bulunduğu yerin kenarına yapışır', () {
    final settled = settleAssistantFab(
      position: const Offset(40, 300),
      velocity: const Offset(20, -10),
      bounds: bounds,
    );
    expect(settled, const Offset(8, 300));
  });

  test('yapıştığı kenara göre peek yönü ve görünür pay', () {
    expect(
      assistantFabEdgeFor(const Offset(254, 300), bounds),
      AssistantFabEdge.right,
    );
    expect(
      assistantFabEdgeFor(const Offset(8, 300), bounds),
      AssistantFabEdge.left,
    );
    expect(
      assistantFabEdgeFor(const Offset(131, 55), bounds),
      AssistantFabEdge.top,
    );
    expect(
      assistantFabEdgeFor(const Offset(131, 682), bounds),
      AssistantFabEdge.bottom,
    );

    const bubble = Size(42, 42);
    expect(
      assistantFabPeekTranslation(
        edge: AssistantFabEdge.right,
        bubble: bubble,
      ).dx,
      closeTo(20, 0.01),
    );
    expect(
      assistantFabPeekTranslation(
        edge: AssistantFabEdge.left,
        bubble: bubble,
      ).dx,
      closeTo(-20, 0.01),
    );
    expect(
      assistantFabPeekTranslation(
        edge: AssistantFabEdge.top,
        bubble: bubble,
      ).dy,
      closeTo(-20, 0.01),
    );
  });

  test('sağlıklı telefonda sınırlar aynı kalır', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 844),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.minX, 8);
    expect(bounds.maxX, 262);
    expect(bounds.minY, 67);
    expect(bounds.maxY, 678);
  });

  test('kısa yığında alt rezerv bir kez düşülür', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 750),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.minY, 67);
    expect(bounds.maxY, 678);
  });

  test('Xiaomi üst inseti yığından büyükse balon içeride kalır', () {
    const viewTop = 575.6444444444444;
    expect(viewTop + kAssistantFabEdgeMargin, closeTo(583.6444444444444, 1e-9));
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 400),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: viewTop,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.minX, 8);
    expect(bounds.maxX, 262);
    expect(bounds.minY, 8);
    expect(bounds.maxY, 350);
    expect(bounds.maxY + 42, lessThanOrEqualTo(400));
    expect(bounds.minY, lessThanOrEqualTo(bounds.maxY));
  });

  test('ekranın kendisinden büyük üst inset yok sayılır', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(360, 560),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 575.6444444444444,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 560,
    );
    expect(bounds.minY, 8);
    expect(bounds.maxY, 394);
    expect(bounds.maxY + 42, lessThanOrEqualTo(560));
  });

  test('ekrandan büyük alt inset uygulama çubuğu rezervini silmez', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 844),
      bubble: const Size(120, 42),
      viewLeft: 0,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 1619,
      fullScreenHeight: 844,
    );
    expect(bounds.minY, 67);
    expect(bounds.maxY, 712);
  });

  test('kutudan geniş sol inset balonu içeride tutar', () {
    final bounds = assistantFabBoundsFor(
      stack: const Size(390, 844),
      bubble: const Size(120, 42),
      viewLeft: 420,
      viewTop: 59,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: 844,
    );
    expect(bounds.minX, 8);
    expect(bounds.maxX, 262);
    expect(bounds.minY, 67);
    expect(bounds.maxY, 678);
  });

  test('NaN ve sonsuz ölçü ArgumentError fırlatmaz', () {
    final nanBounds = assistantFabBoundsFor(
      stack: const Size(390, 844),
      bubble: const Size(120, 42),
      viewLeft: double.nan,
      viewTop: double.nan,
      viewRight: double.nan,
      viewBottom: double.nan,
      fullScreenHeight: 844,
    );
    expect(nanBounds.minX, 8);
    expect(nanBounds.maxX, 262);
    expect(nanBounds.minY, 8);
    expect(nanBounds.maxY, 712);
    expect(nanBounds.minY, lessThanOrEqualTo(nanBounds.maxY));

    final infinite = assistantFabBoundsFor(
      stack: const Size(double.infinity, double.infinity),
      bubble: const Size(double.nan, double.negativeInfinity),
      viewLeft: double.negativeInfinity,
      viewTop: double.infinity,
      viewRight: 0,
      viewBottom: 34,
      fullScreenHeight: double.infinity,
    );
    expect(infinite.minX.isFinite, isTrue);
    expect(infinite.maxX.isFinite, isTrue);
    expect(infinite.minY.isFinite, isTrue);
    expect(infinite.maxY.isFinite, isTrue);
    expect(infinite.minX, lessThanOrEqualTo(infinite.maxX));
    expect(infinite.minY, lessThanOrEqualTo(infinite.maxY));
  });

  test('geçersiz koordinat sınırın içine çekilir', () {
    expect(bounds.clamp(const Offset(double.nan, 300)).dx, bounds.minX);
    expect(bounds.clamp(const Offset(double.infinity, 300)).dx, bounds.maxX);
    expect(
      bounds.clamp(const Offset(40, double.negativeInfinity)).dy,
      bounds.minY,
    );
    expect(bounds.clamp(const Offset(1000, 10)), const Offset(254, 55));
  });
}
