import 'dart:io';

import 'package:arin/core/constants/willpower_templates.dart';
import 'package:arin/core/utils/hive_boxes.dart';
import 'package:arin/data/models/habit_log_model.dart';
import 'package:arin/data/models/habit_log_model.g.dart';
import 'package:arin/data/models/habit_model.dart';
import 'package:arin/data/models/habit_model.g.dart';
import 'package:arin/data/repositories/habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('arin_salat_seed_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(HiveTypeIds.habitType)) {
      Hive.registerAdapter(HabitTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.habit)) {
      Hive.registerAdapter(HabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.habitLog)) {
      Hive.registerAdapter(HabitLogModelAdapter());
    }
    await Hive.openBox<HabitModel>(HiveBoxes.habits);
    await Hive.openBox<HabitLogModel>(HiveBoxes.habitLogs);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('ensureDefaultSalatHabit kurulumu tamamlanmış alışkanlık üretir', () async {
    final repo = HabitRepository();
    await repo.ensureDefaultSalatHabit();
    final habit = repo.findActiveByTemplateId(WillpowerTemplates.salatDaily);
    expect(habit, isNotNull);
    expect(habit!.onboardingCompleted, isTrue);
    expect(habit.commitmentText.trim(), isNotEmpty);
    expect(habit.isArchived, isFalse);
  });

  test('eksik onboarding tamamlanır', () async {
    final repo = HabitRepository();
    await repo.addFromTemplate(
      templateId: WillpowerTemplates.salatDaily,
      title: 'Günlük namaz',
      type: HabitType.good,
      emoji: '🕌',
      onboardingCompleted: false,
      commitmentText: '',
    );
    await repo.ensureDefaultSalatHabit();
    final habit = repo.findActiveByTemplateId(WillpowerTemplates.salatDaily);
    expect(habit!.onboardingCompleted, isTrue);
    expect(habit.commitmentText, WillpowerTemplates.defaultSalatCommitment);
  });

  test('seedDefaultSalatTracking ana sayfa görünürlüğünü açar', () async {
    SharedPreferences.setMockInitialValues({
      WillpowerTemplates.salatVisibleOnHomePrefKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    await HabitRepository.seedDefaultSalatTracking(prefs);
    expect(prefs.getBool(WillpowerTemplates.salatVisibleOnHomePrefKey), isTrue);
    expect(prefs.getBool(WillpowerTemplates.salatPreinstalledPrefKey), isTrue);
    final repo = HabitRepository();
    expect(repo.findActiveByTemplateId(WillpowerTemplates.salatDaily), isNotNull);
  });

  test('preinstall sonrası gizleme korunur', () async {
    SharedPreferences.setMockInitialValues({
      WillpowerTemplates.salatVisibleOnHomePrefKey: false,
      WillpowerTemplates.salatPreinstalledPrefKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await HabitRepository.seedDefaultSalatTracking(prefs);
    expect(prefs.getBool(WillpowerTemplates.salatVisibleOnHomePrefKey), isFalse);
  });

  test('arşivlenmiş namaz alışkanlığı geri açılır', () async {
    final repo = HabitRepository();
    final now = DateTime.now().toIso8601String();
    await repo.save(
      HabitModel(
        id: 'archived-salat',
        title: 'Günlük namaz',
        type: HabitType.good,
        emoji: '🕌',
        createdAt: now,
        isArchived: true,
        templateId: WillpowerTemplates.salatDaily,
        onboardingCompleted: true,
        commitmentText: WillpowerTemplates.defaultSalatCommitment,
      ),
    );
    await repo.ensureDefaultSalatHabit();
    final habit = repo.findActiveByTemplateId(WillpowerTemplates.salatDaily);
    expect(habit, isNotNull);
    expect(habit!.id, 'archived-salat');
    expect(habit.isArchived, isFalse);
  });

  test('eski yedek ana sayfa kurulumunu geri almaz', () async {
    SharedPreferences.setMockInitialValues({
      WillpowerTemplates.salatVisibleOnHomePrefKey: true,
      WillpowerTemplates.salatPreinstalledPrefKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await HabitRepository.applyImportedSalatHomeVisibility(
      prefs,
      incomingVisible: false,
      backupKnowsPreinstall: false,
    );
    expect(prefs.getBool(WillpowerTemplates.salatVisibleOnHomePrefKey), isTrue);
  });

  test('yeni yedekte gizleme uygulanır', () async {
    SharedPreferences.setMockInitialValues({
      WillpowerTemplates.salatVisibleOnHomePrefKey: true,
      WillpowerTemplates.salatPreinstalledPrefKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await HabitRepository.applyImportedSalatHomeVisibility(
      prefs,
      incomingVisible: false,
      backupKnowsPreinstall: true,
    );
    expect(prefs.getBool(WillpowerTemplates.salatVisibleOnHomePrefKey), isFalse);
  });
}
