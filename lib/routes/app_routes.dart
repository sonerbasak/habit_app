import 'package:flutter/material.dart';
import 'package:habit_app/pages/add_page.dart';
import 'package:habit_app/pages/edit_page.dart';
import 'package:habit_app/pages/home/home_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String add = '/add';
  static const String edit = '/edit';

  static Map<String, Widget Function(BuildContext)> get routes => {
    home: (context) => const HomePage(),
    add: (context) => const AddPage(),
    edit: (context) => const EditPage(),
  };
}
