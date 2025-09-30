import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/habit_icon_helper.dart';
import 'package:habit_app/pages/home/widgets/habit_item.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:provider/provider.dart';

class HabitList extends StatefulWidget {
  final bool hideCompleted;
  final FrequencyType? filterType;
  const HabitList({super.key, required this.hideCompleted, this.filterType});

  @override
  State<HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<IsarService>(
      builder: (context, isarService, child) {
        var habits = isarService.habits;

        if (widget.filterType != null) {
          habits = habits
              .where((h) => h.frequencyType == widget.filterType)
              .toList();
        }
        debugPrint("Filtered habits count: ${habits.length}");

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
            final icon = getHabitIcon(habit);

            if (widget.hideCompleted &&
                (icon == Icons.check_box || icon == Icons.info)) {
              return SizedBox(key: ValueKey("hidden_${habit.id}"));
            }

            return HabitItem(key: ValueKey(habit.id), habit: habit);
          },
        );
      },
    );
  }
}
