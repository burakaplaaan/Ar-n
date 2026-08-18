import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../habits/habit_management_page.dart';
import '../willpower/quit_template_picker_page.dart';

Future<bool> openEmbeddedQuitSetup(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const ColoredBox(
        color: AppColors.anthraciteDark,
        child: QuitTemplatePickerPage(embeddedInAppOnboarding: true),
      ),
    ),
  );
  return result == true;
}

Future<bool> openEmbeddedBuildSetup(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const ColoredBox(
        color: AppColors.anthraciteDark,
        child: HabitManagementPage(embeddedInAppOnboarding: true),
      ),
    ),
  );
  return result == true;
}
