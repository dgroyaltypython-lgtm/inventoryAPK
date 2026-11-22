import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'entry_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'requisition_screen.dart';
import 'widgets.dart';

final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
    NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Entry'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
    NavigationDestination(icon: Icon(Icons.shopping_basket_outlined), selectedIcon: Icon(Icons.shopping_basket), label: 'Order'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onGoToStock: () => setState(() => _selectedIndex = 1)),
      const InventoryScreen(),
      const EntryScreen(),
      const ReportsScreen(),
      const RequisitionScreen(),
    ];
    return Scaffold(
      backgroundColor: canvas,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _destinations,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDF1EC),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
      ),
    );
  }
}
