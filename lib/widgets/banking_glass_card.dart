import 'package:flutter/material.dart';
import '../theme/banking_theme.dart';

class BankingGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool hasBorder;
  
  const BankingGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BankingTheme.borderRadiusXLarge,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: BankingTheme.surface,
            borderRadius: BankingTheme.borderRadiusXLarge,
            border: hasBorder
                ? Border.all(color: BankingTheme.border, width: 0.5)
                : null,
            boxShadow: BankingTheme.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
