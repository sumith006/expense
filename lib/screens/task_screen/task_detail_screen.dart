import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants_shared.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/settings_provider.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final task = tasks.where((t) => t.id == taskId).firstOrNull;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: const Center(child: Text('Task not found.')),
      );
    }

    final completedSubtasks = task.subtasks.where((s) => s.isCompleted).length;
    final progress = task.subtasks.isEmpty ? 0.0 : completedSubtasks / task.subtasks.length;
    final priorityColor = _priorityColor(task.priority);
    final isOverdue = task.status != TaskStatus.completed &&
        task.dueDate.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBgColor : AppConstants.lightBgColor,
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: task)),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Delete this task permanently?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(taskProvider.notifier).deleteTask(task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppConstants.expenseColor, size: 18),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                ],
              )),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    priorityColor.withValues(alpha: 0.9),
                    priorityColor.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PriorityBadge(priority: task.priority),
                      const Spacer(),
                      _StatusBadge(status: task.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(task.dueDate),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (task.dueTime != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          task.dueTime!.format(context),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  if (isOverdue) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 12),
                          SizedBox(width: 4),
                          Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Complete Button
            if (task.status != TaskStatus.completed)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Mark as Incomplete', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Subtasks Progress
            if (task.subtasks.isNotEmpty) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoLabel(label: 'SUBTASKS', icon: Icons.checklist),
                        Text(
                          '$completedSubtasks / ${task.subtasks.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...task.subtasks.map((sub) => _SubtaskTile(
                          subtask: sub,
                          taskId: task.id,
                          ref: ref,
                          isDark: isDark,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Details Card
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InfoLabel(label: 'DETAILS', icon: Icons.info_outline),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Category', value: task.categoryName, isDark: isDark),
                  _DetailRow(label: 'Created', value: DateFormat('MMM d, y').format(task.createdAt), isDark: isDark),
                  if (task.completedAt != null)
                    _DetailRow(
                      label: 'Completed',
                      value: DateFormat('MMM d, y – h:mm a').format(task.completedAt!),
                      isDark: isDark,
                    ),
                  if (task.estimatedMinutes != null)
                    _DetailRow(
                      label: 'Estimated',
                      value: '${task.estimatedMinutes} min',
                      isDark: isDark,
                    ),
                  if (task.isRecurring && task.recurringRule != null)
                    _DetailRow(
                      label: 'Recurring',
                      value: task.recurringRule![0].toUpperCase() + task.recurringRule!.substring(1),
                      isDark: isDark,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tags
            if (task.tags.isNotEmpty) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InfoLabel(label: 'TAGS', icon: Icons.label_outline),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: task.tags
                          .map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
                                labelStyle: const TextStyle(color: AppConstants.primaryColor),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Notes
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InfoLabel(label: 'NOTES', icon: Icons.notes_outlined),
                    const SizedBox(height: 10),
                    Text(
                      task.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Linked Expenses
            if (task.linkedExpenseIds.isNotEmpty) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InfoLabel(label: 'LINKED EXPENSES', icon: Icons.attach_money),
                    const SizedBox(height: 10),
                    ...task.linkedExpenseIds.map((expId) {
                      final expenses = ref.read(expenseProvider).expenses;
                      final exp = expenses.where((e) => e.id == expId).firstOrNull;
                      if (exp == null) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppConstants.expenseColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_long_outlined,
                                  color: AppConstants.expenseColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exp.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(exp.categoryName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(exp.amount, settings.currencySymbol),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.expenseColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppConstants.expenseColor;
      case TaskPriority.medium: return AppConstants.warningLight;
      case TaskPriority.low: return AppConstants.secondaryColor;
    }
  }
}

class _SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final String taskId;
  final WidgetRef ref;
  final bool isDark;

  const _SubtaskTile({
    required this.subtask,
    required this.taskId,
    required this.ref,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => ref.read(taskProvider.notifier).toggleSubtaskCompletion(taskId, subtask.id),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(subtask.isCompleted),
                color: subtask.isCompleted ? AppConstants.secondaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                  color: subtask.isCompleted ? Colors.grey : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _DetailRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      TaskPriority.high => 'HIGH PRIORITY',
      TaskPriority.medium => 'MEDIUM',
      TaskPriority.low => 'LOW',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == TaskStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'Done' : 'Pending',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
