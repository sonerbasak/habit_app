// lib/pages/add_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/services/habit_services.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _titleController = TextEditingController();

  // TextField'ın odaklanmasını kontrol etmek için bir FocusNode kullanın
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Sayfa oluşturulduğunda TextField'a odaklan
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose(); // FocusNode'u da dispose etmeyi unutmayın
    super.dispose();
  }

  Future<void> _saveHabit() async {
    final isarService = Provider.of<IsarService>(context, listen: false);
    final newHabit = HabitModel(title: _titleController.text);
    await isarService.saveHabit(newHabit);
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Alışkanlık Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              focusNode: _focusNode, // FocusNode'u TextField'a atayın
              decoration: InputDecoration(
                labelText: 'Alışkanlık Başlığı',
                border: const OutlineInputBorder(),
                // Odaklanıldığında kenarlığın rengini değiştirin
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.purple.shade300,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  _saveHabit();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir başlık girin.')),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
