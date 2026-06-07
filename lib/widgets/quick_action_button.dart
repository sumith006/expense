import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/banking_theme.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: color != null
                  ? LinearGradient(
                      colors: [color!, color!.withValues(alpha: 0.7)],
                    )
                  : BankingTheme.secondaryGradient,
              shape: BoxShape.circle,
              boxShadow: BankingTheme.buttonShadow,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: BankingTheme.textTheme.labelMedium?.copyWith(
              color: BankingTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
