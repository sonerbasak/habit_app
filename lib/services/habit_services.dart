import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:habit_app/models/habit_model.dart';

class IsarService extends ChangeNotifier {
  late Future<Isar> isarDB;

  IsarService() {
    isarDB = init();
  }

  Future<Isar> init() async {
    try {
      if (Isar.instanceNames.isEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final db = await Isar.open([HabitModelSchema], directory: dir.path);
        return db;
      } else {
        return Isar.getInstance()!;
      }
    } catch (e) {
      debugPrint("Error initializing Isar: $e");
      rethrow;
    }
  }

  List<HabitModel> _habits = [];

  List<HabitModel> get habits => _habits;

  Future<void> _refreshHabits() async {
    final isar = await isarDB;
    _habits = await isar.habitModels.where().sortByPosition().findAll();
    notifyListeners();
  }

  Future<void> saveHabit(HabitModel habit) async {
    try {
      final isar = await isarDB;

      final lastPosition = _habits.isEmpty ? 0 : _habits.last.position + 1;
      habit.position = lastPosition;

      if (habit.frequencyType == FrequencyType.custom) {
        habit.daysOfWeek ??= [];
      } else {
        habit.daysOfWeek = null;
      }
      habit.frequencyType = habit.frequencyType;

      await isar.writeTxn(() async {
        await isar.habitModels.put(habit);
      });

      await _refreshHabits();
    } catch (e) {
      debugPrint("Error saving habit: $e");
    }
  }

  Future<void> getAllHabits() async {
    await _refreshHabits();
  }

  Future<int> toggleHabitCompletion(HabitModel habit) async {
    try {
      final isar = await isarDB;
      final updatedHabit = await isar.habitModels.get(habit.id);
      if (updatedHabit == null) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastCheck = updatedHabit.lastCompletedDate != null
          ? DateTime(
              updatedHabit.lastCompletedDate!.year,
              updatedHabit.lastCompletedDate!.month,
              updatedHabit.lastCompletedDate!.day,
            )
          : null;

      if (updatedHabit.isCompleted &&
          lastCheck != null &&
          lastCheck.isAtSameMomentAs(today)) {
        updatedHabit.isCompleted = false;
        updatedHabit.currentStreak = (updatedHabit.currentStreak - 1).toInt();

        int getBackDuration(FrequencyType frequencyType, daysOfWeek) {
          switch (frequencyType) {
            case FrequencyType.daily:
              return 1;
            case FrequencyType.weekly:
              return 7;
            case FrequencyType.monthly:
              return 30;
            case FrequencyType.custom:
              if (daysOfWeek == null || daysOfWeek.isEmpty) {
                return 1;
              }

              for (int i = 1; i <= 7; i++) {
                final checkDate = today.subtract(Duration(days: i));
                if (daysOfWeek.contains(checkDate.weekday)) {
                  return i;
                }
              }
              return 1;
          }
        }

        final backDuration = getBackDuration(
          updatedHabit.frequencyType,
          habit.daysOfWeek,
        );

        updatedHabit.lastCompletedDate = today.subtract(
          Duration(days: backDuration),
        );
      } else {
        int newStreak = 1;

        if (lastCheck != null) {
          switch (updatedHabit.frequencyType) {
            case FrequencyType.daily:
              final diffDays = today.difference(lastCheck).inDays;
              if (diffDays == 1) {
                newStreak = updatedHabit.currentStreak + 1;
              } else if (diffDays < 1) {
                newStreak = updatedHabit.currentStreak;
              } else {
                newStreak = 1;
              }
              break;

            case FrequencyType.weekly:
              final todayWeek = getWeekNumber(today);
              final lastWeek = getWeekNumber(lastCheck);

              if (today.year == lastCheck.year) {
                if (todayWeek == lastWeek) {
                  newStreak = updatedHabit.currentStreak;
                } else if (todayWeek == lastWeek + 1) {
                  newStreak = updatedHabit.currentStreak + 1;
                } else {
                  newStreak = 1;
                }
              } else {
                final totalWeeksLastYear = getWeekNumber(
                  DateTime(lastCheck.year, 12, 31),
                );
                final weekDiff =
                    (today.year - lastCheck.year) * totalWeeksLastYear +
                    (todayWeek - lastWeek);

                if (weekDiff == 1) {
                  newStreak = updatedHabit.currentStreak + 1;
                } else if (weekDiff < 1) {
                  newStreak = updatedHabit.currentStreak;
                } else {
                  newStreak = 1;
                }
              }
              break;

            case FrequencyType.monthly:
              final diffMonths =
                  (today.year - lastCheck.year) * 12 +
                  today.month -
                  lastCheck.month;
              if (diffMonths == 1) {
                newStreak = updatedHabit.currentStreak + 1;
              } else if (diffMonths < 1) {
                newStreak = updatedHabit.currentStreak;
              } else {
                newStreak = 1;
              }
              break;

            case FrequencyType.custom:
              if (updatedHabit.daysOfWeek != null &&
                  updatedHabit.daysOfWeek!.isNotEmpty) {
                final todayWeekday = today.weekday;

                if (updatedHabit.daysOfWeek!.contains(todayWeekday)) {
                  final sortedDays = List<int>.from(updatedHabit.daysOfWeek!)
                    ..sort();

                  int lastCustomDay = sortedDays.last;
                  for (int day in sortedDays) {
                    if (day < todayWeekday) {
                      lastCustomDay = day;
                    }
                  }

                  final diffDays = (todayWeekday - lastCustomDay + 7) % 7;
                  final lastCheckDate = DateTime(
                    updatedHabit.lastCompletedDate!.year,
                    updatedHabit.lastCompletedDate!.month,
                    updatedHabit.lastCompletedDate!.day,
                  );

                  if (diffDays == today.difference(lastCheckDate).inDays) {
                    newStreak = updatedHabit.currentStreak + 1;
                  } else if (today.isAtSameMomentAs(lastCheckDate)) {
                    newStreak = updatedHabit.currentStreak;
                  } else {
                    newStreak = 1;
                  }
                } else {
                  newStreak = updatedHabit.currentStreak;
                }
              }
              break;
          }
        }

        updatedHabit.isCompleted = true;
        updatedHabit.currentStreak = newStreak;
        updatedHabit.lastCompletedDate = today;
      }

      await isar.writeTxn(() async {
        await isar.habitModels.put(updatedHabit);
      });

      await _refreshHabits();
      return 1;
    } catch (e) {
      debugPrint("Error toggling habit: $e");
      return 0;
    }
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final habitToMove = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, habitToMove);

