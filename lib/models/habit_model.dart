import 'package:isar/isar.dart';

part 'habit_model.g.dart';

enum FrequencyType { daily, weekly, monthly, custom }

@collection
class HabitModel {
  Id id = Isar.autoIncrement;

  String? title;
  DateTime? startDate;
  int currentStreak = 0;
  DateTime? lastCompletedDate;
  bool isCompleted = false;

  int position = 0;

  @enumerated
  FrequencyType frequencyType = FrequencyType.daily;

  List<int>? daysOfWeek;

  HabitModel({
    this.title,
    this.startDate,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.isCompleted = false,
    this.position = 0,
    this.frequencyType = FrequencyType.daily,
    this.daysOfWeek,
  });

  @override
  String toString() {
    return 'HabitModel(id: $id, title: $title, '
        'frequencyType: $frequencyType, daysOfWeek: $daysOfWeek, '
        'currentStreak: $currentStreak, isCompleted: $isCompleted, '
        'lastCompletedDate: $lastCompletedDate, position: $position)';
  }
}
