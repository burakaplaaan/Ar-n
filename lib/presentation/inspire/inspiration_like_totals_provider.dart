import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/shared_preferences_provider.dart';
import '../../data/services/inspiration_like_totals_service.dart';
import '../../data/services/product_metrics_service.dart';

const _kRemoteCounted = 'inspire_like_remote_counted_ids';
const _kPendingLiked = 'inspire_like_pending_liked_ids';
const _kPendingUnliked = 'inspire_like_pending_unliked_ids';

class InspirationLikeTotalsState {
  const InspirationLikeTotalsState({
    this.extras = const {},
    this.loadedIds = const {},
    this.remotelyCountedIds = const {},
  });

  final Map<String, int> extras;
  final Set<String> loadedIds;
  final Set<String> remotelyCountedIds;

  InspirationLikeTotalsState copyWith({
    Map<String, int>? extras,
    Set<String>? loadedIds,
    Set<String>? remotelyCountedIds,
  }) {
    return InspirationLikeTotalsState(
      extras: extras ?? this.extras,
      loadedIds: loadedIds ?? this.loadedIds,
      remotelyCountedIds: remotelyCountedIds ?? this.remotelyCountedIds,
    );
  }
}

class InspirationLikeTotalsNotifier
    extends StateNotifier<InspirationLikeTotalsState> {
  InspirationLikeTotalsNotifier(this._prefs)
    : super(
        InspirationLikeTotalsState(
          remotelyCountedIds: _readSet(_prefs, _kRemoteCounted),
        ),
      );

  final SharedPreferences _prefs;
  final Set<String> _inFlight = {};

  static Set<String> _readSet(SharedPreferences prefs, String key) =>
      (prefs.getStringList(key) ?? const <String>[]).toSet();

  Future<void> _writeSet(String key, Set<String> values) {
    return _prefs.setStringList(key, values.toList());
  }

  Future<void> ensureLoaded(
    String cardId, {
    bool locallyLiked = false,
  }) async {
    final id = cardId.trim();
    if (id.isEmpty) return;
    if (locallyLiked && !state.remotelyCountedIds.contains(id)) {
      await syncUserLike(id, liked: true);
    }
    await _flushPending(id);
    if (state.loadedIds.contains(id) || _inFlight.contains('r:$id')) return;
    await refresh(id);
  }

  Future<void> refresh(String cardId) async {
    final id = cardId.trim();
    if (id.isEmpty || _inFlight.contains('r:$id')) return;
    _inFlight.add('r:$id');
    try {
      final extra = await InspirationLikeTotalsService.fetchExtra(id);
      if (extra == null) return;
      final extras = Map<String, int>.from(state.extras)..[id] = extra;
      final loaded = Set<String>.from(state.loadedIds)..add(id);
      state = state.copyWith(extras: extras, loadedIds: loaded);
    } finally {
      _inFlight.remove('r:$id');
    }
  }

  Future<void> syncUserLike(String cardId, {required bool liked}) async {
    final id = cardId.trim();
    if (id.isEmpty) return;
    final pendingLiked = _readSet(_prefs, _kPendingLiked);
    final pendingUnliked = _readSet(_prefs, _kPendingUnliked);
    if (liked) {
      pendingLiked.add(id);
      pendingUnliked.remove(id);
    } else {
      pendingUnliked.add(id);
      pendingLiked.remove(id);
    }
    await _writeSet(_kPendingLiked, pendingLiked);
    await _writeSet(_kPendingUnliked, pendingUnliked);
    await _flushPending(id);
  }

  Future<void> _flushPending(String id) async {
    if (_inFlight.contains('s:$id')) return;
    _inFlight.add('s:$id');
    var didWork = false;
    try {
      final pendingLiked = _readSet(_prefs, _kPendingLiked);
      final pendingUnliked = _readSet(_prefs, _kPendingUnliked);
      final wantLike = pendingLiked.contains(id);
      final wantUnlike = pendingUnliked.contains(id);
      if (wantLike || wantUnlike) {
        final accepted = wantLike
            ? await ProductMetricsService.contentLike(id)
            : await ProductMetricsService.contentUnlike(id);
        if (accepted) {
          final latestLiked = _readSet(_prefs, _kPendingLiked);
          final latestUnliked = _readSet(_prefs, _kPendingUnliked);
          if (wantLike) {
            latestLiked.remove(id);
          } else {
            latestUnliked.remove(id);
          }
          await _writeSet(_kPendingLiked, latestLiked);
          await _writeSet(_kPendingUnliked, latestUnliked);

          final counted = Set<String>.from(state.remotelyCountedIds);
          if (wantLike) {
            counted.add(id);
          } else {
            counted.remove(id);
          }
          await _writeSet(_kRemoteCounted, counted);
          state = state.copyWith(remotelyCountedIds: counted);
          didWork = true;
          await refresh(id);
        }
      }
    } finally {
      _inFlight.remove('s:$id');
    }
    if (!didWork) return;
    final stillLiked = _readSet(_prefs, _kPendingLiked).contains(id);
    final stillUnliked = _readSet(_prefs, _kPendingUnliked).contains(id);
    if (stillLiked || stillUnliked) {
      await _flushPending(id);
    }
  }
}

final inspirationLikeTotalsProvider =
    StateNotifierProvider<
      InspirationLikeTotalsNotifier,
      InspirationLikeTotalsState
    >((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return InspirationLikeTotalsNotifier(prefs);
    });
