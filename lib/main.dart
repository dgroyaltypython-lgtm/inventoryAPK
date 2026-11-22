import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'screens/app_shell.dart';
import 'screens/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const CoastalPearlApp());
}

class CoastalPearlApp extends StatelessWidget {
  const CoastalPearlApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: gold,
      surface: canvas,
    );
    return MaterialApp(
      title: 'Coastal Pearl Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: canvas,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EAE7))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EAE7))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teal, width: 1.5)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          iconTheme: WidgetStatePropertyAll(IconThemeData(size: 20)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const AppShell(),
    );
  }
}
