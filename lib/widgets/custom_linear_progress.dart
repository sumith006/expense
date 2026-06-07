import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class CustomLinearProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final bool showLabel;

  const CustomLinearProgress({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: bgColor,
            color: progressColor,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: AppConstants.spacingM),
          Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
