import 'package:arin/core/router/app_router.dart';
import 'package:arin/presentation/shared/widgets/arin_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sekme kaydırırken widget merkezi ayarlara ezilmez', () {
    expect(
      shouldCommitShellSwipe(
        currentPath: AppRoutes.settingsWidgets,
        tabRoot: AppRoutes.settings,
      ),
      isFalse,
    );
    expect(
      shouldCommitShellSwipe(
        currentPath: AppRoutes.settingsNotifications,
        tabRoot: AppRoutes.settings,
      ),
      isFalse,
    );
    expect(
      shouldCommitShellSwipe(
        currentPath: AppRoutes.home,
        tabRoot: AppRoutes.settings,
      ),
      isTrue,
    );
    expect(
      shouldCommitShellSwipe(
        currentPath: AppRoutes.settings,
        tabRoot: AppRoutes.settings,
      ),
      isFalse,
    );
  });
}
