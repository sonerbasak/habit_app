// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/bottom_navigator.dart';
import 'package:habit_app/pages/home/widgets/habit_list.dart';
import 'package:habit_app/services/theme_services.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/services/habit_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool hideCompleted = false;
  FrequencyType? _filterType;

  void _toggleVisibility() {
    setState(() {
      hideCompleted = !hideCompleted;
    });
  }

  void _filterHabits(FrequencyType? type) {
    setState(() {
      _filterType = type;
    });
    Navigator.pop(context);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filtrele",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                title: const Text("Tümü"),
                onTap: () => _filterHabits(null),
              ),
              ListTile(
                title: const Text("Daily"),
                onTap: () => _filterHabits(FrequencyType.daily),
              ),
              ListTile(
                title: const Text("Weekly"),
                onTap: () => _filterHabits(FrequencyType.weekly),
              ),
              ListTile(
                title: const Text("Monthly"),
                onTap: () => _filterHabits(FrequencyType.monthly),
              ),
              ListTile(
                title: const Text("Custom"),
                onTap: () => _filterHabits(FrequencyType.custom),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final isarService = Provider.of<IsarService>(context, listen: false);
    isarService.resetDailyHabits();
    isarService.getAllHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).appBarColor,
        title: const Text(
          "Don't Break the Chain",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color.fromARGB(255, 240, 231, 231),
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(iconSize: 24),
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
                child: HabitList(
                  hideCompleted: hideCompleted,
                  filterType: _filterType,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigator(
        context: context,
        hideCompleted: hideCompleted,
        onToggleVisibility: _toggleVisibility,
        onFilter: () => _showFilterSheet(context),
      ),
    );
  }
}
