import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/task.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';
import '../database/boxes.dart';
import '../providers/currency_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Task> _tasks = [];
  bool _isLoading = true;

  // ─── Colour palette for pie chart slices ───────────────────────────────────
  static const List<Color> _chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final expenseBox = Hive.isBoxOpen(Boxes.expenses)
          ? Hive.box<Expense>(Boxes.expenses)
          : await Hive.openBox<Expense>(Boxes.expenses);
      final incomeBox = Hive.isBoxOpen(Boxes.incomes)
          ? Hive.box<Income>(Boxes.incomes)
          : await Hive.openBox<Income>(Boxes.incomes);
      final taskBox = Hive.isBoxOpen(Boxes.tasks)
          ? Hive.box<Task>(Boxes.tasks)
          : await Hive.openBox<Task>(Boxes.tasks);

      // Set time to beginning of start day and end of end day for inclusive filtering
      final start = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
      final end = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);

      final loadedExpenses = expenseBox.values
          .where((e) => e.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        e.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
      final loadedIncomes = incomeBox.values
          .where((i) => i.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        i.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
      final loadedTasks = taskBox.values
          .where((t) => t.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        t.createdAt.isBefore(end.add(const Duration(seconds: 1))))
          .toList();

      if (!mounted) return;
      setState(() {
        _expenses = loadedExpenses;
        _incomes = loadedIncomes;
        _tasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: NeoBrutalTheme.error,
        ),
      );
    }
  }

  // ─── Computed values ───────────────────────────────────────────────────────
  double get _totalIncome =>
      _incomes.fold(0.0, (sum, i) => sum + i.amount);

  double get _totalExpenses =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _netSavings => _totalIncome - _totalExpenses;

  /// Spending grouped by categoryName (uses actual Expense.categoryName field)
  Map<String, double> get _spendingByCategory {
    final Map<String, double> totals = {};
    for (final e in _expenses) {
      totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.amount;
    }
    return totals;
  }

  /// Uses EXACT Task model field: task.status == TaskStatus.completed
  int get _completedTasksCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  int get _totalTasksCount => _tasks.length;

  double get _taskCompletionRate =>
      _totalTasksCount == 0 ? 0 : _completedTasksCount / _totalTasksCount;

  /// Uses EXACT Task model field: task.priority (TaskPriority enum)
  Map<String, int> get _tasksByPriority {
    final counts = {'High': 0, 'Medium': 0, 'Low': 0};
    for (final t in _tasks) {
      switch (t.priority) {
        case TaskPriority.high:
          counts['High'] = counts['High']! + 1;
        case TaskPriority.medium:
          counts['Medium'] = counts['Medium']! + 1;
        case TaskPriority.low:
          counts['Low'] = counts['Low']! + 1;
      }
    }
    return counts;
  }

  // ─── Date-range picker ─────────────────────────────────────────────────────
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: NeoBrutalTheme.primary,
            onPrimary: Colors.white,
            surface: const Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _dateRange) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyProvider);
    final currencySymbol = getCurrencySymbol(currencyCode);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            tooltip: 'Change date range',
            onPressed: _selectDateRange,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeoBrutalTheme.primary,
          indicatorWeight: 3,
          labelColor: NeoBrutalTheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Financial'),
            Tab(text: 'Tasks'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFinancialTab(currencySymbol),
                _buildTasksTab(),
                _buildInsightsTab(currencySymbol),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FINANCIAL TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFinancialTab(String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range chip
          _buildDateRangeCard(),
          const SizedBox(height: 16),

          // Summary row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  _totalIncome,
                  const Color(0xFF10B981),
                  Icons.arrow_upward,
                  currencySymbol,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  _totalExpenses,
                  const Color(0xFFEF4444),
                  Icons.arrow_downward,
                  currencySymbol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Net Savings',
            _netSavings,
            _netSavings >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            _netSavings >= 0 ? Icons.trending_up : Icons.trending_down,
            currencySymbol,
          ),
          const SizedBox(height: 24),

          // Pie chart
          if (_expenses.isNotEmpty) ...[
            _sectionTitle('Spending by Category'),
            const SizedBox(height: 12),
            _buildSpendingPieChart(currencySymbol),
            const SizedBox(height: 24),
          ],

          // Savings rate bar
          if (_totalIncome > 0) ...[
            _sectionTitle('Savings Rate'),
            const SizedBox(height: 12),
            _buildSavingsRateCard(currencySymbol),
            const SizedBox(height: 16),
          ],

          if (_expenses.isEmpty && _incomes.isEmpty)
            _emptyState('No financial data for the selected date range.'),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final fmt = DateFormat('MMM dd, yyyy');
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16161D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${fmt.format(_dateRange.start)}  →  ${fmt.format(_dateRange.end)}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Text(
              'Change',
              style: TextStyle(
                  color: NeoBrutalTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String currencySymbol,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(amount, currencySymbol),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPieChart(String currencySymbol) {
    final sorted = _spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = sorted.take(8).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: PieChart(
                PieChartData(
                  sections: slices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final cat = entry.value;
                    final pct = _totalExpenses > 0
                        ? (cat.value / _totalExpenses) * 100
                        : 0.0;
                    return PieChartSectionData(
                      value: cat.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      color: _chartColors[idx % _chartColors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Legend below chart
          Column(
            children: slices.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final pct = _totalExpenses > 0
                  ? (cat.value / _totalExpenses) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartColors[idx % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        cat.key,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyFormatter.format(cat.value, currencySymbol),
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateCard(String currencySymbol) {
    final rate = _totalIncome > 0 ? (_netSavings / _totalIncome) : 0.0;
    final ratePct = (rate * 100).clamp(-100.0, 100.0);
    final isPositive = ratePct >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ratePct.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isPositive ? '🎉 Great!' : '⚠️ Over budget',
                style: TextStyle(color: color, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (ratePct.abs() / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'You saved ${CurrencyFormatter.format(_netSavings, currencySymbol)} this period.'
                : 'You overspent ${CurrencyFormatter.format(_netSavings.abs(), currencySymbol)} this period.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TASKS TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat chips
          _buildTaskStatsRow(),
          const SizedBox(height: 24),

          // Radial completion chart
          _sectionTitle('Task Completion Rate'),
          const SizedBox(height: 12),
          _buildTaskCompletionChart(),
          const SizedBox(height: 24),

          // Priority bars
          if (_tasks.isNotEmpty) ...[
            _sectionTitle('Tasks by Priority'),
            const SizedBox(height: 12),
            _buildPriorityBars(),
          ],

          if (_tasks.isEmpty)
            _emptyState('No tasks found for the selected date range.'),
        ],
      ),
    );
  }

  Widget _buildTaskStatsRow() {
    final pending = _totalTasksCount - _completedTasksCount;
    return Row(
      children: [
        _buildStatChip('Total', _totalTasksCount, const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _buildStatChip('Done', _completedTasksCount, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _buildStatChip('Pending', pending, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionChart() {
    final pct = _taskCompletionRate;
    final color = pct >= 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final pending = _totalTasksCount - _completedTasksCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 14,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Complete',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleStat('Total', _totalTasksCount, const Color(0xFF6366F1)),
              _buildStatDivider(),
              _buildSimpleStat('Done', _completedTasksCount, const Color(0xFF10B981)),
              _buildStatDivider(),
              _buildSimpleStat('Pending', pending, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white10,
    );
  }

  Widget _buildPriorityBars() {
    final priorities = _tasksByPriority;
    final total = _totalTasksCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _buildPriorityBar('High', priorities['High']!, total, const Color(0xFFEF4444)),
          const SizedBox(height: 20),
          _buildPriorityBar('Medium', priorities['Medium']!, total, const Color(0xFFF59E0B)),
          const SizedBox(height: 20),
          _buildPriorityBar('Low', priorities['Low']!, total, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text(
              '$count task${count != 1 ? 's' : ''}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 35,
              child: Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INSIGHTS TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInsightsTab(String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Smart Insights'),
          const SizedBox(height: 12),

          _buildInsightCard(
            icon: Icons.savings,
            title: 'Savings Rate',
            message: _generateSavingsInsight(currencySymbol),
            color: _netSavings >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),

          _buildInsightCard(
            icon: Icons.task_alt,
            title: 'Task Completion',
            message: _generateTaskInsight(),
            color:
                _taskCompletionRate >= 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),

          if (_expenses.isNotEmpty) ...[
            _buildInsightCard(
              icon: Icons.category,
              title: 'Top Spending Category',
              message: _generateTopSpendingInsight(currencySymbol),
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 12),
          ],

          // Best productivity day uses task.completedAt (exact field name)
          if (_tasks.isNotEmpty) ...[
            _buildInsightCard(
              icon: Icons.trending_up,
              title: 'Productivity',
              message: _generateProductivityInsight(),
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
          ],

          // Recommendations section
          _sectionTitle('Recommendations'),
          const SizedBox(height: 12),
          _buildRecommendationsCard(currencySymbol),

          if (_expenses.isEmpty && _tasks.isEmpty)
            _emptyState('Not enough data yet. Add expenses and tasks to see insights.'),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(String currencySymbol) {
    final items = <Map<String, String>>[];

    if (_totalIncome > 0 && _taskCompletionRate < 1) {
      items.add({
        'title': 'Complete pending tasks',
        'desc':
            '${_totalTasksCount - _completedTasksCount} task(s) still pending. Clear them to boost productivity.'
      });
    }
    if (_netSavings < 0) {
      items.add({
        'title': 'Review your spending',
        'desc': 'Your expenses exceed your income. Try to cut back in your top category.'
      });
    } else if (_totalIncome > 0 && (_netSavings / _totalIncome) < 0.2) {
      items.add({
        'title': 'Increase your savings',
        'desc': 'Aim for a 20% savings rate. You\'re currently at ${((_netSavings / _totalIncome) * 100).toStringAsFixed(1)}%.'
      });
    }
    if (_expenses.isEmpty) {
      items.add({
        'title': 'Start tracking expenses',
        'desc': 'Log your first expense to get personalised financial insights.'
      });
    }
    if (_tasks.isEmpty) {
      items.add({
        'title': 'Create your first task',
        'desc': 'Tasks help you stay productive and reach your goals faster.'
      });
    }
    if (items.isEmpty) {
      items.add({
        'title': 'All looking great! 🎉',
        'desc': 'Keep up the good work — your finances and tasks are on track.'
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(item['desc']!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Insight text generators ───────────────────────────────────────────────
  String _generateSavingsInsight(String currencySymbol) {
    if (_totalIncome == 0) return 'No income recorded for this period.';
    final rate = (_netSavings / _totalIncome) * 100;
    if (rate >= 20) {
      return 'Excellent! You\'re saving ${rate.toStringAsFixed(1)}% of your income — keep it up!';
    } else if (rate >= 10) {
      return 'Good job! You\'re saving ${rate.toStringAsFixed(1)}%. Try pushing toward 20%.';
    } else if (rate > 0) {
      return 'You\'re saving ${rate.toStringAsFixed(1)}%. Consider cutting back on your top spending category.';
    } else {
      return 'Warning: Your expenses exceed your income by ${CurrencyFormatter.format(_netSavings.abs(), currencySymbol)}.';
    }
  }

  String _generateTaskInsight() {
    if (_totalTasksCount == 0) return 'No tasks created for this period.';
    final rate = (_taskCompletionRate * 100).toStringAsFixed(0);
    if (_taskCompletionRate >= 0.8) {
      return 'Outstanding! You\'ve completed $rate% of your tasks this period.';
    } else if (_taskCompletionRate >= 0.6) {
      return 'Good progress! You\'ve completed $rate% of your tasks.';
    } else {
      return 'You\'ve completed $rate% of your tasks. Focus on finishing the pending ones.';
    }
  }

  String _generateTopSpendingInsight(String currencySymbol) {
    if (_spendingByCategory.isEmpty) return 'No spending data available.';
    final top =
        _spendingByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = _totalExpenses > 0 ? (top.value / _totalExpenses) * 100 : 0.0;
    return 'Your biggest spend is "${top.key}" at ${CurrencyFormatter.format(top.value, currencySymbol)} '
        '(${pct.toStringAsFixed(1)}% of total expenses).';
  }

  String _generateProductivityInsight() {
    if (_tasks.isEmpty) return 'No tasks data available.';
    // Uses task.status (TaskStatus enum) and task.completedAt (DateTime?)
    final Map<int, int> byDay = {};
    for (final t in _tasks.where((t) => t.status == TaskStatus.completed)) {
      if (t.completedAt != null) {
        final day = t.completedAt!.weekday;
        byDay[day] = (byDay[day] ?? 0) + 1;
      }
    }
    if (byDay.isEmpty) {
      return 'Complete some tasks to discover your most productive day.';
    }
    final best = byDay.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Your most productive day is ${_weekdayName(best.key)} with ${best.value} task(s) completed.';
  }

  String _weekdayName(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday >= 1 && weekday <= 7 ? days[weekday] : 'Unknown';
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
