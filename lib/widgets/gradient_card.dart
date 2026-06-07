import 'package:flutter/material.dart';
import '../theme/banking_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double height;
  final double width;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.height = 200,
    this.width = double.infinity,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient ?? BankingTheme.primaryGradient,
          borderRadius: BankingTheme.borderRadiusXXLarge,
          boxShadow: BankingTheme.cardShadow,
        ),
        child: child,
      ),
    );
  }
}
