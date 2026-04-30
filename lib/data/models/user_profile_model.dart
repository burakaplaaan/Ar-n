// lib/data/models/user_profile_model.dart
// Hive ile saklanan kullanıcı profili modeli.
// Anket cevapları (etiketler) ve son anket tarihi burada tutulur.

import 'package:hive/hive.dart';
import '../../core/utils/hive_boxes.dart';


@HiveType(typeId: HiveTypeIds.userProfile)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  List<String> moodTags;

  @HiveField(1)
  List<String> sectorTags;

  @HiveField(2)
  List<String> needTags;

  @HiveField(3)
  String? lastSurveyDate; // ISO 8601

  @HiveField(4)
  bool onboardingCompleted;

  @HiveField(5)
  String? name;

  @HiveField(6)
  String? gender;

  UserProfileModel({
    required this.moodTags,
    required this.sectorTags,
    required this.needTags,
    this.lastSurveyDate,
    this.onboardingCompleted = false,
    this.name,
    this.gender,
  });

  /// Tüm etiketleri birleştirir
  List<String> get allTags => [...moodTags, ...sectorTags, ...needTags];

  factory UserProfileModel.empty() => UserProfileModel(
        moodTags: [],
        sectorTags: [],
        needTags: [],
        onboardingCompleted: false,
        name: null,
        gender: null,
      );
}
