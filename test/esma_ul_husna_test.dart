import 'package:arin/data/models/esma_ul_husna.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('99 isim ve gün bazlı seçim sabit', () {
    expect(EsmaUlHusna.all.length, 99);
    expect(EsmaUlHusna.all.first.turkish, 'Allah');
    final a = EsmaUlHusna.forDay(DateTime(2026, 8, 18));
    final b = EsmaUlHusna.forDay(DateTime(2026, 8, 18, 23, 50));
    expect(a.index, b.index);
    expect(a.arabic, isNotEmpty);
    expect(
      EsmaUlHusna.forDay(DateTime(2026, 8, 19)).index,
      isNot(a.index),
    );
  });

  test('16 günlük pencerede her gün ayrı isim seçilir', () {
    final start = DateTime(2026, 8, 18);
    final names = List.generate(
      16,
      (i) => EsmaUlHusna.forDay(start.add(Duration(days: i))).index,
    );
    expect(names.toSet().length, 16);
  });
}
