// lib/presentation/qibla/zikir_matik_page.dart
// Dijital zikir sayacı: kayıt, liste, sıfırla, hedef tur, oturum kalıcılığı.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

import 'package:arin/l10n/app_localizations.dart';
import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/product_metric_features.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/models/zikir_matik_tur_log.dart';
import '../../data/repositories/zikir_matik_repository.dart';
import '../../data/services/product_metrics_service.dart';
import '../../data/services/zikir_widget_service.dart';
import 'zikir_bilgisi_page.dart';
import '../shared/mixins/review_prompt_on_exit_mixin.dart';
import '../shared/widgets/tasbeeh_zikirmatik_device_frame.dart';
import '../shared/widgets/arin_back_button.dart';

part 'zikir_matik_phrase_widgets.dart';
part 'zikir_matik_target_sheet.dart';

/// Tasbeeh SVG tasarım genişliği; [FittedBox] ile tüm cihazlarda aynı oran korunur.
const double _kZikirTasbeehDesignW = 320.0;

/// Yalnızca genişlik tavanı (dar ekran).
const double _kZikirTasbeehMaxWidthFactor = 2.15;

/// FittedBox ile sığdırdıktan sonra ek ölçek; 1.0 altı görseli küçültür.
const double _kZikirTasbeehPaintZoom = 0.92;

/// Alt ipucu + titreşim satırı için ayrılan tahmini yükseklik (Stack üst katmanı).
/// Tasbeeh üstüne düşmemesi için alt satır (sadece yuvarlaklar; ipucu yok).
const double _kZikirTasbeehBottomOverlayReserve = 100.0;

/// Titreşim ve zikir bilgisi yuvarlak çapı (aynı boyut).
const double _kZikirRoundToolsDiameter = 58.0;

/// Renkler: [tasbeeh_counter](https://github.com/n4ff4h/tasbeeh_counter) light tema
/// (`constants.dart`: primaryColor, primaryLightColor, tasbeehCounterColor, LCD).
abstract final class _ZikirmatikColors {
  static const Color pageBg = Color(0xFF6A8584);
  static const Color shieldInner = Color(0xFF4B5E5E);
  static const Color outer = Color(0xFF89ABAA);
  static const Color smallBtn = Color(0xFF566B6A);
  static const Color lcdBg = Color(0xFFB1D7B4);
  static const Color lcdDim = Color(0xFF8FA394);
  static const Color lcdActive = Color(0xFF1A1A1A);
  static const Color labelMuted = Color(0xFFEEF6F6);

  /// Diyalog yüzeyi (açık arka planda okunaklı koyu panel).
  static const Color dialogSurface = Color(0xFF3D5050);
}

List<String> _zikirPresetPhrases(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  if (code.startsWith('ar')) {
    return const <String>[
      'سُبْحَانَ ٱللَّٰهِ',
      'ٱلْحَمْدُ لِلَّٰهِ',
      'ٱللَّٰهُ أَكْبَر',
      'لَا إِلَٰهَ إِلَّا ٱللَّٰه',
      'أَسْتَغْفِرُ ٱللَّٰه',
      'حَسْبُنَا ٱللَّٰه',
    ];
  }
  if (code.startsWith('en')) {
    return const <String>[
      'SUBHANALLAH',
      'ALHAMDULILLAH',
      'ALLAHU AKBAR',
      'LA ILAHA ILLALLAH',
      'ASTAGHFIRULLAH',
      'HASBUNALLAH',
    ];
  }
  return const <String>[
    'SÜBHANALLAH',
    'ELHAMDÜLİLLAH',
    'ALLAHU EKBER',
    'LAILAHEİLLALLAH',
    'ESTAĞFİRULLAH',
    'HASBÜNALLAH',
  ];
}

enum _ZikirCustomPhraseAction { use, saveAndUse }

class _ZikirCustomPhraseResult {
  const _ZikirCustomPhraseResult({required this.action, required this.text});

  final _ZikirCustomPhraseAction action;
  final String text;
}

class ZikirMatikPage extends ConsumerStatefulWidget {
  const ZikirMatikPage({super.key});

  @override
  ConsumerState<ZikirMatikPage> createState() => _ZikirMatikPageState();
}

class _ZikirMatikPageState extends ConsumerState<ZikirMatikPage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        ReviewPromptOnExitMixin {
  ZikirMatikRepository? _repo;

  static const _uuid = Uuid();

