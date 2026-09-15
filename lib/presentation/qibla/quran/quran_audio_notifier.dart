// Kur'an tilaveti — ayet ayet stream, çift oynatıcı ile boşluksuz geçiş.
// Ses doğrudan CDN; Firebase / proxy yok.

import 'dart:async';

import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/quran/quran_progress_store.dart';
import '../../../data/quran/quran_surah_catalog.dart';
import '../../../data/services/audio_session_coordinator.dart';

abstract final class QuranAudioUrls {
  static String islamicNetwork(int globalAyah) =>
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';

  static String everyAyah(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$s$a.mp3';
  }

  static String alquranCloud(int globalAyah) =>
      'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/$globalAyah';

  static String quranCdn(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://verses.quran.com/Alafasy/mp3/$s$a.mp3';
  }

  static List<String> forAyah(int surah, int ayah) {
    final global = QuranSurahCatalog.globalAyahNumber(surah, ayah);
    return <String>[
      everyAyah(surah, ayah),
      islamicNetwork(global),
      quranCdn(surah, ayah),
      alquranCloud(global),
    ];
  }
}

@immutable
class QuranAudioState {
  const QuranAudioState({
    required this.isPlaying,
    required this.buffering,
    required this.surah,
    required this.ayah,
    required this.error,
  });

  final bool isPlaying;
  final bool buffering;
  final int? surah;
  final int? ayah;
  final String? error;

  static const idle = QuranAudioState(
    isPlaying: false,
    buffering: false,
    surah: null,
    ayah: null,
    error: null,
  );

  bool get hasTrack => surah != null && ayah != null;

  QuranAudioState copyWith({
    bool? isPlaying,
    bool? buffering,
    int? surah,
    int? ayah,
    String? error,
    bool clearError = false,
  }) {
    return QuranAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      buffering: buffering ?? this.buffering,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  QuranAudioNotifier(this._progress) : super(QuranAudioState.idle) {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    AudioSessionCoordinator.register(AudioSessionOwner.quran, pause);
    _completeA = _playerA.onPlayerComplete.listen((_) {
      unawaited(_onComplete(_playerA));
    });
    _completeB = _playerB.onPlayerComplete.listen((_) {
      unawaited(_onComplete(_playerB));
    });
  }

  final QuranProgressStore _progress;

  late final AudioPlayer _playerA;
  late final AudioPlayer _playerB;
  StreamSubscription<void>? _completeA;
  StreamSubscription<void>? _completeB;

  bool _primaryIsA = true;
  bool _playersReady = false;
  bool _sessionReady = false;
  bool _disposed = false;
  int _suppressFocusPause = 0;
  int _epoch = 0;
  int _completeGen = 0;
  int _armedCompleteGen = -1;
  (int surah, int ayah)? _armed;
  (int surah, int ayah)? _prefetched;

  AudioPlayer get _primary => _primaryIsA ? _playerA : _playerB;
  AudioPlayer get _secondary => _primaryIsA ? _playerB : _playerA;

  AudioContext get _playbackContext {
    if (kIsWeb) return AudioContext();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AudioContext(iOS: AudioContextIOS());
    }
    return AudioContext();
  }

