// lib/data/models/habit_log_model.dart
// Günlük alışkanlık tamamlama kaydı.

import 'package:hive/hive.dart';
import '../../core/utils/hive_boxes.dart';


@HiveType(typeId: HiveTypeIds.habitLog)
class HabitLogModel extends HiveObject {
  @HiveField(0)
  String habitId;

  /// Tarih: "yyyy-MM-dd" formatında saklanır
  @HiveField(1)
  String date;

  @HiveField(2)
  bool isCompleted;

  /// Günlük sayaç/süre/yüzde ilerlemesi (özel alışkanlıklar)
  @HiveField(3)
  int progressValue;

  HabitLogModel({
    required this.habitId,
    required this.date,
    required this.isCompleted,
    this.progressValue = 0,
  });

  /// Benzersiz anahtar: habitId + date
  String get logKey => '${habitId}_$date';
}
