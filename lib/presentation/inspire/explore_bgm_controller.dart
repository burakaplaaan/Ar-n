// Keşfet (explore) arka plan müziği — çift AudioPlayer ile çapraz geçiş.

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/audio_session_coordinator.dart';

const _kExploreBgmLastTrackPrefsKey = 'explore_bgm_last_track_index';
const _kExploreBgmUserEnabledPrefsKey = 'explore_bgm_user_enabled';

String _routePathFromInformation(RouteInformation info) {
  final p = info.uri.path;
  if (p.isEmpty) return '/';
  return p;
}

/// [AssetSource] için `assets/` ön eki olmadan.
/// Kaynak: Pixabay Music (Content License) — bkz. assets/music/explore/README.txt
const kExploreBgmAssetPaths = <String>[
  'music/explore/explore_bg_1.mp3',
  'music/explore/explore_bg_2.mp3',
  'music/explore/explore_bg_3.mp3',
  'music/explore/explore_bg_4.mp3',
];

class ExploreBgmUiState {
  const ExploreBgmUiState({
    required this.userEnabled,
    required this.isPlaying,
    required this.trackIndex,
  });

  final bool userEnabled;
  final bool isPlaying;
  final int trackIndex;

  static const initial = ExploreBgmUiState(
    userEnabled: false,
    isPlaying: false,
    trackIndex: 0,
  );

  ExploreBgmUiState copyWith({
    bool? userEnabled,
    bool? isPlaying,
    int? trackIndex,
  }) {
    return ExploreBgmUiState(
      userEnabled: userEnabled ?? this.userEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      trackIndex: trackIndex ?? this.trackIndex,
    );
  }
}

class ExploreBgmNotifier extends StateNotifier<ExploreBgmUiState> {
  ExploreBgmNotifier(this._prefs) : super(ExploreBgmUiState.initial) {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    // Healing sahneyi alırsa BGM otomatik susar (state initial'e döner).
    AudioSessionCoordinator.register(
      AudioSessionOwner.exploreBgm,
      _pauseByCoordinator,
    );
  }

  /// Koordinatör çağrısıyla tetiklenen pause — kullanıcı toggle'ı off
  /// konumuna çekmiş gibi davranır: son track index'i kaydedip sessizliğe geçer.
  Future<void> _pauseByCoordinator() async {
    if (_disposed) return;
    if (!state.userEnabled && !state.isPlaying) return;
    _playbackEpoch++;
    _persistTrackIndex(state.trackIndex);
    _cancelAllTimers();
    _crossfadeInProgress = false;
    state = state.copyWith(userEnabled: false, isPlaying: false);
    await _silenceBoth();
  }

  final SharedPreferences _prefs;

  int _clampTrackIndex(int i) =>
      i.clamp(0, kExploreBgmAssetPaths.length - 1).toInt();

  int _readSavedTrackIndex() {
    final raw = _prefs.getInt(_kExploreBgmLastTrackPrefsKey);
    if (raw == null) return 0;
    return _clampTrackIndex(raw);
  }

  void _persistTrackIndex(int index) {
    unawaited(_prefs.setInt(_kExploreBgmLastTrackPrefsKey, _clampTrackIndex(index)));
  }

  /// Kullanıcı BGM toggle'ını açık bıraktıysa bir sonraki Keşfet ziyaretinde
  /// otomatik başlatılır. Koordinatör kaynaklı pause'da pref değiştirilmez —
  /// kullanıcının kendi tercihi kaybolmasın.
  bool _readSavedUserEnabled() {
    return _prefs.getBool(_kExploreBgmUserEnabledPrefsKey) ?? false;
  }

  Future<void> _persistUserEnabled(bool value) {
    return _prefs.setBool(_kExploreBgmUserEnabledPrefsKey, value);
  }

  Future<void> _stopAndRequireManualRestart() async {
    if (_disposed) return;
    _playbackEpoch++;
    if (state.userEnabled) {
      _persistTrackIndex(state.trackIndex);
    }
    _cancelAllTimers();
    _crossfadeInProgress = false;
    state = ExploreBgmUiState.initial.copyWith(
      trackIndex: _clampTrackIndex(state.trackIndex),
    );
    await _persistUserEnabled(false);
    await _silenceBoth();
    AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
  }

