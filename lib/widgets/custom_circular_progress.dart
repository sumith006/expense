import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class CustomCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const CustomCircularProgress({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? AppConstants.successLight;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: bgColor,
            color: progressColor,
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
