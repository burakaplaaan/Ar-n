import 'package:arin/presentation/shared/widgets/arin_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('klavye üst kabukta yutulsa bile açık sayılır', () {
    expect(
      ArinShellLayout.keyboardOpenFromMedia(
        viewInsetsBottom: 0,
        viewPaddingBottom: 34,
        paddingBottom: 0,
      ),
      isTrue,
    );
    expect(
      ArinShellLayout.keyboardOpenFromMedia(
        viewInsetsBottom: 280,
        viewPaddingBottom: 34,
        paddingBottom: 0,
      ),
      isTrue,
    );
    expect(
      ArinShellLayout.keyboardOpenFromMedia(
        viewInsetsBottom: 0,
        viewPaddingBottom: 34,
        paddingBottom: 34,
      ),
      isFalse,
    );
  });
}