  static const int _crossfadeMs = 2000;
  static const int _positionPollMs = 450;
  static const int _preCrossfadeLeadMs = 250;
  static const int _fadeTickMs = 50;

  late final AudioPlayer _playerA;
  late final AudioPlayer _playerB;
  bool _primaryIsA = true;
  bool _sessionReady = false;
  bool _disposed = false;
  bool _crossfadeInProgress = false;
  int _playbackEpoch = 0;

  Timer? _positionPoll;
  Timer? _crossfadeRamp;

  AudioPlayer get _primary => _primaryIsA ? _playerA : _playerB;
  AudioPlayer get _secondary => _primaryIsA ? _playerB : _playerA;

  /// Bu oturumda kullanıcı en az bir kez Keşfet'e girdi mi? Cold-start
  /// sonrası ilk ziyarette otomatik müzik başlatmıyoruz (metro, camide,
  /// toplantıda ani patlamasın) — aynı oturumda çıkıp tekrar girerse ise
  /// tercih hatırlanır ve otomatik devam edebilir.
  bool _enteredExploreThisSession = false;

  void onRoutePath(String path) {
    if (_disposed) return;
    final inExplore = path == AppRoutes.inspire ||
        path.startsWith('${AppRoutes.inspire}/');

    if (inExplore) {
      // Cold-start güvenliği: uygulama yeni açıldıysa ve bu, oturumun ilk
      // Keşfet ziyaretiyse → kullanıcı tercihi "açık" olsa bile OTOMATİK
      // başlatma. Kullanıcı üst sağdaki BGM butonuna bassın. Aynı oturum
      // içindeki ikinci Keşfet ziyaretinde eski davranış geçerli: tercih
      // açıksa otomatik sürsün.
      if (!_enteredExploreThisSession) {
        _enteredExploreThisSession = true;
        return;
      }
      if (!state.userEnabled && _readSavedUserEnabled()) {
        final startIndex = _readSavedTrackIndex();
        state = state.copyWith(userEnabled: true, trackIndex: startIndex);
        unawaited(_startPlayback());
      }
      return;
    }

    // Route exit'te kullanıcı tercihini de kapat: Keşfet'e geri dönünce
    // müzik otomatik başlamasın, kullanıcı tekrar elle açsın.
    unawaited(_stopAndRequireManualRestart());
  }

  Future<void> pauseForVisibilityLoss() async {
    await _stopAndRequireManualRestart();
  }

  /// Reklam / premium paneli gibi Keşfet içinde geçici overlay açıldığında
  /// sesi hemen kes. Kullanıcı tercihini prefs'te kapatmaz; panel kapanınca
  /// müziğin otomatik patlamasını da istemediğimiz için state kapalı kalır.
  /// Kullanıcı isterse üst bardan tekrar açabilir.
  Future<void> pauseForAdGate() async {
    if (_disposed) return;
    if (!state.userEnabled && !state.isPlaying) return;
    _playbackEpoch++;
    _persistTrackIndex(state.trackIndex);
    _cancelAllTimers();
    _crossfadeInProgress = false;
    state = state.copyWith(userEnabled: false, isPlaying: false);
    await _silenceBoth();
    AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
  }

  Future<void> toggle() async {
    if (_disposed) return;
    if (state.userEnabled) {
      _persistTrackIndex(state.trackIndex);
      _playbackEpoch++;
      await _persistUserEnabled(false);
      _cancelAllTimers();
      _crossfadeInProgress = false;
      state = state.copyWith(userEnabled: false, isPlaying: false);
      await _silenceBoth();
      AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
      unawaited(ArinAnalytics.kesfetBgmToggle(false));
      return;
    }
    final startIndex = _readSavedTrackIndex();
    state = state.copyWith(userEnabled: true, trackIndex: startIndex);
    await _persistUserEnabled(true);
    await _startPlayback();
    unawaited(ArinAnalytics.kesfetBgmToggle(true));
  }

