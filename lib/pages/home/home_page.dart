import 'package:flutter/material.dart';
import 'package:habit_app/models/habit_model.dart';
import 'package:habit_app/pages/home/widgets/bottom_navigator.dart';
import 'package:habit_app/pages/home/widgets/habit_list.dart';
import 'package:habit_app/services/theme_services.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:confetti/confetti.dart'; // 🔑 Yeni: Confetti paketi
import 'package:habit_app/services/confetti_service.dart'; // 🔑 Yeni: Confetti Servisi

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
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Filtrele",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text("Tümü"),
                    onTap: () {
                      _filterHabits(null);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text("Daily"),
                    onTap: () {
                      _filterHabits(FrequencyType.daily);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text("Weekly"),
                    onTap: () {
                      _filterHabits(FrequencyType.weekly);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text("Monthly"),
                    onTap: () {
                      _filterHabits(FrequencyType.monthly);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text("Custom"),
                    onTap: () {
                      _filterHabits(FrequencyType.custom);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
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
    isarService.refreshHabits();
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Confetti servisine erişim
    final confettiService = Provider.of<ConfettiService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).appBarColor,
        title: const Text(
          "Zinciri Kırma",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color.fromARGB(255, 240, 231, 231),
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
                icon: Icon(
                  Provider.of<ThemeProvider>(context).isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(iconSize: 24),
              );
            },
          ),
        ],
      ),
      body: Stack(
        // 🔑 Body'yi Stack ile sararak Konfeti katmanını ekliyoruz
        children: [
          // 1. KATMAN: Ana İçerik (Liste)
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                  child: HabitList(
                    hideCompleted: hideCompleted,
                    filterType: _filterType,
                  ),
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiService.controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.pinkAccent,
                Colors.purpleAccent,
                Colors.lightGreenAccent,
                Colors.lightBlueAccent,
                Colors.yellowAccent,
              ],
              emissionFrequency: 0.1,
              numberOfParticles: 40,
              gravity: 0.3,
            ),
          ),
        ],
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
