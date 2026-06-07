import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/routes.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../widgets/transaction_item_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/custom_filter_chip.dart';
import '../utils/constants_shared.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filterAndSort(List<dynamic> list) {
    var result = List<dynamic>.from(list);

    // 1. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        final desc =
            item is Expense ? item.description : (item as Income).source;
        final notes = item.notes.toLowerCase();
        final catName = item.categoryName.toLowerCase();
        return desc.toLowerCase().contains(query) ||
            notes.contains(query) ||
            catName.contains(query) ||
            item.amount.toString().contains(query);
      }).toList();
    }

    // 2. Category Filter
    if (_selectedCategoryId != null) {
      result =
          result.where((item) => item.categoryId == _selectedCategoryId).toList();
    }

    // 3. Date Range Filter
    if (_dateRange != null) {
      result = result.where((item) {
        final date = item.date as DateTime;
        return date.isAfter(
              _dateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // 4. Sorting
    result.sort((a, b) {
      final dateA = a.date as DateTime;
      final dateB = b.date as DateTime;
      final amountA = a.amount as double;
      final amountB = b.amount as double;

      switch (_sortBy) {
        case 'date_desc':
          return dateB.compareTo(dateA);
        case 'date_asc':
          return dateA.compareTo(dateB);
        case 'amount_desc':
          return amountB.compareTo(amountA);
        case 'amount_asc':
          return amountA.compareTo(amountB);
        default:
          return dateB.compareTo(dateA);
      }
    });

    return result;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showSortSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Text(
                  'Sort Transactions',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              _buildSortOption(
                Icons.arrow_downward,
                'Date (Newest First)',
                'date_desc',
              ),
              _buildSortOption(
                Icons.arrow_upward,
                'Date (Oldest First)',
                'date_asc',
              ),
              _buildSortOption(
                Icons.trending_down,
                'Amount (High to Low)',
                'amount_desc',
              ),
              _buildSortOption(
                Icons.trending_up,
                'Amount (Low to High)',
                'amount_asc',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final active = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: active ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showAddSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOption(
                  icon: Icons.add_shopping_cart,
                  label: 'Add Expense',
                  color: AppConstants.expenseColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.addExpense);
                  },
                ),
                _buildAddOption(
                  icon: Icons.payments_outlined,
                  label: 'Add Income',
                  color: AppConstants.secondaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.addIncome);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          color: color.withValues(alpha: 0.04),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final theme = Theme.of(context);

    // Filter categories applicable to finances (incomes + expenses)
    final categories = expenseState.categories
        .where(
          (c) => c.type == CategoryType.expense || c.type == CategoryType.income,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Expenses'),
            Tab(text: 'Incomes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSelector,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter & Search Controls Container
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Search Bar + Sort Trigger
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    // Sort Trigger
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.swap_vert,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),

                // Filter Chips List (Category & Dates)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Date range filter chip
                      CustomFilterChip(
                        label: _dateRange == null
                            ? 'Date Range'
                            : '${_dateRange!.start.toString().substring(5, 10)} to ${_dateRange!.end.toString().substring(5, 10)}',
                        isSelected: _dateRange != null,
                        onSelected: () {
                          if (_dateRange != null) {
                            setState(() => _dateRange = null);
                          } else {
                            _selectDateRange();
                          }
                        },
                      ),
                      const SizedBox(width: AppConstants.spacingS),

                      // Category Dropdown Filter Chip
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          hint: Text(
                            'Category',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _selectedCategoryId != null
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: _selectedCategoryId != null
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            size: 18,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                            });
                          },
                          underline: const SizedBox.shrink(),
                          selectedItemBuilder: (context) {
                            return [
                              const Text(
                                'All Categories',
                                style: TextStyle(fontSize: 12),
                              ),
                              ...categories.map(
                                (c) => Text(
                                  c.name,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ];
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Categories',
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ALL Tab
                _buildTransactionList([
                  ...expenseState.expenses,
                  ...expenseState.incomes,
                ], 'No transactions recorded.', Icons.receipt_long),

                // EXPENSES Tab
                _buildTransactionList(
                  expenseState.expenses,
                  'No expenses recorded yet.',
                  Icons.shopping_cart_outlined,
                ),

                // INCOMES Tab
                _buildTransactionList(
                  expenseState.incomes,
                  'No incomes recorded yet.',
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<dynamic> source,
    String emptyMessage,
    IconData emptyIcon,
  ) {
    final filtered = _filterAndSort(source);

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: 'No Data Found',
        message: _searchQuery.isNotEmpty ||
                _selectedCategoryId != null ||
                _dateRange != null
            ? 'No transactions matched your active search and filter combinations.'
            : emptyMessage,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final tx = filtered[index];
        final isExpense = tx is Expense;

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: Dismissible(
              key: Key(tx.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: AppConstants.expenseColor,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                if (isExpense) {
                  ref.read(expenseProvider.notifier).deleteExpense(tx.id);
                } else {
                  ref.read(expenseProvider.notifier).deleteIncome(tx.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${isExpense ? 'Expense' : 'Income'} deleted',
                    ),
                    backgroundColor: AppConstants.expenseColor,
                  ),
                );
              },
              child: TransactionItemCard(
                title: isExpense ? tx.description : tx.source,
                amount: tx.amount,
                date: tx.date,
                isExpense: isExpense,
                category: tx.categoryName,
                onTap: () {
                  if (isExpense) {
                    Navigator.pushNamed(context, AppRoutes.addExpense);
                  } else {
                    Navigator.pushNamed(context, AppRoutes.addIncome);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
