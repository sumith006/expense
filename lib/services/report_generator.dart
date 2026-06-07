import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../database/boxes.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';

class ReportGenerator {
  static final ReportGenerator instance = ReportGenerator._init();

  ReportGenerator._init();

  // Export financial transactions to CSV and return path
  Future<String> generateTransactionsCSV() async {
    final expBox = Hive.box<Expense>(Boxes.expenses);
    final incBox = Hive.box<Income>(Boxes.incomes);

    final List<List<String>> rows = [
      ['Date', 'Type', 'Category', 'Description/Source', 'Amount', 'Notes', 'Is Recurring']
    ];

    // Add Expenses
    for (var exp in expBox.values) {
      rows.add([
        exp.date.toIso8601String().substring(0, 10),
        'Expense',
        exp.categoryName,
        _escapeCSVField(exp.description),
        exp.amount.toStringAsFixed(2),
        _escapeCSVField(exp.notes),
        exp.isRecurring.toString(),
      ]);
    }

    // Add Incomes
    for (var inc in incBox.values) {
      rows.add([
        inc.date.toIso8601String().substring(0, 10),
        'Income',
        inc.categoryName,
        _escapeCSVField(inc.source),
        inc.amount.toStringAsFixed(2),
        _escapeCSVField(inc.notes),
        inc.isRecurring.toString(),
      ]);
    }

    // Sort by date descending
    if (rows.length > 1) {
      final header = rows.first;
      final dataRows = rows.sublist(1);
      dataRows.sort((a, b) => b[0].compareTo(a[0]));
      rows.clear();
      rows.add(header);
      rows.addAll(dataRows);
    }

    return _writeCSVFile('transactions_report', rows);
  }

  // Export tasks summary to CSV and return path
  Future<String> generateTasksCSV() async {
    final taskBox = Hive.box<Task>(Boxes.tasks);

    final List<List<String>> rows = [
      ['Title', 'Description', 'Category', 'Priority', 'Status', 'Due Date', 'Created Date', 'Completed Date', 'Budget Amount', 'Tags', 'Estimated Mins', 'Actual Mins']
    ];

    for (var t in taskBox.values) {
      rows.add([
        _escapeCSVField(t.title),
        _escapeCSVField(t.description),
        t.categoryName,
        t.priority.name,
        t.status.name,
        t.dueDate.toIso8601String().substring(0, 10),
        t.createdAt.toIso8601String().substring(0, 10),
        t.completedAt != null ? t.completedAt!.toIso8601String().substring(0, 10) : '',
        t.budgetAmount != null ? t.budgetAmount!.toStringAsFixed(2) : '0.00',
        _escapeCSVField(t.tags.join(';')),
        t.estimatedMinutes?.toString() ?? '0',
        t.actualMinutes?.toString() ?? '0',
      ]);
    }

    return _writeCSVFile('tasks_report', rows);
  }

  // Helpers to escape CSV fields with commas or quotes
  String _escapeCSVField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<String> _writeCSVFile(String filenamePrefix, List<List<String>> rows) async {
    final csvString = rows.map((row) => row.join(',')).join('\n');
    
    final appDocDir = await getApplicationDocumentsDirectory();
    final String dateString = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final String csvPath = '${appDocDir.path}/${filenamePrefix}_$dateString.csv';

    final File csvFile = File(csvPath);
    await csvFile.writeAsString(csvString);

    return csvPath;
  }
}