  late final AnimationController _phraseAnim;
  late final Animation<double> _phraseScale;
  late final AnimationController _cardIntro;
  late final Animation<double> _cardIntroCurve;

  int _total = 0;
  int _round = 0;
  int _tur = 1;
  String _phrase = '';
  List<String> _customPhrases = [];

  static String _normalizeStoredPhrase(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    // Eski varsayılan / kalıcı oturum
    if (t == 'Zikrullah') return '';
    return t;
  }

  int _target = 33;

  bool _soundTick = false;
  bool _vibrateTarget = true;
  bool _sessionReady = false;

  /// Hızlı zikir çekimde saniyede 5–10 tap olabiliyor; her tap'te disk yazmak
  /// gereksiz I/O ve batarya maliyeti. Tap'ler için debounce, kritik eylemler
  /// (reset, hedef/öbek değişimi) için anlık yazım kullanıyoruz. `dispose`
  /// bekleyen bir flush'ı kaçırmadan işler (veri kaybı riski yok).
  static const _kTapPersistDebounce = Duration(milliseconds: 800);
  Timer? _persistDebounce;

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(_kTapPersistDebounce, () {
      unawaited(_persist());
    });
  }

  @override
  void initState() {
    super.initState();
    startReviewPromptTracking();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ProductMetricsService.featureOpen(ProductMetricFeatures.zikir));
    _phraseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _phraseScale = Tween<double>(
      begin: 1.0,
      end: 1.055,
    ).animate(CurvedAnimation(parent: _phraseAnim, curve: Curves.easeInOut));
    _cardIntro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _cardIntroCurve = CurvedAnimation(
      parent: _cardIntro,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() {
        if (!mounted) return;
        _loadSession();
      });
    });
  }

  @override
  void dispose() {
    maybeRequestReviewOnExit();
    WidgetsBinding.instance.removeObserver(this);
    // Bekleyen debounce varsa kaybetmeden flush et — sayfadan çıkarken
    // son tap yazıldığından emin olalım.
    if (_persistDebounce?.isActive == true) {
      _persistDebounce?.cancel();
      unawaited(_persist());
    }
    _persistDebounce = null;
    _phraseAnim.dispose();
    _cardIntro.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_sessionReady) return;
    // Uygulama foreground'a dönünce widget'tan gelen "+1" tıklarını oturuma
    // adapte et (kullanıcı widget'ta sayıp sayfaya girince kaldığı yerden
    // devam edebilsin).
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconcileWithWidget());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Arka plana geçmeden önce bekleyen tap'leri kaybetmeden yaz/ilet.
      // `pushSession` merge yaptığından bayat yazım widget sayacını düşürmez.
      if (_persistDebounce?.isActive == true) {
        _persistDebounce?.cancel();
        _persistDebounce = null;
        unawaited(_persist());
      }
    }
  }

  /// Widget'ın yazdığı kümülatif toplamı okuyup oturumu kaldığı yerden devam
  /// edecek şekilde günceller; değişiklik yoksa mevcut oturumu widget'a basar.
  Future<void> _reconcileWithWidget() async {
    if (_repo == null) return;
    final widgetTotal = await ZikirWidgetService.readWidgetTotal();
    if (!mounted) return;
    if (widgetTotal == null) {
      // Okuma başarısız/boş → widget sayacını düşürme riskine girme.
      unawaited(_pushToWidget());
      return;
    }
    final prevTotal = _total;
    final prevRound = _round;
    final prevTur = _tur;
    final target = _target;
    final rec = ZikirWidgetService.reconcile(
      sessionTotal: prevTotal,
      sessionRound: prevRound,
      sessionTur: prevTur,
      target: target,
      widgetTotal: widgetTotal,
    );
    if (rec.total == prevTotal &&
        rec.round == prevRound &&
        rec.tur == prevTur) {
      unawaited(_pushToWidget());
      return;
    }
    setState(() {
      _total = rec.total;
      _round = rec.round;
      _tur = rec.tur;
    });
    await _persist();
    // Widget'ta tamamlanan turlar için tur log + analytics'i geriye doldur
    // (uygulama içi tur tamamlama ile tutarlı kalsın).
    await _backfillWidgetTurs(
      prevTotal: prevTotal,
      prevRound: prevRound,
      prevTur: prevTur,
      target: target,
    );
  }

  Future<void> _backfillWidgetTurs({
    required int prevTotal,
    required int prevRound,
    required int prevTur,
    required int target,
  }) async {
    if (target < 1) return;
    final delta = _total - prevTotal;
    if (delta <= 0) return;
    final combinedRound = prevRound + delta;
    final tursCompleted = combinedRound ~/ target;
    if (tursCompleted <= 0) return;
    final repo = _repo;
    if (repo == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var k = 0; k < tursCompleted; k++) {
      final completedTur = prevTur + k;
      final totalAtEvent = prevTotal + (target - prevRound) + k * target;
      await repo.appendTurLog(
        ZikirMatikTurLog(
          id: _uuid.v4(),
          phrase: _phrase,
          completedTur: completedTur,
          target: target,
          totalCountAtEvent: totalAtEvent,
          recordedAtMillis: now,
        ),
      );
      unawaited(ArinAnalytics.zikirComplete(target));
    }
  }

  Future<void> _pushToWidget({bool reset = false}) {
    return ZikirWidgetService.pushSession(
      phrase: _phrase,
      total: _total,
      round: _round,
      tur: _tur,
      target: _target,
      allowDecrease: reset,
    );
  }

  void _loadSession() {
    if (!mounted) return;
    final repo = ZikirMatikRepository(ref.read(sharedPreferencesProvider));
    final s = repo.loadSession();
    setState(() {
      _repo = repo;
      _total = s.total;
      _round = s.round;
      _tur = s.tur;
      _phrase = _normalizeStoredPhrase(s.phrase);
      _customPhrases = repo.loadCustomPhrases();
      // Kalıcılığa 3'ün altına kazara düşmüş eski kayıtları da toparla.
      _target = s.target < 3 ? 33 : s.target;
      _soundTick = repo.soundTickEnabled;
      _vibrateTarget = repo.vibrateOnTargetEnabled;
      _sessionReady = true;
    });
    if (mounted) {
      _cardIntro.forward(from: 0);
      if (_normalizeStoredPhrase(s.phrase) != s.phrase.trim()) {
        _persist();
      }
    }
    unawaited(_reconcileWithWidget());
  }

  Future<void> _persist({bool resetPush = false}) async {
    final r = _repo;
    if (r == null) return;
    await r.saveSession(
      total: _total,
      round: _round,
      tur: _tur,
      phrase: _phrase,
      target: _target,
    );
    unawaited(_pushToWidget(reset: resetPush));
  }

  void _reloadCustomPhrases() {
    final r = _repo;
    if (r == null || !mounted) return;
    setState(() {
      _customPhrases = r.loadCustomPhrases();
    });
  }

  String _sixDigits() {
    final t = _total.clamp(0, 999999);
    return t.toString().padLeft(6, '0');
  }

  List<InlineSpan> _lcdSpans() {
    final s = _sixDigits();
    final idx = s.indexOf(RegExp(r'[1-9]'));
    final dimStyle = GoogleFonts.shareTechMono(
      fontSize: 33,
      fontWeight: FontWeight.w600,
      color: _ZikirmatikColors.lcdDim,
      height: 1.05,
      letterSpacing: 2.2,
    );
    final activeStyle = GoogleFonts.shareTechMono(
      fontSize: 33,
      fontWeight: FontWeight.w700,
      color: _ZikirmatikColors.lcdActive,
      height: 1.05,
      letterSpacing: 2.2,
    );
    if (idx < 0) {
      return [TextSpan(text: s, style: dimStyle)];
    }
    return [
      TextSpan(text: s.substring(0, idx), style: dimStyle),
      TextSpan(text: s.substring(idx), style: activeStyle),
    ];
  }

  Future<void> _vibrateOnTapFeedback() async {
    if (kIsWeb) {
      HapticFeedback.lightImpact();
      return;
    }
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 42);
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _onTapCount() async {
    var roundCompleted = false;
    int? completedTur;
    setState(() {
      _total = (_total + 1).clamp(0, 999999);
      _round++;
      if (_round >= _target) {
        completedTur = _tur;
        _round = 0;
        _tur++;
        roundCompleted = true;
      }
    });
    if (_vibrateTarget) {
      await _vibrateOnTapFeedback();
    }
    if (_soundTick) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
    if (roundCompleted) {
      // Tur tamamlanınca state'i garantiye alalım (log + oturum birlikte,
      // uygulama aniden kapanırsa bile tutarlı kalsın).
      _persistDebounce?.cancel();
      _persistDebounce = null;
      await _persist();
    } else {
      _schedulePersist();
    }
    if (roundCompleted && completedTur != null) {
      final completed = completedTur;
      if (completed == null) return;
      await _repo?.appendTurLog(
        ZikirMatikTurLog(
          id: _uuid.v4(),
          phrase: _phrase,
          completedTur: completed,
          target: _target,
          totalCountAtEvent: _total,
          recordedAtMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      unawaited(ArinAnalytics.zikirComplete(_target));
      await _fireTargetFeedback();
    }
  }

  Future<void> _fireTargetFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    if (_vibrateTarget) {
      HapticFeedback.heavyImpact();
      if (!kIsWeb) {
        try {
          if (await Vibration.hasVibrator() == true) {
            await Vibration.vibrate(duration: 140);
          }
        } catch (_) {}
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.zikirmatikRoundCompleted),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _ZikirmatikColors.dialogSurface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _ZikirmatikColors.outer.withValues(alpha: 0.28),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.zikirmatikResetCounter,
                      style: const TextStyle(
                        color: _ZikirmatikColors.labelMuted,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.zikirmatikResetCounterDesc,
                      style: TextStyle(
                        color: _ZikirmatikColors.labelMuted.withValues(
                          alpha: 0.72,
                        ),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            foregroundColor: _ZikirmatikColors.outer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            l10n.zikirmatikCancel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _ZikirmatikColors.outer,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.zikirmatikReset,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (ok == true) {
      setState(() {
        _total = 0;
        _round = 0;
        _tur = 1;
      });
      // Sıfırlama widget sayacını da düşürmeli (allowDecrease).
      await _persist(resetPush: true);
    }
  }

  Future<void> _openList() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const ZikirBilgisiPage(),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _pickTarget() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (ctx) => _ZikirMatikTargetPickerSheet(
        initialTarget: _target,
        onCommitted: (v) async {
          // Zikir hedefi minimum 3: "1" tek tap'i tam tur yapıp her tapta
          // titreşim + analytics event + disk yazımı tetikler → pil yakar,
          // hatalı kullanım. 3 ve üzeri değerler anlamlı (33, 99, 100 gibi
          // klasik hedefler zaten büyük). Üst sınır 9999 — practical cap.
          setState(() {
            _target = v.clamp(3, 9999);
            _round = 0;
          });
          await _persist();
        },
      ),
    );
  }

  Future<void> _pickPhrase() async {
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (dialogCtx, animation, secondaryAnimation) {
        var dialogCustomPhrases = List<String>.of(_customPhrases);
        void closePicker() {
          final nav = Navigator.of(dialogCtx);
          if (nav.canPop()) {
            nav.pop();
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: _ZikirPhrasePickerPanel(
                    entrance: animation,
                    customPhrases: dialogCustomPhrases,
                    onPick: (p) {
                      closePicker();
                      if (!mounted) return;
                      setState(() => _phrase = p);
                      _persist();
                    },
                    onDeleteCustom: (p) async {
                      setDialogState(() {
                        dialogCustomPhrases = dialogCustomPhrases
                            .where((e) => e.toLowerCase() != p.toLowerCase())
                            .toList();
                      });
                      await _repo?.deleteCustomPhrase(p);
                      _reloadCustomPhrases();
                    },
                    onCustom: () {
                      closePicker();
                      if (mounted) {
                        _editPhrase();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (dialogCtx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _editPhrase() async {
    final result = await showGeneralDialog<_ZikirCustomPhraseResult>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (dialogCtx, animation, secondaryAnimation) {
        return SafeArea(child: _ZikirEditPhraseDialog(initialPhrase: _phrase));
      },
      transitionBuilder: (dialogCtx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    final t = result.text.trim();
    if (result.action == _ZikirCustomPhraseAction.saveAndUse && t.isNotEmpty) {
      await _repo?.saveCustomPhrase(t);
      if (!mounted) return;
    }
    setState(() {
      _phrase = t.isEmpty ? '' : t;
    });
    if (result.action == _ZikirCustomPhraseAction.saveAndUse) {
      _reloadCustomPhrases();
    }
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady || _repo == null) {
      return const Scaffold(
        backgroundColor: _ZikirmatikColors.pageBg,
        body: Center(
          child: CircularProgressIndicator(
            color: _ZikirmatikColors.outer,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.zikirmatikCounterSemantics,
      value: '$_total, ${l10n.zikirmatikRound} $_tur',
      child: Scaffold(
        backgroundColor: _ZikirmatikColors.pageBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
                child: Row(
                  children: [
                    ArinBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: AnimatedBuilder(
                  animation: _cardIntroCurve,
                  builder: (context, child) {
                    final t = _cardIntroCurve.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: _ZikirPhraseConcreteCard(
                    phrase: _phrase,
                    onTap: _pickPhrase,
                    phraseAnim: _phraseAnim,
                    phraseScale: _phraseScale,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenW = MediaQuery.sizeOf(context).width;
                            final maxOuterW = math.min(
                              constraints.maxWidth,
                              math.min(
                                screenW - 32,
                                _kZikirTasbeehDesignW *
                                    _kZikirTasbeehMaxWidthFactor,
                              ),
                            );
                            final maxOuterH = math.max(
                              0.0,
                              constraints.maxHeight -
                                  _kZikirTasbeehBottomOverlayReserve,
                            );
                            final designH =
                                _kZikirTasbeehDesignW /
                                TasbeehZikirmatikLayout.widthOverHeight;
                            return Align(
                              alignment: const Alignment(0, -0.14),
                              child: SizedBox(
                                width: maxOuterW,
                                height: maxOuterH,
                                child: ClipRect(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    child: Transform.scale(
                                      scale: _kZikirTasbeehPaintZoom,
                                      alignment: Alignment.center,
                                      filterQuality: FilterQuality.medium,
                                      child: SizedBox(
                                        width: _kZikirTasbeehDesignW,
                                        height: designH,
                                        child: TasbeehZikirmatikDeviceFrame(
                                          outerColor: _ZikirmatikColors.outer,
                                          innerColor:
                                              _ZikirmatikColors.shieldInner,
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                16,
                                                58,
                                                16,
                                                14,
                                              ),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 15),
                                              Align(
                                                alignment: Alignment.center,
                                                child: FractionallySizedBox(
                                                  widthFactor: 0.86,
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 9,
                                                          horizontal: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _ZikirmatikColors
                                                          .lcdBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: RichText(
                                                        textAlign:
                                                            TextAlign.center,
                                                        text: TextSpan(
                                                          children: _lcdSpans(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                '${l10n.zikirmatikThisRound}: $_round / $_target',
                                                style: TextStyle(
                                                  color: _ZikirmatikColors.outer
                                                      .withValues(alpha: 0.92),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${l10n.zikirmatikRound}: $_tur',
                                                style: TextStyle(
                                                  color: _ZikirmatikColors.outer
                                                      .withValues(alpha: 0.92),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 28,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    _ZikirMatikCircleIconButton(
                                                      onPressed: _reset,
                                                      icon: Icons.undo_rounded,
                                                      tooltip:
                                                          l10n.zikirmatikReset,
                                                    ),
                                                    _ZikirMatikCircleIconButton(
                                                      onPressed: _pickTarget,
                                                      icon: Icons.sync_rounded,
                                                      tooltip:
                                                          l10n.zikirmatikTarget,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Erişilebilirlik (TalkBack /
                                              // VoiceOver): çekirdek zikir
                                              // butonu. Her tap sonrası yeni
                                              // sayımı okumak spam olur, bu
                                              // yüzden label semantiği tap
                                              // anında değil, widget rebuild
                                              // anında güncellenir.
                                              Semantics(
                                                button: true,
                                                label: l10n
                                                    .zikirmatikCounterSemanticsLabel(
                                                      _round,
                                                      _target,
                                                      _total,
                                                    ),
                                                hint: l10n
                                                    .zikirmatikCounterSemanticsHint,
                                                child: Material(
                                                  color:
                                                      _ZikirmatikColors.outer,
                                                  shape: const CircleBorder(),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: InkWell(
                                                    onTap: _onTapCount,
                                                    child: const SizedBox(
                                                      width: 86,
                                                      height: 86,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ZikirmatikRoundToolColumn(
                              diameter: _kZikirRoundToolsDiameter,
                              icon: _vibrateTarget
                                  ? Icons.phonelink_ring_rounded
                                  : Icons.mobile_off_rounded,
                              label: l10n.zikirmatikVibration,
                              tooltip: l10n.zikirmatikVibrationTooltip,
                              activeVisual: _vibrateTarget,
                              semanticsToggled: _vibrateTarget,
                              onTap: () async {
                                setState(
                                  () => _vibrateTarget = !_vibrateTarget,
                                );
                                await _repo?.setVibrateOnTarget(_vibrateTarget);
                              },
                            ),
                            _ZikirmatikRoundToolColumn(
                              diameter: _kZikirRoundToolsDiameter,
                              icon: Icons.menu_book_rounded,
                              label: l10n.zikirmatikInfo,
                              tooltip: l10n.zikirmatikInfo,
                              onTap: _openList,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
