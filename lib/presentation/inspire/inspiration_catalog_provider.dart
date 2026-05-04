import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/inspiration_assets.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/inspiration/inspiration_fallback_catalog.dart';
import '../../data/inspiration/inspiration_local_corpus_loader.dart';
import '../../data/models/inspiration_card_model.dart';
import '../../data/repositories/inspiration_firestore_repository.dart';
import '../../data/services/inspiration_asset_discovery.dart';
import '../../data/services/inspiration_luminance_service.dart';
import 'inspiration_engagement_provider.dart';

/// Keşfet kataloğu: `assets/data/inspiration/*.json` korpusu + görseller;
/// Korpus yoksa görsel tasarım yedeğine düşer.
final inspirationCatalogProvider = FutureProvider<List<InspirationCardModel>>((
  ref,
) async {
  final indices = await InspirationAssetDiscovery.discoverConsecutiveJpeg();
  if (indices.isEmpty) {
    return const [];
  }

  final corpus = await InspirationLocalCorpusLoader.tryLoadMerged(
    indices: indices,
  );

  final remoteCatalog = await InspirationFirestoreRepository.fetchCatalog(
    prefs: ref.read(sharedPreferencesProvider),
  );
  final remoteCards = remoteCatalog.cards;
  if (remoteCards.isEmpty && remoteCatalog.bundledSeedVersion >= 1) {
    return remoteCards;
  }
  if (remoteCards.isNotEmpty) {
    if (remoteCatalog.bundledSeedVersion < 1 && corpus.isNotEmpty) {
      return _mergeRemoteWithBundledCorpus(remoteCards, corpus);
    }
    return remoteCards;
  }

  if (corpus.isNotEmpty) {
    return corpus;
  }

  return indices.map(InspirationFallbackCatalog.cardForImageIndex).toList();
});

List<InspirationCardModel> _mergeRemoteWithBundledCorpus(
  List<InspirationCardModel> remoteCards,
  List<InspirationCardModel> corpus,
) {
  final corpusById = {for (final card in corpus) card.id: card};
  final remoteById = {for (final card in remoteCards) card.id: card};
  final merged = <InspirationCardModel>[];

  for (final local in corpus) {
    final remote = remoteById[local.id];
    if (remote == null) {
      merged.add(local);
      continue;
    }
    merged.add(
      remote.copyWith(
        imageIndex: local.imageIndex,
        useLightTextOnImage: local.useLightTextOnImage,
      ),
    );
  }

  for (final remote in remoteCards) {
    if (!corpusById.containsKey(remote.id)) {
      merged.add(remote);
    }
  }

  return merged;
}

/// Izgara sırasını karıştırmak için tohum; çek-yenile veya uygulama açılışında değişir.
final exploreGridShuffleSeedProvider = StateProvider<int>(
  (ref) => DateTime.now().millisecondsSinceEpoch,
);

/// Keşfet ızgarası ve tam ekran akışı aynı sırayı kullanır (tohum + katalog).
/// Beğenilen kartların `reelsStyle` / `source` değerleri öne alınır.
final inspirationShuffledGridProvider =
    Provider<AsyncValue<List<InspirationCardModel>>>((ref) {
      final async = ref.watch(inspirationCatalogProvider);
      final seed = ref.watch(exploreGridShuffleSeedProvider);
      final likedIds = ref.watch(inspirationLikedIdsProvider);
      if (async.isLoading) {
        return const AsyncValue.loading();
      }
      if (async.hasError) {
        return AsyncValue.error(
          async.error ?? StateError('inspirationCatalogProvider'),
          async.stackTrace ?? StackTrace.empty,
        );
      }
      final cards = async.value ?? const <InspirationCardModel>[];
      if (cards.isEmpty) {
        return const AsyncValue.data([]);
      }
      final byId = {for (final c in cards) c.id: c};
      final likedStyles = <int>{};
      final likedSources = <String>{};
      for (final lid in likedIds) {
        final c = byId[lid];
        if (c != null) {
          likedStyles.add(c.safeReelsStyle);
          final s = c.source?.trim();
          if (s != null && s.isNotEmpty) likedSources.add(s);
        }
      }

      int score(InspirationCardModel c) {
        var s = 0;
        if (likedStyles.contains(c.safeReelsStyle)) s += 3;
        final src = c.source?.trim();
        if (src != null && src.isNotEmpty && likedSources.contains(src)) {
          s += 2;
        }
        return s;
      }

      final rng = Random(seed);
      final tieBreak = <String, int>{
        for (final c in cards) c.id: rng.nextInt(1 << 30),
      };

      final copy = List<InspirationCardModel>.from(cards);
      copy.sort((a, b) {
        final sb = score(b).compareTo(score(a));
        if (sb != 0) return sb;
        final ta = tieBreak[a.id] ?? 0;
        final tb = tieBreak[b.id] ?? 0;
        return ta.compareTo(tb);
      });
      return AsyncValue.data(copy);
    });

/// Görsel merkez parlaklığı → açık renkli yazı kullanılsın mı (koyu merkez = true).
final inspirationCenterLightTextProvider = FutureProvider.family<bool, int>((
  ref,
  imageIndex,
) async {
  if (imageIndex < 1) return true;
  final path = InspirationAssets.pathForIndex(imageIndex);
  return InspirationLuminanceService.recommendLightColoredText(path);
});

/// Reels: metin rengi + düşük varyanslı şeride dikey hizalama (tek görsel analizi, önbellekli).
final inspirationReelsHintsProvider =
    FutureProvider.family<({bool lightText, Alignment textAnchor}), int>((
      ref,
      imageIndex,
    ) async {
      if (imageIndex < 1) {
        return (lightText: true, textAnchor: Alignment.center);
      }
      final path = InspirationAssets.pathForIndex(imageIndex);
      return InspirationLuminanceService.analyzeForReels(path);
    });
