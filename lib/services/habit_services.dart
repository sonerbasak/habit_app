import 'package:flutter/material.dart';
import 'package:habit_app/services/notification_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:habit_app/models/habit_model.dart';
// HabitModel'in FrequencyType enum'unu içerdiğini varsayıyorum.

class IsarService extends ChangeNotifier {
  late Future<Isar> isarDB;

  IsarService() {
    isarDB = init();
  }

  Future<Isar> init() async {
    try {
      if (Isar.instanceNames.isEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        // Lütfen buradaki [HabitModelSchema] ve diğer şemaların doğru olduğunu kontrol edin.
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

  Future<void> refreshHabits() async {
    final isar = await isarDB;
    _habits = await isar.habitModels.where().sortByPosition().findAll();
    notifyListeners();
  }

  Future<void> saveHabit(HabitModel habit, {bool isUpdate = false}) async {
    try {
      final isar = await isarDB;

      if (!isUpdate) {
        final lastPosition = _habits.isEmpty ? 0 : _habits.last.position + 1;
        habit.position = lastPosition;
        debugPrint("New habit position set: ${habit.position}");
      }

      // Frekans tipi kontrolü (özelleştirilmiş günlerin temizlenmesi)
      if (habit.frequencyType == FrequencyType.custom) {
        habit.daysOfWeek ??= [];
      } else {
        habit.daysOfWeek = null;
      }

      // Isar veritabanına kaydetme
      await isar.writeTxn(() async {
        await isar.habitModels.put(habit);
      });

      await refreshHabits();
    } catch (e) {
      debugPrint("Error saving habit: $e");
    }

    // BİLDİRİM PLANLAMA
    if (habit.notificationTime != null) {
      // Önceki bildirimleri iptal et
      await NotificationService.cancelNotification(habit.id);

      await NotificationService.showScheduledNotification(
        id: habit.id,
        title: habit.title ?? "Hatırlatma",
        body: "Bugünkü alışkanlığını tamamlama zamanı!",
        scheduledDate: habit.notificationTime!,
      );
    } else {
      // Bildirim saati kaldırıldıysa bildirimi iptal et
      await NotificationService.cancelNotification(habit.id);
    }
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

      // Alışkanlığı Geri Al (Undo) Kısmı
      if (updatedHabit.isCompleted &&
          lastCheck != null &&
          lastCheck.isAtSameMomentAs(today)) {
        updatedHabit.isCompleted = false;
        updatedHabit.currentStreak = (updatedHabit.currentStreak - 1).toInt();

        // Geri alma (Undo) mantığını buraya taşıdık.
        final backDuration = _getUndoDuration(
          updatedHabit.frequencyType,
          habit.daysOfWeek,
          today,
        );

        updatedHabit.lastCompletedDate = today.subtract(
          Duration(days: backDuration),
        );
      }
      // Alışkanlığı Tamamlama Kısmı
      else {
        int newStreak = 1;

        if (lastCheck != null) {
          switch (updatedHabit.frequencyType) {
            case FrequencyType.daily:
              newStreak = _calculateDailyStreak(updatedHabit, today, lastCheck);
              break;
            case FrequencyType.weekly:
              newStreak = _calculateWeeklyStreak(
                updatedHabit,
                today,
                lastCheck,
              );
              break;
            case FrequencyType.monthly:
              newStreak = _calculateMonthlyStreak(
                updatedHabit,
                today,
                lastCheck,
              );
              break;
            case FrequencyType.custom:
              newStreak = _calculateCustomStreak(
                updatedHabit,
                today,
                lastCheck,
              );
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

      await refreshHabits();
      return 1;
    } catch (e) {
      debugPrint("Error toggling habit: $e");
      return 0;
    }
  }

  int _getUndoDuration(
    FrequencyType frequencyType,
    List<int>? daysOfWeek,
    DateTime today,
  ) {
    switch (frequencyType) {
      case FrequencyType.daily:
        return 1;
      case FrequencyType.weekly:
        // Haftalık streak'te geri alma, bir önceki tamamlanan haftanın son gününe gitmelidir.
        // Basitlik için bir hafta geriye gidiyoruz.
        return 7;
      case FrequencyType.monthly:
        // Basitlik için bir ay geriye gidiyoruz (Ortalama 30 gün).
        return 30;
      case FrequencyType.custom:
        if (daysOfWeek == null || daysOfWeek.isEmpty) {
          return 1;
        }

        // En yakın önceki custom günü bul
        for (int i = 1; i <= 7; i++) {
          final checkDate = today.subtract(Duration(days: i));
          if (daysOfWeek.contains(checkDate.weekday)) {
            return i;
          }
        }
        return 1; // Bulunamazsa varsayılan 1 gün
    }
  }

  int _calculateDailyStreak(
    HabitModel habit,
    DateTime today,
    DateTime lastCheck,
  ) {
    final diffDays = today.difference(lastCheck).inDays;
    if (diffDays == 1) {
      return habit.currentStreak + 1;
    } else if (diffDays < 1) {
      return habit.currentStreak;
    } else {
      return 1;
    }
  }

  int _calculateWeeklyStreak(
    HabitModel habit,
    DateTime today,
    DateTime lastCheck,
  ) {
    // Haftalık streak hesaplamanız karmaşık olduğu için, sadece ilgili mantığı buraya taşıdık.
    // **NOT: Bu metodun ISO 8601'e göre tam olarak test edilmesi gerekir.**
    final todayWeek = getWeekNumber(today);
    final lastWeek = getWeekNumber(lastCheck);

    if (today.year == lastCheck.year) {
      if (todayWeek == lastWeek) {
        return habit.currentStreak;
      } else if (todayWeek == lastWeek + 1) {
        return habit.currentStreak + 1;
      } else {
        return 1;
      }
    } else {
      final totalWeeksLastYear = getWeekNumber(
        DateTime(lastCheck.year, 12, 31),
      );
      final weekDiff =
          (today.year - lastCheck.year) * totalWeeksLastYear +
          (todayWeek - lastWeek);

      if (weekDiff == 1) {
        return habit.currentStreak + 1;
      } else if (weekDiff < 1) {
        return habit.currentStreak;
      } else {
        return 1;
      }
    }
  }

  int _calculateMonthlyStreak(
    HabitModel habit,
    DateTime today,
    DateTime lastCheck,
  ) {
    final diffMonths =
        (today.year - lastCheck.year) * 12 + today.month - lastCheck.month;
    if (diffMonths == 1) {
      return habit.currentStreak + 1;
    } else if (diffMonths < 1) {
      return habit.currentStreak;
    } else {
      return 1;
    }
  }

  int _calculateCustomStreak(
    HabitModel habit,
    DateTime today,
    DateTime lastCheck,
  ) {
    if (habit.daysOfWeek != null && habit.daysOfWeek!.isNotEmpty) {
      final todayWeekday = today.weekday;

      if (habit.daysOfWeek!.contains(todayWeekday)) {
        final sortedDays = List<int>.from(habit.daysOfWeek!)..sort();

        // Önceki tamamlanması gereken custom günü bul (lastCustomDay mantığı)
        int lastCustomDayWeekday = sortedDays.last;
        for (int day in sortedDays.reversed) {
          if (day < todayWeekday) {
            lastCustomDayWeekday = day;
            break;
          }
        }

        // Hafta döngüsünde kaç gün önce olması gerektiğini hesapla
        final diffDays = (todayWeekday - lastCustomDayWeekday + 7) % 7;

        final lastCheckDate = DateTime(
          habit.lastCompletedDate!.year,
          habit.lastCompletedDate!.month,
          habit.lastCompletedDate!.day,
        );

        if (diffDays == today.difference(lastCheckDate).inDays) {
          return habit.currentStreak + 1;
        } else if (today.isAtSameMomentAs(lastCheckDate)) {
          return habit.currentStreak;
        } else {
          return 1;
        }
      } else {
        return habit.currentStreak;
      }
    }
    return habit.currentStreak;
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
    // Bildirimi iptal etmeyi unutmayın
    await NotificationService.cancelNotification(id);

    await isar.writeTxn(() async {
      await isar.habitModels.delete(id);
    });
    await refreshHabits();
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

    await refreshHabits();
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diffDays = date.difference(firstDayOfYear).inDays;
    return ((diffDays + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }
}
