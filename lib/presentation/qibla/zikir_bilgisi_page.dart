// lib/presentation/qibla/zikir_bilgisi_page.dart
// Zikir bilgisi: günlük pay, analiz, tamamlanan turlar, arşiv oturumları.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share/platform_channel_share_errors.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/models/zikir_matik_record.dart';
import '../../data/models/zikir_matik_tur_log.dart';
import '../../data/repositories/zikir_matik_repository.dart';

import 'package:arin/l10n/app_localizations.dart';

abstract final class _Zc {
  static const pageBg = Color(0xFF1A2B34);
  static const outer = Color(0xFF708A96);
  static const lcdBg = Color(0xFFB2C9AB);
  static const labelMuted = Color(0xFFC5D4DC);
  static const dialogSurface = Color(0xFF0C1419);
}

const List<String> _kZikirDailyReflections = <String>[
  'Zikir, kalbin yorulmak bilmeyen o bitmek bilmeyen uğultusunu dindirme sanatıdır.',
  'Dile düşen her kelime, ruhun üzerindeki tozları birer birer temizleyen bir yağmur damlasıdır.',
  'Dünyanın karmaşasında kaybolduğunda, kendi ismini değil, O\'nun ismini hatırlayarak kendini bulursun.',
  'Zikir, sessizliğin içinde yankılanan en samimi ve en derin fısıltıdır.',
  'Kalbin vuruşlarını birer tesbihe dönüştürmek, hayatı ritimli bir huzura kavuşturur.',
  'Kelimeler dudaktan döküldükçe, içindeki o devasa boşluğun şefkatle dolduğunu hissedersin.',
  'Zikir, aklın labirentlerinden çıkıp kalbin geniş ovalarına ulaşmanın en kısa yoludur.',
  'Unutkanlıklar denizinde boğulurken, bir kelimeyle hatırlamak ruhun can simididir.',
  'İçindeki fırtınaları dindirmek istiyorsan, dilini huzurun zikrine alıştır.',
  'Her zikir, ruhun karanlık köşelerine bırakılan küçük ve zarif birer mum ışığıdır.',
  'Zamanın acımasız akışına karşı, kalbi ebediyete bağlayan kopmaz bir bağdır.',
  'Zikir, insanın kendine verdiği en anlamlı ve en dingin mola anıdır.',
  'Söylediğin her güzel kelime, ruhunun bahçesinde açan birer çiçek gibidir.',
  'Zihin düşüncelerin yüküyle ağırlaştığında, zikir tüm fazlalıkları bir kenara iter.',
  'Kelimelerin gücüyle kalbi parlatmak, dünyayı daha net görmeni sağlar.',
  'Zikir, yalnızlığın ortasında kimsesiz olmadığını fısıldayan gizli bir arkadaştır.',
  'Kalbin pasını silen, ruhun aynasını parlatan en naif temizliktir.',
  'Her nefeste O\'nu anmak, hayatın her saniyesini anlamlı bir şiire dönüştürür.',
  'Zikir, kaygının bittiği ve güvenin başladığı o ince çizgidir.',
  'Dilin damağınla buluştuğu her an, ruhun gökyüzüyle buluştuğu andır.',
  'Dünyanın sahte renklerinden yorulan gözler için zikir, en saf beyazdır.',
  'Kalbin her atışında bir "hu" bulmak, varlığın özüne dokunmaktır.',
  'Zikir, kalbin üzerine serilen yumuşak ve huzurlu bir kadife örtüdür.',
  'Kelimelerin ötesindeki o derin sessizliğe ulaşmak için zikir en emin köprüdür.',
  'İnsanın kendiyle barışması, dilinin sevgiyi zikretmesiyle başlar.',
  'Zikir, ruhun yarasını saran, kanayan yerlerini dindiren bir merhemdir.',
  'Gözle görülmeyen ama kalple hissedilen o en büyük güce tutunma halidir.',
  'Her tesbih tanesi, seni yoran bir endişeyi parmaklarının ucundan bırakıp gitmektir.',
  'Zikir, nefes almanın sadece biyolojik değil, ruhsal bir eylem olduğunu hatırlatır.',
  'Kalbin en derin odasında yankılanan o tek isim, tüm soruların en huzurlu cevabıdır.',
];

