import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class TaskSummaryCard extends StatelessWidget {
  final int pendingTasks;
  final int completedTasks;
  final int tasksDueToday;
  final int highPriorityTasks;
  final VoidCallback onViewAllTap;

  const TaskSummaryCard({
    super.key,
    required this.pendingTasks,
    required this.completedTasks,
    required this.tasksDueToday,
    required this.highPriorityTasks,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = pendingTasks + completedTasks;
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        side: BorderSide(color: theme.colorScheme.outlineVariant ?? AppConstants.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppConstants.spacingS),
                Text('Task Summary', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending: $pendingTasks', style: theme.textTheme.bodyMedium),
                      Text('Completed this month: $completedTasks', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Text('${(progress * 100).toInt()}%', style: theme.textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppConstants.priorityMedium),
                const SizedBox(width: AppConstants.spacingS),
                Text('$tasksDueToday tasks due today', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppConstants.priorityHigh),
                const SizedBox(width: AppConstants.spacingS),
                Text('$highPriorityTasks high priority task${highPriorityTasks == 1 ? '' : 's'}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            GestureDetector(
              onTap: onViewAllTap,
              child: Row(
                children: [
                  Text('View All Tasks', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(width: AppConstants.spacingXs),
                  Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
