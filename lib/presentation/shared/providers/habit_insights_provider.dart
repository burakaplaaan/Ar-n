import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/willpower/habit_insights_catalog.dart';
import '../../../data/willpower/insight_quote_pools.dart';
import 'quotes_providers.dart';

final habitInsightsCatalogProvider =
    FutureProvider<HabitInsightsCatalog>((ref) async {
  return HabitInsightsCatalog.load();
});

final habitInsightQuotePoolsProvider =
    FutureProvider<InsightQuotePools>((ref) async {
  final pools = ref.watch(quotePoolsRepositoryProvider);
  return InsightQuotePools.loadWithPools(pools);
});
