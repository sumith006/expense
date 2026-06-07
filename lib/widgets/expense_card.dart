import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../utils/constants_shared.dart';
import '../utils/helpers.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';
import '../providers/settings_provider.dart';

class TransactionCard extends ConsumerWidget {
  final dynamic transaction; // Can be Expense or Income
  final VoidCallback onTap;
  final Function(DismissDirection)? onDismissed;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final symbol = settings.currencySymbol;
    final isExpense = transaction is Expense;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amount = transaction.amount as double;
    final date = transaction.date as DateTime;
    final notes = transaction.notes as String;
    final categoryName = transaction.categoryName as String;

    // Find visual details: category color and icon
    final description = isExpense
        ? (transaction as Expense).description
        : (transaction as Income).source;

    final receiptPath = isExpense
        ? (transaction as Expense).receiptImagePath
        : null;
    final linkedTaskId = isExpense
        ? (transaction as Expense).linkedTaskId
        : null;

    // Load category color dynamically from boxes or fall back to default
    final color = _getCategoryColor(transaction.categoryId, isExpense);
    final iconData = _getCategoryIcon(transaction.categoryId, isExpense);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppConstants.expenseColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: onDismissed,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Color(color), width: 5)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(color).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Color(color), size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.isNotEmpty ? description : categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 4,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatRelative(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      // Attachment Badges
                      if ((receiptPath != null && receiptPath.isNotEmpty) ||
                          (linkedTaskId != null &&
                              linkedTaskId.isNotEmpty)) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (receiptPath != null && receiptPath.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 10,
                                        color: AppConstants.primaryColor,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Receipt',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (linkedTaskId != null && linkedTaskId.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 10,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Task Linked',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    (isExpense ? '-' : '+') +
                        CurrencyFormatter.format(amount, symbol),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isExpense
                          ? AppConstants.expenseColor
                          : AppConstants.secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getCategoryColor(String id, bool isExpense) {
    final catBox = Hive.box<Category>(Boxes.categories);
    final cat = catBox.get(id);
    if (cat != null) return cat.colorValue;
    return isExpense ? Colors.red.value : Colors.green.value;
  }

  IconData _getCategoryIcon(String id, bool isExpense) {
    final catBox = Hive.box<Category>(Boxes.categories);
    final cat = catBox.get(id);
    if (cat != null) {
      return IconHelper.getIcon(cat.iconCodePoint);
    }
    return isExpense ? Icons.payment : Icons.attach_money;
  }
}
