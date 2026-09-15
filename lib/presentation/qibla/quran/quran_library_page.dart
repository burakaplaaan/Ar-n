// Sure kütüphanesi — 114 sure yerelde anında; meal/ses CDN.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/product_metric_features.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_progress_store.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/quran/quran_surah_catalog.dart';
import '../../../data/services/product_metrics_service.dart';
import '../../shared/mixins/review_prompt_on_exit_mixin.dart';
import '../../shared/widgets/arin_back_button.dart';
import '../../shared/widgets/arin_shell_layout.dart';
import '../qibla_hub_page.dart';
import 'quran_audio_notifier.dart';
import 'quran_style.dart';
import 'quran_widgets.dart';

class QuranLibraryPage extends ConsumerStatefulWidget {
  const QuranLibraryPage({super.key});

  @override
  ConsumerState<QuranLibraryPage> createState() => _QuranLibraryPageState();
}

class _QuranLibraryPageState extends ConsumerState<QuranLibraryPage>
    with ReviewPromptOnExitMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    startReviewPromptTracking();
    unawaited(ProductMetricsService.featureOpen(ProductMetricFeatures.quran));
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _warmCache();
    });
  }

  void _warmCache() {
    final lang = QuranMealLang.fromLocaleCode(
      Localizations.localeOf(context).languageCode,
    );
    final repo = ref.read(quranRepositoryProvider);
    final last = ref.read(quranProgressStoreProvider).readProgress();
    repo.prefetch(surah: last?.surah ?? 1, lang: lang);
    if (last != null && last.surah != 1) {
      repo.prefetch(surah: 1, lang: lang);
    }
    if (last != null && last.surah < 114) {
      repo.prefetch(surah: last.surah + 1, lang: lang);
    }
  }

  @override
  void dispose() {
    maybeRequestReviewOnExit();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<QuranSurahMeta> _filtered(String languageCode) {
    final q = _fold(_query);
    if (q.isEmpty) return QuranSurahCatalog.all;
    final asNum = int.tryParse(q);
    return QuranSurahCatalog.all.where((s) {
      if (asNum != null && s.number == asNum) return true;
      return _fold(s.nameTr).contains(q) ||
          _fold(s.nameEn).contains(q) ||
          _fold(s.transliteration).contains(q) ||
          s.arabic.contains(_query.trim()) ||
          _fold(s.localizedName(languageCode)).contains(q);
    }).toList(growable: false);
  }

  static String _fold(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ı', 'i')
        .replaceAll('\'', '')
        .replaceAll('’', '')
        .trim();
  }

  Future<void> _openReader({
    required int surah,
    int? ayah,
    bool autoplay = false,
  }) async {
    HapticFeedback.selectionClick();
    _searchFocus.unfocus();
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      QiblaHubRoutes.quranReader,
      arguments: QuranReaderArgs(
        surah: surah,
        ayah: ayah,
        autoplay: autoplay,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final onDark = QuranStyle.onDark(context);
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final progress = ref.watch(quranProgressStoreProvider).readProgress();
    final audio = ref.watch(quranAudioNotifierProvider);
    final audioN = ref.read(quranAudioNotifierProvider.notifier);
    final surahs = _filtered(languageCode);
    final bottomPad = ArinShellLayout.bottomContentPadding(context);
    final bronze = QuranStyle.bronze(onDark);
    final playingMeta = audio.surah != null
        ? QuranSurahCatalog.byNumber(audio.surah!)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    ArinBackButton(onPressed: () => Navigator.maybePop(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.quranTitle,
                        style: TextStyle(
                          color: QuranStyle.title(onDark),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                          fontFamily: AppTextStyles.primaryFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              QuranOrnamentBar(onDark: onDark),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: QuranStyle.title(onDark),
                    fontSize: 15,
                    fontFamily: AppTextStyles.primaryFontFamily,
                  ),
                  cursorColor: bronze,
                  decoration: InputDecoration(
                    hintText: l10n.quranSearchHint,
                    hintStyle: TextStyle(
                      color: QuranStyle.muted(onDark),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: bronze.withValues(alpha: 0.85),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchCtrl.clear,
                            icon: Icon(
                              Icons.close_rounded,
                              color: QuranStyle.muted(onDark),
                            ),
                          ),
                    filled: true,
                    fillColor: QuranStyle.cardFill(onDark),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: QuranStyle.border(onDark)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: bronze, width: 1.3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                  itemCount: surahs.isEmpty
                      ? 1
                      : surahs.length + (progress != null && _query.isEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (surahs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                        child: Text(
                          l10n.quranEmptySearch,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: QuranStyle.muted(onDark),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      );
                    }
                    var i = index;
                    if (progress != null && _query.isEmpty) {
                      if (i == 0) {
                        final meta = QuranSurahCatalog.byNumber(progress.surah);
                        return QuranContinueCard(
                          onDark: onDark,
                          title: l10n.quranContinueTitle,
                          body: l10n.quranContinueBody(
                            meta.localizedName(languageCode),
                            progress.ayah,
                          ),
                          onOpen: () => _openReader(
                            surah: progress.surah,
                            ayah: progress.ayah,
                          ),
                          onPlay: () => _openReader(
                            surah: progress.surah,
                            ayah: progress.ayah,
                            autoplay: true,
                          ),
                        );
                      }
                      i -= 1;
                    }
                    final meta = surahs[i];
                    return QuranSurahTile(
                      meta: meta,
                      onDark: onDark,
                      languageCode: languageCode,
                      meccanLabel: l10n.quranMeccan,
                      medinanLabel: l10n.quranMedinan,
                      ayahCountLabel: l10n.quranAyahCount(meta.ayahCount),
                      onTap: () => _openReader(surah: meta.number),
                    );
                  },
                ),
              ),
              if (audio.hasTrack && playingMeta != null)
                Padding(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  child: QuranMiniPlayer(
                    onDark: onDark,
                    surahName: playingMeta.localizedName(languageCode),
                    ayahLabel: l10n.quranAyahLabel(audio.ayah ?? 1),
                    playing: audio.isPlaying,
                    buffering: audio.buffering,
                    onPlayPause: () => unawaited(audioN.toggle()),
                    onOpen: () => _openReader(
                      surah: audio.surah!,
                      ayah: audio.ayah,
                    ),
                    onStop: () => unawaited(audioN.stop()),
                  ),
                )
              else
                SizedBox(height: bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}
