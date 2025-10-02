import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';

class EditDialog extends StatelessWidget {
  const EditDialog({super.key, required this.habit});

  final HabitModel habit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Alışkanlığı Düzenle"),
      content: Text(
        "“${habit.title ?? 'Başlık Yok'}” alışkanlığını düzenlemek istediğinize emin misiniz?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("İptal"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
          },
          child: const Text("Düzenle"),
        ),
      ],
    );
  }
}
