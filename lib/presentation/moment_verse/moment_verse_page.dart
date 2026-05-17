// lib/presentation/moment_verse/moment_verse_page.dart
//
// "Anın Ayeti" — FCM bildirim tıklamasından açılan özel tam ekran sayfa.
//
// Akış:
//   1. Firestore'dan admin_ntf_config/current_moment okunur.
//   2. expiresAtMs kontrolü: 5 dakikalık pencere içindeyse ayet gösterilir.
//   3. Süre geçmişse "Bu anı kaçırdın" ekranı gösterilir.
//   4. Döküman hiç yoksa "Henüz bir an yok" nötr durumu.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';

// ── Veri Modeli ───────────────────────────────────────────────────────────────

class _MomentData {
  const _MomentData({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.ref,
    required this.clockStr,
    required this.sentAtMs,
    required this.expiresAtMs,
  });

  final int? surahNumber;
  final String surahName;
  final int? verseNumber;
  final String verseText;
  final String ref;
  final String clockStr;
  final int sentAtMs;
  final int expiresAtMs;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAtMs;

  Duration get remaining {
    final ms = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: ms.clamp(0, 5 * 60 * 1000));
  }

  factory _MomentData.fromMap(Map<String, dynamic> d) {
    return _MomentData(
      surahNumber: (d['surahNumber'] as num?)?.toInt(),
      surahName: d['surahName']?.toString() ?? '',
      verseNumber: (d['verseNumber'] as num?)?.toInt(),
      verseText: d['verseText']?.toString() ?? '',
      ref: d['ref']?.toString() ?? '',
      clockStr: d['clockStr']?.toString() ?? '',
      sentAtMs: (d['sentAtMs'] as num?)?.toInt() ?? 0,
      expiresAtMs: (d['expiresAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Sayfa ─────────────────────────────────────────────────────────────────────

class MomentVersePage extends StatefulWidget {
  const MomentVersePage({super.key});

  @override
  State<MomentVersePage> createState() => _MomentVersePageState();
}

class _MomentVersePageState extends State<MomentVersePage>
    with SingleTickerProviderStateMixin {
  // Yükleme durumu
  bool _loading = true;
  String? _error;
  _MomentData? _moment;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  // Reveal animasyonu
  late final AnimationController _revealCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));

    _loadMoment();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMoment() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_ntf_config')
          .doc('current_moment')
          .get(const GetOptions(source: Source.server));

      if (!mounted) return;

      if (!snap.exists || snap.data() == null) {
        setState(() {
          _loading = false;
          _moment = null;
        });
        return;
      }

      final moment = _MomentData.fromMap(snap.data()!);
      setState(() {
        _loading = false;
        _moment = moment;
        if (!moment.isExpired) {
          _remaining = moment.remaining;
        }
      });

      if (!moment.isExpired) {
        _revealCtrl.forward();
        _startCountdown(moment);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Yüklenemedi. Lütfen tekrar dene.';
      });
    }
  }

  void _startCountdown(_MomentData moment) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = moment.remaining;
      setState(() => _remaining = remaining);
      if (moment.isExpired) {
        _countdownTimer?.cancel();
        // Süre doldu: rebuild tetikle (isExpired kontrolü build'de yapılır)
        setState(() {});
      }
    });
  }

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.6, -0.6),
          radius: 1.4,
          colors: [Color(0xFF0D2B1F), Color(0xFF030806)],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    final moment = _moment;
    if (moment == null) return _buildEmpty();
    if (moment.isExpired) return _buildExpired(moment);
    return _buildActive(moment);
  }

  // ── Yükleniyor ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _topBar(),
        const Expanded(
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentNeonGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hata ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 40),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _closeButton(),
          ],
        ),
      ),
    );
  }

  // ── Henüz an yok ──────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🌿',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Henüz bir an yok',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bir sonraki bildirimi bekle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _homeButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Süre geçmiş ───────────────────────────────────────────────────────

  Widget _buildExpired(_MomentData moment) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Soluk saat gösterimi
                  if (moment.clockStr.isNotEmpty) ...[
                    Text(
                      moment.clockStr,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.07),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    '🌙',
                    style: TextStyle(fontSize: 44),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bu vakit geçti',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Bazı anlar yalnızca bir kez gelir.\nBelki bir sonrakinde buluşuruz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.38),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // İnce ayırıcı çizgi
                  Container(
                    width: 40,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bildirimleri açık tut,\nbir sonraki an kaçmasın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.22),
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _homeButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Aktif ayet ────────────────────────────────────────────────────────

  Widget _buildActive(_MomentData moment) {
    final hasRef = moment.surahNumber != null && moment.verseNumber != null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            _topBar(moment: moment),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Saat büyük gösterimi
                    if (moment.clockStr.isNotEmpty) ...[
                      Text(
                        moment.clockStr,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentNeonGreen
                              .withValues(alpha: 0.12),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Saat → Ayet bağlantı açıklaması: kullanıcı "Sure X, Ayet
                    // Y" gördüğünde rakamların saatin koordinatı olduğunu
                    // anlasın. Şiirsel ton korunur, mantık bir kez aktarılır.
                    if (hasRef && moment.clockStr.isNotEmpty) ...[
                      Text(
                        'Saatin sana fısıldadığı ayet',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.3,
                          color: Colors.white.withValues(alpha: 0.38),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${moment.clockStr}  →  Sure ${moment.surahNumber}, '
                        'Ayet ${moment.verseNumber}',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.accentNeonGreen
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Referans pill
                    if (hasRef) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentNeonGreen
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.accentNeonGreen
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          moment.surahName.isNotEmpty
                              ? '${moment.surahName} ${moment.verseNumber}. Ayet'
                              : 'Sure ${moment.surahNumber}, Ayet ${moment.verseNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentNeonGreen
                                .withValues(alpha: 0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ] else
                      const SizedBox(height: 24),

                    // Türkçe meal
                    if (moment.verseText.isNotEmpty)
                      Text(
                        moment.verseText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          height: 1.75,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),

                    // Kaynak (Kur'an ref)
                    if (moment.ref.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        moment.ref,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.accentNeonGreen
                              .withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Sıralama: not (ayetin altında ek anlam) → geri sayım barı
            // (zaman baskısı, butonun hemen üstü) → ana sayfa butonu.
            _buildMomentNote(moment),
            _buildCountdownBar(),
            _homeButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Yardımcı widget'lar ───────────────────────────────────────────────

  Widget _topBar({_MomentData? moment}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white38,
              size: 22,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          const Spacer(),
          if (moment != null && !moment.isExpired)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1610),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatCountdown(_remaining),
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMomentNote(_MomentData moment) {
    final hasTime = moment.clockStr.isNotEmpty;
    if (!hasTime) return const SizedBox.shrink();

    // Adres bölümü esnek: surahNumber/verseNumber yoksa ref string'ine düş;
    // o da yoksa "bir ayete" şeklinde generic dile dön. Eski pool item'larında
    // bu alanlar boş olabilir — not yine de gösterilsin, mantık ayakta kalsın.
    String address;
    if (moment.surahNumber != null && moment.verseNumber != null) {
      address = 'Sure ${moment.surahNumber}, ${moment.verseNumber}. ayet';
    } else if (moment.ref.isNotEmpty) {
      address = moment.ref;
    } else {
      address = 'bir ayet';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 14),
          Text(
            'Saat ${moment.clockStr} — $address. '
            'Bu tesadüf değil; zamanın rakamları Kur\'an\'da bir adrese dönüşür. '
            'Bu bildirimi tam vaktinde açman ve bu ayetin önüne geçmen de öyle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Geri sayım barı ───────────────────────────────────────────────────
  Widget _buildCountdownBar() {
    final total = const Duration(minutes: 5).inSeconds;
    final elapsed = total - _remaining.inSeconds;
    final progress = (elapsed / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentNeonGreen.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatCountdown(_remaining)} sonra bu an kaybolacak',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.25),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.accentNeonGreen.withValues(alpha: 0.12),
            foregroundColor: AppColors.accentNeonGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.2),
              ),
            ),
          ),
          onPressed: () => context.go(AppRoutes.home),
          child: const Text(
            'Ana Sayfaya Dön',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return TextButton(
      onPressed: () => context.go(AppRoutes.home),
      child: Text(
        'Kapat',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}
