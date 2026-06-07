import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/constants_shared.dart';
import '../utils/currency_formatter.dart';
import '../providers/settings_provider.dart';

class BudgetProgressIndicator extends ConsumerWidget {
  final double spent;
  final double limit;
  final String categoryName;
  final bool isCircular;

  const BudgetProgressIndicator({
    super.key,
    required this.spent,
    required this.limit,
    this.categoryName = 'Monthly Budget',
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final symbol = settings.currencySymbol;
    if (limit <= 0) return const SizedBox.shrink();

    final percentage = (spent / limit) * 100;
    final progress = (spent / limit).clamp(0.0, 1.0);

    // Dynamic color thresholding
    Color progressColor;
    if (progress >= 1.0) {
      progressColor = AppConstants.expenseColor;
    } else if (progress >= 0.8) {
      progressColor = AppConstants.warningLight;
    } else {
      progressColor = AppConstants.secondaryColor;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCircular) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        progress >= 1.0 ? 'Overspent' : 'Used',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${CurrencyFormatter.format(spent, symbol)} of ${CurrencyFormatter.format(limit, symbol)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${CurrencyFormatter.format(spent, symbol)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              progress >= 1.0
                  ? 'Exceeded by ${CurrencyFormatter.format(spent - limit, symbol)}'
                  : 'Remaining: ${CurrencyFormatter.format(limit - spent, symbol)}',
              style: TextStyle(
                fontSize: 11,
                color: progress >= 1.0
                    ? AppConstants.expenseColor
                    : Colors.grey,
                fontWeight: progress >= 1.0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
