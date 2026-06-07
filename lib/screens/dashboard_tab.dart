import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../app/routes.dart';
import '../models/expense.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/task_provider.dart';
import '../providers/budget_provider.dart';
import '../screens/task_screen.dart';
import '../widgets/balance_card_new.dart';
import '../widgets/task_summary_card.dart';
import '../widgets/transaction_item_card.dart';
import '../widgets/secondary_button.dart';
import '../widgets/budget_progress_indicator.dart';
import 'package:expense/utils/constants_shared.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _DashboardHeader(),
          SizedBox(height: AppConstants.spacingXl),
          _BalanceSection(),
          SizedBox(height: AppConstants.spacingXl),
          _QuickActionsSection(),
          SizedBox(height: AppConstants.spacingXl),
          _BudgetSection(),
          SizedBox(height: AppConstants.spacingXl),
          _TaskSummarySection(),
          SizedBox(height: AppConstants.spacingXl),
          _RecentTransactionsSection(),
          SizedBox(height: AppConstants.spacingXxl),
        ],
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileName = ref.watch(settingsProvider.select((s) => s.profileName));
    final today = DateTime.now();
    
    // Display name with "Welcome back!" prefix, or just "Welcome back!" if no name is set
    final displayName = (profileName?.isNotEmpty == true) ? profileName! : '';

    return Card(
      color: theme.colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant ?? AppConstants.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back${displayName.isNotEmpty ? ',' : '!'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  if (displayName.isNotEmpty)
                    Text(
                      displayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    DateFormat('EEEE, MMM d').format(today),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSection extends ConsumerWidget {
  const _BalanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalance = ref.watch(netBalanceProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);

    return BalanceCard(
      totalBalance: netBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: SecondaryButton(
                icon: Icons.add_shopping_cart,
                label: 'Expense',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: SecondaryButton(
                icon: Icons.payments,
                label: 'Income',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addIncome),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: SecondaryButton(
                icon: Icons.add_task,
                label: 'Task',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BudgetSection extends ConsumerWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetState = ref.watch(budgetProvider);
    final activeBudget = budgetState.currentBudget;
    
    if (activeBudget == null || activeBudget.monthlyTotalBudget <= 0) {
      return const SizedBox.shrink();
    }

    final monthlyLimit = activeBudget.monthlyTotalBudget;
    final monthlySpent = ref.watch(monthlySpentProvider(DateTime.now()));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant ?? AppConstants.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: BudgetProgressIndicator(
          spent: monthlySpent,
          limit: monthlyLimit,
          categoryName: 'Monthly Spending Budget',
        ),
      ),
    );
  }
}

class _TaskSummarySection extends ConsumerWidget {
  const _TaskSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskProvider);
    final today = DateTime.now();

    final pendingTasks = taskList.where((t) => t.status == TaskStatus.pending).length;
    final completedTasksThisMonth = taskList.where(
      (t) => t.status == TaskStatus.completed &&
             t.completedAt != null &&
             t.completedAt!.month == today.month &&
             t.completedAt!.year == today.year,
    ).length;

    final tasksDueToday = taskList.where(
      (t) => t.status == TaskStatus.pending &&
             t.dueDate.day == today.day &&
             t.dueDate.month == today.month &&
             t.dueDate.year == today.year,
    ).length;

    final highPriorityTasks = taskList.where(
      (t) => t.status == TaskStatus.pending && t.priority == TaskPriority.high,
    ).length;

    return TaskSummaryCard(
      pendingTasks: pendingTasks,
      completedTasks: completedTasksThisMonth,
      tasksDueToday: tasksDueToday,
      highPriorityTasks: highPriorityTasks,
      onViewAllTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskScreen()),
        );
      },
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseProvider);
    
    final allTransactions = <dynamic>[];
    allTransactions.addAll(expenseState.expenses);
    allTransactions.addAll(expenseState.incomes);
    allTransactions.sort((a, b) {
      final dateA = a.date as DateTime;
      final dateB = b.date as DateTime;
      return dateB.compareTo(dateA);
    });
    final recentTransactions = allTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TRANSACTIONS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        if (recentTransactions.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant ?? AppConstants.borderLight,
                width: 1,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppConstants.spacingXl),
              child: Center(
                child: Text(
                  'No transactions recorded yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...recentTransactions.map((tx) {
            final isExpense = tx is Expense;
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                child: TransactionItemCard(
                  title: isExpense ? (tx).description : tx.source,
                  amount: isExpense ? (tx).amount : tx.amount,
                  date: isExpense ? (tx).date : tx.date,
                  isExpense: isExpense,
                  category: isExpense ? (tx).categoryName : tx.categoryName,
                  onTap: () {},
                ),
              ),
            );
          }),
      ],
    );
  }
}
