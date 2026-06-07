import 'dart:convert';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../database/boxes.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';

class BackupService {
  static final BackupService instance = BackupService._init();

  BackupService._init();

  // Export all Hive boxes to a JSON file
  Future<String> exportBackup() async {
    final Map<String, dynamic> backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': _exportCategories(),
      'expenses': _exportExpenses(),
      'incomes': _exportIncomes(),
      'tasks': _exportTasks(),
      'budgets': _exportBudgets(),
      'goals': _exportGoals(),
      'recurring': _exportRecurring(),
    };

    final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    // Try to save to Downloads folder first, fallback to Documents
    Directory? backupDir = await getDownloadsDirectory();
    backupDir ??= await getApplicationDocumentsDirectory();

    final String dateString = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final String backupPath = '${backupDir.path}/backup_$dateString.json';

    final File backupFile = File(backupPath);
    await backupFile.writeAsString(jsonString);

    return backupPath;
  }

  // Restore Hive boxes from a picked JSON file
  Future<bool> restoreBackup() async {
    // TODO: Implement file picker without file_picker dependency
    // File picker dependency causes AAR metadata conflicts with API 36
    // For now, this feature is disabled
    return false;
  }

  // --- Helpers for Export ---
  List<Map<String, dynamic>> _exportCategories() {
    final box = Hive.box<Category>(Boxes.categories);
    return box.values.map((c) => {
      'id': c.id,
      'name': c.name,
      'iconCodePoint': c.iconCodePoint,
      'colorValue': c.colorValue,
      'type': c.type.index,
      'isDefault': c.isDefault,
      'budgetLimit': c.budgetLimit,
    }).toList();
  }

  List<Map<String, dynamic>> _exportExpenses() {
    final box = Hive.box<Expense>(Boxes.expenses);
    return box.values.map((e) => {
      'id': e.id,
      'amount': e.amount,
      'categoryId': e.categoryId,
      'categoryName': e.categoryName,
      'description': e.description,
      'notes': e.notes,
      'date': e.date.toIso8601String(),
      'receiptImagePath': e.receiptImagePath,
      'linkedTaskId': e.linkedTaskId,
      'isRecurring': e.isRecurring,
      'recurringId': e.recurringId,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportIncomes() {
    final box = Hive.box<Income>(Boxes.incomes);
    return box.values.map((i) => {
      'id': i.id,
      'amount': i.amount,
      'categoryId': i.categoryId,
      'categoryName': i.categoryName,
      'source': i.source,
      'notes': i.notes,
      'date': i.date.toIso8601String(),
      'isRecurring': i.isRecurring,
      'recurringId': i.recurringId,
      'createdAt': i.createdAt.toIso8601String(),
      'updatedAt': (i.updatedAt ?? i.createdAt).toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportTasks() {
    final box = Hive.box<Task>(Boxes.tasks);
    return box.values.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'categoryId': t.categoryId,
      'categoryName': t.categoryName,
      'priority': t.priority.index,
      'status': t.status.index,
      'dueDate': t.dueDate.toIso8601String(),
      'dueHour': t.dueHour,
      'dueMinute': t.dueMinute,
      'subtasks': t.subtasks.map((sub) => {
        'id': sub.id,
        'title': sub.title,
        'isCompleted': sub.isCompleted,
        'completedAt': sub.completedAt?.toIso8601String(),
      }).toList(),
      'notes': t.notes,
      'isRecurring': t.isRecurring,
      'recurringRule': t.recurringRule,
      'budgetAmount': t.budgetAmount,
      'linkedExpenseIds': t.linkedExpenseIds,
      'createdAt': t.createdAt.toIso8601String(),
      'completedAt': t.completedAt?.toIso8601String(),
      'tags': t.tags,
      'estimatedMinutes': t.estimatedMinutes,
      'actualMinutes': t.actualMinutes,
    }).toList();
  }

  List<Map<String, dynamic>> _exportBudgets() {
    final box = Hive.box<Budget>(Boxes.budgets);
    return box.values.map((b) => {
      'id': b.id,
      'monthlyTotalBudget': b.monthlyTotalBudget,
      'categoryBudgets': b.categoryBudgets,
      'month': b.month,
      'year': b.year,
      'lastUpdated': b.lastUpdated.toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportGoals() {
    final box = Hive.box<SavingsGoal>(Boxes.goals);
    return box.values.map((g) => {
      'id': g.id,
      'name': g.name,
      'targetAmount': g.targetAmount,
      'currentAmount': g.currentAmount,
      'targetDate': g.targetDate.toIso8601String(),
      'linkedTaskId': g.linkedTaskId,
      'requiredTaskCount': g.requiredTaskCount,
      'currentTaskCount': g.currentTaskCount,
      'isAchieved': g.isAchieved,
      'createdAt': g.createdAt.toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportRecurring() {
    final box = Hive.box<RecurringTransaction>(Boxes.recurring);
    return box.values.map((r) => {
      'id': r.id,
      'title': r.title,
      'amount': r.amount,
      'categoryId': r.categoryId,
      'type': r.type.index,
      'frequency': r.frequency,
      'startDate': r.startDate.toIso8601String(),
      'endDate': r.endDate?.toIso8601String(),
      'dayOfMonth': r.dayOfMonth,
      'dayOfWeek': r.dayOfWeek,
      'nextExecutionDate': r.nextExecutionDate.toIso8601String(),
      'isActive': r.isActive,
    }).toList();
  }

  // --- Helpers for Import ---
  Future<void> _restoreCategories(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Category>(Boxes.categories);
    await box.clear();
    for (var item in list) {
      final c = Category(
        id: item['id'],
        name: item['name'],
        iconCodePoint: item['iconCodePoint'],
        colorValue: item['colorValue'],
        type: CategoryType.values[item['type']],
        isDefault: item['isDefault'] ?? false,
        budgetLimit: item['budgetLimit'] != null ? (item['budgetLimit'] as num).toDouble() : null,
      );
      await box.put(c.id, c);
    }
  }

  Future<void> _restoreExpenses(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Expense>(Boxes.expenses);
    await box.clear();
    for (var item in list) {
      final e = Expense(
        id: item['id'],
        amount: (item['amount'] as num).toDouble(),
        categoryId: item['categoryId'],
        categoryName: item['categoryName'],
        description: item['description'],
        notes: item['notes'],
        date: DateTime.parse(item['date']),
        receiptImagePath: item['receiptImagePath'],
        linkedTaskId: item['linkedTaskId'],
        isRecurring: item['isRecurring'] ?? false,
        recurringId: item['recurringId'],
        createdAt: DateTime.parse(item['createdAt']),
        updatedAt: DateTime.parse(item['updatedAt']),
      );
      await box.put(e.id, e);
    }
  }

  Future<void> _restoreIncomes(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Income>(Boxes.incomes);
    await box.clear();
    for (var item in list) {
      final i = Income(
        id: item['id'],
        amount: (item['amount'] as num).toDouble(),
        categoryId: item['categoryId'],
        categoryName: item['categoryName'],
        source: item['source'],
        notes: item['notes'],
        date: DateTime.parse(item['date']),
        isRecurring: item['isRecurring'] ?? false,
        recurringId: item['recurringId'],
        createdAt: DateTime.parse(item['createdAt']),
        updatedAt: DateTime.parse(item['updatedAt'] ?? item['createdAt']),
      );
      await box.put(i.id, i);
    }
  }

  Future<void> _restoreTasks(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Task>(Boxes.tasks);
    await box.clear();
    for (var item in list) {
      final subList = (item['subtasks'] as List<dynamic>?)?.map((sub) {
        return Subtask(
          id: sub['id'],
          title: sub['title'],
          isCompleted: sub['isCompleted'] ?? false,
          completedAt: sub['completedAt'] != null ? DateTime.parse(sub['completedAt']) : null,
        );
      }).toList() ?? [];

      final t = Task(
        id: item['id'],
        title: item['title'],
        description: item['description'] ?? '',
        categoryId: item['categoryId'],
        categoryName: item['categoryName'],
        priority: TaskPriority.values[item['priority']],
        status: TaskStatus.values[item['status']],
        dueDate: DateTime.parse(item['dueDate']),
        dueHour: item['dueHour'],
        dueMinute: item['dueMinute'],
        subtasks: subList,
        notes: item['notes'],
        isRecurring: item['isRecurring'] ?? false,
        recurringRule: item['recurringRule'],
        budgetAmount: item['budgetAmount'] != null ? (item['budgetAmount'] as num).toDouble() : null,
        linkedExpenseIds: List<String>.from(item['linkedExpenseIds'] ?? []),
        createdAt: DateTime.parse(item['createdAt']),
        completedAt: item['completedAt'] != null ? DateTime.parse(item['completedAt']) : null,
        tags: List<String>.from(item['tags'] ?? []),
        estimatedMinutes: item['estimatedMinutes'],
        actualMinutes: item['actualMinutes'],
      );
      await box.put(t.id, t);
    }
  }

  Future<void> _restoreBudgets(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Budget>(Boxes.budgets);
    await box.clear();
    for (var item in list) {
      final catBudgets = <String, double>{};
      if (item['categoryBudgets'] != null) {
        (item['categoryBudgets'] as Map<dynamic, dynamic>).forEach((k, v) {
          catBudgets[k.toString()] = (v as num).toDouble();
        });
      }

      final b = Budget(
        id: item['id'],
        monthlyTotalBudget: (item['monthlyTotalBudget'] as num).toDouble(),
        categoryBudgets: catBudgets,
        month: item['month'],
        year: item['year'],
        lastUpdated: DateTime.parse(item['lastUpdated']),
      );
      await box.put(b.id, b);
    }
  }

  Future<void> _restoreGoals(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<SavingsGoal>(Boxes.goals);
    await box.clear();
    for (var item in list) {
      final g = SavingsGoal(
        id: item['id'],
        name: item['name'],
        targetAmount: (item['targetAmount'] as num).toDouble(),
        currentAmount: (item['currentAmount'] as num).toDouble(),
        targetDate: DateTime.parse(item['targetDate']),
        linkedTaskId: item['linkedTaskId'],
        requiredTaskCount: item['requiredTaskCount'],
        currentTaskCount: item['currentTaskCount'] ?? 0,
        isAchieved: item['isAchieved'] ?? false,
        createdAt: DateTime.parse(item['createdAt']),
      );
      await box.put(g.id, g);
    }
  }

  Future<void> _restoreRecurring(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<RecurringTransaction>(Boxes.recurring);
    await box.clear();
    for (var item in list) {
      final r = RecurringTransaction(
        id: item['id'],
        title: item['title'],
        amount: (item['amount'] as num).toDouble(),
        categoryId: item['categoryId'],
        type: RecurringType.values[item['type']],
        frequency: item['frequency'],
        startDate: DateTime.parse(item['startDate']),
        endDate: item['endDate'] != null ? DateTime.parse(item['endDate']) : null,
        dayOfMonth: item['dayOfMonth'],
        dayOfWeek: item['dayOfWeek'],
        nextExecutionDate: DateTime.parse(item['nextExecutionDate']),
        isActive: item['isActive'] ?? true,
      );
      await box.put(r.id, r);
    }
  }
}
