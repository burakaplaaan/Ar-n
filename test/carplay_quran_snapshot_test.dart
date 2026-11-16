import 'dart:ui' show Locale;

import 'package:arin/data/quran/quran_models.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/assistant/carplay_quran_snapshot.dart';
import 'package:arin/presentation/qibla/quran/quran_audio_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  test('boş oynatıcı kayıtlı ayeti gösterir', () {
    final snap = buildCarPlayQuranSnapshot(
      l10n: l10n,
      languageCode: 'tr',
      audio: QuranAudioState.idle,
      saved: const QuranProgress(surah: 36, ayah: 12),
    );

    expect(snap['surah'], 36);
    expect(snap['ayah'], 12);
    expect(snap['name'], 'Yâsîn');
    expect(snap['playing'], isFalse);
    expect(snap.containsKey('surahs'), isFalse);
    expect(snap.containsKey('verse'), isFalse);
  });

  test('çalan ayet kaydın önüne geçer ve katalog yalnız istenince gelir', () {
    final snap = buildCarPlayQuranSnapshot(
      l10n: l10n,
      languageCode: 'tr',
      audio: const QuranAudioState(
        isPlaying: true,
        buffering: false,
        surah: 1,
        ayah: 99,
        error: null,
      ),
      saved: const QuranProgress(surah: 2, ayah: 4),
      verse: 'بِسْمِ ٱللَّهِ',
      includeCatalog: true,
    );

    expect(snap['surah'], 1);
    expect(snap['ayah'], 7);
    expect(snap['playing'], isTrue);
    expect(snap['verse'], 'بِسْمِ ٱللَّهِ');
    final surahs = snap['surahs'] as List<Object?>;
    expect(surahs, hasLength(114));
  });
}
