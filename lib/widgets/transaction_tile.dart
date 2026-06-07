import 'package:flutter/material.dart';
import '../theme/neobrutal_theme.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final bool isExpense;
  final VoidCallback? onTap;
  
  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.isExpense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoBrutalTheme.surface,
          borderRadius: NeoBrutalTheme.radiusMedium,
          border: Border.all(
            color: isExpense ? NeoBrutalTheme.error.withValues(alpha: 0.2) : NeoBrutalTheme.success.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpense
                      ? [NeoBrutalTheme.error, NeoBrutalTheme.accent]
                      : [NeoBrutalTheme.success, NeoBrutalTheme.secondary],
                ),
                borderRadius: NeoBrutalTheme.radiusMedium,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NeoBrutalTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: amount),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Text(
                  '${isExpense ? '-' : '+'}\$${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isExpense ? NeoBrutalTheme.error : NeoBrutalTheme.success,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
