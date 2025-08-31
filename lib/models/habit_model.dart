import 'package:isar/isar.dart';

part 'habit_model.g.dart';

@collection
class HabitModel {
  Id id = Isar.autoIncrement;

  String? title;
  DateTime? startDate;
  int currentStreak = 0;
  DateTime? lastCompletedDate;
  bool isCompleted = false;

  int position = 0;

  HabitModel({
    this.title,
    this.startDate,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.isCompleted = false,
    this.position = 0,
  });

  @override
  String toString() {
    return 'HabitModel(id: $id, title: $title, currentStreak: $currentStreak, isCompleted: $isCompleted, lastCompletedDate: $lastCompletedDate, position: $position)';
  }
}
