import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class TaskItemCard extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final String priorityText;
  final Color priorityColor;
  final String dueDateTime;
  final String categoryName;
  final int completedSubtasks;
  final int totalSubtasks;
  final double? budgetAmount;
  final double? spentAmount;
  final VoidCallback? onCheckboxChanged;
  final VoidCallback? onTap;

  const TaskItemCard({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.priorityText,
    required this.priorityColor,
    required this.dueDateTime,
    required this.categoryName,
    this.completedSubtasks = 0,
    this.totalSubtasks = 0,
    this.budgetAmount,
    this.spentAmount,
    this.onCheckboxChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Row(
            children: [
              Container(
                width: 4,
                color: priorityColor,
                height: 140, // Sufficient height for the card
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: onCheckboxChanged,
                            child: Icon(
                              isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isCompleted
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isCompleted
                                        ? theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingS),
                                Container(
                                  padding:
                                      const EdgeInsets.all(AppConstants.spacingS),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSmall,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: priorityColor,
                                          ),
                                          const SizedBox(
                                            width: AppConstants.spacingXs,
                                          ),
                                          Text(
                                            priorityText,
                                            style: theme.textTheme.labelMedium,
                                          ),
                                          const SizedBox(
                                            width: AppConstants.spacingM,
                                          ),
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                          ),
                                          const SizedBox(
                                            width: AppConstants.spacingXs,
                                          ),
                                          Text(
                                            dueDateTime,
                                            style: theme.textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppConstants.spacingS,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.local_offer_outlined,
                                            size: 12,
                                          ),
                                          const SizedBox(
                                            width: AppConstants.spacingXs,
                                          ),
                                          Text(
                                            categoryName,
                                            style: theme.textTheme.labelMedium,
                                          ),
                                          if (totalSubtasks > 0) ...[
                                            const SizedBox(
                                              width: AppConstants.spacingM,
                                            ),
                                            const Icon(Icons.list_alt, size: 12),
                                            const SizedBox(
                                              width: AppConstants.spacingXs,
                                            ),
                                            Text(
                                              '$completedSubtasks/$totalSubtasks subtasks',
                                              style:
                                                  theme.textTheme.labelMedium,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (budgetAmount != null && spentAmount != null) ...[
                        const SizedBox(height: AppConstants.spacingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget: \$${budgetAmount!.toStringAsFixed(0)}',
                              style: theme.textTheme.labelMedium,
                            ),
                            Text(
                              'Spent: \$${spentAmount!.toStringAsFixed(0)}',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        LinearProgressIndicator(
                          value: budgetAmount! > 0
                              ? spentAmount! / budgetAmount!
                              : 0,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          color: (spentAmount! > budgetAmount!)
                              ? AppConstants.dangerLight
                              : theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
