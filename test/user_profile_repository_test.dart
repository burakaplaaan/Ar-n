import 'dart:io';

import 'package:arin/core/utils/hive_boxes.dart';
import 'package:arin/data/models/user_profile_model.dart';
import 'package:arin/data/models/user_profile_model.g.dart';
import 'package:arin/data/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arin_profile_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(HiveTypeIds.userProfile)) {
      Hive.registerAdapter(UserProfileModelAdapter());
    }
    await Hive.openBox<UserProfileModel>(HiveBoxes.userProfile);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('profil adi ve cinsiyet Hive yeniden acilinca korunur', () async {
    final repo = UserProfileRepository();

    await repo.saveProfile(
      name: 'Burak',
      gender: 'male',
      moodTags: const ['calm'],
      sectorTags: const ['student'],
      needTags: const ['focus'],
    );

    await Hive.box<UserProfileModel>(HiveBoxes.userProfile).close();
    await Hive.openBox<UserProfileModel>(HiveBoxes.userProfile);

    final reloaded = UserProfileRepository().load();
    expect(reloaded.name, 'Burak');
    expect(reloaded.gender, 'male');
    expect(reloaded.onboardingCompleted, isTrue);

    await UserProfileRepository().updateName('Melih');

    await Hive.box<UserProfileModel>(HiveBoxes.userProfile).close();
    await Hive.openBox<UserProfileModel>(HiveBoxes.userProfile);

    final renamed = UserProfileRepository().load();
    expect(renamed.name, 'Melih');
    expect(renamed.gender, 'male');
  });
}
