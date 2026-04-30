// lib/data/models/habit_model.g.dart
// Hive type adapter'ları — HabitType enum ve HabitModel (manuel).

import 'package:hive/hive.dart';
import 'habit_model.dart';

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 10;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.good;
      case 1:
        return HabitType.bad;
      default:
        return HabitType.good;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.good:
        writer.writeByte(0);
      case HabitType.bad:
        writer.writeByte(1);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 1;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final created = fields[4] as String;
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as HabitType,
      emoji: fields[3] as String,
      createdAt: created,
      isArchived: fields[5] as bool? ?? false,
      templateId: fields[6] as String? ?? '',
      startedAtIso: fields[7] as String? ?? created,
      commitmentText: fields[8] as String? ?? '',
      quitSubtype: fields[9] as String?,
      quitMethod: fields[10] as String?,
      onboardingCompleted: fields[11] as bool? ?? true,
      quitClockStartedAtIso: fields[12] as String?,
      note: fields[13] as String? ?? '',
      customTarget: fields[14] as int? ?? 1,
      customUnit: fields[15] as String? ?? 'kez',
      customTrackingKind: fields[16] as int? ?? 0,
      customFlexible: fields[17] as bool? ?? false,
      customMinTarget: fields[18] as int? ?? 0,
      customRepeatCycle: fields[19] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isArchived)
      ..writeByte(6)
      ..write(obj.templateId)
      ..writeByte(7)
      ..write(obj.startedAtIso)
      ..writeByte(8)
      ..write(obj.commitmentText)
      ..writeByte(9)
      ..write(obj.quitSubtype)
      ..writeByte(10)
      ..write(obj.quitMethod)
      ..writeByte(11)
      ..write(obj.onboardingCompleted)
      ..writeByte(12)
      ..write(obj.quitClockStartedAtIso)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.customTarget)
      ..writeByte(15)
      ..write(obj.customUnit)
      ..writeByte(16)
      ..write(obj.customTrackingKind)
      ..writeByte(17)
      ..write(obj.customFlexible)
      ..writeByte(18)
      ..write(obj.customMinTarget)
      ..writeByte(19)
      ..write(obj.customRepeatCycle);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModelAdapter && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
