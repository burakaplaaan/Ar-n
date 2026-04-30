// lib/data/models/habit_log_model.g.dart
// HabitLogModel için manuel Hive TypeAdapter.

import 'package:hive/hive.dart';
import 'habit_log_model.dart';

class HabitLogModelAdapter extends TypeAdapter<HabitLogModel> {
  @override
  final int typeId = 2;

  @override
  HabitLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLogModel(
      habitId: fields[0] as String,
      date: fields[1] as String,
      isCompleted: fields[2] as bool,
      progressValue: fields[3] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.progressValue);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogModelAdapter && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
