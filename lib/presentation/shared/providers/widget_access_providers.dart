import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/widget_access_service.dart';
import '../../../core/providers/shared_preferences_provider.dart';

final widgetAccessServiceProvider = Provider<WidgetAccessService>((ref) {
  return WidgetAccessService(ref.watch(sharedPreferencesProvider));
});
