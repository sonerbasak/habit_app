import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/habit_item.dart';

IconData getHabitIcon(HabitModel habit) {
  final today = DateTime.now();

  if (habit.frequencyType == FrequencyType.custom) {
    if (habit.daysOfWeek == null ||
        !habit.daysOfWeek!.contains(today.weekday)) {
      return Icons.info;
    }
    return isHabitChecked(habit, today)
        ? Icons.check_box
        : Icons.check_box_outline_blank;
  } else {
    if (isHabitChecked(habit, today)) {
      return (habit.lastCompletedDate != null &&
              isToday(habit.lastCompletedDate!))
          ? Icons.check_box
          : Icons.info;
    }
    return Icons.check_box_outline_blank;
  }
}
