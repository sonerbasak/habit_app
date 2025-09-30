import 'package:flutter/material.dart';
import 'package:habit_app/pages/home/widgets/habit_item.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:provider/provider.dart';

class HabitList extends StatefulWidget {
  const HabitList({super.key});

  @override
  State<HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<IsarService>(
      builder: (context, isarService, child) {
        final habits = isarService.habits;
        if (habits.isEmpty) {
          return const Center(child: Text("Please add a habit"));
        }
        return ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) {
            final isarService = Provider.of<IsarService>(
              context,
              listen: false,
            );

            isarService.reorderHabits(oldIndex, newIndex);
          },
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return HabitItem(key: ValueKey(habit.id), habit: habit);
          },
        );
      },
    );
  }
}
