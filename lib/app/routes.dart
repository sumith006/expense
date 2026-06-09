import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../auth/pin_setup_screen.dart';
import '../auth/pin_lock_screen.dart';
import '../screens/expense_screen/add_expense_screen.dart';
import '../screens/income_screen/add_income_screen.dart';
import '../screens/task_screen/add_task_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/backup_screen.dart';
import '../screens/notification_test_screen.dart';
import '../screens/neobrutal_dashboard_screen.dart';
import '../screens/neobrutal_expense_screen.dart';
import '../screens/neobrutal_task_screen.dart';
import '../screens/neobrutal_profile_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/reports_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String pinSetup = '/pin_setup';
  static const String pinLock = '/pin_lock';
  static const String dashboard = '/dashboard';
  static const String modernDashboard = '/modern_dashboard';
  static const String bankingDashboard = '/banking_dashboard';
  static const String neobrutalDashboard = '/neobrutal_dashboard';
  static const String neobrutalExpense = '/neobrutal_expense';
  static const String neobrutalTask = '/neobrutal_task';
  static const String neobrutalProfile = '/neobrutal_profile';
  static const String profile = '/profile';
  static const String addExpense = '/add_expense';
  static const String addIncome = '/add_income';
  static const String addTask = '/add_task';
  static const String settings = '/settings';
  static const String backup = '/backup';
  static const String notificationTest = '/notification_test';
  static const String reports = '/reports';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      pinSetup: (context) => const PinSetupScreen(),
      pinLock: (context) => const PinLockScreen(),
      // Use NeoBrutalDashboardScreen as the default for all dashboard routes
      dashboard: (context) => const NeoBrutalDashboardScreen(),
      modernDashboard: (context) => const NeoBrutalDashboardScreen(),
      bankingDashboard: (context) => const NeoBrutalDashboardScreen(),
      neobrutalDashboard: (context) => const NeoBrutalDashboardScreen(),
      neobrutalExpense: (context) => const NeoBrutalExpenseScreen(),
      neobrutalTask: (context) => const NeoBrutalTaskScreen(),
      neobrutalProfile: (context) => const NeoBrutalProfileScreen(),
      profile: (context) => const NeoBrutalProfileScreen(),
      addExpense: (context) => const AddExpenseScreen(),
      addIncome: (context) => const AddIncomeScreen(),
      addTask: (context) => const AddTaskScreen(),
      settings: (context) => const SettingsScreen(),
      backup: (context) => const BackupScreen(),
      notificationTest: (context) => const NotificationTestScreen(),
      reports: (context) => const ReportsScreen(),
    };
  }
}
