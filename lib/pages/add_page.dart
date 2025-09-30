// lib/pages/add_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:habit_app/pages/home/constant.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  FrequencyType _selectedFrequency = FrequencyType.daily;
  final List<int> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    final isarService = Provider.of<IsarService>(context, listen: false);

    final newHabit = HabitModel(
      title: _titleController.text,
      frequencyType: _selectedFrequency,
      daysOfWeek: _selectedFrequency == FrequencyType.custom
          ? _selectedDays
          : null,
    );

    await isarService.saveHabit(newHabit);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildCustomDaySelector() {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final dayName = dayNames[index];
        final isSelected = _selectedDays.contains(dayNum);

        return FilterChip(
          label: Text(dayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayNum);
              } else {
                _selectedDays.remove(dayNum);
              }
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Alışkanlık Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Başlık
            TextField(
              controller: _titleController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Alışkanlık Başlığı',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.purple.shade300,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Frequency seçimi
            DropdownButtonFormField<FrequencyType>(
              initialValue: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: "Tekrar Sıklığı",
                border: OutlineInputBorder(),
              ),
              items: FrequencyType.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(freq.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                  if (_selectedFrequency != FrequencyType.custom) {
                    _selectedDays.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // Sadece Custom için gün seçimi
            if (_selectedFrequency == FrequencyType.custom) ...[
              const Text(
                "Seçili Günler:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildCustomDaySelector(),
              const SizedBox(height: 20),
            ],

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
