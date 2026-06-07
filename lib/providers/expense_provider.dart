import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ExpenseState {
  final List<Expense> expenses;
  final List<Income> incomes;
  final List<Category> categories;

  ExpenseState({
    required this.expenses,
    required this.incomes,
    required this.categories,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    List<Income>? incomes,
    List<Category>? categories,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      categories: categories ?? this.categories,
    );
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier();
});

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  late final Box<Expense> _expenseBox;
  late final Box<Income> _incomeBox;
  late final Box<Category> _categoryBox;

  ExpenseNotifier()
      : super(ExpenseState(expenses: [], incomes: [], categories: [])) {
    _init();
  }

  void _init() {
    _expenseBox = Hive.box<Expense>(Boxes.expenses);
    _incomeBox = Hive.box<Income>(Boxes.incomes);
    _categoryBox = Hive.box<Category>(Boxes.categories);
    
    _seedCategoriesIfNeeded();
    _loadAll();
  }

  void _loadAll() {
    state = ExpenseState(
      expenses: _expenseBox.values.toList()..sort((a, b) => b.date.compareTo(a.date)),
      incomes: _incomeBox.values.toList()..sort((a, b) => b.date.compareTo(a.date)),
      categories: _categoryBox.values.toList(),
    );
  }

  void refresh() {
    _loadAll();
  }

  void _seedCategoriesIfNeeded() {
    if (_categoryBox.isEmpty) {
      final defaultCategories = [
        Category(id: 'cat_food', name: 'Food & Dining', iconCodePoint: 0xe543.toString(), colorValue: 0xFFEF4444, type: CategoryType.expense, isDefault: true),
        Category(id: 'cat_shopping', name: 'Shopping', iconCodePoint: 0xe8ee.toString(), colorValue: 0xFF6366F1, type: CategoryType.expense, isDefault: true),
        Category(id: 'cat_transport', name: 'Transport', iconCodePoint: 0xe1c4.toString(), colorValue: 0xFF06B6D4, type: CategoryType.expense, isDefault: true),
        Category(id: 'cat_entertainment', name: 'Entertainment', iconCodePoint: 0xe30d.toString(), colorValue: 0xFFF59E0B, type: CategoryType.expense, isDefault: true),
        Category(id: 'cat_utilities', name: 'Bills & Utilities', iconCodePoint: 0xe57e.toString(), colorValue: 0xFFEC4899, type: CategoryType.expense, isDefault: true),
        Category(id: 'cat_misc_expense', name: 'Miscellaneous', iconCodePoint: 0xe838.toString(), colorValue: 0xFF64748B, type: CategoryType.expense, isDefault: true),

        Category(id: 'cat_salary', name: 'Salary', iconCodePoint: 0xe25a.toString(), colorValue: 0xFF10B981, type: CategoryType.income, isDefault: true),
        Category(id: 'cat_freelance', name: 'Freelance', iconCodePoint: 0xe8f8.toString(), colorValue: 0xFF14B8A6, type: CategoryType.income, isDefault: true),
        Category(id: 'cat_investments', name: 'Investments', iconCodePoint: 0xf00e.toString(), colorValue: 0xFF8B5CF6, type: CategoryType.income, isDefault: true),
        Category(id: 'cat_misc_income', name: 'Miscellaneous Income', iconCodePoint: 0xe868.toString(), colorValue: 0xFF64748B, type: CategoryType.income, isDefault: true),

        Category(id: 'cat_work', name: 'Work', iconCodePoint: 0xe8f8.toString(), colorValue: 0xFF6366F1, type: CategoryType.task, isDefault: true),
        Category(id: 'cat_personal', name: 'Personal', iconCodePoint: 0xe88a.toString(), colorValue: 0xFFEC4899, type: CategoryType.task, isDefault: true),
        Category(id: 'cat_finance_task', name: 'Finance Task', iconCodePoint: 0xe25a.toString(), colorValue: 0xFF10B981, type: CategoryType.task, isDefault: true),
      ];

      for (var cat in defaultCategories) {
        _categoryBox.put(cat.id, cat);
      }
    }
  }

  // --- Expenses ---
  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _loadAll();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _loadAll();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    _loadAll();
  }

  // --- Incomes ---
  Future<void> addIncome(Income income) async {
    await _incomeBox.put(income.id, income);
    _loadAll();
  }

  Future<void> updateIncome(Income income) async {
    await _incomeBox.put(income.id, income);
    _loadAll();
  }

  Future<void> deleteIncome(String id) async {
    await _incomeBox.delete(id);
    _loadAll();
  }

  // --- Categories ---
  Future<void> addCategory(Category category) async {
    await _categoryBox.put(category.id, category);
    _loadAll();
  }

  Future<void> updateCategory(Category category) async {
    await _categoryBox.put(category.id, category);
    _loadAll();
  }

  Future<void> deleteCategory(String id) async {
    final category = _categoryBox.get(id);
    if (category == null || category.isDefault) return;

    String fallbackId;
    if (category.type == CategoryType.expense) {
      fallbackId = 'cat_misc_expense';
    } else if (category.type == CategoryType.income) {
      fallbackId = 'cat_misc_income';
    } else {
      fallbackId = 'cat_personal';
    }

    // Update expenses
    for (var exp in _expenseBox.values.where((e) => e.categoryId == id)) {
      exp.categoryId = fallbackId;
      await exp.save();
    }

    // Update incomes
    for (var inc in _incomeBox.values.where((i) => i.categoryId == id)) {
      inc.categoryId = fallbackId;
      await inc.save();
    }
    await _categoryBox.delete(id);
    _loadAll();
  }
}

// Keep the old providers for compatibility if needed elsewhere
final expenseBoxProvider = Provider<Box<Expense>>((ref) {
  return Hive.box<Expense>(Boxes.expenses);
});

final expenseListProvider = StreamProvider<List<Expense>>((ref) {
  final box = ref.watch(expenseBoxProvider);
  final controller = StreamController<List<Expense>>();
  controller.add(box.values.toList());
  final subscription = box.watch().listen((event) {
    controller.add(box.values.toList());
  });
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});

// ─── Dashboard summary providers ─────────────────────────────────────────────

/// Total income across all time
final totalIncomeProvider = Provider<double>((ref) {
  final state = ref.watch(expenseProvider);
  return state.incomes.fold(0.0, (sum, i) => sum + i.amount);
});

/// Total expenses across all time
final totalExpenseProvider = Provider<double>((ref) {
  final state = ref.watch(expenseProvider);
  return state.expenses.fold(0.0, (sum, e) => sum + e.amount);
});

/// Net balance = income - expenses
final netBalanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});
