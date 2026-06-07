import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants_shared.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';

class TransactionItemCard extends ConsumerWidget {
  final String title;
  // Legacy params kept for backward compat
  final String? subtitle;
  final String? time;
  // New convenience params used by dashboard_tab
  final DateTime? date;
  final String? category;
  final double amount;
  final String? categoryName;
  final Color? categoryColor;
  final bool hasReceipt;
  final bool isExpense;
  final VoidCallback? onTap;

  const TransactionItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.time,
    this.date,
    this.category,
    required this.amount,
    this.categoryName,
    this.categoryColor,
    this.hasReceipt = false,
    this.isExpense = true,
    this.onTap,
  });

  String get _displayTime {
    if (time != null) return time!;
    if (date != null) return DateFormat('MMM d, h:mm a').format(date!);
    return '';
  }

  String get _displayCategory => categoryName ?? category ?? '';

  Color get _displayColor => categoryColor ?? AppConstants.primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final symbol = settings.currencySymbol;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          child: Row(
            children: [
              Container(
                width: 4,
                color: _displayColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppConstants.spacingXs),
                            Row(
                              children: [
                                if (_displayCategory.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _displayColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _displayCategory,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: _displayColor,
                                      ),
                                    ),
                                  ),
                                if (hasReceipt) ...[
                                  const SizedBox(width: AppConstants.spacingS),
                                  Icon(
                                    Icons.receipt_long,
                                    size: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ],
                                if (subtitle != null) ...[
                                  const SizedBox(width: AppConstants.spacingS),
                                  Expanded(
                                    child: Text(
                                      subtitle!,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount, symbol)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isExpense
                                    ? AppConstants.dangerLight
                                    : AppConstants.successLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              _displayTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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
