import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/delete_dialog.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:provider/provider.dart';

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

        // Önce listeden kaldır
        Provider.of<IsarService>(
          context,
          listen: false,
        ).removeHabitFromList(widget.habit.id);

        // Veritabanından kalıcı olarak sil
        await _deleteHabit(widget.habit.id);

        // Bildirim göster
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${removedHabitTitle ?? 'Alışkanlık'} silindi.'),
          ),
        );
      },
      child: Card(
        child: ListTile(
          title: Text(widget.habit.title ?? 'Başlık Yok'),
          leading: Chip(label: Text(widget.habit.currentStreak.toString())),
          trailing: IconButton(
            onPressed: () {
              _toggleHabit(widget.habit);
            },
            icon: Icon(
              widget.habit.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
            ),
          ),
        ),
      ),
    );
  }
}
