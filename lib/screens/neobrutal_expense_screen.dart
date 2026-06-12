import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/expense_provider.dart';
import '../widgets/transaction_tile.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../app/routes.dart';
import '../utils/constants_shared.dart';
import 'expense_screen/add_expense_screen.dart';
import 'income_screen/add_income_screen.dart';
import '../providers/currency_provider.dart';

import '../services/image_service.dart';

class NeoBrutalExpenseScreen extends ConsumerStatefulWidget {
  const NeoBrutalExpenseScreen({super.key});

  @override
  ConsumerState<NeoBrutalExpenseScreen> createState() => _NeoBrutalExpenseScreenState();
}

class _NeoBrutalExpenseScreenState extends ConsumerState<NeoBrutalExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final currencyCode = ref.watch(currencyProvider);
    final currencySymbol = getCurrencySymbol(currencyCode);

    return Scaffold(
      backgroundColor: NeoBrutalTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'TRANSACTIONS',
          style: NeoBrutalTheme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeoBrutalTheme.primary,
          indicatorWeight: 4,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'EXPENSES'),
            Tab(text: 'INCOMES'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummarySection(totalIncome, totalExpense, currencySymbol),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList([...expenseState.expenses, ...expenseState.incomes], currencySymbol),
                _buildTransactionList(expenseState.expenses, currencySymbol),
                _buildTransactionList(expenseState.incomes, currencySymbol),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSelector(context),
        backgroundColor: NeoBrutalTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummarySection(double income, double expense, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildSummaryCard('INCOME', income, NeoBrutalTheme.success, currencySymbol),
          const SizedBox(width: 16),
          _buildSummaryCard('SPENT', expense, NeoBrutalTheme.error, currencySymbol),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, String currencySymbol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: NeoBrutalTheme.radiusMedium,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
              '$currencySymbol${amount.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'SEARCH ACTIVITY...',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: NeoBrutalTheme.radiusMedium,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<dynamic> list, String currencySymbol) {
    final filtered = list.where((item) {
      final query = _searchQuery.toLowerCase();
      final title = item is Expense ? item.description : (item as Income).source;
      return title.toLowerCase().contains(query) || item.categoryName.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    if (filtered.isEmpty) {
      return const Center(child: Text('NO ACTIVITY FOUND', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)));
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tx = filtered[index];
          final isExpense = tx is Expense;
          final id = isExpense ? tx.id : (tx as Income).id;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _confirmDeletion(context, isExpense ? (tx).description : (tx as Income).source);
                  },
                  onDismissed: (direction) {
                    _deleteTransactionWithUndo(tx, isExpense);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: NeoBrutalTheme.error,
                      borderRadius: NeoBrutalTheme.radiusMedium,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                  ),
                  child: TransactionTile(
                    title: isExpense ? (tx).description : (tx as Income).source,
                    subtitle: isExpense ? (tx).categoryName : (tx as Income).categoryName,
                    amount: isExpense ? (tx).amount : (tx as Income).amount,
                    icon: isExpense ? Icons.shopping_bag_rounded : Icons.payments_rounded,
                    isExpense: isExpense,
                    onTap: () => _editTransaction(tx, isExpense),
                    onLongPress: () => _editTransaction(tx, isExpense),
                    currencySymbol: currencySymbol,
                    receiptImagePath: isExpense ? (tx).receiptImagePath : null,
                    onReceiptTap: isExpense && (tx).receiptImagePath != null 
                        ? () => ImageService.showReceiptPreview(context, (tx).receiptImagePath!) 
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: NeoBrutalTheme.radiusLarge),
        title: const Text('DELETE RECORD?', style: TextStyle(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: NeoBrutalTheme.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _deleteTransactionWithUndo(dynamic tx, bool isExpense) {
    if (isExpense) {
      final expense = tx as Expense;
      ref.read(expenseProvider.notifier).deleteExpense(expense.id);
      _showUndoSnackBar('Expense deleted', () {
        ref.read(expenseProvider.notifier).addExpense(expense);
      });
    } else {
      final income = tx as Income;
      ref.read(expenseProvider.notifier).deleteIncome(income.id);
      _showUndoSnackBar('Income deleted', () {
        ref.read(expenseProvider.notifier).addIncome(income);
      });
    }
  }

  void _showUndoSnackBar(String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: NeoBrutalTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: NeoBrutalTheme.radiusMedium),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: onUndo,
        ),
      ),
    );
  }

  void _editTransaction(dynamic tx, bool isExpense) {
    if (isExpense) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(existingExpense: tx as Expense),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddIncomeScreen(existingIncome: tx as Income),
        ),
      );
    }
  }

  void _showAddSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoBrutalTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: NeoBrutalTheme.radiusLarge),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ADD NEW RECORD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white70)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildAddOption(context, 'EXPENSE', Icons.remove_circle_outline_rounded, NeoBrutalTheme.primary, AppRoutes.addExpense),
                  const SizedBox(width: 16),
                  _buildAddOption(context, 'INCOME', Icons.add_circle_outline_rounded, NeoBrutalTheme.success, AppRoutes.addIncome),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(BuildContext context, String label, IconData icon, Color color, String route) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        borderRadius: NeoBrutalTheme.radiusMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: NeoBrutalTheme.radiusMedium,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
