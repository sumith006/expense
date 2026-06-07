import 'package:flutter/material.dart';
import '../theme/neobrutal_theme.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool hasGlow;
  final EdgeInsets padding;
  
  const NeonCard({
    super.key,
    required this.child,
    this.onTap,
    this.hasGlow = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeoBrutalTheme.surface,
            NeoBrutalTheme.surfaceVariant,
          ],
        ),
        borderRadius: NeoBrutalTheme.radiusXLarge,
        border: Border.all(
          color: NeoBrutalTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: hasGlow ? NeoBrutalTheme.glowShadow : NeoBrutalTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: NeoBrutalTheme.radiusXLarge,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
