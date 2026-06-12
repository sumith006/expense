import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants_shared.dart';
import '../../utils/currency_formatter.dart';
import 'expense_screen/add_expense_screen.dart';
import 'income_screen/add_income_screen.dart';

import '../../services/image_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

enum _FilterType { all, expenses, income }

enum _SortBy { dateDesc, dateAsc, amountDesc, amountAsc }

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  _FilterType _filter = _FilterType.all;
  _SortBy _sortBy = _SortBy.dateDesc;
  String _searchQuery = '';
  String? _selectedCategoryId;
  DateTimeRange? _dateRange;
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _filter = _FilterType.all;
            break;
          case 1:
            _filter = _FilterType.expenses;
            break;
          case 2:
            _filter = _FilterType.income;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build combined list
    final allItems = <dynamic>[
      ...expenseState.expenses,
      ...expenseState.incomes,
    ];

    // Filter
    var filtered = allItems.where((item) {
      if (_filter == _FilterType.expenses && item is! Expense) return false;
      if (_filter == _FilterType.income && item is! Income) return false;
      return true;
    }).toList();

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        if (item is Expense) {
          return item.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.categoryName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        } else if (item is Income) {
          return item.source.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.categoryName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        }
        return false;
      }).toList();
    }

    // Category filter
    if (_selectedCategoryId != null) {
      filtered = filtered.where((item) {
        if (item is Expense) return item.categoryId == _selectedCategoryId;
        if (item is Income) return item.categoryId == _selectedCategoryId;
        return false;
      }).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((item) {
        final date = item is Expense ? item.date : (item as Income).date;
        return date.isAfter(
              _dateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      final dateA = a is Expense ? a.date : (a as Income).date;
      final dateB = b is Expense ? b.date : (b as Income).date;
      final amtA = a is Expense ? a.amount : (a as Income).amount;
      final amtB = b is Expense ? b.amount : (b as Income).amount;
      switch (_sortBy) {
        case _SortBy.dateDesc:
          return dateB.compareTo(dateA);
        case _SortBy.dateAsc:
          return dateA.compareTo(dateB);
        case _SortBy.amountDesc:
          return amtB.compareTo(amtA);
        case _SortBy.amountAsc:
          return amtA.compareTo(amtB);
      }
    });

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final item in filtered) {
      final date = item is Expense ? item.date : (item as Income).date;
      final key = DateFormat('MMMM d, y').format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final totalExpenses = filtered.whereType<Expense>().fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final totalIncome = filtered.whereType<Income>().fold(
      0.0,
      (sum, i) => sum + i.amount,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppConstants.darkBgColor
          : AppConstants.lightBgColor,
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickDateRange(context),
            tooltip: 'Filter by date',
          ),
          PopupMenuButton<_SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SortBy.dateDesc,
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: _SortBy.dateAsc,
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: _SortBy.amountDesc,
                child: Text('Highest Amount'),
              ),
              const PopupMenuItem(
                value: _SortBy.amountAsc,
                child: Text('Lowest Amount'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppConstants.darkCardColor : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Summary chips
          if (_dateRange != null || _selectedCategoryId != null) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onSelected: (_) {},
                        onDeleted: () => setState(() => _dateRange = null),
                        selected: true,
                        selectedColor: AppConstants.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Summary Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Expenses',
                  value: CurrencyFormatter.format(
                    totalExpenses,
                    settings.currencySymbol,
                  ),
                  color: AppConstants.expenseColor,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Income',
                  value: CurrencyFormatter.format(
                    totalIncome,
                    settings.currencySymbol,
                  ),
                  color: AppConstants.secondaryColor,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Net',
                  value: CurrencyFormatter.format(
                    totalIncome - totalExpenses,
                    settings.currencySymbol,
                  ),
                  color: (totalIncome - totalExpenses) >= 0
                      ? AppConstants.secondaryColor
                      : AppConstants.expenseColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Transactions list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, idx) {
                      final dateKey = grouped.keys.elementAt(idx);
                      final items = grouped[dateKey]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(
                                    items.whereType<Expense>().fold(
                                          0.0,
                                          (s, e) => s + e.amount,
                                        ) -
                                        items.whereType<Income>().fold(
                                          0.0,
                                          (s, i) => s + i.amount,
                                        ),
                                    settings.currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (item) => _TransactionTile(
                              item: item,
                              settings: settings,
                              isDark: isDark,
                              context: context,
                              onTap: () {
                                if (item is Expense) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddExpenseScreen(existingExpense: item),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddIncomeScreen(
                                        existingIncome: item as Income,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onDismissed: () {
                                if (item is Expense) {
                                  ref
                                      .read(expenseProvider.notifier)
                                      .deleteExpense(item.id);
                                } else {
                                  ref
                                      .read(expenseProvider.notifier)
                                      .deleteIncome((item as Income).id);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transaction deleted'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic item;
  final dynamic settings;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final BuildContext context;

  const _TransactionTile({
    required this.item,
    required this.settings,
    required this.isDark,
    required this.onTap,
    required this.onDismissed,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = item is Expense;
    final amount = isExpense
        ? (item as Expense).amount
        : (item as Income).amount;
    final label = isExpense
        ? (item as Expense).description
        : (item as Income).source;
    final category = isExpense
        ? (item as Expense).categoryName
        : (item as Income).categoryName;
    final date = isExpense ? (item as Expense).date : (item as Income).date;
    final color = isExpense
        ? AppConstants.expenseColor
        : AppConstants.secondaryColor;
    final receiptPath = isExpense ? (item as Expense).receiptImagePath : null;

    return Dismissible(
      key: Key(isExpense ? (item as Expense).id : (item as Income).id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppConstants.expenseColor,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppConstants.expenseColor),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$category • ${DateFormat('h:mm a').format(date)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (receiptPath != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => ImageService.showReceiptPreview(context, receiptPath),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attachment_rounded, size: 10, color: AppConstants.primaryColor),
                                    SizedBox(width: 2),
                                    Text('RECEIPT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount, settings.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
