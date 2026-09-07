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

  test('asistan yazma çubuğu alt menü insetini iki kez eklemez', () {
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 96,
      ),
      8,
    );
  });

  test('asistan yazma çubuğu yalnızca sistem inseti varken menünün üstünde durur', () {
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 34,
      ),
      68,
    );
  });

  test('gövde alt menünün üstünde bitiyorsa yazma çubuğu tekrar pay eklemez', () {
    expect(
      ArinShellLayout.assistantComposerBottomPaddingFromMedia(
        viewPaddingBottom: 34,
        paddingBottom: 34,
        screenHeight: 800,
        bodyHeight: 690,
      ),
      8,
    );
  });
}
