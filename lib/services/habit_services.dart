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

  // Alışkanlıkları tutacak private liste
  List<HabitModel> _habits = [];

  // Diğer sınıfların erişebilmesi için getter
  List<HabitModel> get habits => _habits;

  Future<void> _refreshHabits() async {
    final isar = await isarDB;
    _habits = await isar.habitModels.where().findAll();
    notifyListeners();
  }

  Future<void> saveHabit(HabitModel habit) async {
    try {
      final isar = await isarDB;
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

  Future<void> toggleHabitCompletion(HabitModel habit) async {
    try {
      final isar = await isarDB;
      final updatedHabit = await isar.habitModels.get(habit.id);
      if (updatedHabit == null) return;

      if (updatedHabit.isCompleted) {
        updatedHabit.isCompleted = false;
        updatedHabit.currentStreak = 0;
        updatedHabit.lastCompletedDate = null;
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastCheck = updatedHabit.lastCompletedDate;

        if (lastCheck == null) {
          updatedHabit.currentStreak = 1;
        } else {
          final lastCompletedDay = DateTime(
            lastCheck.year,
            lastCheck.month,
            lastCheck.day,
          );
          final yesterday = today.subtract(const Duration(days: 1));

          if (lastCompletedDay.isAtSameMomentAs(yesterday)) {
            updatedHabit.currentStreak++;
          } else {
            updatedHabit.currentStreak = 1;
          }
        }
        updatedHabit.isCompleted = true;
        updatedHabit.lastCompletedDate = now;
      }
      await isar.writeTxn(() async {
        await isar.habitModels.put(updatedHabit);
      });
      final check = await isar.habitModels.get(updatedHabit.id);
      debugPrint(
        'After put -> isCompleted: ${check?.isCompleted}, streak: ${check?.currentStreak}',
      );
      await _refreshHabits();
    } catch (e) {
      debugPrint("Error toggling habit: $e");
    }
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
}