  AudioContext get _prefetchContext {
    if (kIsWeb) return AudioContext();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
      );
    }
    return _playbackContext;
  }

  Future<void> _applyPlayerRoles() async {
    try {
      await _primary.setAudioContext(_playbackContext);
      await _secondary.setAudioContext(_prefetchContext);
      await _primary.setVolume(1);
      await _secondary.setVolume(1);
    } catch (_) {}
  }

  Future<void> _ensurePlayers() async {
    if (_playersReady) return;
    try {
      await _playerA.setPlayerMode(PlayerMode.mediaPlayer);
      await _playerB.setPlayerMode(PlayerMode.mediaPlayer);
      await _playerA.setReleaseMode(ReleaseMode.stop);
      await _playerB.setReleaseMode(ReleaseMode.stop);
      await _applyPlayerRoles();
    } catch (_) {}
    _playersReady = true;
  }

  Future<void> _configureExclusiveSession() async {
    if (_sessionReady) return;
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
      }
    } catch (_) {}
    _sessionReady = true;
  }

  Future<void> _claimExclusivePlayback() async {
    await AudioSessionCoordinator.pauseOwner(AudioSessionOwner.healing);
    await AudioSessionCoordinator.pauseOwner(AudioSessionOwner.exploreBgm);
    await AudioSessionCoordinator.claim(AudioSessionOwner.quran);
  }

  void _invalidateCompletes() {
    _completeGen++;
  }

  Future<void> _silenceBoth() async {
    _invalidateCompletes();
    try {
      await _playerA.stop();
      await _playerB.stop();
    } catch (_) {}
  }

  Future<bool> _continueOrAbort(int epoch) async {
    if (_disposed) {
      await _silenceBoth();
      return false;
    }
    if (epoch != _epoch) {
      if (!state.isPlaying) {
        await _silenceBoth();
      }
      return false;
    }
    if (state.isPlaying) return true;
    _armed = null;
    _prefetched = null;
    await _silenceBoth();
    AudioSessionCoordinator.release(AudioSessionOwner.quran);
    return false;
  }

  Future<void> playSurah(int surah, {int ayah = 1}) async {
    if (_disposed) return;
    final meta = QuranSurahCatalog.byNumber(surah);
    final start = ayah.clamp(1, meta.ayahCount);
    await _playAt(meta.number, start, userStarted: true);
  }

  Future<void> toggle() async {
    if (_disposed) return;
    if (state.isPlaying) {
      await pause();
      return;
    }
    if (state.hasTrack) {
      await _resumeHeld();
      return;
    }
    final last = _progress.readProgress();
    await playSurah(last?.surah ?? 1, ayah: last?.ayah ?? 1);
  }

  Future<void> _resumeHeld() async {
    if (_disposed || !state.hasTrack) return;
    final epoch = ++_epoch;
    final surah = state.surah!;
    final ayah = state.ayah!;
    _armed = (surah, ayah);
    state = state.copyWith(isPlaying: true, buffering: true, clearError: true);
    await _ensurePlayers();
    await _claimExclusivePlayback();
    if (!await _continueOrAbort(epoch)) return;
    await _configureExclusiveSession();
    if (!await _continueOrAbort(epoch)) return;
    _suppressFocusPause++;
    try {
      await _primary.resume();
      if (!await _continueOrAbort(epoch)) return;
      final ready = await _waitUntilReady(_primary, epoch);
      if (!await _continueOrAbort(epoch)) return;
      if (!ready) {
        await _startPrimary(surah, ayah, epoch);
        if (!await _continueOrAbort(epoch)) return;
      }
      _armed = (surah, ayah);
      _armedCompleteGen = _completeGen;
      state = state.copyWith(isPlaying: true, buffering: false, clearError: true);
      unawaited(_prefetchNext(surah, ayah, epoch));
    } catch (_) {
      if (!await _continueOrAbort(epoch)) return;
      await _playAt(surah, ayah, userStarted: true);
    } finally {
      if (_suppressFocusPause > 0) _suppressFocusPause--;
    }
  }

  Future<void> pause() async {
    if (_disposed) return;
    if (_suppressFocusPause > 0) return;
    _epoch++;
    _invalidateCompletes();
    _armed = null;
    _prefetched = null;
    state = state.copyWith(isPlaying: false, buffering: false);
    try {
      await _playerA.pause();
      await _playerB.pause();
    } catch (_) {}
    AudioSessionCoordinator.release(AudioSessionOwner.quran);
  }

  Future<void> stop() async {
    if (_disposed) return;
    _epoch++;
    _armed = null;
    _prefetched = null;
    state = QuranAudioState.idle;
    await _silenceBoth();
    AudioSessionCoordinator.release(AudioSessionOwner.quran);
  }

  Future<void> nextAyah() async {
    final next = _nextOf(state.surah, state.ayah);
    if (next == null) {
      await pause();
      return;
    }
    await _playAt(next.$1, next.$2, userStarted: true);
  }

  Future<void> previousAyah() async {
    final prev = _prevOf(state.surah, state.ayah);
    if (prev == null) return;
    await _playAt(prev.$1, prev.$2, userStarted: true);
  }

  Future<void> _onComplete(AudioPlayer source) async {
    if (_disposed || source != _primary) return;
    if (_completeGen != _armedCompleteGen) return;
    if (!state.isPlaying || state.buffering) return;
    final armed = _armed;
    if (armed == null) return;
    if (state.surah != armed.$1 || state.ayah != armed.$2) return;
    final next = _nextOf(armed.$1, armed.$2);
    if (next == null) {
      await pause();
      return;
    }
    await _playAt(next.$1, next.$2, userStarted: false);
  }

  Future<void> _playAt(
    int surah,
    int ayah, {
    required bool userStarted,
  }) async {
    if (_disposed) return;
    final epoch = ++_epoch;
    final meta = QuranSurahCatalog.byNumber(surah);
    final clamped = ayah.clamp(1, meta.ayahCount);
    _armed = (meta.number, clamped);
    _prefetched = userStarted ? null : _prefetched;
    state = QuranAudioState(
      isPlaying: true,
      buffering: true,
      surah: meta.number,
      ayah: clamped,
      error: null,
    );
    unawaited(_progress.saveProgress(surah: meta.number, ayah: clamped));

    await _ensurePlayers();
    await _claimExclusivePlayback();
    if (!await _continueOrAbort(epoch)) return;
    await _configureExclusiveSession();
    if (!await _continueOrAbort(epoch)) return;

    final usedPrefetch = !userStarted &&
        _prefetched != null &&
        _prefetched!.$1 == meta.number &&
        _prefetched!.$2 == clamped;

    _suppressFocusPause++;
    try {
      if (usedPrefetch) {
        _primaryIsA = !_primaryIsA;
        _prefetched = null;
        _invalidateCompletes();
        await _applyPlayerRoles();
        try {
          await _secondary.stop();
        } catch (_) {}
        if (!await _continueOrAbort(epoch)) return;
        try {
          await _primary.resume();
        } catch (_) {}
        if (!await _continueOrAbort(epoch)) return;
        final ready = await _waitUntilReady(_primary, epoch);
        if (!await _continueOrAbort(epoch)) return;
        if (!ready) {
          await _startPrimary(meta.number, clamped, epoch);
        }
      } else {
        _prefetched = null;
        _invalidateCompletes();
        try {
          await _secondary.stop();
        } catch (_) {}
        if (!await _continueOrAbort(epoch)) return;
        await _startPrimary(meta.number, clamped, epoch);
      }
      if (!await _continueOrAbort(epoch)) return;
      _armed = (meta.number, clamped);
      _armedCompleteGen = _completeGen;
      state = state.copyWith(isPlaying: true, buffering: false, clearError: true);
      unawaited(_prefetchNext(meta.number, clamped, epoch));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuranAudioNotifier.play: $e\n$st');
      }
      if (epoch != _epoch || _disposed) return;
      await _silenceBoth();
      if (epoch != _epoch || _disposed) return;
      state = state.copyWith(
        isPlaying: false,
        buffering: false,
        error: 'audio',
      );
      AudioSessionCoordinator.release(AudioSessionOwner.quran);
    } finally {
      if (_suppressFocusPause > 0) _suppressFocusPause--;
    }
  }

  Future<void> _startPrimary(int surah, int ayah, int epoch) async {
    final urls = QuranAudioUrls.forAyah(surah, ayah);
    Object? lastError;
    for (final url in urls) {
      if (!await _continueOrAbort(epoch)) {
        throw StateError('stale play');
      }
      try {
        _invalidateCompletes();
        await _primary.stop();
        await _primary.play(UrlSource(url, mimeType: 'audio/mpeg'));
        if (!await _continueOrAbort(epoch)) {
          throw StateError('stale play');
        }
        if (await _waitUntilReady(_primary, epoch)) return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError('audio start failed');
  }

  Future<bool> _waitUntilReady(AudioPlayer player, int epoch) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < const Duration(seconds: 10)) {
      if (_disposed || epoch != _epoch || !state.isPlaying) return false;
      try {
        if (player.state == PlayerState.playing) return true;
        final position = await player.getCurrentPosition();
        if (position != null && position > Duration.zero) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return false;
  }

  Future<void> _prefetchNext(int surah, int ayah, int epoch) async {
    final next = _nextOf(surah, ayah);
    if (next == null || _disposed || epoch != _epoch) return;
    final urls = QuranAudioUrls.forAyah(next.$1, next.$2);
    for (final url in urls) {
      if (_disposed || epoch != _epoch) return;
      try {
        await _secondary.stop();
        await _secondary.setSource(UrlSource(url, mimeType: 'audio/mpeg'));
        await _secondary.setVolume(1);
        if (_disposed || epoch != _epoch) return;
        _prefetched = next;
        return;
      } catch (_) {
        _prefetched = null;
      }
    }
  }

  (int, int)? _nextOf(int? surah, int? ayah) {
    if (surah == null || ayah == null) return null;
    final meta = QuranSurahCatalog.byNumber(surah);
    if (ayah < meta.ayahCount) return (surah, ayah + 1);
    if (surah >= 114) return null;
    return (surah + 1, 1);
  }

  (int, int)? _prevOf(int? surah, int? ayah) {
    if (surah == null || ayah == null) return null;
    if (ayah > 1) return (surah, ayah - 1);
    if (surah <= 1) return null;
    final prev = QuranSurahCatalog.byNumber(surah - 1);
    return (prev.number, prev.ayahCount);
  }

  Future<void> disposePlayers() async {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    _armed = null;
    await _completeA?.cancel();
    await _completeB?.cancel();
    AudioSessionCoordinator.unregister(AudioSessionOwner.quran);
    try {
      await _playerA.stop();
      await _playerB.stop();
      await _playerA.dispose();
      await _playerB.dispose();
    } catch (_) {}
  }
}

final quranAudioNotifierProvider =
    StateNotifierProvider.autoDispose<QuranAudioNotifier, QuranAudioState>((
      ref,
    ) {
      final n = QuranAudioNotifier(ref.read(quranProgressStoreProvider));
      ref.onDispose(n.disposePlayers);
      return n;
    });
