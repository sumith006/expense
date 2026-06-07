import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';
import '../providers/expense_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants_shared.dart';
import '../utils/currency_formatter.dart';
import 'expense_screen/add_expense_screen.dart';
import 'income_screen/add_income_screen.dart';
import 'task_screen/task_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final tasks = ref.watch(taskProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build event maps
    final expenseEvents = <DateTime, List<Expense>>{};
    for (final e in expenseState.expenses) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      expenseEvents.putIfAbsent(key, () => []).add(e);
    }

    final incomeEvents = <DateTime, List<Income>>{};
    for (final i in expenseState.incomes) {
      final key = DateTime(i.date.year, i.date.month, i.date.day);
      incomeEvents.putIfAbsent(key, () => []).add(i);
    }

    final taskEvents = <DateTime, List<Task>>{};
    for (final t in tasks) {
      final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      taskEvents.putIfAbsent(key, () => []).add(t);
    }

    // Get events for selected day
    final selDay = _selectedDay ?? _focusedDay;
    final selKey = DateTime(selDay.year, selDay.month, selDay.day);
    final selectedExpenses = expenseEvents[selKey] ?? [];
    final selectedIncomes = incomeEvents[selKey] ?? [];
    final selectedTasks = taskEvents[selKey] ?? [];

    final dayTotal =
        selectedExpenses.fold(0.0, (s, e) => s + e.amount) -
        selectedIncomes.fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      backgroundColor: isDark
          ? AppConstants.darkBgColor
          : AppConstants.lightBgColor,
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                final events = <Object>[];
                events.addAll(expenseEvents[key] ?? []);
                events.addAll(incomeEvents[key] ?? []);
                events.addAll(taskEvents[key] ?? []);
                return events;
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (f) => setState(() => _calendarFormat = f),
              onPageChanged: (f) => setState(() => _focusedDay = f),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppConstants.expenseColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 5.5,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                weekendTextStyle: TextStyle(
                  color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                ),
                defaultTextStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                outsideTextStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                todayTextStyle: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 12,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppConstants.primaryColor,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Selected day summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(selDay),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (selectedExpenses.isNotEmpty || selectedIncomes.isNotEmpty)
                  Text(
                    dayTotal >= 0
                        ? '-${CurrencyFormatter.format(dayTotal, settings.currencySymbol)}'
                        : '+${CurrencyFormatter.format(-dayTotal, settings.currencySymbol)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dayTotal >= 0
                          ? AppConstants.expenseColor
                          : AppConstants.secondaryColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Events for the day
          Expanded(
            child:
                (selectedExpenses.isEmpty &&
                    selectedIncomes.isEmpty &&
                    selectedTasks.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nothing recorded for this day',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    children: [
                      if (selectedTasks.isNotEmpty) ...[
                        _DaySection(
                          label: 'TASKS',
                          color: AppConstants.primaryColor,
                        ),
                        ...selectedTasks.map(
                          (task) => _TaskDayTile(
                            task: task,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(taskId: task.id),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (selectedExpenses.isNotEmpty) ...[
                        _DaySection(
                          label: 'EXPENSES',
                          color: AppConstants.expenseColor,
                        ),
                        ...selectedExpenses.map(
                          (exp) => _TransactionDayTile(
                            title: exp.description,
                            subtitle: exp.categoryName,
                            amount:
                                '-${CurrencyFormatter.format(exp.amount, settings.currencySymbol)}',
                            amountColor: AppConstants.expenseColor,
                            icon: Icons.arrow_downward,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (selectedIncomes.isNotEmpty) ...[
                        _DaySection(
                          label: 'INCOME',
                          color: AppConstants.secondaryColor,
                        ),
                        ...selectedIncomes.map(
                          (inc) => _TransactionDayTile(
                            title: inc.source,
                            subtitle: inc.categoryName,
                            amount:
                                '+${CurrencyFormatter.format(inc.amount, settings.currencySymbol)}',
                            amountColor: AppConstants.secondaryColor,
                            icon: Icons.arrow_upward,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddIncomeScreen(existingIncome: inc),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String label;
  final Color color;
  const _DaySection({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDayTile extends StatelessWidget {
  final Task task;
  final bool isDark;
  final VoidCallback onTap;

  const _TaskDayTile({
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppConstants.expenseColor,
      TaskPriority.medium => AppConstants.warningColor,
      TaskPriority.low => AppConstants.secondaryColor,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              task.status == TaskStatus.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.status == TaskStatus.completed
                  ? AppConstants.secondaryColor
                  : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (task.dueTime != null)
                    Text(
                      task.dueTime!.format(context),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDayTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _TransactionDayTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: amountColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
