import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  
  const NeumorphicCard({
    super.key,
    required this.child,
    this.elevation = 8,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkShadow = Colors.black.withValues(alpha: 0.5);
    final lightShadow = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: Offset(elevation, elevation),
            blurRadius: elevation * 2,
          ),
          BoxShadow(
            color: lightShadow,
            offset: Offset(-elevation, -elevation),
            blurRadius: elevation * 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
