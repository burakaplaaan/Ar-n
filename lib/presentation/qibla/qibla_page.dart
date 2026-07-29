// lib/presentation/qibla/qibla_page.dart
//
// Tasarım: "Manevi Modern" — zümrüt + altın İslami estetik.
//   • ArinShellBackground ile tüm uygulama ile tutarlı zemin.
//   • Altın (ornament gold) kıble vurgusu, ok ucunda Kâbe silueti.
//   • Statik süsleme katmanı: radyal derinlik + 8 köşeli yıldız (Rub el-Hizb).
//   • Hizalanınca: altın halka + nefes alan pulse + çift haptic.
//   • Kâbe'ye mesafe ve mesafeye duyarlı manevi mesaj satırı.
//
// Performans mimarisi:
//   • Hiçbir sensör güncellemesi setState çağırmaz.
//   • ValueNotifier + ValueListenableBuilder — minimal subtree rebuild.
//   • Katmanlar ayrı RepaintBoundary'lerde:
//       1. Süsleme (statik, tek boyama)
//       2. Kadran (Transform.rotate — GPU matrix, repaint yok)
//       3. Hizalanma yayı (yalnız delta değişince ucuz arc repaint)
//       4. Pulse halkası (yalnız hizalıyken animasyonlu)
//   • Kadran painter'ı yalnızca qiblaBearing/tema değişince repaint eder.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/arin_review_prompter.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/qibla_compass_controller.dart';
import '../shared/widgets/arin_back_button.dart';

import 'package:arin/l10n/app_localizations.dart';

// ─── Manevi palet ────────────────────────────────────────────────────────────
/// Koyu tema altını — Kâbe örtüsü işlemesi tonunda sıcak, mat altın.
const _goldOnDark = Color(0xFFE3B65A);

/// Koyu tema altını — daha soluk süsleme tonu.
const _goldSoftDark = Color(0xFFB88E47);

/// Açık tema altını — krem zeminde okunur koyu bronz.
const _goldOnLight = Color(0xFF9D7438);

const _tickNorth = Color(0xFFD97862); // kuzey — yumuşak mercan
const _tickDim = Color(0x59FFFFFF); // beyaz %35
const _textDim = Color(0x9EFFFFFF); // beyaz %62

// ─── Hizalanma eşikleri (hysteresis) ────────────────────────────────────────
const _alignInDeg = 5.0;
const _alignOutDeg = 9.0;
const _directFollowOutDeg = 15.0;

// ─── Mesafe eşikleri (km) — manevi mesaj kademeleri ─────────────────────────
const _tierHaramKm = 1.0; // Mescid-i Haram çevresi
const _tierMeccaKm = 25.0; // Mekke ve yakın çevresi
const _tierApproachingKm = 500.0; // Haremeyn'e yaklaşan bölge

enum _ProximityTier { none, far, approaching, mecca, haram }

_ProximityTier _tierFor(double? km) {
  if (km == null) return _ProximityTier.none;
  if (km < _tierHaramKm) return _ProximityTier.haram;
  if (km < _tierMeccaKm) return _ProximityTier.mecca;
  if (km < _tierApproachingKm) return _ProximityTier.approaching;
  return _ProximityTier.far;
}

