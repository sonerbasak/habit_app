// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/delete_dialog.dart';
import 'package:habit_app/pages/home/widgets/edit_dialog.dart';
import 'package:habit_app/pages/home/widgets/habit_icon_helper.dart';
import 'package:habit_app/routes/app_routes.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/pages/home/constant.dart';

class HabitItem extends StatefulWidget {
  final HabitModel habit;
  const HabitItem({super.key, required this.habit});

  @override
  State<HabitItem> createState() => _HabitItemState();
}

class _HabitItemState extends State<HabitItem> {
  Future<void> _toggleHabit(HabitModel habit) async {
    final isarService = Provider.of<IsarService>(context, listen: false);
    await isarService.toggleHabitCompletion(habit);
  }

  Future<void> _deleteHabit(int id) async {
    final isarService = Provider.of<IsarService>(context, listen: false);
    await isarService.deleteHabit(id);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.habit.id.toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.lightBlueAccent,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Sağa kaydır → Edit
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
              return EditDialog(habit: widget.habit);
            },
          );

          if (confirm == true) {
            Navigator.pushNamed(
              context,
              AppRoutes.add,
              arguments: widget.habit,
            );
          }
          return false; // Edit yapıldığında kartı dismiss etme
        }

        if (direction == DismissDirection.endToStart) {
          // Sola kaydır → Delete
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
              return DeleteDialog(habit: widget.habit);
            },
          );

          if (confirm == true) {
            // burada gerçek silme işlemi yapılacak
            return true;
          }
          return false;
        }

        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete işlemi onaylandıysa buraya düşer
          final removedHabitTitle = widget.habit.title;

          // Artık sadece asıl silme işlemini çağırıyoruz.
          // IsarService içindeki deleteHabit metodu, refreshHabits() çağrısını yaparak UI'ı zaten güncelleyecek.
          await _deleteHabit(widget.habit.id);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${removedHabitTitle ?? 'Alışkanlık'} silindi.'),
            ),
          );
        }
      },

      child: Card(
        child: ListTile(
          title: Text(widget.habit.title ?? ''),
          //Text(widget.habit.title ?? ''),
          leading: Chip(label: Text(widget.habit.currentStreak.toString())),
          subtitle: widget.habit.frequencyType == FrequencyType.custom
              ? Text(
                  '${widget.habit.daysOfWeek?.map((day) => dayNames[day - 1]).join(', ')}',
                )
              : Text(widget.habit.frequencyType.toString().split('.').last),
          trailing: IconButton(
            onPressed: () => toggleSpecial(),
            icon: Icon(getHabitIcon(widget.habit)),
          ),
        ),
      ),
    );
  }

  void toggleSpecial() {
    final today = DateTime.now();

    if (widget.habit.frequencyType == FrequencyType.custom) {
      if (widget.habit.daysOfWeek != null &&
          widget.habit.daysOfWeek!.contains(today.weekday)) {
        _toggleHabit(widget.habit);
      }
      return;
    }

    final doneToday =
        widget.habit.lastCompletedDate != null &&
        isToday(widget.habit.lastCompletedDate!);

    if (isHabitChecked(widget.habit, today) && !doneToday) {
      return;
    }
    _toggleHabit(widget.habit);
  }
}

bool isHabitChecked(HabitModel habit, DateTime date) {
  if (habit.lastCompletedDate == null) return false;

  final lastCheck = DateTime(
    habit.lastCompletedDate!.year,
    habit.lastCompletedDate!.month,
    habit.lastCompletedDate!.day,
  );

  final targetDate = DateTime(date.year, date.month, date.day);

  switch (habit.frequencyType) {
    case FrequencyType.daily:
      return lastCheck == targetDate;

    case FrequencyType.weekly:
      final startOfWeek = targetDate.subtract(
        Duration(days: targetDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      return lastCheck.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          lastCheck.isBefore(endOfWeek.add(const Duration(days: 1)));

    case FrequencyType.monthly:
      final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);

      return lastCheck.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          lastCheck.isBefore(endOfMonth.add(const Duration(days: 1)));

    case FrequencyType.custom:
      if (habit.daysOfWeek == null || habit.daysOfWeek!.isEmpty) {
        return false;
      }

      if (!habit.daysOfWeek!.contains(targetDate.weekday)) {
        return false;
      }

      return lastCheck == targetDate;
  }
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}
