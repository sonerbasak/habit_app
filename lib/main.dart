import 'package:flutter/material.dart';
import 'package:habit_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/routes/app_routes.dart';
import 'package:habit_app/services/habit_services.dart';
import 'package:habit_app/services/theme_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init(); // bildirim servisini başlat

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

        ChangeNotifierProvider<IsarService>(create: (context) => IsarService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: '/',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple.shade200,
            ),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 38, 44, 38),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      },
    );
  }
}
