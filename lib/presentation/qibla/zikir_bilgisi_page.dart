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
import '../shared/widgets/arin_back_button.dart';

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

const List<String> _kZikirDailyReflectionsEn = <String>[
  'Dhikr is the art of quieting the heart’s endless, restless murmur.',
  'Every word that leaves the tongue is a raindrop washing the dust from the soul.',
  'When you are lost in the world’s noise, you find yourself by remembering His name, not your own.',
  'Dhikr is the most sincere and deepest whisper echoing inside silence.',
  'Turning each heartbeat into a bead of praise brings a calm rhythm to life.',
  'As the words fall from the lips, you feel that vast inner emptiness fill with mercy.',
  'Dhikr is the shortest path out of the mind’s labyrinths and into the wide plains of the heart.',
  'When you are drowning in forgetfulness, remembering with a single word is the soul’s lifeline.',
  'If you want to still the storms within, train the tongue on the dhikr of peace.',
  'Each remembrance is a small, graceful candle left in the dark corners of the soul.',
  'Against time’s harsh current, it is an unbreakable bond tying the heart to eternity.',
  'Dhikr is the most meaningful and quiet pause a person can give themselves.',
  'Every beautiful word you say is a flower opening in the garden of the soul.',
  'When the mind is heavy with thoughts, dhikr sets the excess aside.',
  'Polishing the heart with the power of words lets you see the world more clearly.',
  'Dhikr is a hidden companion whispering, in the middle of loneliness, that you are not abandoned.',
  'It is the gentlest cleansing: it wipes rust from the heart and brightens the soul’s mirror.',
  'Remembering Him with every breath turns each second of life into a meaningful poem.',
  'Dhikr is the thin line where anxiety ends and trust begins.',
  'Every meeting of tongue and palate is a meeting of the soul with the sky.',
  'For eyes tired of the world’s false colors, dhikr is the purest white.',
  'Finding a “Hu” in every heartbeat is touching the essence of being.',
  'Dhikr is a soft, peaceful velvet laid over the heart.',
  'To reach that deep silence beyond words, dhikr is the surest bridge.',
  'Making peace with oneself begins when the tongue remembers love.',
  'Dhikr is a balm that binds the soul’s wound and eases what is bleeding.',
  'It is holding onto that greatest power the eye cannot see and the heart can feel.',
  'Each prayer bead is letting a tired worry slip from the fingertips.',
  'Dhikr reminds us that breathing is not only biological, but spiritual.',
  'That single name echoing in the heart’s deepest room is the most peaceful answer.',
];

const List<String> _kZikirDailyReflectionsAr = <String>[
  'الذكر فنّ تهدئة همهمة القلب التي لا تعرف الكلل.',
  'كل كلمة تخرج من اللسان قطرة مطر تنظّف غبار الروح شيئاً فشيئاً.',
  'إذا تِهتَ في ضجيج الدنيا وجدتَ نفسك بذكر اسمه لا باسمك.',
  'الذكر أصدق همسة وأعمقها تتردد في داخل الصمت.',
  'تحويل نبضات القلب إلى حبّات تسبيح يمنح الحياة إيقاعاً من السكينة.',
  'كلما تساقطت الكلمات من الشفتين شعرتَ أن الفراغ الواسع في داخلك يمتلئ رحمة.',
  'الذكر أقصر طريق للخروج من متاهات العقل إلى سهول القلب الواسعة.',
  'حين تغرق في بحر النسيان يكون التذكّر بكلمة واحدة طوق نجاة الروح.',
  'إن أردت تسكين العواصف في داخلك فعوّد لسانك على ذكر السكينة.',
  'كل ذكر شمعة صغيرة رقيقة تُترك في زوايا الروح المظلمة.',
  'في وجه جريان الزمن القاسي هو رباط لا ينقطع يربط القلب بالأبد.',
  'الذكر أعمق وأهدأ استراحة يهبها الإنسان لنفسه.',
  'كل كلمة جميلة تقولها زهرة تتفتح في حديقة روحك.',
  'إذا ثقل العقل بأعباء الأفكار نحّى الذكر كل الزوائد جانباً.',
  'جلاء القلب بقوة الكلمات يجعلك ترى الدنيا أوضح.',
  'الذكر رفيق خفيّ يهمس في وسط الوحدة أنك لست وحيداً.',
  'هو ألطف تطهير: يمسح صدأ القلب ويُشرق مرآة الروح.',
  'ذكره مع كل نفس يحوّل كل ثانية من الحياة إلى قصيدة ذات معنى.',
  'الذكر ذلك الخط الرفيع حيث ينتهي القلق ويبدأ الاطمئنان.',
  'كل التقاء للسان بالحنك التقاء للروح بالسماء.',
  'لعيون تعبت من ألوان الدنيا الزائفة الذكر هو الأبيض الأنقى.',
  'أن تجد «هو» في كل نبضة قلب هو أن تلمس جوهر الوجود.',
  'الذكر غطاء مخملي ناعم هادئ يُفرش على القلب.',
  'للوصول إلى ذلك الصمت العميق وراء الكلمات، الذكر هو الجسر الأكثر أماناً.',
  'التصالح مع الذات يبدأ حين يذكر اللسان الحب.',
  'الذكر مرهم يضمّد جرح الروح ويسكّن ما ينزف.',
  'هو التمسك بتلك القوة العظمى التي لا تراها العين ويشعر بها القلب.',
  'كل حبّة سبحة هي ترك همّ يتعبك ينزلق من أطراف أصابعك.',
  'الذكر يذكّرنا أن التنفس ليس فعلاً بيولوجياً فحسب، بل روحياً.',
  'ذلك الاسم الواحد الذي يتردد في أعمق غرفة في القلب هو الجواب الأكثر سلاماً.',
];

int zikirDailyReflectionIndex({
  required DateTime now,
  required int length,
}) {
  if (length <= 0) return 0;
  final day = DateTime(now.year, now.month, now.day);
  final origin = DateTime(2020, 1, 1);
  return day.difference(origin).inDays.abs() % length;
}

List<String> _zikirDailyReflections(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') return _kZikirDailyReflectionsEn;
  if (locale == 'ar') return _kZikirDailyReflectionsAr;
  return _kZikirDailyReflections;
}

String _zikirDateLocale(BuildContext context) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return 'ar';
    case 'en':
      return 'en';
    default:
      return 'tr';
  }
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
    final dateStr =
        DateFormat('dd.MM.yyyy HH:mm', _zikirDateLocale(context)).format(d);
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
    final reflections = _zikirDailyReflections(context);
    final text = reflections[zikirDailyReflectionIndex(
      now: DateTime.now(),
      length: reflections.length,
    )];
    final analytics = _computeAnalytics(_turLogs);
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm', _zikirDateLocale(context));

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
                    ArinBackButton(
                      onPressed: () => Navigator.of(context).pop(),
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
      compareLine = l10n.zikirmatikCompareLine(diff, first.key, second.key);
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
    final line =
        DateFormat('dd.MM.yyyy HH:mm', _zikirDateLocale(context)).format(d);
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
