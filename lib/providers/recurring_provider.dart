import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_formatter.dart';
import '../database/boxes.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';
import 'expense_provider.dart';
import 'task_provider.dart';

final recurringProvider =
    StateNotifierProvider<RecurringNotifier, List<RecurringTransaction>>((ref) {
      final expNotifier = ref.watch(expenseProvider.notifier);
      final tNotifier = ref.watch(taskProvider.notifier);
      return RecurringNotifier(expNotifier, tNotifier);
    });

class RecurringNotifier extends StateNotifier<List<RecurringTransaction>> {
  late final Box<RecurringTransaction> _recurringBox;
  final ExpenseNotifier _expenseNotifier;
  final TaskNotifier _taskNotifier;

  RecurringNotifier(this._expenseNotifier, this._taskNotifier) : super([]) {
    _init();
  }

  void _init() {
    _recurringBox = Hive.box<RecurringTransaction>(Boxes.recurring);
    _loadRecurring();
    // Run the scheduler check on initialization
    processDueRecurringItems();
  }

  void _loadRecurring() {
    state = _recurringBox.values.toList()
      ..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
  }

  Future<void> addRecurring(RecurringTransaction item) async {
    await _recurringBox.put(item.id, item);
    _loadRecurring();
  }

  Future<void> updateRecurring(RecurringTransaction item) async {
    await _recurringBox.put(item.id, item);
    _loadRecurring();
  }

  Future<void> deleteRecurring(String id) async {
    await _recurringBox.delete(id);
    _loadRecurring();
  }

  Future<void> toggleActive(String id) async {
    final item = _recurringBox.get(id);
    if (item != null) {
      item.isActive = !item.isActive;
      await item.save();
      _loadRecurring();
    }
  }

  // --- Core Scheduler: Auto-generates due transactions & tasks ---
  Future<List<String>> processDueRecurringItems() async {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ); // Check up to end of today
    final createdNotifications = <String>[];
    bool modified = false;

    for (var item in _recurringBox.values.where((rt) => rt.isActive)) {
      var executionDate = item.nextExecutionDate;

      // Loop in case the app wasn't opened for multiple cycles (e.g. daily items missed for 3 days)
      while (executionDate.isBefore(today) ||
          executionDate.isAtSameMomentAs(today)) {
        // 1. Create the instance of the transaction/task
        final uuid = const Uuid().v4();
        if (item.type == RecurringType.expense) {
          final newExpense = Expense(
            id: uuid,
            amount: item.amount,
            categoryId: item.categoryId,
            categoryName: _getCategoryName(
              item.categoryId,
              CategoryType.expense,
            ),
            description: item.title,
            notes: 'Auto-generated recurring transaction',
            date: executionDate,
            isRecurring: true,
            recurringId: item.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _expenseNotifier.addExpense(newExpense);
          final prefs = await SharedPreferences.getInstance();
          final symbol = prefs.getString('currency_symbol') ?? r'$';
          final formatted = CurrencyFormatter.format(item.amount, symbol);
          createdNotifications.add('Log Expense: ${item.title} ($formatted)');
        } else if (item.type == RecurringType.income) {
          final newIncome = Income(
            id: uuid,
            amount: item.amount,
            categoryId: item.categoryId,
            categoryName: _getCategoryName(
              item.categoryId,
              CategoryType.income,
            ),
            source: item.title,
            notes: 'Auto-generated recurring income',
            date: executionDate,
            isRecurring: true,
            recurringId: item.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _expenseNotifier.addIncome(newIncome);
          final prefs = await SharedPreferences.getInstance();
          final symbol = prefs.getString('currency_symbol') ?? r'$';
          final formatted = CurrencyFormatter.format(item.amount, symbol);
          createdNotifications.add('Log Income: ${item.title} ($formatted)');
        } else if (item.type == RecurringType.task) {
          final newTask = Task(
            id: uuid,
            title: item.title,
            description: 'Auto-generated recurring task',
            categoryId: item.categoryId,
            categoryName: _getCategoryName(item.categoryId, CategoryType.task),
            priority: TaskPriority.medium,
            status: TaskStatus.pending,
            dueDate: executionDate,
            subtasks: [],
            isRecurring: true,
            recurringRule: item.frequency,
            linkedExpenseIds: [],
            createdAt: DateTime.now(),
            tags: ['recurring'],
          );
          await _taskNotifier.addTask(newTask);
          createdNotifications.add('Task Due: ${item.title}');
        }

        // 2. Advance to the next execution date
        executionDate = _calculateNextDate(executionDate, item.frequency);
        item.nextExecutionDate = executionDate;

        // Stop if end date is reached
        if (item.endDate != null && executionDate.isAfter(item.endDate!)) {
          item.isActive = false;
          break;
        }
        modified = true;
      }

      if (modified) {
        await item.save();
      }
    }

    if (modified) {
      _loadRecurring();
    }

    return createdNotifications;
  }

  // Helper to calculate the next execution date
  DateTime _calculateNextDate(DateTime current, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        var nextMonth = current.month + 1;
        var nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        }
        int targetDay = current.day;
        var nextDate = DateTime(nextYear, nextMonth, targetDay);
        // Safety check for short months (e.g. Jan 31 -> Feb 28/29)
        if (nextDate.month != nextMonth) {
          nextDate = DateTime(
            nextYear,
            nextMonth + 1,
            0,
          ); // Last day of previous month
        }
        return nextDate;
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return current.add(const Duration(days: 30));
    }
  }

  String _getCategoryName(String id, CategoryType type) {
    final catBox = Hive.box<Category>(Boxes.categories);
    final cat = catBox.get(id);
    return cat?.name ?? 'Miscellaneous';
  }

  void refresh() {
    _loadRecurring();
    processDueRecurringItems();
  }
}

// Selector to calculate total subscription cost (annualized)
final subscriptionStatsProvider = Provider<Map<String, double>>((ref) {
  final items = ref.watch(recurringProvider);
  final activeSubs = items.where(
    (i) => i.isActive && i.type == RecurringType.expense,
  );

  double monthlyTotal = 0.0;
  double annualTotal = 0.0;

  for (var sub in activeSubs) {
    double monthlyMultiplier = 0;
    switch (sub.frequency.toLowerCase()) {
      case 'daily':
        monthlyMultiplier = 30.0;
        break;
      case 'weekly':
        monthlyMultiplier = 4.33; // average weeks in month
        break;
      case 'monthly':
        monthlyMultiplier = 1.0;
        break;
      case 'yearly':
        monthlyMultiplier = 1.0 / 12.0;
        break;
    }
    monthlyTotal += sub.amount * monthlyMultiplier;
    annualTotal += sub.amount * monthlyMultiplier * 12;
  }

  return {'monthly': monthlyTotal, 'annual': annualTotal};
});
