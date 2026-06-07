import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/constants_shared.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = task.status == TaskStatus.completed;

    // Priority color
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = AppConstants.expenseColor;
        break;
      case TaskPriority.medium:
        priorityColor = AppConstants.warningLight;
        break;
      case TaskPriority.low:
        priorityColor = Colors.blue;
        break;
    }

    // Due date overdue check
    final isOverdue = !isCompleted && task.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
        !(task.dueDate.day == DateTime.now().day && task.dueDate.month == DateTime.now().month && task.dueDate.year == DateTime.now().year);

    final dueStr = DateFormatter.getDayDifferenceString(task.dueDate);

    // Subtask count
    final totalSubtasks = task.subtasks.length;
    final completedSubtasks = task.subtasks.where((sub) => sub.isCompleted).length;

    // Load category color dynamically
    final categoryColor = _getCategoryColor(task.categoryId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                // Interactive Checkbox
                IconButton(
                  onPressed: () {
                    ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
                  },
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? AppConstants.secondaryColor : Colors.grey,
                    size: 28,
                  ),
                ),
                
                // Content section
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted 
                                ? Colors.grey 
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Metadata badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(categoryColor).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.categoryName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(categoryColor),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Due Date Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverdue 
                                    ? AppConstants.expenseColor.withValues(alpha: 0.1)
                                    : (isCompleted ? Colors.grey.withValues(alpha: 0.1) : AppConstants.primaryColor.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dueStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOverdue 
                                      ? AppConstants.expenseColor 
                                      : (isCompleted ? Colors.grey : AppConstants.primaryColor),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.priority.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Budget badge if exists
                            if (task.budgetAmount != null && task.budgetAmount! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Limit: ${CurrencyFormatter.format(task.budgetAmount!, '\$')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Expand button if task has subtasks or notes
                if (totalSubtasks > 0 || (task.notes != null && task.notes!.isNotEmpty))
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                  )
              ],
            ),
          ),
          
          // Expandable Subtask/Note Section
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.02) 
                  : Colors.black.withValues(alpha: 0.01),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Notes
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.notes!,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Subtask checklist
                  if (totalSubtasks > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtasks',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          '$completedSubtasks/$totalSubtasks completed',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Subtask items
                    ...task.subtasks.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: sub.isCompleted,
                                onChanged: (val) {
                                  ref.read(taskProvider.notifier).toggleSubtaskCompletion(task.id, sub.id);
                                },
                                activeColor: AppConstants.secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                  color: sub.isCompleted ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCategoryColor(String id) {
    final catBox = Hive.box<Category>(Boxes.categories);
    final cat = catBox.get(id);
    return cat?.colorValue ?? Colors.grey.value;
  }
}
