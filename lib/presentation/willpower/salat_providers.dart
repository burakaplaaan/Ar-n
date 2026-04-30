import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/salat_log_repository.dart';

final salatLogRepositoryProvider = Provider<SalatLogRepository>(
  (_) => SalatLogRepository(),
);
