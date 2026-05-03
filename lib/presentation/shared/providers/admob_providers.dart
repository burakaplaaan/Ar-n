import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/admob_service.dart';

final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});
