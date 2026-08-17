import 'package:arin/presentation/shared/navigation/once_open.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aynı anda ikinci çağrı düşer, bitince yeniden açılır', () async {
    final gate = OnceOpen();
    var started = 0;
    var finished = 0;

    Future<void> slow() async {
      started++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      finished++;
    }

    final first = gate.run(slow);
    final second = gate.run(slow);
    await Future.wait([first, second]);

    expect(started, 1);
    expect(finished, 1);
    expect(gate.isBusy, isFalse);

    await gate.run(slow);
    expect(started, 2);
    expect(finished, 2);
  });

  test('hata olsa bile kilit açılır', () async {
    final gate = OnceOpen();
    await expectLater(
      gate.run(() async {
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(gate.isBusy, isFalse);
    expect(await gate.run(() async => 7), 7);
  });
}
