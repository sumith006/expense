import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';
import '../models/user_settings.dart';
import 'boxes.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(CategoryTypeAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(TaskStatusAdapter());
    Hive.registerAdapter(SubtaskAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(SavingsGoalAdapter());
    Hive.registerAdapter(RecurringTransactionAdapter());
    Hive.registerAdapter(RecurringTypeAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    
    // Open boxes using the Boxes constants
    await Hive.openBox<Category>(Boxes.categories);
    await Hive.openBox<Expense>(Boxes.expenses);
    await Hive.openBox<Income>(Boxes.incomes);
    await Hive.openBox<Task>(Boxes.tasks);
    await Hive.openBox<Budget>(Boxes.budgets);
    await Hive.openBox<SavingsGoal>(Boxes.goals);
    await Hive.openBox<RecurringTransaction>(Boxes.recurring);
    await Hive.openBox<UserSettings>('settings');
    
    _initialized = true;
  }

  Future<void> clearAllData() async {
    await Hive.box<Category>(Boxes.categories).clear();
    await Hive.box<Expense>(Boxes.expenses).clear();
    await Hive.box<Income>(Boxes.incomes).clear();
    await Hive.box<Task>(Boxes.tasks).clear();
    await Hive.box<Budget>(Boxes.budgets).clear();
    await Hive.box<SavingsGoal>(Boxes.goals).clear();
    await Hive.box<RecurringTransaction>(Boxes.recurring).clear();
    await Hive.box<UserSettings>('settings').clear();
  }
}