    final isar = await isarDB;
    await isar.writeTxn(() async {
      for (var i = 0; i < _habits.length; i++) {
        _habits[i].position = i;
        await isar.habitModels.put(_habits[i]);
      }
    });

    notifyListeners();
  }

  Future<void> deleteHabit(int id) async {
    final isar = await isarDB;
    await isar.writeTxn(() async {
      await isar.habitModels.delete(id);
    });
    await _refreshHabits();
  }

  Future<void> resetDailyHabits() async {
    final isar = await isarDB;
    final habits = await isar.habitModels.where().findAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await isar.writeTxn(() async {
      for (var habit in habits) {
        final lastCheck = habit.lastCompletedDate;
        if (lastCheck == null) {
          habit.isCompleted = false;
        } else {
          final lastCompletedDay = DateTime(
            lastCheck.year,
            lastCheck.month,
            lastCheck.day,
          );
          if (lastCompletedDay.isBefore(today)) {
            habit.isCompleted = false;
          }
        }
        await isar.habitModels.put(habit);
      }
    });

    await _refreshHabits();
  }

  void removeHabitFromList(int id) {
    _habits.removeWhere((habit) => habit.id == id);

    notifyListeners();
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diffDays = date.difference(firstDayOfYear).inDays;
    return ((diffDays + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }

  FrequencyType? _currentFilter;

  void filterFrequencyType(FrequencyType type) {
    _currentFilter = type;
    notifyListeners();
  }

  void clearFilter() {
    _currentFilter = null;
    notifyListeners();
  }

  List<HabitModel> get filteredHabits {
    if (_currentFilter == null) {
      return _habits;
    }
    return _habits
        .where((habit) => habit.frequencyType == _currentFilter)
        .toList();
  }
}
