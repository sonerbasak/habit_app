import 'package:flutter/material.dart';
import 'package:habit_app/routes/app_routes.dart';
import 'package:habit_app/services/theme_services.dart';
import 'package:provider/provider.dart';

BottomAppBar bottomNavigator({
  required BuildContext context,
  required bool hideCompleted,
  required VoidCallback onToggleVisibility,
  required VoidCallback onFilter,
}) {
  return BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8.0,
    child: SizedBox(
      height: 60.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: onFilter),
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.add);
            },
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              iconSize: 42,
              elevation: 2,
              backgroundColor: Provider.of<ThemeProvider>(context).appBarColor,
              foregroundColor: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggleVisibility,
          ),
        ],
      ),
    ),
  );
}
