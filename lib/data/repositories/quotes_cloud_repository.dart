// lib/data/repositories/quotes_cloud_repository.dart
// Kişiselleştirilmiş sözler: `quote_pools/personalized_quotes` (+ widget havuzu).

import '../../core/constants/quote_pool_ids.dart';
import '../../domain/entities/matched_content.dart';
import 'quote_pools_repository.dart';

class QuotesCloudRepository {
  QuotesCloudRepository({
    required QuotePoolsRepository pools,
  }) : _pools = pools;

  final QuotePoolsRepository _pools;

  /// Bugün için havuzları senkronla (günde ≤1 okuma / havuz).
  Future<void> ensureSyncedToday() async {
    await _pools.ensureSyncedToday(QuotePoolIds.personalizedQuotes);
    await _pools.ensureSyncedToday(QuotePoolIds.widgetQuote);
  }

  /// Eşleştirme için havuz; yoksa null → ContentMatcher asset yolu.
  List<MatchedContent>? cachedPoolIfAny() {
    return _pools.matchedContentFromPersonalizedCache();
  }
}
