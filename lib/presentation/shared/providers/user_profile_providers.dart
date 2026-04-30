// lib/presentation/shared/providers/user_profile_providers.dart
// Riverpod provider'ları — Kullanıcı profili ve içerik eşleştirme.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../domain/algorithms/content_matcher.dart';
import '../../../domain/algorithms/user_content_tags.dart';
import '../../../domain/entities/matched_content.dart';
import 'quotes_providers.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (_) => UserProfileRepository(),
);

/// Kullanıcı profil state notifier'ı
class UserProfileNotifier extends StateNotifier<UserProfileModel> {
  final UserProfileRepository _repo;

  UserProfileNotifier(this._repo) : super(_repo.load());

  Future<void> saveProfile({
    String? name,
    String? gender,
    required List<String> moodTags,
    required List<String> sectorTags,
    required List<String> needTags,
  }) async {
    await _repo.saveProfile(
      name: name,
      gender: gender,
      moodTags: moodTags,
      sectorTags: sectorTags,
      needTags: needTags,
    );
    state = _repo.load(); // state'i tazele
  }

  Future<void> updateTags({
    required List<String> moodTags,
    required List<String> sectorTags,
    required List<String> needTags,
  }) async {
    await _repo.updateTags(
      moodTags: moodTags,
      sectorTags: sectorTags,
      needTags: needTags,
    );
    state = _repo.load();
  }

  Future<void> completeOnboarding() async {
    await _repo.completeOnboarding();
    state = _repo.load();
  }

  bool get isWeeklySurveyDue => _repo.isWeeklySurveyDue;
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileModel>(
  (ref) => UserProfileNotifier(ref.watch(userProfileRepositoryProvider)),
);

/// Günün sözü: Firestore paketi (günde 1 okuma) + Hive önbellek; yoksa asset havuzu.
final dailyContentProvider = FutureProvider<MatchedContent>((ref) async {
  final profile = ref.watch(userProfileProvider);
  final quotesRepo = ref.watch(quotesCloudRepositoryProvider);
  await quotesRepo.ensureSyncedToday();
  final cloud = quotesRepo.cachedPoolIfAny();
  final tags = UserContentTags.fromSelections(
    moodTags: profile.moodTags,
    sectorTags: profile.sectorTags,
    needTags: profile.needTags,
  );
  return ContentMatcher.todaysContentHybrid(
    tags,
    cloudPool: cloud,
  );
});
