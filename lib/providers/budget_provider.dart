import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../database/boxes.dart';
import '../models/budget.dart';
import 'expense_provider.dart';

class BudgetState {
  final int month;
  final int year;
  final Budget? currentBudget;

  BudgetState({
    required this.month,
    required this.year,
    this.currentBudget,
  });

  BudgetState copyWith({
    int? month,
    int? year,
    Budget? currentBudget,
  }) {
    return BudgetState(
      month: month ?? this.month,
      year: year ?? this.year,
      currentBudget: currentBudget ?? this.currentBudget,
    );
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<BudgetState> {
  late final Box<Budget> _budgetBox;

  BudgetNotifier()
      : super(BudgetState(
          month: DateTime.now().month,
          year: DateTime.now().year,
        )) {
    _init();
  }

  void _init() {
    _budgetBox = Hive.box<Budget>(Boxes.budgets);
    _loadBudgetForPeriod(state.month, state.year);
  }

  void _loadBudgetForPeriod(int month, int year) {
    // Find a budget that matches the month and year
    final match = _budgetBox.values.firstWhere(
      (b) => b.month == month && b.year == year,
      orElse: () => Budget(
        id: const Uuid().v4(),
        monthlyTotalBudget: 0.0,
        categoryBudgets: {},
        month: month,
        year: year,
        lastUpdated: DateTime.now(),
      ),
    );

    state = BudgetState(
      month: month,
      year: year,
      currentBudget: match.monthlyTotalBudget > 0 || match.categoryBudgets.isNotEmpty ? match : null,
    );
  }

  void setPeriod(int month, int year) {
    _loadBudgetForPeriod(month, year);
  }

  Future<void> setTotalBudget(double amount) async {
    var budget = _getCurrentOrCreateBudget();
    budget.monthlyTotalBudget = amount;
    budget.lastUpdated = DateTime.now();

    await _budgetBox.put(budget.id, budget);
    state = state.copyWith(currentBudget: budget);
  }

  Future<void> setCategoryBudget(String categoryId, double amount) async {
    var budget = _getCurrentOrCreateBudget();
    // Copy the map to ensure modifications are registered
    final updatedBudgets = Map<String, double>.from(budget.categoryBudgets);
    if (amount <= 0) {
      updatedBudgets.remove(categoryId);
    } else {
      updatedBudgets[categoryId] = amount;
    }
    budget.categoryBudgets = updatedBudgets;
    budget.lastUpdated = DateTime.now();

    await _budgetBox.put(budget.id, budget);
    state = state.copyWith(currentBudget: budget);
  }

  Budget _getCurrentOrCreateBudget() {
    if (state.currentBudget != null) {
      return state.currentBudget!;
    }
    return Budget(
      id: const Uuid().v4(),
      monthlyTotalBudget: 0.0,
      categoryBudgets: {},
      month: state.month,
      year: state.year,
      lastUpdated: DateTime.now(),
    );
  }

  void refresh() {
    _loadBudgetForPeriod(state.month, state.year);
  }
}

// --- Selectors for Budget calculations ---
// Calculate total spent in the selected month & year
final monthlySpentProvider = Provider.family<double, DateTime>((ref, date) {
  final expenseState = ref.watch(expenseProvider);
  return expenseState.expenses
      .where((e) => e.date.month == date.month && e.date.year == date.year)
      .fold(0.0, (sum, exp) => sum + exp.amount);
});

// Calculate spent by category for a specific month
final monthlyCategorySpentProvider = Provider.family<Map<String, double>, DateTime>((ref, date) {
  final expenseState = ref.watch(expenseProvider);
  final result = <String, double>{};

  final targetExpenses = expenseState.expenses
      .where((e) => e.date.month == date.month && e.date.year == date.year);

  for (var exp in targetExpenses) {
    result[exp.categoryId] = (result[exp.categoryId] ?? 0.0) + exp.amount;
  }
  return result;
});
