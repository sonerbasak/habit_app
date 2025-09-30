import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/delete_dialog.dart';
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
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) {
        return showDialog<bool>(
          context: context,
          builder: (context) {
            return DeleteDialog(habit: widget.habit);
          },
        );
      },
      onDismissed: (direction) async {
        final removedHabitTitle = widget.habit.title;

        Provider.of<IsarService>(
          context,
          listen: false,
        ).removeHabitFromList(widget.habit.id);

        await _deleteHabit(widget.habit.id);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${removedHabitTitle ?? 'Alışkanlık'} silindi.'),
          ),
        );
      },
      child: Card(
        child: ListTile(
          title: Text(widget.habit.title ?? ''),
          leading: Chip(label: Text(widget.habit.currentStreak.toString())),
          subtitle: widget.habit.frequencyType == FrequencyType.custom
              ? Text(
                  '${widget.habit.daysOfWeek?.map((day) => dayNames[day - 1]).join(', ')}',
                )
              : Text(widget.habit.frequencyType.toString().split('.').last),
          trailing: IconButton(
            onPressed: () {
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
            },
            icon: Icon(
              widget.habit.frequencyType == FrequencyType.custom
                  ? (() {
                      final today = DateTime.now();
                      if (widget.habit.daysOfWeek == null ||
                          !widget.habit.daysOfWeek!.contains(today.weekday)) {
                        return Icons.info;
                      }
                      return isHabitChecked(widget.habit, today)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank;
                    })()
                  : isHabitChecked(widget.habit, DateTime.now())
                  ? (widget.habit.lastCompletedDate != null &&
                            isToday(widget.habit.lastCompletedDate!))
                        ? Icons.check_box
                        : Icons.info
                  : Icons.check_box_outline_blank,
            ),
          ),
        ),
      ),
    );
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