int _dailyReflectionIndex() {
  final d = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final origin = DateTime(2020, 1, 1);
  final i = day.difference(origin).inDays.abs() % _kZikirDailyReflections.length;
  return i;
}

List<String> _zikirDailyReflections(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  // Temporary fallback logic for zikir daily reflections depending on locale.
  // Idealy these should be fully localized in ARB, but as a quick fix,
  // we check the locale name and return english or arabic arrays if needed.
  if (l10n.localeName.startsWith('en')) {
    return [
      'Zikr is a soft and peaceful velvet cover laid upon the heart.',
      'To reach that deep silence beyond words, zikr is the surest bridge.',
      'Making peace with oneself begins with the tongue reciting love.',
      'Zikr is an ointment that heals the wounds of the soul.',
      'It is the state of holding onto that greatest unseen power felt with the heart.',
      'With each bead, you let go of a worry that tires you.',
      'Zikr reminds us that breathing is not just a biological act, but a spiritual one.',
      'That single name echoing in the deepest room of the heart is the most peaceful answer.'
    ];
  } else if (l10n.localeName.startsWith('ar')) {
    return [
      'الذكر هو غطاء ناعم وهادئ يوضع على القلب.',
      'للوصول إلى ذلك الصمت العميق وراء الكلمات، الذكر هو الجسر الأكثر أماناً.',
      'التصالح مع الذات يبدأ بذكر اللسان للحب.',
      'الذكر مرهم يشفي جراح الروح.',
      'إنه حالة التمسك بتلك القوة الخفية العظمى التي تشعر بها بالقلب.',
      'مع كل حبة سبحة، تتخلى عن قلق يتعبك.',
      'الذكر يذكرنا بأن التنفس ليس مجرد فعل بيولوجي، بل روحي.',
      'ذلك الاسم الواحد الذي يتردد في أعمق غرفة في القلب هو الجواب الأكثر سلاماً.'
    ];
  }
  return _kZikirDailyReflections;
}

class _TurAnalytics {
  _TurAnalytics({
    required this.totalTurs,
    required this.activeDays,
    required this.byPhrase,
    required this.last7Days,
  });

  final int totalTurs;
  final int activeDays;
  final Map<String, int> byPhrase;
  final int last7Days;

  List<MapEntry<String, int>> get sortedPhrases {
    final e = byPhrase.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e;
  }
}

_TurAnalytics _computeAnalytics(List<ZikirMatikTurLog> logs) {
  final now = DateTime.now();
  final sevenAgo = now.subtract(const Duration(days: 7));
  final days = <String>{};
  final byPhrase = <String, int>{};
  var last7 = 0;
  for (final e in logs) {
    byPhrase[e.phrase] = (byPhrase[e.phrase] ?? 0) + 1;
    final d = e.recordedAt;
    days.add('${d.year}-${d.month}-${d.day}');
    if (!e.recordedAt.isBefore(sevenAgo)) last7++;
  }
  return _TurAnalytics(
    totalTurs: logs.length,
    activeDays: days.length,
    byPhrase: byPhrase,
    last7Days: last7,
  );
}

class ZikirBilgisiPage extends ConsumerStatefulWidget {
  const ZikirBilgisiPage({super.key});

  @override
  ConsumerState<ZikirBilgisiPage> createState() => _ZikirBilgisiPageState();
}

