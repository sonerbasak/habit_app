import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_app/routes/app_routes.dart';
import 'package:habit_app/services/habit_services.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => IsarService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: AppRoutes.routes,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple.shade300),
        useMaterial3: true,
      ),
    );
  }
}
