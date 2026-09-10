import 'package:arin/presentation/shared/widgets/arin_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('klavye yalnızca gerçek viewInsets ile açık sayılır', () {
    expect(
      ArinShellLayout.keyboardOpenFromMedia(
        viewInsetsBottom: 0,
        viewPaddingBottom: 34,
        paddingBottom: 0,
      ),
      isFalse,
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

  test('yazma çubuğu padding soyulunca da barın üstünde kalır', () {
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 0,
        paddingBottom: 0,
      ),
      96,
    );
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 34,
      ),
      130,
    );
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 96,
      ),
      ArinShellLayout.barClearance(96),
    );
  });

  test('gövde yüksekliği bar boşluğunu kısaltmaz', () {
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 34,
        screenHeight: 800,
        bodyHeight: 690,
      ),
      130,
    );
  });
}
