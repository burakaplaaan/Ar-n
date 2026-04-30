// lib/presentation/shared/providers/quotes_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/utils/hive_boxes.dart';
import '../../../data/repositories/quote_pools_repository.dart';
import '../../../data/repositories/quotes_cloud_repository.dart';

final quotePoolsRepositoryProvider = Provider<QuotePoolsRepository>((ref) {
  return QuotePoolsRepository(
    prefs: ref.read(sharedPreferencesProvider),
    cacheBox: Hive.box<String>(HiveBoxes.quotesCache),
  );
});

final quotesCloudRepositoryProvider = Provider<QuotesCloudRepository>((ref) {
  return QuotesCloudRepository(
    pools: ref.read(quotePoolsRepositoryProvider),
  );
});
