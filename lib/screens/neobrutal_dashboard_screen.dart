import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neobrutal_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/animated_task_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/animated_bottom_nav.dart';
import '../providers/expense_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../app/routes.dart';
import '../providers/currency_provider.dart';
import '../providers/user_provider.dart';

import '../services/image_service.dart';

class NeoBrutalDashboardScreen extends ConsumerStatefulWidget {
  const NeoBrutalDashboardScreen({super.key});

  @override
  ConsumerState<NeoBrutalDashboardScreen> createState() => _NeoBrutalDashboardScreenState();
}

class _NeoBrutalDashboardScreenState extends ConsumerState<NeoBrutalDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  
  late AnimationController _balanceController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _balanceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
    _balanceAnimation = CurvedAnimation(
      parent: _balanceController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final taskList = ref.watch(taskProvider);
    final settings = ref.watch(settingsProvider);
    final userName = ref.watch(userProvider);
    final currencyCode = ref.watch(currencyProvider);
    final currencySymbol = getCurrencySymbol(currencyCode);
    
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final netBalance = ref.watch(netBalanceProvider);

    final recentTasks = taskList.where((t) => t.status == TaskStatus.pending).take(3).toList();
    
    final allTransactions = <dynamic>[...expenseState.expenses, ...expenseState.incomes];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = allTransactions.take(4).toList();

    return Scaffold(
      backgroundColor: NeoBrutalTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(userName.isNotEmpty ? userName : 'User'),
            Expanded(
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildBalanceCard(netBalance, totalIncome, totalExpense, currencySymbol),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        _buildTasksSection(recentTasks),
                        const SizedBox(height: 32),
                        _buildTransactionsSection(recentTransactions, currencySymbol),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GradientFAB(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: NeoBrutalTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: NeoBrutalTheme.secondaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeoBrutalTheme.secondary.withValues(alpha: 0.3),
                  blurRadius: 15,
                )
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeonCard(
        hasGlow: true,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL BALANCE',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _balanceAnimation,
              child: Text(
                '$currencySymbol${balance.toStringAsFixed(2)}',
                style: NeoBrutalTheme.textTheme.displayLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = NeoBrutalTheme.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 300, 70),
                    ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildStatItem('INCOME', '$currencySymbol${income.toStringAsFixed(0)}', NeoBrutalTheme.success, Icons.arrow_upward_rounded),
                const SizedBox(width: 16),
                _buildStatItem('EXPENSES', '$currencySymbol${expense.toStringAsFixed(0)}', NeoBrutalTheme.error, Icons.arrow_downward_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: NeoBrutalTheme.radiusMedium,
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.add_rounded, 'label': 'Expense', 'color': NeoBrutalTheme.primary, 'route': AppRoutes.addExpense},
      {'icon': Icons.payments_rounded, 'label': 'Income', 'color': NeoBrutalTheme.secondary, 'route': AppRoutes.addIncome},
      {'icon': Icons.add_task_rounded, 'label': 'Task', 'color': NeoBrutalTheme.accent, 'route': AppRoutes.addTask},
      {'icon': Icons.analytics_rounded, 'label': 'Reports', 'color': NeoBrutalTheme.success, 'route': AppRoutes.reports},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, action['route'] as String),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: NeoBrutalTheme.radiusMedium,
                    border: Border.all(color: (action['color'] as Color).withValues(alpha: 0.2), width: 2),
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  action['label'] as String,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksSection(List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ QUICK TASKS',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalTheme.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.neobrutalTask),
                child: const Text('VIEW ALL →', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            _buildEmptyState('No pending tasks', Icons.task_alt_rounded)
          else
            ...tasks.map((task) => AnimatedTaskCard(
                  title: task.title,
                  priority: task.priority.name.toUpperCase(),
                  dueTime: 'Today',
                  onToggle: () => ref.read(taskProvider.notifier).toggleTaskCompletion(task.id),
                  onTap: () {},
                )),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<dynamic> txs, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 RECENT ACTIVITY',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalTheme.accent,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.neobrutalExpense),
                child: const Text('VIEW ALL →', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (txs.isEmpty)
            _buildEmptyState('No transactions yet', Icons.receipt_long_rounded)
          else
            ...txs.map((tx) {
              if (tx is Expense) {
                return TransactionTile(
                  title: tx.description,
                  subtitle: tx.categoryName,
                  amount: tx.amount,
                  icon: Icons.shopping_cart_rounded,
                  isExpense: true,
                  currencySymbol: currencySymbol,
                  receiptImagePath: tx.receiptImagePath,
                  onReceiptTap: tx.receiptImagePath != null ? () => ImageService.showReceiptPreview(context, tx.receiptImagePath!) : null,
                );
              } else if (tx is Income) {
                return TransactionTile(
                  title: tx.source,
                  subtitle: tx.categoryName,
                  amount: tx.amount,
                  icon: Icons.account_balance_wallet_rounded,
                  isExpense: false,
                  currencySymbol: currencySymbol,
                );
              }
              return const SizedBox.shrink();
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: NeoBrutalTheme.radiusLarge,
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white12),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}
