import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'expense_provider.dart';
import 'task_provider.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/line_chart_widget.dart';
import '../utils/constants_shared.dart';

class FinancialReportData {
  final List<CategoryPieData> pieData;
  final List<BarDataPoint> cashflowBarData;
  final List<LineDataPoint> expenseLineData;
  final List<LineDataPoint> incomeLineData;
  final double totalExpense;

  FinancialReportData({
    required this.pieData,
    required this.cashflowBarData,
    required this.expenseLineData,
    required this.incomeLineData,
    required this.totalExpense,
  });
}

final financialReportProvider = Provider<FinancialReportData>((ref) {
  final expenseState = ref.watch(expenseProvider);
  
  // 1. Group expenses by category
  final categoryTotals = <String, double>{};
  final categoryColors = <String, Color>{};
  double totalExpense = 0.0;

  for (var exp in expenseState.expenses) {
    categoryTotals[exp.categoryName] = (categoryTotals[exp.categoryName] ?? 0.0) + exp.amount;
    totalExpense += exp.amount;
    
    final cat = expenseState.categories.firstWhere(
      (c) => c.id == exp.categoryId,
      orElse: () => Category(
        id: '',
        name: '',
        iconCodePoint: '',
        colorValue: Colors.red.value,
        type: CategoryType.expense,
        isDefault: false,
      ),
    );
    categoryColors[exp.categoryName] = Color(cat.colorValue);
  }

  final pieData = categoryTotals.entries.map((entry) {
    return CategoryPieData(
      name: entry.key,
      value: entry.value,
      color: categoryColors[entry.key] ?? AppConstants.primaryColor,
    );
  }).toList();

  // 2. Monthly cashflow data (Last 6 months)
  final cashflowBarData = <BarDataPoint>[];
  final today = DateTime.now();

  for (var i = 5; i >= 0; i--) {
    final monthDate = DateTime(today.year, today.month - i, 1);
    final monthLabel = _getMonthAbbreviation(monthDate.month);
    
    final double spentInMonth = expenseState.expenses
        .where((e) => e.date.month == monthDate.month && e.date.year == monthDate.year)
        .fold(0.0, (sum, exp) => sum + exp.amount);

    cashflowBarData.add(BarDataPoint(
      label: monthLabel,
      value: spentInMonth,
      color: i == 0 ? AppConstants.primaryColor : Colors.grey.withValues(alpha: 0.5),
    ));
  }

  // 3. Line chart data (Weekly for last 4 weeks)
  final line1Data = <LineDataPoint>[]; // Expenses
  final line2Data = <LineDataPoint>[]; // Incomes

  for (var w = 3; w >= 0; w--) {
    final weekStart = today.subtract(Duration(days: today.weekday - 1 + (w * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    final weekLabel = 'W${4 - w}';

    final double spent = expenseState.expenses
        .where((e) => e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && e.date.isBefore(weekEnd))
        .fold(0.0, (sum, exp) => sum + exp.amount);

    final double earned = expenseState.incomes
        .where((i) => i.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && i.date.isBefore(weekEnd))
        .fold(0.0, (sum, inc) => sum + inc.amount);

    line1Data.add(LineDataPoint(x: (3 - w).toDouble(), y: spent, label: weekLabel));
    line2Data.add(LineDataPoint(x: (3 - w).toDouble(), y: earned, label: weekLabel));
  }

  return FinancialReportData(
    pieData: pieData,
    cashflowBarData: cashflowBarData,
    expenseLineData: line1Data,
    incomeLineData: line2Data,
    totalExpense: totalExpense,
  );
});

class ProductivityReportData {
  final List<CategoryPieData> productivityPie;
  final List<BarDataPoint> priorityBarData;
  final List<LineDataPoint> dailyProductivityData;
  final int totalCount;

  ProductivityReportData({
    required this.productivityPie,
    required this.priorityBarData,
    required this.dailyProductivityData,
    required this.totalCount,
  });
}

final productivityReportProvider = Provider<ProductivityReportData>((ref) {
  final tasks = ref.watch(taskProvider);
  final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
  final pendingCount = tasks.where((t) => t.status == TaskStatus.pending).length;
  final totalCount = tasks.length;

  final productivityPie = [
    CategoryPieData(name: 'Completed', value: completedCount.toDouble(), color: AppConstants.secondaryColor),
    CategoryPieData(name: 'Pending', value: pendingCount.toDouble(), color: AppConstants.primaryColor),
  ];

  final highCount = tasks.where((t) => t.priority == TaskPriority.high).length;
  final medCount = tasks.where((t) => t.priority == TaskPriority.medium).length;
  final lowCount = tasks.where((t) => t.priority == TaskPriority.low).length;

  final priorityBarData = [
    BarDataPoint(label: 'HIGH', value: highCount.toDouble(), color: AppConstants.expenseColor),
    BarDataPoint(label: 'MEDIUM', value: medCount.toDouble(), color: AppConstants.warningLight),
    BarDataPoint(label: 'LOW', value: lowCount.toDouble(), color: Colors.blue),
  ];

  final today = DateTime.now();
  final dailyProductivityData = <LineDataPoint>[];

  for (var i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final dayLabel = DateFormat('E').format(date);
    
    final completedOnDay = tasks.where((t) =>
        t.status == TaskStatus.completed &&
        t.completedAt != null &&
        t.completedAt!.day == date.day &&
        t.completedAt!.month == date.month &&
        t.completedAt!.year == date.year).length;

    dailyProductivityData.add(LineDataPoint(
      x: (6 - i).toDouble(),
      y: completedOnDay.toDouble(),
      label: dayLabel,
    ));
  }

  return ProductivityReportData(
    productivityPie: productivityPie,
    priorityBarData: priorityBarData,
    dailyProductivityData: dailyProductivityData,
    totalCount: totalCount,
  );
});

String _getMonthAbbreviation(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month >= 1 && month <= 12) {
    return months[month - 1];
  }
  return '';
}