// ────────────────────────────────────────────────────────────────────────────

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key, this.exitToHomeOnBack = false});

  final bool exitToHomeOnBack;

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  final _dialAngle = ValueNotifier<double>(0);
  final _qiblaDeg = ValueNotifier<double>(0);
  final _deltaDeg = ValueNotifier<double>(0);
  final _signedDelta = ValueNotifier<double>(0);
  final _aligned = ValueNotifier<bool>(false);
  final _hasData = ValueNotifier<bool>(false);
  final _hasError = ValueNotifier<bool>(false);
  final _stable = ValueNotifier<bool>(true);
  final _guidance = ValueNotifier<QiblaGuidance>(QiblaGuidance.good);
  final _distanceKm = ValueNotifier<double?>(null);

  double? _contAngle;
  double? _smoothAngle;
  bool _prevAligned = false;

  QiblaCompassController? _compass;
  StreamSubscription<QiblaSensorReading>? _sub;

  DateTime? _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    // Umre/çekim senaryosu: pusula açıkken ekran kararmasın.
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _launch();
  }

  /// Kıble bulucuyu anlamlı süre kullanıp çıkan kullanıcıya mağaza
  /// değerlendirme sheet'i önerir (bkz. `ArinReviewPrompter`). `ref` yok —
  /// bu sayfa `ConsumerStatefulWidget` değil — bu yüzden kendi
  /// `SharedPreferences` örneğini alır.
  void _maybeRequestReviewOnExit() {
    final enteredAt = _enteredAt;
    if (enteredAt == null) return;
    final usedFor = DateTime.now().difference(enteredAt);
    if (usedFor < ArinReviewPrompter.minFeatureUseDuration) return;
    unawaited(
      SharedPreferences.getInstance().then(
        (prefs) =>
            ArinReviewPrompter.maybeAskAfterFeatureUse(prefs, usedFor: usedFor),
      ),
    );
  }

  void _launch() {
    final c = QiblaCompassController();
    _compass = c;
    c
        .start()
        .then((ok) {
          if (!mounted || _compass != c) return;
          if (ok) {
            _sub = c.stream.listen(
              _onReading,
              onError: (_) {
                if (mounted) _hasError.value = true;
              },
            );
          } else {
            if (mounted) _hasError.value = true;
          }
        })
        .catchError((_) {
          // start() beklenmedik bir hata atarsa unhandled future olmasın.
          if (mounted && _compass == c) _hasError.value = true;
        });
  }

  void _restart() {
    _sub?.cancel();
    _sub = null;
    _compass?.dispose();
    _compass = null;
    _contAngle = null;
    _smoothAngle = null;
    _prevAligned = false;
    _hasData.value = false;
    _hasError.value = false;
    _stable.value = true;
    _guidance.value = QiblaGuidance.good;
    _aligned.value = false;
    _deltaDeg.value = 0;
    _signedDelta.value = 0;
    _distanceKm.value = null;
    _launch();
  }

  // ── Hot path — setState YOK ──────────────────────────────────────────────

  void _onReading(QiblaSensorReading r) {
    if (!mounted) return;

    final h = r.heading % 360;
    final q = r.qiblaFromNorth % 360;

    // Sürekli açı — 0/360 sıçramasını önler.
    final rad = h * math.pi / 180;
    if (_contAngle == null) {
      _contAngle = rad;
    } else {
      var d = rad - _contAngle! % (2 * math.pi);
      if (d > math.pi) d -= 2 * math.pi;
      if (d < -math.pi) d += 2 * math.pi;
      _contAngle = _contAngle! + d;
    }

    // Adaptive EMA — native taraftaki dairesel ortalamayı tamamlar. Küçük
    // hareketlerde yeterince hızlı güncellenerek hedef çevresindeki basamaklı
    // görünümü önler, hızlı dönüşlerde ise yönü gecikmeden takip eder.
    if (_smoothAngle == null) {
      _smoothAngle = _contAngle!;
    } else {
      final stepDeg = _angleDeltaDeg(
        _contAngle! * 180 / math.pi,
        _smoothAngle! * 180 / math.pi,
      );
      final alpha = stepDeg > 28 ? 0.60 : (stepDeg > 10 ? 0.40 : 0.18);
      _smoothAngle = alpha * _contAngle! + (1 - alpha) * _smoothAngle!;
    }

    final smoothHeadingDeg = _normalizeDeg(_smoothAngle! * 180 / math.pi);
    final rawHeadingDeg = _normalizeDeg(_contAngle! * 180 / math.pi);
    final rawDelta = _angleDeltaDeg(q, rawHeadingDeg);
    // Yalnız görsel kadran, son 15° içinde native-filtreli sensör açısına
    // kesintisiz yaklaşır ve 5° içinde onu doğrudan izler. Böylece hedefteki
    // EMA kuyruğu ağır çekim gibi görünmez; ölçüm, eşik ve haptic zamanlaması
    // aşağıdaki özgün yumuşatılmış açıyla tamamen aynı kalır.
    final directFollow =
        ((_directFollowOutDeg - rawDelta) / (_directFollowOutDeg - _alignInDeg))
            .clamp(0.0, 1.0);
    final displayAngle =
        _smoothAngle! + (_contAngle! - _smoothAngle!) * directFollow;
    final delta = _angleDeltaDeg(q, smoothHeadingDeg);
    final signed = _signedAngleDeltaDeg(q, smoothHeadingDeg);
    final canAlign = r.stable && r.guidance == QiblaGuidance.good;
    final nowAligned =
        canAlign &&
        (_prevAligned ? delta <= _alignOutDeg : delta <= _alignInDeg);

    if (nowAligned && nowAligned != _prevAligned) {
      // Çift haptic — kalp atışı hissi: tık … tık.
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted && _aligned.value) HapticFeedback.selectionClick();
      });
    }
    _prevAligned = nowAligned;

    _dialAngle.value = displayAngle;
    _qiblaDeg.value = q;
    _deltaDeg.value = delta;
    _signedDelta.value = signed;
    _aligned.value = nowAligned;
    _stable.value = r.stable;
    _guidance.value = r.guidance;
    if (_distanceKm.value == null && r.distanceKm != null) {
      _distanceKm.value = r.distanceKm;
    }
    if (!_hasData.value) _hasData.value = true;
  }

  double _angleDeltaDeg(double a, double b) {
    final raw = (a - b).abs();
    return raw > 180 ? 360 - raw : raw;
  }

  /// İşaretli fark: kıbleye dönmek için saat yönünde (+) / tersine (−) açı.
  double _signedAngleDeltaDeg(double target, double heading) {
    var d = (target - heading) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  double _normalizeDeg(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  @override
  void dispose() {
    _maybeRequestReviewOnExit();
    unawaited(WakelockPlus.disable().catchError((_) {}));
    _sub?.cancel();
    _compass?.dispose();
    _dialAngle.dispose();
    _qiblaDeg.dispose();
    _deltaDeg.dispose();
    _signedDelta.dispose();
    _aligned.dispose();
    _hasData.dispose();
    _hasError.dispose();
    _stable.dispose();
    _guidance.dispose();
    _distanceKm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                qiblaDeg: _qiblaDeg,
                distanceKm: _distanceKm,
                hasData: _hasData,
                exitToHomeOnBack: widget.exitToHomeOnBack,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasError,
      builder: (_, hasError, __) {
        if (hasError) return _ErrorView(onRetry: _restart);
        return ValueListenableBuilder<bool>(
          valueListenable: _hasData,
          builder: (_, hasData, __) {
            if (!hasData) return const _LoadingView();
            return _CompassView(
              dialAngle: _dialAngle,
              qiblaDeg: _qiblaDeg,
              deltaDeg: _deltaDeg,
              signedDelta: _signedDelta,
              aligned: _aligned,
              stable: _stable,
              guidance: _guidance,
              distanceKm: _distanceKm,
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Üst bar — başlık + kıble açısı + Kâbe'ye mesafe
// ────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.qiblaDeg,
    required this.distanceKm,
    required this.hasData,
    required this.exitToHomeOnBack,
  });

  final ValueNotifier<double> qiblaDeg;
  final ValueNotifier<double?> distanceKm;
  final ValueNotifier<bool> hasData;
  final bool exitToHomeOnBack;

  String _distanceLabel(BuildContext context, double km) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    if (km < 1.0) {
      final m = math.max(10, (km * 1000 / 10).round() * 10);
      return l10n.qiblaCompassDistanceM(
        NumberFormat.decimalPattern(locale).format(m),
      );
    }
    final text = km < 100
        ? NumberFormat('#,##0.0', locale).format(km)
        : NumberFormat.decimalPattern(locale).format(km.round());
    return l10n.qiblaCompassDistanceKm(text);
  }

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final gold = light ? _goldOnLight : _goldOnDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ArinBackButton(
            onPressed: () {
              if (exitToHomeOnBack) {
                context.go(AppRoutes.home);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),

          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: hasData,
              builder: (_, got, __) => ListenableBuilder(
                listenable: Listenable.merge([qiblaDeg, distanceKm]),
                builder: (_, __) {
                  final deg = qiblaDeg.value;
                  final km = distanceKm.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.qiblaCompassTitle,
                        style: TextStyle(
                          color: light
                              ? AppColors.emeraldDark
                              : Colors.white.withValues(alpha: 0.90),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (got) ...[
                        const SizedBox(height: 2),
                        Text(
                          km != null
                              ? '${AppLocalizations.of(context)!.qiblaCompassQibla}'
                                    ' ${deg.toStringAsFixed(1)}°  ·  '
                                    '${_distanceLabel(context, km)}'
                              : '${AppLocalizations.of(context)!.qiblaCompassQibla}'
                                    ' ${deg.toStringAsFixed(1)}°',
                          style: TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Yüklenme
// ────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final gold = light ? _goldOnLight : _goldOnDark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(color: gold, strokeWidth: 2),
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context)!.qiblaCompassGettingLocation,
            style: TextStyle(
              color: light
                  ? AppColors.textSecondary
                  : Colors.white.withValues(alpha: 0.40),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hata
// ────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final gold = light ? _goldOnLight : _goldOnDark;
    final textColor = light
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.60);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_off_rounded,
              size: 44,
              color: light
                  ? AppColors.textMuted
                  : Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.qiblaCompassInitError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: gold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.qiblaCompassRetry,
                  style: TextStyle(
                    color: gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pusula + manevi mesaj + hizalanma badge
// ────────────────────────────────────────────────────────────────────────────

class _CompassView extends StatefulWidget {
  const _CompassView({
    required this.dialAngle,
    required this.qiblaDeg,
    required this.deltaDeg,
    required this.signedDelta,
    required this.aligned,
    required this.stable,
    required this.guidance,
    required this.distanceKm,
  });

  final ValueNotifier<double> dialAngle;
  final ValueNotifier<double> qiblaDeg;
  final ValueNotifier<double> deltaDeg;
  final ValueNotifier<double> signedDelta;
  final ValueNotifier<bool> aligned;
  final ValueNotifier<bool> stable;
  final ValueNotifier<QiblaGuidance> guidance;
  final ValueNotifier<double?> distanceKm;

  @override
  State<_CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<_CompassView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    widget.aligned.addListener(_syncPulse);
    _syncPulse();
  }

  void _syncPulse() {
    if (!mounted) return;
    if (widget.aligned.value) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    widget.aligned.removeListener(_syncPulse);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final gold = light ? _goldOnLight : _goldOnDark;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const Spacer(),

        // ── Pusula kadranı — 4 katman ────────────────────────────────────
        Expanded(
          flex: 8,
          child: Center(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = constraints.biggest.shortestSide * 0.88;

                return SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    fit: StackFit.expand,
                    // Üst işaret elması ve dışa genişleyen pulse halkası
                    // kadran sınırının dışına taşar — kırpılmamalı.
                    clipBehavior: Clip.none,
                    children: [
                      // 1) Statik süsleme — radyal derinlik + 8 köşeli yıldız.
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: _OrnamentPainter(light: light),
                        ),
                      ),

                      // 2) Dönen kadran. RepaintBoundary DIŞARIDA — GPU layer.
                      //    Transform.rotate yalnızca matrix değiştirir.
                      RepaintBoundary(
                        child: ValueListenableBuilder<double>(
                          valueListenable: widget.dialAngle,
                          builder: (_, angle, child) =>
                              Transform.rotate(angle: -angle, child: child),
                          child: ValueListenableBuilder<double>(
                            valueListenable: widget.qiblaDeg,
                            builder: (_, deg, __) => CustomPaint(
                              painter: _DialPainter(
                                qiblaBearingDeg: deg,
                                light: light,
                                labelNorth: l10n.qiblaCompassNorth,
                                labelEast: l10n.qiblaCompassEast,
                                labelSouth: l10n.qiblaCompassSouth,
                                labelWest: l10n.qiblaCompassWest,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3) Dönmeyen üst işaret + hizalanma yayı.
                      RepaintBoundary(
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            widget.signedDelta,
                            widget.aligned,
                          ]),
                          builder: (_, __) => CustomPaint(
                            painter: _OverlayPainter(
                              signedDeltaDeg: widget.signedDelta.value,
                              aligned: widget.aligned.value,
                              light: light,
                            ),
                          ),
                        ),
                      ),

                      // 4) Nefes alan altın pulse — yalnız hizalıyken çizilir.
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => CustomPaint(
                            painter: _PulsePainter(
                              t: _pulse.value,
                              active: widget.aligned.value,
                              light: light,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const Spacer(),

        // ── Manevi mesaj — mesafeye duyarlı ──────────────────────────────
        ValueListenableBuilder<double?>(
          valueListenable: widget.distanceKm,
          builder: (_, km, __) {
            final tier = _tierFor(km);
            if (tier == _ProximityTier.none) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 14),
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.aligned,
                builder: (_, isAligned, __) =>
                    _ProximityMessage(tier: tier, aligned: isAligned),
              ),
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.stable, widget.guidance]),
            builder: (_, __) => _GuidanceCard(
              stable: widget.stable.value,
              guidance: widget.guidance.value,
            ),
          ),
        ),

        // ── Hizalanma badge ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              widget.aligned,
              widget.deltaDeg,
              widget.stable,
              widget.guidance,
            ]),
            builder: (_, __) {
              final isAligned = widget.aligned.value;
              final delta = widget.deltaDeg.value;
              final isStable =
                  widget.stable.value &&
                  widget.guidance.value == QiblaGuidance.good;

              final bgAligned = gold.withValues(alpha: light ? 0.14 : 0.12);
              final bgDefault = light
                  ? AppColors.emeraldFaint.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.04);
              final bdrAligned = gold.withValues(alpha: 0.55);
              final bdrDefault = light
                  ? AppColors.emeraldMid.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.10);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isAligned ? bgAligned : bgDefault,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isAligned ? bdrAligned : bdrDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAligned) ...[
                      Icon(Icons.check_circle_rounded, color: gold, size: 15),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isAligned
                          ? l10n.qiblaCompassAligned
                          : (isStable
                                ? '${delta.toStringAsFixed(1)}° '
                                      '${l10n.qiblaCompassDeviation}'
                                : l10n.qiblaCompassStabilizing),
                      style: TextStyle(
                        color: isAligned
                            ? gold
                            : (light
                                  ? AppColors.textSecondary
                                  : Colors.white.withValues(alpha: 0.50)),
                        fontSize: 14,
                        fontWeight: isAligned
                            ? FontWeight.w600
                            : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Manevi mesaj satırı
// ────────────────────────────────────────────────────────────────────────────

class _ProximityMessage extends StatelessWidget {
  const _ProximityMessage({required this.tier, required this.aligned});

  final _ProximityTier tier;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    final gold = light ? _goldOnLight : _goldOnDark;

    final text = switch (tier) {
      _ProximityTier.haram => l10n.qiblaCompassProximityHaram,
      _ProximityTier.mecca => l10n.qiblaCompassProximityMecca,
      _ProximityTier.approaching => l10n.qiblaCompassProximityApproaching,
      _ => l10n.qiblaCompassProximityFar,
    };

    // Haremeyn'deyken ya da hizalanınca mesaj altına döner — "an"ı taçlandırır.
    final isSacredMoment =
        aligned || tier == _ProximityTier.haram || tier == _ProximityTier.mecca;

    final color = isSacredMoment
        ? gold
        : (light
              ? AppColors.textSecondary.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.55));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: child,
        ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        style: TextStyle(
          color: color,
          fontSize: 14.5,
          fontStyle: FontStyle.italic,
          fontWeight: isSacredMoment ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
        child: Text('“$text”', textAlign: TextAlign.center),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Yönlendirme kartı
// ────────────────────────────────────────────────────────────────────────────

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.stable, required this.guidance});

  final bool stable;
  final QiblaGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final gold = light ? _goldOnLight : _goldOnDark;
    final config = _configFor(context, guidance, gold);
    final isGood = stable && guidance == QiblaGuidance.good;
    final accent = isGood ? gold : config.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: light
            ? accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: isGood ? 0.035 : 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: light
                        ? AppColors.emeraldDark
                        : Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.body,
                  style: TextStyle(
                    color: light
                        ? AppColors.textSecondary
                        : Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _GuidanceConfig _configFor(
    BuildContext context,
    QiblaGuidance guidance,
    Color gold,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (guidance) {
      QiblaGuidance.tilt => _GuidanceConfig(
        icon: Icons.screen_rotation_alt_rounded,
        color: AppColors.warning,
        title: l10n.qiblaCompassGuidanceTiltTitle,
        body: l10n.qiblaCompassGuidanceTiltBody,
      ),
      QiblaGuidance.calibrate => _GuidanceConfig(
        icon: Icons.explore_off_rounded,
        color: AppColors.warning,
        title: l10n.qiblaCompassGuidanceCalibrateTitle,
        body: l10n.qiblaCompassGuidanceCalibrateBody,
      ),
      QiblaGuidance.unstable => _GuidanceConfig(
        icon: Icons.sensors_off_rounded,
        color: AppColors.warning,
        title: l10n.qiblaCompassGuidanceUnstableTitle,
        body: l10n.qiblaCompassGuidanceUnstableBody,
      ),
      QiblaGuidance.good => _GuidanceConfig(
        icon: Icons.check_circle_outline_rounded,
        color: gold,
        title: l10n.qiblaCompassGuidanceGoodTitle,
        body: l10n.qiblaCompassGuidanceGoodBody,
      ),
    };
  }
}

class _GuidanceConfig {
  const _GuidanceConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

// ────────────────────────────────────────────────────────────────────────────
// Katman 1 — Statik süsleme painter'ı
//
// Tek kez boyanır (shouldRepaint yalnız tema değişince true).
// Klasik İslami tezhip dili:
//   • Radyal derinlik zemini
//   • 12 yapraklı şemse rozeti (iç içe geçen daire yayları — çiçek motifi)
//   • Kemer dizisi (revak/arkad) halkası
//   • Boncuk (tesbih tanesi) halkası + çift altın çerçeve
// ────────────────────────────────────────────────────────────────────────────

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter({required this.light});

  final bool light;

  @override
  bool shouldRepaint(covariant _OrnamentPainter old) => old.light != light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final gold = light ? _goldOnLight : _goldSoftDark;

    _drawBackground(canvas, c, r);
    _drawRosette(canvas, c, r, gold);
    _drawArcade(canvas, c, r, gold);
    _drawBeads(canvas, c, r, gold);
    _drawFrames(canvas, c, r, gold);
  }

  // Radyal derinlik — merkez hafif aydınlık, kenara doğru zemine karışır.
  void _drawBackground(Canvas canvas, Offset c, double r) {
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        c,
        r,
        light
            ? [
                const Color(0xFFEFEBE1),
                const Color(0xFFE0DBCF),
                const Color(0x00E0DBCF),
              ]
            : [
                const Color(0xFF133024),
                const Color(0xFF0A1710),
                const Color(0x000A1710),
              ],
        const [0.0, 0.70, 1.0],
      );
    canvas.drawCircle(c, r, bgPaint);
  }

  /// 12 yapraklı şemse rozeti — merkez etrafında üst üste binen daireler.
  /// Klasik tezhip/kubbe göbeği motifi; çiçek gibi okunur, yıldız değil.
  void _drawRosette(Canvas canvas, Offset c, double r, Color gold) {
    final petalPaint = Paint()
      ..color = gold.withValues(alpha: light ? 0.20 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const petals = 12;
    final orbitR = r * 0.21; // yaprak merkezlerinin gezindiği yörünge
    final petalR = orbitR; // yaprak dairesi yarıçapı = yörünge → rozet

    for (var i = 0; i < petals; i++) {
      final a = i * 2 * math.pi / petals - math.pi / 2;
      canvas.drawCircle(
        Offset(c.dx + orbitR * math.cos(a), c.dy + orbitR * math.sin(a)),
        petalR,
        petalPaint,
      );
    }

    // Rozeti saran iki ince halka — motifi toparlar, madalyon hissi verir.
    canvas.drawCircle(
      c,
      orbitR * 2,
      Paint()
        ..color = gold.withValues(alpha: light ? 0.26 : 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      c,
      orbitR * 2 + 5,
      Paint()
        ..color = gold.withValues(alpha: light ? 0.14 : 0.11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  /// Kemer dizisi — cami revakları gibi, rozet ile tick'ler arasında dolanan
  /// sivri kemercikler halkası.
  void _drawArcade(Canvas canvas, Offset c, double r, Color gold) {
    final arcPaint = Paint()
      ..color = gold.withValues(alpha: light ? 0.24 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const arches = 24;
    final baseR = r * 0.565; // kemer ayaklarının oturduğu yarıçap
    final apexR = r * 0.635; // kemer tepe noktası
    const halfStep = math.pi / arches;

    for (var i = 0; i < arches; i++) {
      final mid = i * 2 * math.pi / arches - math.pi / 2;
      final aL = mid - halfStep;
      final aR = mid + halfStep;

      final foot1 = Offset(
        c.dx + baseR * math.cos(aL),
        c.dy + baseR * math.sin(aL),
      );
      final foot2 = Offset(
        c.dx + baseR * math.cos(aR),
        c.dy + baseR * math.sin(aR),
      );
      final apex = Offset(
        c.dx + apexR * math.cos(mid),
        c.dy + apexR * math.sin(mid),
      );

      // Sivri (tudor) kemer: iki yay yerine iki quadratic eğri — ucuz ve zarif.
      final ctrl1 = Offset(
        c.dx + apexR * math.cos(aL + halfStep * 0.45),
        c.dy + apexR * math.sin(aL + halfStep * 0.45),
      );
      final ctrl2 = Offset(
        c.dx + apexR * math.cos(aR - halfStep * 0.45),
        c.dy + apexR * math.sin(aR - halfStep * 0.45),
      );

      final path = Path()
        ..moveTo(foot1.dx, foot1.dy)
        ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, apex.dx, apex.dy)
        ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, foot2.dx, foot2.dy);
      canvas.drawPath(path, arcPaint);
    }

    // Kemer ayaklarının bastığı ince zemin halkası.
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = gold.withValues(alpha: light ? 0.15 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  /// Boncuk halkası — tesbih taneleri gibi 72 minik altın nokta.
  void _drawBeads(Canvas canvas, Offset c, double r, Color gold) {
    // Kemer tepesi (0.635r) ile yön etiketleri (~0.76r) arasındaki boşluk.
    final beadR = r * 0.685;
    final beadDot = Paint()
      ..color = gold.withValues(alpha: light ? 0.38 : 0.34);
    final beadBig = Paint()
      ..color = gold.withValues(alpha: light ? 0.55 : 0.50);

    for (var i = 0; i < 72; i++) {
      final a = i * 2 * math.pi / 72 - math.pi / 2;
      final p = Offset(c.dx + beadR * math.cos(a), c.dy + beadR * math.sin(a));
      // Her 18'de bir (ana yönlerde) iri "imame" boncuğu.
      final isCard = i % 18 == 0;
      canvas.drawCircle(p, isCard ? 1.9 : 0.9, isCard ? beadBig : beadDot);
    }
  }

  /// Çift altın çerçeve + iç zümrüt halka.
  void _drawFrames(Canvas canvas, Offset c, double r, Color gold) {
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..color = gold.withValues(alpha: light ? 0.55 : 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..color = gold.withValues(alpha: light ? 0.22 : 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawCircle(
      c,
      r - 9,
      Paint()
        ..color = light
            ? AppColors.emeraldMid.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Katman 2 — Dönen kadran painter'ı
//
// shouldRepaint: yalnızca qiblaBearingDeg / tema / etiketler değişince.
// Transform.rotate GPU katmanında; painter nadiren çağrılır.
// ────────────────────────────────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.qiblaBearingDeg,
    required this.light,
    required this.labelNorth,
    required this.labelEast,
    required this.labelSouth,
    required this.labelWest,
  });

  final double qiblaBearingDeg;
  final bool light;
  final String labelNorth;
  final String labelEast;
  final String labelSouth;
  final String labelWest;

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.qiblaBearingDeg != qiblaBearingDeg ||
      old.light != light ||
      old.labelNorth != labelNorth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    _drawTicks(canvas, c, r);
    _drawQiblaArrow(canvas, c, r);
    _drawCenter(canvas, c);
  }

  void _drawTicks(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 72; i++) {
      final deg = i * 5.0;
      final rad = deg * math.pi / 180;
      final isNorth = i == 0;
      final isCard = i % 18 == 0;
      final isMajor = i % 6 == 0;

      final outer = r - 11.0;
      final len = isCard ? 15.0 : (isMajor ? 10.0 : 4.5);
      final sw = isCard ? 2.0 : (isMajor ? 1.1 : 0.8);

      final tickColor = isNorth
          ? _tickNorth
          : (light
                ? AppColors.emeraldMid.withValues(alpha: isMajor ? 0.60 : 0.40)
                : (isMajor ? _tickDim : const Color(0x33FFFFFF)));

      final sinA = math.sin(rad);
      final cosA = math.cos(rad);

      canvas.drawLine(
        Offset(c.dx + outer * sinA, c.dy - outer * cosA),
        Offset(c.dx + (outer - len) * sinA, c.dy - (outer - len) * cosA),
        Paint()
          ..color = tickColor
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );

      if (isCard) {
        final label = switch (i) {
          0 => labelNorth,
          18 => labelEast,
          36 => labelSouth,
          54 => labelWest,
          _ => '',
        };
        final lr = outer - len - 13.0;
        _text(
          canvas,
          label,
          Offset(c.dx + lr * sinA, c.dy - lr * cosA),
          color: isNorth
              ? _tickNorth
              : (light ? AppColors.emeraldDark : _textDim),
          size: 11,
          bold: true,
        );
      }
    }
  }

  void _drawQiblaArrow(Canvas canvas, Offset c, double r) {
    final rad = qiblaBearingDeg * math.pi / 180;
    final sinA = math.sin(rad);
    final cosA = math.cos(rad);

    final gold = light ? _goldOnLight : _goldOnDark;
    final goldDeep = light ? const Color(0xFF7A5A2B) : _goldSoftDark;

    // Kâbe ikonu ok ucunda; ok gövdesi merkezden ikona uzanan zarif kama.
    final kaabaR = r - 40.0; // Kâbe ikonunun merkezi
    final tipR = kaabaR - 15.0; // ok ucu, ikonun hemen altında
    final baseR = r * 0.10;

    final tip = Offset(c.dx + tipR * sinA, c.dy - tipR * cosA);
    final base = Offset(c.dx + baseR * sinA, c.dy - baseR * cosA);

    const hw = 6.0;
    final left = Offset(base.dx - hw * cosA, base.dy + hw * sinA);
    final right = Offset(base.dx + hw * cosA, base.dy - hw * sinA);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(base.dx, base.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    // Altın gövde + koyu altın kontur — güneş ışığında da seçilir.
    canvas.drawPath(path, Paint()..color = gold);
    canvas.drawPath(
      path,
      Paint()
        ..color = goldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Kâbe silueti — ok ucunun üzerinde, radyal hizada. Kıbleyi metin
    // yerine ikonun kendisi anlatır; dönen etiket okunaklılık sorunu yaratır.
    _drawKaaba(
      canvas,
      Offset(c.dx + kaabaR * sinA, c.dy - kaabaR * cosA),
      rad,
      18.0,
      gold,
    );
  }

  /// Minimal Kâbe silueti: koyu küp + altın kuşak (hizam) + altın kapı.
  void _drawKaaba(
    Canvas canvas,
    Offset center,
    double angleRad,
    double s,
    Color gold,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleRad);

    final bodyColor = light ? const Color(0xFF23211D) : const Color(0xFF14120E);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s, height: s),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(body, Paint()..color = bodyColor);
    canvas.drawRRect(
      body,
      Paint()
        ..color = gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Hizam — üst üçte birlik altın kuşak.
    canvas.drawRect(
      Rect.fromLTWH(-s / 2 + 1.2, -s / 2 + s * 0.26, s - 2.4, s * 0.12),
      Paint()..color = gold,
    );

    // Kapı — alt sağda küçük altın dikdörtgen.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.10, s * 0.08, s * 0.18, s * 0.34),
        const Radius.circular(1),
      ),
      Paint()..color = gold.withValues(alpha: 0.9),
    );

    canvas.restore();
  }

  void _drawCenter(Canvas canvas, Offset c) {
    final gold = light ? _goldOnLight : _goldOnDark;
    canvas.drawCircle(
      c,
      5.5,
      Paint()
        ..color = light
            ? AppColors.emeraldDark.withValues(alpha: 0.92)
            : const Color(0xFF0D1B13),
    );
    canvas.drawCircle(
      c,
      5.5,
      Paint()
        ..color = gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(c, 2.0, Paint()..color = gold);
  }

  void _text(
    Canvas canvas,
    String label,
    Offset center, {
    required Color color,
    required double size,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Katman 3 — Dönmeyen üst işaret + hizalanma yayı
//
// Üstte sabit altın elmas işaret; kıbleye kalan açıyı gösteren ince yay.
// Yay kıbleye yaklaştıkça altına döner ve kısalır; hizalanınca tam altın
// halka belirir. Sensör hızında repaint olur; tek arc + tek path, çok ucuz.
// ────────────────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({
    required this.signedDeltaDeg,
    required this.aligned,
    required this.light,
  });

  final double signedDeltaDeg;
  final bool aligned;
  final bool light;

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.signedDeltaDeg != signedDeltaDeg ||
      old.aligned != aligned ||
      old.light != light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final gold = light ? _goldOnLight : _goldOnDark;

    // Sabit üst işaret — küçük altın elmas.
    final markY = c.dy - r + 2.0;
    final diamond = Path()
      ..moveTo(c.dx, markY - 5)
      ..lineTo(c.dx + 4.5, markY + 1)
      ..lineTo(c.dx, markY + 7)
      ..lineTo(c.dx - 4.5, markY + 1)
      ..close();
    canvas.drawPath(diamond, Paint()..color = gold);

    final arcRect = Rect.fromCircle(center: c, radius: r - 4.5);

    if (aligned) {
      // Tam altın halka — hizalanmanın taçlandığı an.
      canvas.drawArc(
        arcRect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = gold.withValues(alpha: 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Kalan açı yayı — üstteki işaretten kıble tarafına doğru.
    final absDelta = signedDeltaDeg.abs();
    if (absDelta < 0.5) return;

    // Yaklaştıkça altınlaşır: 60°+ soluk, 0°'a inerken parlak altın.
    final closeness = (1 - (absDelta / 60)).clamp(0.0, 1.0);
    final arcColor = Color.lerp(
      light
          ? AppColors.emeraldMid.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.16),
      gold.withValues(alpha: 0.85),
      closeness,
    )!;

    final sweep = signedDeltaDeg * math.pi / 180;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Katman 4 — Nefes alan altın pulse halkası
//
// Yalnız hizalıyken animasyonludur; değilken boş döner (sıfır maliyet).
// Blur/MaskFilter yok — genişleyip solan konsantrik stroke'lar.
// ────────────────────────────────────────────────────────────────────────────

class _PulsePainter extends CustomPainter {
  const _PulsePainter({
    required this.t,
    required this.active,
    required this.light,
  });

  final double t;
  final bool active;
  final bool light;

  @override
  bool shouldRepaint(covariant _PulsePainter old) =>
      old.t != t || old.active != active || old.light != light;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final gold = light ? _goldOnLight : _goldOnDark;

    // Nefes eğrisi: yumuşak çıkış — sinüs yarım dalgası.
    final breath = math.sin(t * math.pi);

    // Dışa doğru genişleyen, solarak kaybolan halka.
    final expandR = r * (1.0 + 0.055 * t);
    final fade = (1.0 - t) * 0.30;
    if (fade > 0.01) {
      canvas.drawCircle(
        c,
        expandR,
        Paint()
          ..color = gold.withValues(alpha: fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Kadran kenarında nefes alan sabit iç ışıma — 3 konsantrik stroke.
    for (var i = 0; i < 3; i++) {
      final alpha = (0.14 - i * 0.04) * breath;
      if (alpha <= 0.005) continue;
      canvas.drawCircle(
        c,
        r - 4.5 + i * 2.6,
        Paint()
          ..color = gold.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }
  }
}