  Future<void> skip() async {
    if (_disposed || !state.userEnabled || !state.isPlaying) return;
    final startEpoch = _playbackEpoch;
    _cancelAllTimers();
    _crossfadeInProgress = false;

    final next = (state.trackIndex + 1) % kExploreBgmAssetPaths.length;
    await _silenceBoth();
    if (!_isPlaybackStartCurrent(startEpoch)) {
      AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
      return;
    }

    _primaryIsA = true;
    state = state.copyWith(trackIndex: next, isPlaying: true);
    _persistTrackIndex(next);
    await _prepareSession();
    if (!_isPlaybackStartCurrent(startEpoch)) {
      await _silenceBoth();
      AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
      return;
    }
    try {
      await _playerA.setVolume(1.0);
      await _playerA.play(AssetSource(kExploreBgmAssetPaths[next]));
      if (!_isPlaybackStartCurrent(startEpoch)) {
        await _silenceBoth();
        AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
        return;
      }
      state = state.copyWith(isPlaying: true);
      _startPositionPoll();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(isPlaying: false);
      }
    }
  }

  Future<void> _startPlayback() async {
    if (_disposed || !state.userEnabled) return;
    final startEpoch = ++_playbackEpoch;
    // Sahneyi al — varsa Healing Frequencies otomatik pause olur.
    await AudioSessionCoordinator.claim(AudioSessionOwner.exploreBgm);
    if (!_isPlaybackStartCurrent(startEpoch)) {
      AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
      return;
    }
    _cancelAllTimers();
    _crossfadeInProgress = false;
    _primaryIsA = true;
    await _silenceBoth();
    await _prepareSession();
    if (!_isPlaybackStartCurrent(startEpoch)) {
      await _silenceBoth();
      AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
      return;
    }
    try {
      final idx = state.trackIndex.clamp(0, kExploreBgmAssetPaths.length - 1);
      await _playerA.setVolume(1.0);
      await _playerA.play(AssetSource(kExploreBgmAssetPaths[idx]));
      if (!_isPlaybackStartCurrent(startEpoch)) {
        await _silenceBoth();
        AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
        return;
      }
      state = state.copyWith(isPlaying: true, trackIndex: idx);
      _startPositionPoll();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(userEnabled: false, isPlaying: false);
      }
    }
  }

  bool _isPlaybackStartCurrent(int startEpoch) {
    return !_disposed && state.userEnabled && startEpoch == _playbackEpoch;
  }

  Future<void> _beginCrossfadeToNext() async {
    if (_disposed || !state.userEnabled || !state.isPlaying) return;
    if (_crossfadeInProgress) return;
    final startEpoch = _playbackEpoch;
    _crossfadeInProgress = true;
    _positionPoll?.cancel();
    _positionPoll = null;

    final from = _primary;
    final to = _secondary;
    final nextIndex = (state.trackIndex + 1) % kExploreBgmAssetPaths.length;

    try {
      await to.stop();
      if (!await _continueOrAbortStalePlayback(startEpoch)) return;
      await to.setVolume(0);
      if (!await _continueOrAbortStalePlayback(startEpoch)) return;
      await to.play(AssetSource(kExploreBgmAssetPaths[nextIndex]));
      if (!await _continueOrAbortStalePlayback(startEpoch)) return;
    } catch (_) {
      _crossfadeInProgress = false;
      if (!_disposed && state.userEnabled) {
        _startPositionPoll();
      }
      return;
    }

    var elapsed = 0;
    _crossfadeRamp?.cancel();
    _crossfadeRamp = Timer.periodic(
      const Duration(milliseconds: _fadeTickMs),
      (timer) {
        if (!_isPlaybackStartCurrent(startEpoch)) {
          timer.cancel();
          _crossfadeRamp = null;
          _crossfadeInProgress = false;
          unawaited(_silenceBoth());
          AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
          return;
        }
        elapsed += _fadeTickMs;
        final t = (elapsed / _crossfadeMs).clamp(0.0, 1.0);
        unawaited(from.setVolume(1.0 - t));
        unawaited(to.setVolume(t));
        if (elapsed >= _crossfadeMs) {
          timer.cancel();
          _crossfadeRamp = null;
          unawaited(_completeCrossfade(from, to, nextIndex, startEpoch));
        }
      },
    );
  }

  Future<bool> _continueOrAbortStalePlayback(int startEpoch) async {
    if (_isPlaybackStartCurrent(startEpoch)) return true;
    _crossfadeInProgress = false;
    await _silenceBoth();
    AudioSessionCoordinator.release(AudioSessionOwner.exploreBgm);
    return false;
  }

  Future<void> _completeCrossfade(
    AudioPlayer from,
    AudioPlayer to,
    int nextIndex,
    int startEpoch,
  ) async {
    if (!_isPlaybackStartCurrent(startEpoch)) {
      await _continueOrAbortStalePlayback(startEpoch);
      return;
    }
    try {
      await from.stop();
      if (!await _continueOrAbortStalePlayback(startEpoch)) return;
      await from.setVolume(1.0);
      if (!await _continueOrAbortStalePlayback(startEpoch)) return;
      await to.setVolume(1.0);
    } catch (_) {}
    if (!_isPlaybackStartCurrent(startEpoch)) {
      await _continueOrAbortStalePlayback(startEpoch);
      return;
    }
    _primaryIsA = !_primaryIsA;
    _crossfadeInProgress = false;
    state = state.copyWith(trackIndex: nextIndex, isPlaying: true);
    _persistTrackIndex(nextIndex);
    if (state.userEnabled) {
      _startPositionPoll();
    }
  }

  void _startPositionPoll() {
    _positionPoll?.cancel();
    if (_disposed || !state.userEnabled || !state.isPlaying) return;
    _positionPoll = Timer.periodic(
      const Duration(milliseconds: _positionPollMs),
      (_) => unawaited(_tickPositionPoll()),
    );
  }

  Future<void> _tickPositionPoll() async {
    if (_disposed ||
        !state.userEnabled ||
        !state.isPlaying ||
        _crossfadeInProgress) {
      return;
    }
    try {
      final primary = _primary;
      final pos = await primary.getCurrentPosition();
      final dur = await primary.getDuration();
      if (pos == null || dur == null) return;
      if (dur.inMilliseconds <= 0) return;
      final remaining = dur - pos;
      if (remaining.inMilliseconds <= _crossfadeMs + _preCrossfadeLeadMs) {
        await _beginCrossfadeToNext();
      }
    } catch (_) {}
  }

  Future<void> _prepareSession() async {
    if (_sessionReady) return;
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
      await _playerA.setPlayerMode(PlayerMode.mediaPlayer);
      await _playerB.setPlayerMode(PlayerMode.mediaPlayer);
      await _playerA.setReleaseMode(ReleaseMode.stop);
      await _playerB.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
    _sessionReady = true;
  }

  Future<void> _silenceBoth() async {
    try {
      await _playerA.stop();
      await _playerB.stop();
      await _playerA.setVolume(1.0);
      await _playerB.setVolume(1.0);
    } catch (_) {}
  }

  void _cancelAllTimers() {
    _positionPoll?.cancel();
    _positionPoll = null;
    _crossfadeRamp?.cancel();
    _crossfadeRamp = null;
  }

  void disposePlayers() {
    if (_disposed) return;
    _cancelAllTimers();
    _crossfadeInProgress = false;
    AudioSessionCoordinator.unregister(AudioSessionOwner.exploreBgm);
    unawaited(_playerA.dispose());
    unawaited(_playerB.dispose());
    _disposed = true;
  }
}

final exploreBgmNotifierProvider =
    StateNotifierProvider<ExploreBgmNotifier, ExploreBgmUiState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = ExploreBgmNotifier(prefs);
  final router = ref.watch(appRouterProvider);
  var disposed = false;
  var syncScheduled = false;
  String? lastAppliedPath;

  void applyRouteSync() {
    if (disposed) return;
    final info = router.routeInformationProvider.value;
    final path = _routePathFromInformation(info);
    if (path == lastAppliedPath) return;
    lastAppliedPath = path;
    notifier.onRoutePath(path);
  }

  void syncRouteDeferred() {
    if (disposed || syncScheduled) return;
    syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      syncScheduled = false;
      applyRouteSync();
    });
  }

  router.routerDelegate.addListener(syncRouteDeferred);
  syncRouteDeferred();

  ref.onDispose(() {
    disposed = true;
    router.routerDelegate.removeListener(syncRouteDeferred);
    notifier.disposePlayers();
  });

  return notifier;
});
