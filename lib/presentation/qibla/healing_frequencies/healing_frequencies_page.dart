// İyileştirici Frekanslar — tam ekran oturum.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_text.dart';
import 'healing_audio_notifier.dart';
import 'healing_daily_comfort_entries.dart';
import '../../shared/providers/quote_pool_content_providers.dart';
import 'healing_freq_catalog.dart';
import 'healing_frequencies_sheets.dart';

class HealingFrequenciesPage extends ConsumerStatefulWidget {
  const HealingFrequenciesPage({super.key});

  @override
  ConsumerState<HealingFrequenciesPage> createState() =>
      _HealingFrequenciesPageState();
}

class _HealingFrequenciesPageState extends ConsumerState<HealingFrequenciesPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(healingAudioNotifierProvider.notifier).onAppResumed();
    }
  }

  String _ambientLabel(String key) {
    switch (key) {
      case kHealingAmbientForest:
        return trEnAr(context, tr: 'Orman Sesi', en: 'Forest Sound', ar: 'صوت الغابة');
      case kHealingAmbientFire:
        return trEnAr(context, tr: 'Ateş Sesi', en: 'Fire Sound', ar: 'صوت النار');
      case kHealingAmbientEvren:
        return trEnAr(context, tr: 'Evren Sesi', en: 'Cosmic Sound', ar: 'صوت الكون');
      case kHealingAmbientInshirah:
        return trEnAr(context, tr: 'İnşirah Suresi', en: 'Surah Al-Inshirah', ar: 'سورة الشرح');
      default:
        return trEnAr(context, tr: 'Orman Sesi', en: 'Forest Sound', ar: 'صوت الغابة');
    }
  }

  String _sleepRowSubtitle(HealingAudioState s) {
    final m = s.selectedSleepMinutes;
    if (m == null) return trEnAr(context, tr: 'Kapalı', en: 'Off', ar: 'متوقف');
    if (s.isPlaying && s.sleepEndsAt != null) {
      final left = s.sleepEndsAt!.difference(DateTime.now());
      if (!left.isNegative) {
        return '${trEnAr(context, tr: 'Kalan ', en: 'Remaining ', ar: 'المتبقي ')}${_fmtMmSs(left)}';
      }
    }
    return trEnAr(
      context,
      tr: '$m dakika',
      en: '$m minutes',
      ar: '$m دقيقة',
    );
  }

  double _progress(HealingAudioState s) {
    final start = s.playWindowStart;
    if (start == null) return 0;
    final elapsed = DateTime.now().difference(start);
    final total = s.sleepEndsAt != null
        ? s.sleepEndsAt!.difference(start)
        : const Duration(minutes: 30);
    if (total.inMilliseconds <= 0) return 0;
    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  String _fmtMmSs(Duration d) {
    if (d.isNegative) return '00:00';
    final totalSeconds = d.inSeconds;
    final m = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _rightLabel(HealingAudioState s) {
    final start = s.playWindowStart;
    if (start != null && s.sleepEndsAt != null) {
      return _fmtMmSs(s.sleepEndsAt!.difference(start));
    }
    return '30:00';
  }

  Future<void> _pauseIfPlaying() async {
    final st = ref.read(healingAudioNotifierProvider);
    if (!st.isPlaying) return;
    await ref.read(healingAudioNotifierProvider.notifier).pause();
  }

  Future<void> _showInfo() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B2220).withValues(alpha: 0.96),
                    const Color(0xFF111715).withValues(alpha: 0.94),
                  ],
                ),
                border: Border.all(
                  color: AppColors.healingTeal.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.healingTeal.withValues(
                              alpha: 0.14,
                            ),
                            border: Border.all(
                              color: AppColors.healingTeal.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.healingTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            trEnAr(
                              context,
                              tr: 'Bilgi',
                              en: 'Info',
                              ar: 'معلومات',
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      trEnAr(
                        context,
                        tr: 'Bu bölüm rahatlama ve tefekkür için tasarlanmıştır; tıbbi tedavi yerine geçmez. Sesleri düşük seviyede dinlemeniz önerilir. Rahatsızlık hissederseniz durdurun.',
                        en: 'This section is for relaxation and reflection; it is not a medical treatment. Listen at low volume. Stop if you feel discomfort.',
                        ar: 'هذا القسم للاسترخاء والتأمل وليس بديلاً عن العلاج الطبي. يُنصح بالاستماع بصوت منخفض. أوقفه إذا شعرت بعدم الارتياح.',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.healingTeal,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        child: Text(
                          trEnAr(
                            context,
                            tr: 'Tamam',
                            en: 'OK',
                            ar: 'حسنًا',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(healingAudioNotifierProvider);
    final n = ref.read(healingAudioNotifierProvider.notifier);
    final hz = s.hz;
    final isInshirah = s.isInshirahMode;
    const teal = AppColors.healingTeal;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      body: Stack(
        children: [
          const Positioned.fill(child: _HealingRippleBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).maybePop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white.withValues(alpha: 0.9),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              trEnAr(
                                context,
                                tr: 'İyileştirici Frekanslar',
                                en: 'Healing Frequencies',
                                ar: 'الترددات العلاجية',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              HealingFreqCatalog.shortTitle(context, hz),
                              style: TextStyle(
                                color: teal.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showInfo();
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                        color: teal,
                        style: IconButton.styleFrom(
                          backgroundColor: teal.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 8),
                      _FrequencyHero(hz: hz, teal: teal),
                      const SizedBox(height: 20),
                      Text(
                        HealingFreqCatalog.heading(context, hz),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        HealingFreqCatalog.body(context, hz),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _VerseCard(teal: teal),
                      const SizedBox(height: 22),
                      _AmbientRow(
                        label: trEnAr(
                          context,
                          tr: 'Ambiyans Sesi',
                          en: 'Ambient Sound',
                          ar: 'صوت الخلفية',
                        ),
                        value: _ambientLabel(s.ambientKey),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await _pauseIfPlaying();
                          if (!mounted) return;
                          // State.context kullanımı `mounted` ile aynı
                          // State'e ait olduğunu analizöre açıkça söyler —
                          // aksi halde `unrelated 'mounted' check` uyarısı.
                          showHealingAmbientSheet(this.context, ref);
                        },
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          trEnAr(
                            context,
                            tr: 'ÖNAYARLAR',
                            en: 'PRESETS',
                            ar: 'إعدادات مسبقة',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: isInshirah,
                        child: Opacity(
                          opacity: isInshirah ? 0.38 : 1,
                          child: _PresetRow(
                            active: s.activePreset,
                            onPick: (p) async {
                              HapticFeedback.lightImpact();
                              if (s.activePreset != p) {
                                await _pauseIfPlaying();
                                if (!mounted) return;
                              }
                              n.setPreset(p);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PlayerBlock(
                        isPlaying: s.isPlaying,
                        progress: _progress(s),
                        left: _fmtMmSs(
                          s.playWindowStart != null
                              ? DateTime.now().difference(s.playWindowStart!)
                              : Duration.zero,
                        ),
                        right: _rightLabel(s),
                        onPlay: () {
                          HapticFeedback.lightImpact();
                          n.togglePlay();
                        },
                        teal: teal,
                      ),
                      const SizedBox(height: 22),
                      _VolumeSlider(
                        icon: Icons.graphic_eq_rounded,
                        label: trEnAr(
                          context,
                          tr: 'Frekans tonu (Hz)',
                          en: 'Frequency tone (Hz)',
                          ar: 'نغمة التردد (Hz)',
                        ),
                        value: s.toneVolume01,
                        tint: teal,
                        trailingPct: '${(s.toneVolume01 * 100).round()}%',
                        onChanged: s.isPlaying && !isInshirah
                            ? n.setToneVolume01
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _VolumeSlider(
                        icon: Icons.local_fire_department_outlined,
                        label: trEnAr(
                          context,
                          tr: 'Ambiyans',
                          en: 'Ambient',
                          ar: 'الخلفية',
                        ),
                        value: s.ambientVolume01,
                        tint: AppColors.healingOrange,
                        trailingPct: '${(s.ambientVolume01 * 100).round()}%',
                        onChanged: n.setAmbientVolume01,
                      ),
                      const SizedBox(height: 18),
                      _AmbientRow(
                        label: trEnAr(
                          context,
                          tr: 'Uyku Zamanlayıcı',
                          en: 'Sleep Timer',
                          ar: 'مؤقت النوم',
                        ),
                        value: _sleepRowSubtitle(s),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await _pauseIfPlaying();
                          if (!mounted) return;
                          showHealingSleepSheet(this.context, ref);
                        },
                        icon: Icons.nightlight_round,
                      ),
                      const SizedBox(height: 24),
                      if (isInshirah)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            trEnAr(
                              context,
                              tr: 'İnşirah modunda frekans kontrolleri kapalıdır.',
                              en: 'Frequency controls are locked in Inshirah mode.',
                              ar: 'عناصر التحكم بالتردد مقفلة في وضع الشرح.',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        trEnAr(
                          context,
                          tr: 'Tüm Frekanslar',
                          en: 'All Frequencies',
                          ar: 'كل الترددات',
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: isInshirah,
                        child: Opacity(
                          opacity: isInshirah ? 0.35 : 1,
                          child: SizedBox(
                            height: 132,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: HealingFreqCatalog.orderedHz.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final h = HealingFreqCatalog.orderedHz[i];
                                final sel = h == hz;
                                return GestureDetector(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    if (h != hz) {
                                      await _pauseIfPlaying();
                                      if (!mounted) return;
                                    }
                                    unawaited(n.selectFrequency(h));
                                  },
                                  child: SizedBox(
                                    width: 118,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 76,
                                          height: 76,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: sel
                                                  ? teal
                                                  : Colors.white.withValues(
                                                      alpha: 0.18,
                                                    ),
                                              width: sel ? 2.4 : 1.2,
                                            ),
                                            color: sel
                                                ? teal.withValues(alpha: 0.28)
                                                : Colors.white.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              child: Text(
                                                '$h Hz',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          HealingFreqCatalog.listCaption(context, h),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealingRippleBackground extends StatelessWidget {
  const _HealingRippleBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RipplePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RipplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.28);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF26C6DA).withValues(alpha: 0.06);
    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(c, 60.0 * i, base);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FrequencyHero extends StatelessWidget {
  const _FrequencyHero({required this.hz, required this.teal});

  final int hz;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: teal.withValues(alpha: 0.22),
              blurRadius: 48,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D1814),
            border: Border.all(color: teal.withValues(alpha: 0.35), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hz Hz',
                style: TextStyle(
                  color: teal,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                HealingFreqCatalog.shortTitle(context, hz),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({required this.teal});

  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healingComfortEntryProvider);
    final v = async.when(
      data: (e) => e,
      loading: HealingDailyComfort.forLocalToday,
      error: (_, __) => HealingDailyComfort.forLocalToday(),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0C1610).withValues(alpha: 0.92),
        border: Border.all(color: teal.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            v.arabic,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppColors.goldAccent,
              fontSize: 26,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            v.turkish,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            v.ref,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientRow extends StatelessWidget {
  const _AmbientRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.volume_up_rounded,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.active, required this.onPick});

  final HealingPreset? active;
  final void Function(HealingPreset) onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PresetChip(
            label: trEnAr(
              context,
              tr: 'Odak',
              en: 'Focus',
              ar: 'تركيز',
            ),
            icon: Icons.psychology_outlined,
            tint: AppColors.healingTeal,
            selected: active == HealingPreset.focus,
            onTap: () => onPick(HealingPreset.focus),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PresetChip(
            label: trEnAr(
              context,
              tr: 'Uyku',
              en: 'Sleep',
              ar: 'نوم',
            ),
            icon: Icons.bedtime_outlined,
            tint: Colors.lightBlueAccent.shade100,
            selected: active == HealingPreset.sleep,
            onTap: () => onPick(HealingPreset.sleep),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tint.withValues(alpha: 0.14) : const Color(0xFF1E1E22),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: tint, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? tint : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerBlock extends StatelessWidget {
  const _PlayerBlock({
    required this.isPlaying,
    required this.progress,
    required this.left,
    required this.right,
    required this.onPlay,
    required this.teal,
  });

  final bool isPlaying;
  final double progress;
  final String left;
  final String right;
  final VoidCallback onPlay;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: teal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            Text(
              right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: teal,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.trailingPct,
    this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color tint;
  final String trailingPct;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121814),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                trailingPct,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              overlayColor: tint.withValues(alpha: 0.12),
              trackHeight: 5,
            ),
            child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
