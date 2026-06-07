import 'package:flutter/material.dart';

class AnimationsUtils {
  static Animation<Offset> slideAnimation(AnimationController controller) {
    return Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }
  
  static Animation<double> fadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
  }
  
  static Animation<double> scaleAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
  }
  
  static Animation<EdgeInsets> slideUpAnimation(AnimationController controller) {
    return Tween<EdgeInsets>(begin: const EdgeInsets.only(top: 50), end: EdgeInsets.zero)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }
}

class ShimmerEffect extends StatelessWidget {
  final Widget child;
  
  const ShimmerEffect({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}
