import 'package:arin/core/router/app_router.dart';
import 'package:arin/presentation/assistant/widgets/assistant_fab_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asistan Bilgi Düellosu ve onboarding dışında görünür', () {
    expect(
      assistantFabHiddenFor(path: AppRoutes.home, duelActive: false),
      isFalse,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.qibla, duelActive: false),
      isFalse,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.premium, duelActive: false),
      isFalse,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.hilalDuel, duelActive: false),
      isTrue,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.qibla, duelActive: true),
      isTrue,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.assistant, duelActive: false),
      isTrue,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.onboarding, duelActive: false),
      isTrue,
    );
    expect(
      assistantFabHiddenFor(path: AppRoutes.appPrepare, duelActive: false),
      isTrue,
    );
  });
}
