import 'package:arin/presentation/assistant/widgets/assistant_fab_physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = AssistantFabBounds(
    minX: 8,
    maxX: 254,
    minY: 55,
    maxY: 682,
  );

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
}
