import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_locale_provider.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_progress_store.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/quran/quran_surah_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../qibla/quran/quran_audio_notifier.dart';
import 'carplay_quran_snapshot.dart';

/// CarPlay ve Android Auto, telefonla aynı [QuranAudioNotifier] üzerinden okur.
/// Sayfa açık olmasa da bir araç kanalı bağlıyken oynatıcı yaşar.
abstract final class QuranRemoteHost {
  static const carPlayChannel = MethodChannel('com.arin.arin/carplay');
  static const autoChannel = MethodChannel('com.arin.arin/auto');
  static const _verseLimit = 180;

  static final List<MethodChannel> _channels = [carPlayChannel, autoChannel];
  static final Set<MethodChannel> _live = {};

  static WidgetRef? _ref;
  static ProviderSubscription<QuranAudioState>? _sub;
  static bool holdsPlayback = false;
  static int _verseGen = 0;
  static String? _verse;
  static (int, int)? _verseKey;

  static void bind(WidgetRef ref) {
    _ref = ref;
    for (final channel in _channels) {
      channel.setMethodCallHandler((call) => _handle(channel, call));
      unawaited(_announce(channel));
    }
  }

  static void unbind() {
    for (final channel in _channels) {
      channel.setMethodCallHandler(null);
    }
    _live.clear();
    holdsPlayback = false;
    _detach();
    _ref = null;
  }

  static Future<void> _announce(MethodChannel channel) async {
    try {
      await channel.invokeMethod<void>('hostReady');
    } catch (_) {}
  }

  static Future<Object?> _handle(MethodChannel channel, MethodCall call) async {
    switch (call.method) {
      case 'connected':
        _live.add(channel);
        holdsPlayback = true;
        _attach();
        final snap = _snapshot(includeCatalog: true);
        _primeVerse(snap);
        return snap;
      case 'disconnected':
        _live.remove(channel);
        if (_live.isEmpty) {
          holdsPlayback = false;
          final ref = _ref;
          if (_sub != null && ref != null) {
            await ref.read(quranAudioNotifierProvider.notifier).pauseFromCar();
          }
          _detach();
        }
        return null;
      case 'play':
        if (!holdsPlayback) return null;
        await _resumeOrStart();
        return null;
      case 'pause':
        if (!holdsPlayback) return null;
        await _ref?.read(quranAudioNotifierProvider.notifier).pauseFromCar();
        return null;
      case 'toggle':
        if (!holdsPlayback) return null;
        final audio = _audio;
        if (audio != null && audio.isPlaying) {
          await _ref?.read(quranAudioNotifierProvider.notifier).pauseFromCar();
        } else {
          await _resumeOrStart();
        }
        return null;
      case 'next':
        if (!holdsPlayback) return null;
        await _ref?.read(quranAudioNotifierProvider.notifier).nextAyah();
        return null;
      case 'previous':
        if (!holdsPlayback) return null;
        await _ref?.read(quranAudioNotifierProvider.notifier).previousAyah();
        return null;
      case 'playSurah':
        if (!holdsPlayback) return null;
        final surah = _surahArg(call.arguments);
        if (surah == null) return null;
        await _playSurah(surah);
        return null;
      default:
        return null;
    }
  }

  static int? _surahArg(Object? raw) {
    if (raw is int) return raw;
    if (raw is Map) {
      final value = raw['surah'];
      if (value is int) return value;
      if (value is num) return value.toInt();
    }
    return null;
  }

  static QuranAudioState? get _audio {
    final ref = _ref;
    if (ref == null) return null;
    return ref.read(quranAudioNotifierProvider);
  }

  static void _attach() {
    final ref = _ref;
    if (ref == null || _sub != null) return;
    _sub = ref.listenManual(quranAudioNotifierProvider, (_, next) {
      _push(next);
      final surah = next.surah;
      final ayah = next.ayah;
      if (surah == null || ayah == null) return;
      if (_verseKey == (surah, ayah) && _verse != null) return;
      unawaited(_loadVerse(surah, ayah));
    }, fireImmediately: true);
  }

  static void _detach() {
    _verseGen++;
    _sub?.close();
    _sub = null;
    _verse = null;
    _verseKey = null;
  }

  static Future<void> _resumeOrStart() async {
    final ref = _ref;
    if (ref == null) return;
    _attach();
    final audio = ref.read(quranAudioNotifierProvider);
    if (audio.isPlaying) return;
    await ref.read(quranAudioNotifierProvider.notifier).toggle();
  }

  static Future<void> _playSurah(int surah) async {
    final ref = _ref;
    if (ref == null) return;
    _attach();
    final meta = QuranSurahCatalog.byNumber(surah);
    final saved = ref.read(quranProgressStoreProvider).readProgress();
    final ayah =
        (saved != null && saved.surah == meta.number) ? saved.ayah : 1;
    await ref.read(quranAudioNotifierProvider.notifier).playSurah(
          meta.number,
          ayah: ayah,
        );
  }

  static void _push(QuranAudioState _) {
    if (!holdsPlayback || _live.isEmpty) return;
    final snap = _snapshot();
    for (final channel in _live) {
      unawaited(channel.invokeMethod<void>('onState', snap));
    }
  }

  static Map<String, Object?> _snapshot({bool includeCatalog = false}) {
    final ref = _ref;
    if (ref == null) return const {};
    final locale = ref.read(appLocaleProvider).languageCode;
    final l10n = lookupAppLocalizations(Locale(locale));
    final audio = ref.read(quranAudioNotifierProvider);
    final saved = ref.read(quranProgressStoreProvider).readProgress();
    final surah = audio.surah ?? saved?.surah;
    final ayah = audio.ayah ?? saved?.ayah;
    final verse = (_verseKey != null &&
            _verseKey == (surah, ayah) &&
            _verse != null)
        ? _verse
        : null;
    return buildCarPlayQuranSnapshot(
      l10n: l10n,
      languageCode: locale,
      audio: audio,
      saved: saved,
      verse: verse,
      includeCatalog: includeCatalog,
    );
  }

  static void _primeVerse(Map<String, Object?> snap) {
    final surah = snap['surah'];
    final ayah = snap['ayah'];
    if (surah is! int || ayah is! int) return;
    unawaited(_loadVerse(surah, ayah));
  }

  static Future<void> _loadVerse(int surah, int ayah) async {
    final gen = ++_verseGen;
    final ref = _ref;
    if (ref == null) return;
    try {
      final locale = ref.read(appLocaleProvider).languageCode;
      final content = await ref.read(quranRepositoryProvider).loadSurah(
            surah: surah,
            lang: QuranMealLang.fromLocaleCode(locale),
          );
      if (gen != _verseGen || !holdsPlayback || _ref == null) return;
      String? text;
      for (final item in content.ayahs) {
        if (item.ayah == ayah) {
          text = item.arabic;
          break;
        }
      }
      final flat = text?.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (flat == null || flat.isEmpty) return;
      _verse = flat.length <= _verseLimit
          ? flat
          : '${flat.substring(0, _verseLimit - 1)}…';
      _verseKey = (surah, ayah);
      _push(ref.read(quranAudioNotifierProvider));
    } catch (_) {}
  }
}
