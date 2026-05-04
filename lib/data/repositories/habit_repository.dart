// lib/data/repositories/habit_repository.dart
// Alışkanlık ve günlük log CRUD işlemleri.

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/habit_cloud_sync_queue.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/utils/hive_boxes.dart';
import '../../domain/algorithms/streak_calculator.dart';

class HabitRepository {
  Box<HabitModel> get _habitsBox => Hive.box<HabitModel>(HiveBoxes.habits);
  Box<HabitLogModel> get _logsBox =>
      Hive.box<HabitLogModel>(HiveBoxes.habitLogs);
  static const _uuid = Uuid();

  static String _todayKey() {
    final now = DateTime.now();
    return _dateKeyFromDateTime(now);
  }

  static String _dateKeyFromDateTime(DateTime d) {
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Özel alışkanlık: ilerleme kaydı hangi [date] anahtarıyla tutulur (gün / hafta Pazartesi / ayın 1’i).
  static String customPeriodDateKey(HabitModel h) {
    if (!h.isCustomTracked) return _todayKey();
    final n = DateTime.now();
    final day = DateTime(n.year, n.month, n.day);
    switch (h.customRepeatCycle.clamp(0, 2)) {
      case 1:
        final fromMon = day.weekday - DateTime.monday;
        return _dateKeyFromDateTime(day.subtract(Duration(days: fromMon)));
      case 2:
        return '${n.year}-${n.month.toString().padLeft(2, '0')}-01';
      default:
        return _dateKeyFromDateTime(day);
    }
  }

  static DateTime _periodStartContaining(HabitModel h, DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    switch (h.customRepeatCycle.clamp(0, 2)) {
      case 1:
        final fromMon = day.weekday - DateTime.monday;
        return day.subtract(Duration(days: fromMon));
      case 2:
        return DateTime(day.year, day.month, 1);
      default:
        return day;
    }
  }

  static DateTime _previousPeriodStart(HabitModel h, DateTime periodStart) {
    switch (h.customRepeatCycle.clamp(0, 2)) {
      case 1:
        return periodStart.subtract(const Duration(days: 7));
      case 2:
        if (periodStart.month <= 1) {
          return DateTime(periodStart.year - 1, 12, 1);
        }
        return DateTime(periodStart.year, periodStart.month - 1, 1);
      default:
        return periodStart.subtract(const Duration(days: 1));
    }
  }

  int _customPeriodStreak(HabitModel h) {
    final target = h.effectiveDailyTarget;
    final doneKeys = <String>{};
    for (final l in getLogs(h.id)) {
      if (l.progressValue >= target || l.isCompleted) {
        doneKeys.add(l.date);
      }
    }
    if (doneKeys.isEmpty) return 0;

    var periodCursor = _periodStartContaining(h, DateTime.now());
    var periodKey = _dateKeyFromDateTime(periodCursor);

    if (!doneKeys.contains(periodKey)) {
      final prevStart = _previousPeriodStart(h, periodCursor);
      final prevKey = _dateKeyFromDateTime(prevStart);
      if (!doneKeys.contains(prevKey)) return 0;
      periodCursor = prevStart;
      periodKey = prevKey;
    }

    var streak = 0;
    while (doneKeys.contains(periodKey)) {
      streak++;
      periodCursor = _previousPeriodStart(h, periodCursor);
      periodKey = _dateKeyFromDateTime(periodCursor);
    }
    return streak;
  }

  /// Günlük özel takipte (repeatCycle=0) streak hesabı:
  /// `isCompleted` veya `progress >= target` günlerini "tamam" kabul eder.
  int _customDailyStreak(HabitModel h) {
    final target = h.effectiveDailyTarget;
    final completedDates = <String>{};
    for (final l in getLogs(h.id)) {
      if (l.isCompleted || l.progressValue >= target) {
        completedDates.add(l.date);
      }
    }
    if (completedDates.isEmpty) return 0;

    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    var key = _dateKeyFromDateTime(day);

    // Bugün tamam değilse dünü dene; ikisi de değilse streak 0.
    if (!completedDates.contains(key)) {
      day = day.subtract(const Duration(days: 1));
      key = _dateKeyFromDateTime(day);
      if (!completedDates.contains(key)) return 0;
    }

    var streak = 0;
    while (completedDates.contains(key)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
      key = _dateKeyFromDateTime(day);
    }
    return streak;
  }

  static DateTime? _dateKeyToLocalDay(String dateKey) {
    final p = dateKey.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  HabitModel? getById(String id) => _habitsBox.get(id);

  List<HabitModel> getAll() {
    return _habitsBox.values
        .whereType<HabitModel>()
        .where((h) => !h.isArchived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Arşiv dahil tüm alışkanlıklar (bulut senkronu için).
  List<HabitModel> getAllIncludingArchived() {
    return _habitsBox.values.whereType<HabitModel>().toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<HabitModel> getByType(HabitType type) {
    return getAll().where((h) => h.type == type).toList();
  }

  /// Arşivlenmemiş tek bir alışkanlıkta bu şablon var mı (yinelenen program önleme).
  HabitModel? findActiveByTemplateId(String templateId) {
    if (templateId.isEmpty) return null;
    for (final h in getAll()) {
      if (h.isArchived) continue;
      if (h.templateId == templateId) return h;
    }
    return null;
  }

  bool hasActiveTemplate(String templateId) =>
      findActiveByTemplateId(templateId) != null;

  /// Günlük namaz takibi her zaman aktif kalsın: yoksa oluşturur; yalnızca arşivdeyse en yeniyi geri açar.
  Future<void> ensureDefaultSalatHabit() async {
    if (hasActiveTemplate(WillpowerTemplates.salatDaily)) return;

    HabitModel? newestArchived;
    for (final h in _habitsBox.values.whereType<HabitModel>()) {
      if (h.templateId != WillpowerTemplates.salatDaily || !h.isArchived) {
        continue;
      }
      if (newestArchived == null ||
          h.createdAt.compareTo(newestArchived.createdAt) > 0) {
        newestArchived = h;
      }
    }
    if (newestArchived != null) {
      newestArchived.isArchived = false;
      await _habitsBox.put(newestArchived.id, newestArchived);
      await HabitCloudSyncQueue.markHabitDirty(newestArchived.id);
      return;
    }

    await addFromTemplate(
      templateId: WillpowerTemplates.salatDaily,
      title: 'Günlük namaz',
      type: HabitType.good,
      emoji: '🕌',
      onboardingCompleted: false,
    );
  }

  /// Klasik serbest alışkanlık
  Future<HabitModel> add({
    required String title,
    required HabitType type,
    required String emoji,
  }) async {
    final now = DateTime.now().toIso8601String();
    final model = HabitModel(
      id: _uuid.v4(),
      title: title,
      type: type,
      emoji: emoji,
      createdAt: now,
      startedAtIso: now,
      templateId: '',
      onboardingCompleted: true,
    );
    await _habitsBox.put(model.id, model);
    await HabitCloudSyncQueue.markHabitDirty(model.id);
    return model;
  }

  /// Özel takip alanlarıyla (sayaç / süre / yüzde) alışkanlık
  Future<HabitModel> addCustom({
    required String title,
    required HabitType type,
    required String emoji,
    String note = '',
    required int customTarget,
    required String customUnit,
    required int customTrackingKind,
    required bool customFlexible,
    required int customMinTarget,
    int customRepeatCycle = 0,
  }) async {
    final now = DateTime.now().toIso8601String();
    final model = HabitModel(
      id: _uuid.v4(),
      title: title,
      type: type,
      emoji: emoji,
      createdAt: now,
      startedAtIso: now,
      templateId: WillpowerTemplates.customTracked,
      onboardingCompleted: true,
      note: note.trim(),
      customTarget: customTarget.clamp(1, 999999),
      customUnit: customUnit,
      customTrackingKind: customTrackingKind.clamp(0, 2),
      customFlexible: customFlexible,
      customMinTarget: customMinTarget.clamp(0, 999999),
      customRepeatCycle: customRepeatCycle.clamp(0, 2),
    );
    await _habitsBox.put(model.id, model);
    await HabitCloudSyncQueue.markHabitDirty(model.id);
    return model;
  }

  HabitLogModel? logForDay(String habitId, String dateKey) {
    return _logsBox.get('${habitId}_$dateKey');
  }

  int todayProgressValue(String habitId) {
    final h = getById(habitId);
    final dateKey = (h != null && h.isCustomTracked)
        ? customPeriodDateKey(h)
        : _todayKey();
    final log = logForDay(habitId, dateKey);
    return log?.progressValue ?? 0;
  }

  Future<void> addProgressToday(String habitId, int delta) async {
    final h = getById(habitId);
    if (h == null || !h.isCustomTracked) return;
    final dateKey = customPeriodDateKey(h);
    final key = '${habitId}_$dateKey';
    final existing = _logsBox.get(key);
    var next = (existing?.progressValue ?? 0) + delta;
    if (next < 0) next = 0;
    final cap = h.effectiveDailyTarget;
    if (next > cap) next = cap;
    final done = next >= cap;
    await _logsBox.put(
      key,
      HabitLogModel(
        habitId: habitId,
        date: dateKey,
        isCompleted: done,
        progressValue: next,
      ),
    );
    await HabitCloudSyncQueue.markLogDirty(key);
  }

  Future<void> fillProgressToday(String habitId) async {
    final h = getById(habitId);
    if (h == null || !h.isCustomTracked) return;
    final cap = h.effectiveDailyTarget;
    final dateKey = customPeriodDateKey(h);
    final key = '${habitId}_$dateKey';
    await _logsBox.put(
      key,
      HabitLogModel(
        habitId: habitId,
        date: dateKey,
        isCompleted: true,
        progressValue: cap,
      ),
    );
    await HabitCloudSyncQueue.markLogDirty(key);
  }

  Future<void> updateHabitNote(String habitId, String note) async {
    final h = getById(habitId);
    if (h == null) return;
    h.note = note.trim();
    await h.save();
    await HabitCloudSyncQueue.markHabitDirty(habitId);
  }

  /// İrade şablonundan program
  Future<HabitModel> addFromTemplate({
    required String templateId,
    required String title,
    required HabitType type,
    required String emoji,
    String commitmentText = '',
    String? quitSubtype,
    String? quitMethod,
    bool onboardingCompleted = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final model = HabitModel(
      id: _uuid.v4(),
      title: title,
      type: type,
      emoji: emoji,
      createdAt: now,
      startedAtIso: now,
      templateId: templateId,
      commitmentText: commitmentText,
      quitSubtype: quitSubtype,
      quitMethod: quitMethod,
      onboardingCompleted: onboardingCompleted,
    );
    await _habitsBox.put(model.id, model);
    await HabitCloudSyncQueue.markHabitDirty(model.id);
    return model;
  }

  Future<void> save(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
    await HabitCloudSyncQueue.markHabitDirty(habit.id);
  }

  Future<void> saveFromCloud(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  /// Firestore geri yükleme — log anahtarı `habitId_yyyy-MM-dd`.
  Future<void> upsertLog(HabitLogModel log) async {
    await _logsBox.put(log.logKey, log);
    await HabitCloudSyncQueue.markLogDirty(log.logKey);
  }

  Future<void> upsertLogFromCloud(HabitLogModel log) async {
    await _logsBox.put(log.logKey, log);
  }

  /// Buluttan namaz alışkanlığı geldiğinde yerelde otomatik oluşan yineleneni arşivler.
  Future<void> dedupeActiveSalatPreferringCloudIds(
    Set<String> cloudHabitIds,
  ) async {
    final candidates = _habitsBox.values
        .whereType<HabitModel>()
        .where(
          (h) => h.templateId == WillpowerTemplates.salatDaily && !h.isArchived,
        )
        .toList();
    if (candidates.length <= 1) return;

    HabitModel? keep;
    for (final h in candidates) {
      if (cloudHabitIds.contains(h.id)) {
        keep = h;
        break;
      }
    }
    keep ??= candidates.first;

    final keepId = keep.id;
    for (final h in candidates) {
      if (h.id == keepId) continue;
      h.isArchived = true;
      await h.save();
      await HabitCloudSyncQueue.markHabitDirty(h.id);
    }
  }

  Future<void> completeQuitOnboarding({
    required String habitId,
    required String commitmentText,
    String? quitMethod,
  }) async {
    final h = getById(habitId);
    if (h == null) return;
    h.commitmentText = commitmentText;
    h.onboardingCompleted = true;
    if (quitMethod != null) h.quitMethod = quitMethod;
    await h.save();
    await HabitCloudSyncQueue.markHabitDirty(habitId);
  }

  Future<void> archive(String id) async {
    final habit = _habitsBox.get(id);
    if (habit == null) return;
    habit.isArchived = true;
    await habit.save();
    await HabitCloudSyncQueue.markHabitDirty(id);
  }

  /// Alışkanlığı ve ona bağlı tüm günlük logları kalıcı olarak siler.
  Future<void> deletePermanently(String id) async {
    final prefix = '${id}_';
    final logKeys = _logsBox.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList(growable: false);
    for (final k in logKeys) {
      await _logsBox.delete(k);
    }
    await _habitsBox.delete(id);
    await HabitCloudSyncQueue.markHabitDeleted(id);
  }

  /// Belirli gün için tamamlandı bayrağı (namaz 5/5 senkronu vb.)
  Future<void> setCompletedForDay(
    String habitId,
    String dateKey,
    bool completed,
  ) async {
    final key = '${habitId}_$dateKey';
    final existing = _logsBox.get(key);
    final h = getById(habitId);
    final target = h?.effectiveDailyTarget ?? 1;
    final progress = (h != null && h.isCustomTracked && completed)
        ? target
        : (existing?.progressValue ?? 0);

    if (existing != null) {
      existing.isCompleted = completed;
      existing.progressValue = progress;
      await existing.save();
    } else {
      await _logsBox.put(
        key,
        HabitLogModel(
          habitId: habitId,
          date: dateKey,
          isCompleted: completed,
          progressValue: progress,
        ),
      );
    }
    await HabitCloudSyncQueue.markLogDirty(key);
  }

  Future<bool> toggleToday(String habitId) async {
    final h = getById(habitId);
    if (h != null && h.isCustomTracked) {
      final dateKey = customPeriodDateKey(h);
      final key = '${habitId}_$dateKey';
      final done = isCompletedToday(habitId);
      if (done) {
        await _logsBox.delete(key);
        await HabitCloudSyncQueue.markLogDeleted(key);
        return false;
      }
      final cap = h.effectiveDailyTarget;
      await _logsBox.put(
        key,
        HabitLogModel(
          habitId: habitId,
          date: dateKey,
          isCompleted: true,
          progressValue: cap,
        ),
      );
      await HabitCloudSyncQueue.markLogDirty(key);
      return true;
    }

    final key = '${habitId}_${_todayKey()}';
    final existing = _logsBox.get(key);

    if (existing != null) {
      existing.isCompleted = !existing.isCompleted;
      await existing.save();
      await HabitCloudSyncQueue.markLogDirty(key);
      return existing.isCompleted;
    } else {
      final log = HabitLogModel(
        habitId: habitId,
        date: _todayKey(),
        isCompleted: true,
      );
      await _logsBox.put(key, log);
      await HabitCloudSyncQueue.markLogDirty(key);
      return true;
    }
  }

  HabitLogModel? logByKey(String logKey) {
    return _logsBox.get(logKey);
  }

  List<HabitLogModel> getLogs(String habitId) {
    return _logsBox.values
        .whereType<HabitLogModel>()
        .where((l) => l.habitId == habitId)
        .toList();
  }

  int getStreak(String habitId) {
    final h = getById(habitId);
    if (h != null && h.isCustomTracked) {
      if (h.customRepeatCycle != 0) {
        return _customPeriodStreak(h);
      }
      return _customDailyStreak(h);
    }
    final logs = getLogs(habitId);
    return StreakCalculator.calculate(logs);
  }

  int quitCleanDayCount(String habitId) {
    final logs = getLogs(habitId);
    return logs.where((l) => l.isCompleted).length;
  }

  /// Bırakma sayacı başlangıcından bu yana tam gün (ISO farkı, negatifse 0).
  int elapsedQuitDays(String habitId) {
    final h = getById(habitId);
    if (h == null) return 0;
    final iso = h.quitClockStartedAtIso;
    if (iso == null || iso.isEmpty) return 0;
    final start = DateTime.tryParse(iso);
    if (start == null) return 0;
    final diff = DateTime.now().difference(start);
    final d = diff.inDays;
    return d < 0 ? 0 : d;
  }

  /// Bırakma anından şu ana (sayaç yoksa null).
  Duration? quitElapsedSinceClock(String habitId) {
    final h = getById(habitId);
    if (h == null) return null;
    final iso = h.quitClockStartedAtIso;
    if (iso == null || iso.isEmpty) return null;
    final start = DateTime.tryParse(iso);
    if (start == null) return null;
    final d = DateTime.now().difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> setQuitClockNow(String habitId, [DateTime? when]) async {
    final h = getById(habitId);
    if (h == null) return;
    h.quitClockStartedAtIso = (when ?? DateTime.now()).toIso8601String();
    await h.save();
    await HabitCloudSyncQueue.markHabitDirty(habitId);
  }

  /// Kriz anında kullanıcının onboarding'i tamamlamadan sayacı başlatabilmesi
  /// için kısa yol: sadece clock kurar, `onboardingCompleted` false kalır —
  /// böylece kullanıcı ahdini/detayları sonra tamamlayabilir. Program home
  /// sayfası clock varken onboarding'e redirect etmez (bkz. program home
  /// yönlendirme koşulu).
  Future<void> quickStartQuitClock(String habitId) async {
    final h = getById(habitId);
    if (h == null) return;
    h.quitClockStartedAtIso ??= DateTime.now().toIso8601String();
    await h.save();
    await HabitCloudSyncQueue.markHabitDirty(habitId);
  }

  /// Sayaç + tüm günlük logları sıfırla (yeniden başla).
  ///
  /// [preserveHistory] true ise önceki denemenin logları silinmez; yalnızca
  /// `quitClockStartedAtIso` sıfırlanır → kullanıcı sayaç sıfırdan başlar ama
  /// eski istatistikler, streak'ler ve milestone'lar kayıtta kalır.
  /// Varsayılan false → eski "tamamen sıfırla" davranışı.
  Future<void> restartQuitProgram(
    String habitId, {
    bool preserveHistory = false,
  }) async {
    final h = getById(habitId);
    if (h == null) return;
    h.quitClockStartedAtIso = null;
    await h.save();
    await HabitCloudSyncQueue.markHabitDirty(habitId);
    if (preserveHistory) return;
    final keys = _logsBox.keys
        .where((k) => k.toString().startsWith('${habitId}_'))
        .toList();
    for (final k in keys) {
      await _logsBox.delete(k);
      await HabitCloudSyncQueue.markLogDeleted(k.toString());
    }
  }

  /// Pazartesi=0 … Pazar=6; o hafta her gün için tik var mı.
  List<bool> quitWeekCompletionFlags(String habitId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mondayOffset = today.weekday - DateTime.monday;
    final monday = today.subtract(Duration(days: mondayOffset));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final key =
          '${habitId}_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final log = _logsBox.get(key);
      return log?.isCompleted == true;
    });
  }

  int quitWeekCompletedCount(String habitId) =>
      quitWeekCompletionFlags(habitId).where((v) => v).length;

  /// Bırakma tarihinden bugüne kadar işaretlenen temiz gün / geçen gün oranı (%).
  double quitSuccessRateSinceClockPercent(String habitId) {
    final h = getById(habitId);
    if (h == null || h.quitClockStartedAtIso == null) return 0;
    final start = DateTime.tryParse(h.quitClockStartedAtIso!);
    if (start == null) return 0;
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final total = todayDay.difference(startDay).inDays + 1;
    if (total <= 0) return 0;
    final logs = getLogs(habitId);
    var completed = 0;
    for (final l in logs) {
      if (!l.isCompleted) continue;
      final day = _dateKeyToLocalDay(l.date);
      if (day == null) continue;
      if (!day.isBefore(startDay) && !day.isAfter(todayDay)) {
        completed++;
      }
    }
    return (completed * 100 / total).clamp(0, 100);
  }

  /// `yyyy-MM-dd` gününde günlük tamamlandı kaydı var mı (iyi alışkanlık tikleri, namaz 5/5 vb.).
  bool isCompletedOnDay(String habitId, DateTime day) {
    final k =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final log = _logsBox.get('${habitId}_$k');
    if (log == null) return false;
    if (log.isCompleted) return true;
    final h = getById(habitId);
    if (h != null && h.isCustomTracked) {
      return log.progressValue >= h.effectiveDailyTarget;
    }
    return false;
  }

  bool isCompletedToday(String habitId) {
    final h = getById(habitId);
    if (h != null && h.isCustomTracked) {
      final dateKey = customPeriodDateKey(h);
      final key = '${habitId}_$dateKey';
      final log = _logsBox.get(key);
      if (log == null) return false;
      if (log.isCompleted) return true;
      return log.progressValue >= h.effectiveDailyTarget;
    }
    return StreakCalculator.isCompletedToday(getLogs(habitId));
  }

  List<({HabitModel habit, int streak, bool completedToday})> getSummary() {
    return getAll()
        .map(
          (h) => (
            habit: h,
            streak: getStreak(h.id),
            completedToday: isCompletedToday(h.id),
          ),
        )
        .toList();
  }
}