class _ZikirBilgisiPageState extends ConsumerState<ZikirBilgisiPage>
    with SingleTickerProviderStateMixin {
  ZikirMatikRepository? _repo;
  List<ZikirMatikTurLog> _turLogs = [];
  List<ZikirMatikRecord> _archive = [];

  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>(() {
        if (!mounted) return;
        _reload();
      });
      _intro.forward();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _reload() {
    final repo = ZikirMatikRepository(ref.read(sharedPreferencesProvider));
    setState(() {
      _repo = repo;
      _turLogs = repo.loadTurLogs();
      _archive = repo.loadRecords();
    });
  }

  Future<void> _deleteTur(ZikirMatikTurLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _Zc.dialogSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _Zc.outer.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.zikirmatikDeleteRoundRecord,
                    style: TextStyle(
                      color: _Zc.labelMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          l10n.zikirmatikCancel,
                          style: TextStyle(color: _Zc.outer),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _Zc.outer,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(l10n.zikirmatikDelete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      await _repo?.deleteTurLog(log.id);
      _reload();
    }
  }

  Future<void> _shareArchive(ZikirMatikRecord r) async {
    final l10n = AppLocalizations.of(context)!;
    final d = r.savedAt;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(d);
    final text =
        '${r.phrase}\n${r.totalCount} ${l10n.zikirmatikDhikr}\n'
        '${l10n.zikirmatikRound}: ${r.tur}\n'
        '${l10n.zikirmatikTarget}: ${r.target}\n$dateStr';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      if (!mounted) return;
          final msg = isMethodChannelLateInitResultError(e)
          ? platformShareTransientErrorMessage()
          : l10n.zikirmatikShareError;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _deleteArchive(ZikirMatikRecord r) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => AlertDialog(
        backgroundColor: _Zc.dialogSurface,
        title: Text(
          l10n.zikirmatikDeleteRecord,
          style: TextStyle(color: _Zc.labelMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.zikirmatikCancel,
                style: TextStyle(color: _Zc.outer)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _Zc.outer),
            child: Text(l10n.zikirmatikDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo?.deleteRecord(r.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_repo == null) {
      return const Scaffold(
        backgroundColor: _Zc.pageBg,
        body: Center(
          child: CircularProgressIndicator(color: _Zc.outer),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final idx = _dailyReflectionIndex();
    final text = _zikirDailyReflections(context)[idx];
    final analytics = _computeAnalytics(_turLogs);
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm', 'tr_TR');

    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: _Zc.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arkaplan zenginliği: soft gradient + Arapça "tesbîh" watermark.
          // `pageBg` flat kalmıyor, utilitarian analytics görünümünden
          // kurtuluyoruz ama mevcut içerik (scroll, sticky header, analytics
          // kartları) dokunulmadan üzerinde yaşamaya devam ediyor.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2B34),
                  Color(0xFF142028),
                  Color(0xFF0F1A20),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -20,
            child: Text(
              'تَسْبِيح',
              style: GoogleFonts.scheherazadeNew(
                fontSize: 140,
                color: _Zc.outer.withValues(alpha: 0.06),
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _Zc.labelMuted, size: 22),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _Zc.outer.withValues(alpha: 0.35),
                                  _Zc.outer.withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: _Zc.outer.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: _Zc.labelMuted,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.zikirmatikInfo,
                              style: TextStyle(
                                color: _Zc.labelMuted,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, child) {
                    final t = curve.value;
                    return Transform.translate(
                      offset: Offset(0, 16 * (1 - t)),
                      child: Opacity(opacity: t, child: child),
                    );
                  },
                  child: _DailyCard(text: text),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, child) {
                    final t = CurvedAnimation(
                      parent: _intro,
                      curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
                    ).value;
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - t)),
                      child: Opacity(opacity: t, child: child),
                    );
                  },
                  child: _AnalyticsCard(
                    analytics: analytics,
                    hasLogs: _turLogs.isNotEmpty,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l10n.zikirmatikCompletedRounds,
                  style: TextStyle(
                    color: _Zc.outer.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            if (_turLogs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    l10n.zikirmatikNoCompletedRounds,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _Zc.labelMuted.withValues(alpha: 0.7),
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final log = _turLogs[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16, i == 0 ? 4 : 0, 16, 10),
                      child: _TurLogTile(
                        log: log,
                        dateFmt: dateFmt,
                        onDelete: () => _deleteTur(log),
                      ),
                    );
                  },
                  childCount: _turLogs.length,
                ),
              ),
            if (_archive.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    l10n.zikirmatikArchivedSessions,
                    style: TextStyle(
                      color: _Zc.outer.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = _archive[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ArchiveTile(
                        record: r,
                        onShare: () => _shareArchive(r),
                        onDelete: () => _deleteArchive(r),
                      ),
                    );
                  },
                  childCount: _archive.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Zc.lcdBg.withValues(alpha: 0.42),
            _Zc.outer.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Zc.outer.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: _Zc.lcdBg.withValues(alpha: 0.95), size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.zikirmatikTodaysReflection,
                style: TextStyle(
                  color: _Zc.labelMuted.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: _Zc.pageBg,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.analytics,
    required this.hasLogs,
  });

  final _TurAnalytics analytics;
  final bool hasLogs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = analytics.sortedPhrases;
    final first = top.isNotEmpty ? top.first : null;
    final second = top.length > 1 ? top[1] : null;

    String? compareLine;
    if (first != null &&
        second != null &&
        first.value > second.value &&
        second.value > 0) {
      final diff = first.value - second.value;
      compareLine = l10n.zikirmatikCompareLine(first.key, second.key, diff);
    } else if (first != null && top.length == 1) {
      compareLine = l10n.zikirmatikOnlyOneRecord(first.key);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Zc.pageBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Zc.outer.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.zikirmatikSummaryAndAnalytics,
            style: TextStyle(
              color: _Zc.outer.withValues(alpha: 0.95),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasLogs)
            Text(
              l10n.zikirmatikAnalyticsNoLogs,
              style: TextStyle(
                color: _Zc.labelMuted.withValues(alpha: 0.72),
                height: 1.45,
                fontSize: 14,
              ),
            )
          else ...[
            _AnLine(
              icon: Icons.layers_rounded,
              text: l10n.zikirmatikTotalRoundsCompleted(analytics.totalTurs),
            ),
            _AnLine(
              icon: Icons.calendar_month_rounded,
              text: l10n.zikirmatikActiveDays(analytics.activeDays),
            ),
            _AnLine(
              icon: Icons.trending_up_rounded,
              text: l10n.zikirmatikLast7Days(analytics.last7Days),
            ),
            if (first != null)
              _AnLine(
                icon: Icons.star_rounded,
                text: l10n.zikirmatikMostCompleted(first.key, first.value),
              ),
            if (compareLine != null) ...[
              const SizedBox(height: 8),
              Text(
                compareLine,
                style: TextStyle(
                  color: _Zc.labelMuted.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AnLine extends StatelessWidget {
  const _AnLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _Zc.lcdBg.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _Zc.labelMuted.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TurLogTile extends StatelessWidget {
  const _TurLogTile({
    required this.log,
    required this.dateFmt,
    required this.onDelete,
  });

  final ZikirMatikTurLog log;
  final DateFormat dateFmt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Zc.outer.withValues(alpha: 0.4)),
        color: const Color(0xFF15242E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.phrase,
                  style: const TextStyle(
                    color: _Zc.labelMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade300, size: 22),
                tooltip: l10n.zikirmatikDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.zikirmatikRound} ${log.completedTur} ${l10n.zikirmatikCompleted} · '
            '${l10n.zikirmatikTarget} ${log.target} · ${l10n.zikirmatikTotalCounter} ${log.totalCountAtEvent}',
            style: TextStyle(
              color: _Zc.outer.withValues(alpha: 0.92),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFmt.format(log.recordedAt),
            style: TextStyle(
              color: _Zc.labelMuted.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.record,
    required this.onShare,
    required this.onDelete,
  });

  final ZikirMatikRecord record;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = record.savedAt;
    final line = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(d);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Zc.outer.withValues(alpha: 0.28)),
        color: const Color(0xFF121C24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.phrase,
                  style: const TextStyle(
                    color: _Zc.labelMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: onShare,
                icon: Icon(Icons.share_rounded,
                    color: _Zc.lcdBg.withValues(alpha: 0.9), size: 20),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade300, size: 20),
              ),
            ],
          ),
          Text(
            '${record.totalCount} ${l10n.zikirmatikDhikr} · '
            '${l10n.zikirmatikRound} ${record.tur} · ${l10n.zikirmatikTarget} ${record.target}',
            style: TextStyle(color: _Zc.outer.withValues(alpha: 0.85), fontSize: 12),
          ),
          Text(
            line,
            style: TextStyle(
              color: _Zc.labelMuted.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
