import 'package:flutter/material.dart';
import 'package:habit_app/pages/home/widgets/habit_list.dart';
import 'package:habit_app/services/theme_services.dart';
import 'package:provider/provider.dart';
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
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.add);
            },
            icon: const Icon(Icons.add, color: Colors.white),
            style: IconButton.styleFrom(iconSize: 32),
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
                child: HabitList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
