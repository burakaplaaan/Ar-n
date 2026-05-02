// lib/data/models/user_profile_model.g.dart
// Hive type adapter - manuel yazılmıştır (build_runner gerektirmez).
// user_profile_model.dart ile aynı TypeId kullanılır.

import 'package:hive/hive.dart';
import 'user_profile_model.dart';

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 0;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      moodTags: (fields[0] as List).cast<String>(),
      sectorTags: (fields[1] as List).cast<String>(),
      needTags: (fields[2] as List).cast<String>(),
      lastSurveyDate: fields[3] as String?,
      onboardingCompleted: fields[4] as bool,
      name: fields[5] as String?,
      gender: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.moodTags)
      ..writeByte(1)
      ..write(obj.sectorTags)
      ..writeByte(2)
      ..write(obj.needTags)
      ..writeByte(3)
      ..write(obj.lastSurveyDate)
      ..writeByte(4)
      ..write(obj.onboardingCompleted)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.gender);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
