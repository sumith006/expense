import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_tab.dart';
import 'expense_screen.dart';
import 'task_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/custom_bottom_nav.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    ExpenseScreen(),
    TaskScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Reactively watch the pending tasks count to show a badge on the navigation bar
    final pendingTasksCount = ref.watch(taskProvider)
        .where((t) => t.status == TaskStatus.pending)
        .length;

    return Scaffold(
      body: SafeArea(
        top: false, // Let status bar color flow naturally
        child: _tabs[_selectedIndex],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          print("🔍 DEBUG: Bottom nav tapped - index: $index");
          print("🔍 DEBUG: Current tab: ${_tabs[_selectedIndex].runtimeType}");
          print("🔍 DEBUG: Switching to: ${_tabs[index].runtimeType}");
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
