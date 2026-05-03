import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/ad_gate_service.dart';
import '../../../core/providers/shared_preferences_provider.dart';

final adGateServiceProvider = Provider<AdGateService>((ref) {
  return AdGateService(ref.watch(sharedPreferencesProvider));
});
