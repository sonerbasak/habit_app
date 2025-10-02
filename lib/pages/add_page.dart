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

  TimeOfDay? selectedTime;

  HabitModel? _editingHabit;

  void _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_editingHabit == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is HabitModel) {
        _editingHabit = args;

        _titleController.text = _editingHabit!.title ?? '';
        _selectedFrequency = _editingHabit!.frequencyType;
        _selectedDays.clear();
        if (_editingHabit!.daysOfWeek != null) {
          _selectedDays.addAll(List.from(_editingHabit!.daysOfWeek!));
        }
        if (_editingHabit!.notificationTime != null) {
          selectedTime = TimeOfDay.fromDateTime(
            _editingHabit!.notificationTime!,
          );
        }
      }
    }
  }

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

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık girin.')));
      return;
    }

    // YENİ MANTIK: Bildirim zamanını hesapla ve geçmişteyse ileri taşı
    DateTime? scheduledDateTime;

    if (selectedTime != null) {
      // 1. Seçilen saati, bugünün tarihiyle birleştir:
      scheduledDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // 2. Eğer bu zaman şimdiden geçmişse, tarihi bir gün ileri sar:
      if (scheduledDateTime.isBefore(DateTime.now())) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        debugPrint(
          "Seçilen saat geçmişte olduğu için bildirim yarın ${scheduledDateTime.hour}:${scheduledDateTime.minute} olarak planlandı.",
        );
      } else {
        debugPrint(
          "Bildirim bugün ${scheduledDateTime.hour}:${scheduledDateTime.minute} olarak planlandı.",
        );
      }
    }

    if (_editingHabit == null) {
      // YENİ ALIŞKANLIK
      final newHabit = HabitModel(
        title: _titleController.text,
        frequencyType: _selectedFrequency,
        daysOfWeek: _selectedFrequency == FrequencyType.custom
            ? _selectedDays
            : null,
        // Düzeltilmiş değişken kullanılıyor
        notificationTime: scheduledDateTime,
      );

      await isarService.saveHabit(newHabit, isUpdate: false);
    } else {
      // ALIŞKANLIK GÜNCELLEME
      _editingHabit!
        ..title = _titleController.text
        ..frequencyType = _selectedFrequency
        ..daysOfWeek = _selectedFrequency == FrequencyType.custom
            ? _selectedDays
            : null
        // Düzeltilmiş değişken kullanılıyor
        ..notificationTime = scheduledDateTime;

      await isarService.saveHabit(_editingHabit!, isUpdate: true);
      debugPrint("Alışkanlık güncellendi: ${_editingHabit!.title}");
    }

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
    final isEditing = _editingHabit != null;
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
              readOnly: isEditing,
              style: isEditing ? const TextStyle(color: Colors.grey) : null,
              decoration: InputDecoration(
                labelText: 'Alışkanlık Başlığı',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
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
            ],
            SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedTime != null
                    ? "Alarm: ${selectedTime!.format(context)}"
                    : "Alarm zamanı seç",
                style: const TextStyle(fontSize: 24),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _pickTime(context),
            ),
            SizedBox(height: 20),
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
              child: const Text('Kaydet', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}
