// lib/data/repositories/user_profile_repository.dart
// Kullanıcı profili CRUD işlemleri.

import 'package:hive/hive.dart';
import '../models/user_profile_model.dart';
import '../../core/utils/hive_boxes.dart';

class UserProfileRepository {
  /// Hive.box(name) tek başına E=dynamic çıkarır; kutu Box<UserProfileModel>
  /// iken HiveError: "already open and of type Box<UserProfileModel>" verir.
  Box<UserProfileModel> get _box =>
      Hive.box<UserProfileModel>(HiveBoxes.userProfile);
  static const _profileKey = 'profile';

  /// Profili yükle (yoksa boş oluştur)
  UserProfileModel load() {
    final data = _box.get(_profileKey);
    if (data is UserProfileModel) return data;
    return UserProfileModel.empty();
  }

  /// Profili kaydet
  Future<void> save(UserProfileModel profile) async {
    await _box.put(_profileKey, profile);
  }

  /// Tüm profil verilerini kaydet (Yeni Onboarding V2)
  Future<void> saveProfile({
    String? name,
    String? gender,
    required List<String> moodTags,
    required List<String> sectorTags,
    required List<String> needTags,
  }) async {
    final profile = load();
    profile.name = name;
    profile.gender = gender;
    profile.moodTags = moodTags;
    profile.sectorTags = sectorTags;
    profile.needTags = needTags;
    profile.lastSurveyDate = DateTime.now().toIso8601String();
    profile.onboardingCompleted = true; // Anket bitince onboarding tamamlanır
    await save(profile);
  }

  /// Etiketleri güncelle (Haftalık anket)
  Future<void> updateTags({
    required List<String> moodTags,
    required List<String> sectorTags,
    required List<String> needTags,
  }) async {
    final profile = load();
    profile.moodTags = moodTags;
    profile.sectorTags = sectorTags;
    profile.needTags = needTags;
    profile.lastSurveyDate = DateTime.now().toIso8601String();
    await save(profile);
  }

  /// Onboarding tamamlandı mı kontrolü
  bool get isOnboardingCompleted => load().onboardingCompleted;

  /// Onboarding'i tamamlandı olarak işaretle
  Future<void> completeOnboarding() async {
    final profile = load();
    profile.onboardingCompleted = true;
    await save(profile);
  }

  /// Haftalık anket gerekli mi? (7 günden fazla geçtiyse)
  bool get isWeeklySurveyDue {
    final profile = load();
    if (profile.lastSurveyDate == null) return true;
    final last = DateTime.parse(profile.lastSurveyDate!);
    return DateTime.now().difference(last).inDays >= 7;
  }
}
