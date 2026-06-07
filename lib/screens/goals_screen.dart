import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/savings_goal.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants_shared.dart';
import '../../utils/currency_formatter.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeGoals = goals.where((g) => !g.isAchieved).toList();
    final achievedGoals = goals.where((g) => g.isAchieved).toList();

    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBgColor : AppConstants.lightBgColor,
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, isDark, null),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: goals.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 14),
                    Text('No savings goals yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('Tap + to create your first goal', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL SAVINGS PROGRESS',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(totalSaved, settings.currencySymbol),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4, left: 8),
                                child: Text(
                                  'of ${CurrencyFormatter.format(totalTarget, settings.currencySymbol)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${achievedGoals.length} / ${goals.length} goals achieved',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                totalTarget > 0 ? '${((totalSaved / totalTarget) * 100).toStringAsFixed(0)}%' : '0%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Active Goals
                    if (activeGoals.isNotEmpty) ...[
                      const _SectionLabel(label: 'ACTIVE GOALS'),
                      const SizedBox(height: 10),
                      ...activeGoals.map((goal) => _GoalCard(
                            goal: goal,
                            settings: settings,
                            isDark: isDark,
                            onTap: () => _showAddGoalSheet(context, isDark, goal),
                            onAddSavings: (amount) async {
                              await ref.read(goalsProvider.notifier).addSavings(goal.id, amount);
                            },
                            onDelete: () async {
                              await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                            },
                          )),
                    ],

                    // Achieved Goals
                    if (achievedGoals.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const _SectionLabel(label: 'ACHIEVED 🎉'),
                      const SizedBox(height: 10),
                      ...achievedGoals.map((goal) => _GoalCard(
                            goal: goal,
                            settings: settings,
                            isDark: isDark,
                            onTap: () => _showAddGoalSheet(context, isDark, goal),
                            onAddSavings: null,
                            onDelete: () async {
                              await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                            },
                          )),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, bool isDark, SavingsGoal? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final targetCtrl = TextEditingController(
        text: existing != null && existing.targetAmount > 0
            ? existing.targetAmount.toStringAsFixed(2)
            : '');
    DateTime targetDate = existing?.targetDate ?? DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppConstants.darkCardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing != null ? 'Edit Goal' : 'New Savings Goal',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  hintText: 'e.g. New Laptop, Vacation...',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) setModal(() => targetDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            DateFormat('MMMM d, y').format(targetDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text);
                    if (name.isEmpty || target == null || target <= 0) return;

                    final goal = SavingsGoal(
                      id: existing?.id ?? const Uuid().v4(),
                      name: name,
                      targetAmount: target,
                      currentAmount: existing?.currentAmount ?? 0.0,
                      targetDate: targetDate,
                      isAchieved: existing?.isAchieved ?? false,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing != null) {
                      await ref.read(goalsProvider.notifier).updateGoal(goal);
                    } else {
                      await ref.read(goalsProvider.notifier).addGoal(goal);
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    existing != null ? 'Update Goal' : 'Create Goal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final dynamic settings;
  final bool isDark;
  final VoidCallback onTap;
  final Future<void> Function(double)? onAddSavings;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.settings,
    required this.isDark,
    required this.onTap,
    required this.onAddSavings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
    final isDue = daysLeft <= 0;

    const goalColor = Color(0xFF7C3AED);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(
              color: goal.isAchieved
                  ? AppConstants.secondaryColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            boxShadow: goal.isAchieved
                ? [BoxShadow(color: AppConstants.secondaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: goal.isAchieved
                          ? AppConstants.secondaryColor.withValues(alpha: 0.15)
                          : goalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      goal.isAchieved ? Icons.emoji_events : Icons.savings_outlined,
                      color: goal.isAchieved ? AppConstants.secondaryColor : goalColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          goal.isAchieved
                              ? '🎉 Goal achieved!'
                              : isDue
                                  ? 'Due date passed'
                                  : '$daysLeft days left',
                          style: TextStyle(
                            fontSize: 12,
                            color: goal.isAchieved
                                ? AppConstants.secondaryColor
                                : isDue
                                    ? AppConstants.expenseColor
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Goal'),
                            content: const Text('Delete this savings goal?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) onDelete();
                      }
                    },
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppConstants.expenseColor, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(goal.currentAmount, settings.currencySymbol),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: goal.isAchieved ? AppConstants.secondaryColor : goalColor,
                    ),
                  ),
                  Text(
                    'of ${CurrencyFormatter.format(goal.targetAmount, settings.currencySymbol)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: goalColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isAchieved ? AppConstants.secondaryColor : goalColor,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% saved',
                    style: TextStyle(fontSize: 12, color: goal.isAchieved ? AppConstants.secondaryColor : goalColor),
                  ),
                  Text(
                    'Target: ${DateFormat('MMM d, y').format(goal.targetDate)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              if (!goal.isAchieved && onAddSavings != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddSavingsDialog(context, goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Savings', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: goalColor,
                      side: BorderSide(color: goalColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSavingsDialog(BuildContext context, SavingsGoal goal) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to add',
            prefixIcon: Icon(Icons.add),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0 && onAddSavings != null) {
                await onAddSavings!(val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }
}
