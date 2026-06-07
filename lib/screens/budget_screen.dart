import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants_shared.dart';
import '../../utils/currency_formatter.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    ref.read(budgetProvider.notifier).setPeriod(_selectedMonth.month, _selectedMonth.year);
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final expenseState = ref.watch(expenseProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budget = budgetState.currentBudget;
    final expenseCategories =
        expenseState.categories.where((c) => c.type == CategoryType.expense).toList();

    final monthlySpent = ref.watch(monthlySpentProvider(_selectedMonth));
    final categorySpent = ref.watch(monthlyCategorySpentProvider(_selectedMonth));

    final monthlyLimit = budget?.monthlyTotalBudget ?? 0.0;
    final overallProgress = monthlyLimit > 0 ? (monthlySpent / monthlyLimit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = monthlyLimit > 0 && monthlySpent > monthlyLimit;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBgColor : AppConstants.lightBgColor,
      appBar: AppBar(
        title: const Text('Budget Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showSetBudgetDialog(context, isDark, budget, monthlyLimit),
            tooltip: 'Set monthly budget',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Navigator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Column(
                      children: [
                        Text(
                          _monthYear(_selectedMonth),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCurrentMonth() ? 'Current Month' : 'Past Month',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _isCurrentMonth() ? null : () => _changeMonth(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overall Budget Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverBudget
                        ? [AppConstants.expenseColor, AppConstants.expenseColor.withRed(200)]
                        : [AppConstants.primaryColor, AppConstants.primaryColor.withBlue(220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: (isOverBudget ? AppConstants.expenseColor : AppConstants.primaryColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MONTHLY BUDGET',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (isOverBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⚠ Over Budget',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (monthlyLimit == 0)
                      GestureDetector(
                        onTap: () => _showSetBudgetDialog(context, isDark, budget, monthlyLimit),
                        child: const Text(
                          'Tap + to set a budget',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      )
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(monthlySpent, settings.currencySymbol),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'of ${CurrencyFormatter.format(monthlyLimit, settings.currencySymbol)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(overallProgress * 100).toStringAsFixed(0)}% used',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${CurrencyFormatter.format(monthlyLimit - monthlySpent, settings.currencySymbol)} remaining',
                            style: TextStyle(
                              color: isOverBudget ? Colors.red.shade200 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Budgets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CATEGORY BUDGETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showCategoryBudgetDialog(context, isDark, expenseCategories, budget),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    child: const Text('Edit Limits', style: TextStyle(color: AppConstants.primaryColor, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (expenseCategories.isEmpty)
                _EmptyState(message: 'No expense categories found')
              else
                ...expenseCategories.map((cat) {
                  final catSpent = categorySpent[cat.id] ?? 0.0;
                  final catLimit = budget?.categoryBudgets[cat.id] ?? cat.budgetLimit ?? 0.0;
                  final catProgress = catLimit > 0 ? (catSpent / catLimit).clamp(0.0, 1.0) : 0.0;
                  final catOverBudget = catLimit > 0 && catSpent > catLimit;
                  final catColor = Color(cat.colorValue);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.darkCardColor : Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: catOverBudget
                              ? AppConstants.expenseColor.withValues(alpha: 0.5)
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  IconData(int.tryParse(cat.iconCodePoint) ?? 0xe25a, fontFamily: 'MaterialIcons'),
                                  color: catColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (catLimit > 0)
                                      Text(
                                        '${CurrencyFormatter.format(catSpent, settings.currencySymbol)} / ${CurrencyFormatter.format(catLimit, settings.currencySymbol)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
                                    else
                                      Text(
                                        '${CurrencyFormatter.format(catSpent, settings.currencySymbol)} spent',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              if (catOverBudget)
                                const Icon(Icons.warning_amber_rounded, color: AppConstants.expenseColor, size: 18),
                            ],
                          ),
                          if (catLimit > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: catProgress,
                                backgroundColor: catColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  catOverBudget ? AppConstants.expenseColor : catColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              catOverBudget
                                  ? 'Over by ${CurrencyFormatter.format(catSpent - catLimit, settings.currencySymbol)}'
                                  : '${CurrencyFormatter.format(catLimit - catSpent, settings.currencySymbol)} left',
                              style: TextStyle(
                                fontSize: 11,
                                color: catOverBudget ? AppConstants.expenseColor : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  String _monthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showSetBudgetDialog(BuildContext context, bool isDark, Budget? budget, double currentLimit) {
    final ctrl = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Total Budget Amount',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                await ref.read(budgetProvider.notifier).setTotalBudget(val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCategoryBudgetDialog(
    BuildContext context,
    bool isDark,
    List<Category> categories,
    Budget? budget,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppConstants.darkCardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Category Budget Limits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Set spending limits per category',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ...categories.map((cat) {
              final current = budget?.categoryBudgets[cat.id] ?? cat.budgetLimit ?? 0.0;
              final ctrl = TextEditingController(
                text: current > 0 ? current.toStringAsFixed(2) : '',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(int.tryParse(cat.iconCodePoint) ?? 0xe25a, fontFamily: 'MaterialIcons'),
                        color: Color(cat.colorValue),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        decoration: InputDecoration(
                          labelText: cat.name,
                          prefixText: '  ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) async {
                          final val = double.tryParse(v);
                          await ref.read(budgetProvider.notifier).setCategoryBudget(cat.id, val ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
    );
  }
}
