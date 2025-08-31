import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/routes/app_routes.dart';
import 'package:habit_app/services/habit_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final isarService = Provider.of<IsarService>(context, listen: false);
    isarService.resetDailyHabits();
    isarService.getAllHabits();
  }

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade300,
        title: const Text("Don't Break the Chain"),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.add);
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer<IsarService>(
                  builder: (context, isarService, child) {
                    final habits = isarService.habits;
                    if (habits.isEmpty) {
                      return const Center(child: Text("Please add a habit"));
                    }
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Dismissible(
                          key: Key(habit.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) {
                            return showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Alışkanlığı Sil"),
                                  content: Text(
                                    "“${habit.title ?? 'Başlık Yok'}” alışkanlığını silmek istediğinize emin misiniz?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("İptal"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text("Sil"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            final removedHabitTitle = habit.title;

                            // Önce listeden kaldır
                            Provider.of<IsarService>(
                              context,
                              listen: false,
                            ).removeHabitFromList(habit.id);

                            // Veritabanından kalıcı olarak sil
                            await _deleteHabit(habit.id);

                            // Bildirim göster
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${removedHabitTitle ?? 'Alışkanlık'} silindi.',
                                ),
                              ),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(habit.title ?? 'Başlık Yok'),
                              leading: Chip(
                                label: Text(habit.currentStreak.toString()),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  _toggleHabit(habit);
                                },
                                icon: Icon(
                                  habit.isCompleted
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
