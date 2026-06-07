import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/expense_provider.dart';
import '../widgets/transaction_tile.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../app/routes.dart';

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
          _buildSummarySection(totalIncome, totalExpense),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList([...expenseState.expenses, ...expenseState.incomes]),
                _buildTransactionList(expenseState.expenses),
                _buildTransactionList(expenseState.incomes),
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

  Widget _buildSummarySection(double income, double expense) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildSummaryCard('INCOME', income, NeoBrutalTheme.success),
          const SizedBox(width: 16),
          _buildSummaryCard('SPENT', expense, NeoBrutalTheme.error),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
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
              '\$${amount.toStringAsFixed(0)}',
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

  Widget _buildTransactionList(List<dynamic> list) {
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
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: TransactionTile(
                  title: isExpense ? tx.description : (tx as Income).source,
                  subtitle: tx.categoryName,
                  amount: tx.amount,
                  icon: isExpense ? Icons.shopping_bag_rounded : Icons.payments_rounded,
                  isExpense: isExpense,
                  onTap: () {},
                ),
              ),
            ),
          );
        },
      ),
    );
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
