// Ayet okuyucu + tilavet. İskelet ışıltısı; cache varsa anında.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_progress_store.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/quran/quran_surah_catalog.dart';
import '../../shared/widgets/arin_back_button.dart';
import '../../shared/widgets/arin_pressable.dart';
import '../../shared/widgets/arin_shell_layout.dart';
import '../../shared/widgets/arin_top_toast.dart';
import 'quran_audio_notifier.dart';
import 'quran_style.dart';
import 'quran_widgets.dart';

class QuranReaderPage extends ConsumerStatefulWidget {
  const QuranReaderPage({
    super.key,
    required this.surah,
    this.initialAyah,
    this.autoplay = false,
  });

  final int surah;
  final int? initialAyah;
  final bool autoplay;

  @override
  ConsumerState<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends ConsumerState<QuranReaderPage> {
  ItemScrollController _itemScroll = ItemScrollController();
  bool _initialJumpDone = false;
  QuranSurahContent? _content;
  Object? _error;
  bool _loading = true;
  bool _showMeal = true;
  int _fontStep = 1;
  bool _autoplayDone = false;
  bool _followAudio = false;
  int _loadGen = 0;
  late int _viewingSurah;

  QuranSurahMeta get _meta => QuranSurahCatalog.byNumber(_viewingSurah);

  bool get _hasViewingContent =>
      _content != null && _content!.meta.number == _viewingSurah;

  @override
  void initState() {
    super.initState();
    _viewingSurah = widget.surah.clamp(1, 114);
    _followAudio = widget.autoplay;
    final store = ref.read(quranProgressStoreProvider);
    _fontStep = store.fontStep();
    final lang = QuranMealLang.fromLocaleCode(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    _showMeal = store.showTranslation(defaultOn: lang != QuranMealLang.none);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_load(applyOpenArgs: true));
    });
  }

  Future<void> _followSurah(int surah, int? ayah) async {
    final next = surah.clamp(1, 114);
    if (next == _viewingSurah && _hasViewingContent && !_loading) {
      if (ayah != null) _ensureAyahVisible(ayah, instant: false);
      return;
    }
    _viewingSurah = next;
    _itemScroll = ItemScrollController();
    _initialJumpDone = false;
    await _load(jumpAyah: ayah);
  }

  Future<void> _load({bool applyOpenArgs = false, int? jumpAyah}) async {
    final gen = ++_loadGen;
    final lang = QuranMealLang.fromLocaleCode(
      Localizations.localeOf(context).languageCode,
    );
    setState(() {
      _loading = true;
      _error = null;
      if (_content?.meta.number != _viewingSurah) {
        _content = null;
      }
    });
    try {
      final content = await ref.read(quranRepositoryProvider).loadSurah(
            surah: _viewingSurah,
            lang: lang,
          );
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _content = content;
        _loading = false;
      });
      final start = _clampedAyah(
        jumpAyah ??
            (applyOpenArgs
                ? (widget.initialAyah ??
                    (ref.read(quranProgressStoreProvider).readProgress()?.surah ==
                            _viewingSurah
                        ? ref
                            .read(quranProgressStoreProvider)
                            .readProgress()
                            ?.ayah
                        : null))
                : null),
      );
      if (applyOpenArgs && widget.initialAyah != null && start != null) {
        unawaited(
          ref.read(quranProgressStoreProvider).saveProgress(
                surah: _viewingSurah,
                ayah: start,
              ),
        );
      }
      if (start != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || gen != _loadGen) return;
          _ensureAyahVisible(start, instant: true);
          _initialJumpDone = true;
        });
      } else {
        _initialJumpDone = true;
      }
      if (applyOpenArgs && widget.autoplay && !_autoplayDone) {
        _autoplayDone = true;
        _followAudio = true;
        unawaited(
          ref.read(quranAudioNotifierProvider.notifier).playSurah(
                _viewingSurah,
                ayah: start ?? 1,
              ),
        );
      }
      final prefetch = _viewingSurah < 114 ? _viewingSurah + 1 : 1;
      ref.read(quranRepositoryProvider).prefetch(surah: prefetch, lang: lang);
    } catch (e) {
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  int? _clampedAyah(int? ayah) {
    if (ayah == null) return null;
    return ayah.clamp(1, _meta.ayahCount);
  }

  int _ayahListIndex(int ayah) {
    final extra = QuranSurahCatalog.showsBismillah(_meta.number) ? 1 : 0;
    final count = _content?.ayahs.length ?? _meta.ayahCount;
    final maxIndex = extra + count - 1;
    if (maxIndex < 0) return 0;
    return (extra + ayah.clamp(1, count) - 1).clamp(0, maxIndex);
  }

  void _ensureAyahVisible(int ayah, {required bool instant}) {
    final target = ayah.clamp(1, _meta.ayahCount);
    var attempts = 0;

    void go() {
      if (!mounted) return;
      if (!_itemScroll.isAttached) {
        if (attempts++ < 8) {
          WidgetsBinding.instance.addPostFrameCallback((_) => go());
        }
        return;
      }
      final index = _ayahListIndex(target);
      if (instant) {
        _itemScroll.jumpTo(index: index, alignment: 0.12);
      } else {
        _itemScroll.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    }

    go();
  }

  Future<void> _toggleMeal() async {
    setState(() => _showMeal = !_showMeal);
    await ref.read(quranProgressStoreProvider).setShowTranslation(_showMeal);
  }

  Future<void> _cycleFont() async {
    final next = (_fontStep + 1) % 3;
    setState(() => _fontStep = next);
    await ref.read(quranProgressStoreProvider).setFontStep(next);
  }

  int _startAyahForPlay() {
    final audio = ref.read(quranAudioNotifierProvider);
    if (audio.surah == _meta.number && audio.ayah != null) {
      return audio.ayah!.clamp(1, _meta.ayahCount);
    }
    final last = ref.read(quranProgressStoreProvider).readProgress();
    final raw = (widget.surah == _meta.number ? widget.initialAyah : null) ??
        ((last != null && last.surah == _meta.number) ? last.ayah : 1);
    return raw.clamp(1, _meta.ayahCount);
  }

  Future<void> _playAyah(int ayah) async {
    HapticFeedback.selectionClick();
    _followAudio = true;
    await ref.read(quranAudioNotifierProvider.notifier).playSurah(
          _meta.number,
          ayah: ayah,
        );
  }

  @override
  Widget build(BuildContext context) {
    final onDark = QuranStyle.onDark(context);
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final audio = ref.watch(quranAudioNotifierProvider);
    final audioN = ref.read(quranAudioNotifierProvider.notifier);
    final bronze = QuranStyle.bronze(onDark);
    final playingHere = audio.surah == _meta.number;

    ref.listen<QuranAudioState>(quranAudioNotifierProvider, (prev, next) {
      if (next.error == 'audio' && prev?.error != 'audio') {
        showArinTopToast(
          context,
          l10n.quranAudioError,
          tone: ArinTopToastTone.error,
        );
      }
      if (_followAudio &&
          next.surah != null &&
          next.surah != _viewingSurah &&
          (next.isPlaying || next.buffering || next.hasTrack)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_followSurah(next.surah!, next.ayah));
        });
        return;
      }
      if (next.surah == _viewingSurah &&
          next.ayah != null &&
          next.ayah != prev?.ayah) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureAyahVisible(
            next.ayah!,
            instant: !_initialJumpDone,
          );
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    ArinBackButton(onPressed: () => Navigator.maybePop(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _meta.localizedName(languageCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: QuranStyle.title(onDark),
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                              fontFamily: AppTextStyles.primaryFontFamily,
                            ),
                          ),
                          Text(
                            '${_meta.number}  ·  ${_meta.arabic}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: bronze.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTextStyles.primaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (QuranMealLang.fromLocaleCode(languageCode) !=
                        QuranMealLang.none)
                      _ToolbarChip(
                        onDark: onDark,
                        icon: _showMeal
                            ? Icons.notes_rounded
                            : Icons.notes_outlined,
                        selected: _showMeal,
                        tooltip: _showMeal
                            ? l10n.quranTranslationOn
                            : l10n.quranTranslationOff,
                        onTap: _toggleMeal,
                      ),
                    _ToolbarChip(
                      onDark: onDark,
                      icon: Icons.text_fields_rounded,
                      selected: _fontStep != 1,
                      tooltip: l10n.quranFontSize,
                      onTap: _cycleFont,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              QuranOrnamentBar(onDark: onDark),
              Expanded(
                child: _buildBody(
                  onDark: onDark,
                  l10n: l10n,
                  playingHere: playingHere,
                  playingAyah: audio.ayah,
                ),
              ),
              _ReaderPlayer(
                onDark: onDark,
                l10n: l10n,
                meta: _meta,
                languageCode: languageCode,
                mealLang: QuranMealLang.fromLocaleCode(languageCode),
                audio: audio,
                bottomPad: ArinShellLayout.bottomContentPadding(context),
                onPlayPause: () {
                  _followAudio = true;
                  if (audio.isPlaying) {
                    unawaited(audioN.toggle());
                    return;
                  }
                  if (audio.hasTrack && audio.surah == _meta.number) {
                    unawaited(audioN.toggle());
                    return;
                  }
                  unawaited(
                    audioN.playSurah(
                      _meta.number,
                      ayah: _startAyahForPlay(),
                    ),
                  );
                },
                onPrev: () {
                  _followAudio = true;
                  unawaited(audioN.previousAyah());
                },
                onNext: () {
                  _followAudio = true;
                  unawaited(audioN.nextAyah());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool onDark,
    required AppLocalizations l10n,
    required bool playingHere,
    required int? playingAyah,
  }) {
    if (_error != null && !_hasViewingContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.quranLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: QuranStyle.title(onDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ArinPressable(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: QuranStyle.border(onDark)),
                    color: QuranStyle.cardFill(onDark),
                  ),
                  child: Text(
                    l10n.quranRetry,
                    style: TextStyle(
                      color: QuranStyle.bronze(onDark),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ayahs = _hasViewingContent ? _content!.ayahs : null;
    final showBismillah = QuranSurahCatalog.showsBismillah(_meta.number);
    if (_loading || ayahs == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        children: [
          if (showBismillah) QuranBismillahHeader(onDark: onDark),
          for (var i = 0; i < 6; i++) QuranAyahSkeleton(onDark: onDark),
        ],
      );
    }

    final extra = showBismillah ? 1 : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScroll,
        itemCount: extra + ayahs.length,
        itemBuilder: (context, index) {
          if (showBismillah && index == 0) {
            return QuranBismillahHeader(onDark: onDark);
          }
          final ayah = ayahs[index - extra];
          return _AyahCard(
            ayah: ayah,
            onDark: onDark,
            active: playingHere && playingAyah == ayah.ayah,
            showMeal: _showMeal && ayah.translation.isNotEmpty,
            fontStep: _fontStep,
            ayahLabel: l10n.quranAyahLabel(ayah.ayah),
            onTap: () => unawaited(_playAyah(ayah.ayah)),
          );
        },
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.onDark,
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final bool onDark;
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return Tooltip(
      message: tooltip,
      child: ArinPressable(
        onTap: onTap,
        scale: 0.92,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? bronze.withValues(alpha: onDark ? 0.22 : 0.16)
                : Colors.transparent,
            border: Border.all(
              color: bronze.withValues(alpha: selected ? 0.7 : 0.28),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? bronze : QuranStyle.muted(onDark),
          ),
        ),
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.onDark,
    required this.active,
    required this.showMeal,
    required this.fontStep,
    required this.ayahLabel,
    required this.onTap,
  });

  final QuranAyah ayah;
  final bool onDark;
  final bool active;
  final bool showMeal;
  final int fontStep;
  final String ayahLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    return ArinPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [
                    bronze.withValues(alpha: onDark ? 0.18 : 0.14),
                    QuranStyle.cardFillDeep(onDark),
                  ]
                : [
                    QuranStyle.cardFill(onDark),
                    QuranStyle.cardFillDeep(onDark),
                  ],
          ),
          border: Border.all(
            color: active
                ? bronze.withValues(alpha: 0.72)
                : QuranStyle.border(onDark),
            width: active ? 1.35 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: bronze.withValues(alpha: onDark ? 0.2 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bronze.withValues(alpha: active ? 0.85 : 0.45),
                    ),
                    color: bronze.withValues(alpha: active ? 0.2 : 0.08),
                  ),
                  child: Text(
                    '${ayah.ayah}',
                    style: TextStyle(
                      color: QuranStyle.title(onDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTextStyles.primaryFontFamily,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  ayahLabel,
                  style: TextStyle(
                    color: QuranStyle.muted(onDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: QuranStyle.title(onDark),
                  fontFamily: QuranStyle.arabicFamily,
                  fontSize: QuranStyle.arabicSize(fontStep),
                  height: 1.85,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showMeal) ...[
              const SizedBox(height: 12),
              Text(
                ayah.translation,
                style: TextStyle(
                  color: QuranStyle.subtitle(onDark),
                  fontFamily: AppTextStyles.primaryFontFamily,
                  fontSize: QuranStyle.mealSize(fontStep),
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReaderPlayer extends StatelessWidget {
  const _ReaderPlayer({
    required this.onDark,
    required this.l10n,
    required this.meta,
    required this.languageCode,
    required this.mealLang,
    required this.audio,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
    required this.bottomPad,
  });

  final bool onDark;
  final AppLocalizations l10n;
  final QuranSurahMeta meta;
  final String languageCode;
  final QuranMealLang mealLang;
  final QuranAudioState audio;
  final double bottomPad;
  final VoidCallback onPlayPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bronze = QuranStyle.bronze(onDark);
    final playingMeta = audio.surah != null
        ? QuranSurahCatalog.byNumber(audio.surah!)
        : meta;
    final ayah = audio.ayah ?? 1;
    final progress = audio.hasTrack
        ? ayah / playingMeta.ayahCount
        : 0.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: onDark
              ? [
                  const Color(0xFF16120C).withValues(alpha: 0.96),
                  const Color(0xFF0A0907).withValues(alpha: 0.99),
                ]
              : [
                  QuranStyle.cardFill(onDark),
                  QuranStyle.cardFillDeep(onDark),
                ],
        ),
        border: Border(
          top: BorderSide(color: bronze.withValues(alpha: 0.32)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: audio.hasTrack ? progress.clamp(0.0, 1.0) : 0,
                minHeight: 3,
                backgroundColor: bronze.withValues(alpha: 0.14),
                color: bronze,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audio.hasTrack
                  ? l10n.quranNowPlaying(
                      playingMeta.localizedName(languageCode),
                      ayah,
                    )
                  : l10n.quranReciterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: QuranStyle.muted(onDark),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onPrev,
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: QuranStyle.title(onDark),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                ArinPressable(
                  onTap: onPlayPause,
                  scale: 0.94,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          bronze,
                          QuranStyle.bronzeSoft(onDark),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: bronze.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: audio.buffering && audio.isPlaying
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFFF6E7C9),
                            ),
                          )
                        : Icon(
                            audio.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: const Color(0xFFF6E7C9),
                            size: 34,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onNext,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: QuranStyle.title(onDark),
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              mealLang == QuranMealLang.none
                  ? l10n.quranReciterName
                  : l10n.quranMealAttribution,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: QuranStyle.muted(onDark).withValues(alpha: 0.8),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
