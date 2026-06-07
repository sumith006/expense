import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  
  const ParticlesBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
  });

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _initParticles();
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        position: Offset(
          Random().nextDouble() * 400,
          Random().nextDouble() * 800,
        ),
        velocity: Offset(
          (Random().nextDouble() - 0.5) * 0.5,
          (Random().nextDouble() - 0.5) * 0.5,
        ),
        size: Random().nextDouble() * 3 + 1,
        opacity: Random().nextDouble() * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particle positions
        for (var particle in _particles) {
          particle.position += particle.velocity;
          if (particle.position.dx < 0 || particle.position.dx > 400) {
            particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
          }
          if (particle.position.dy < 0 || particle.position.dy > 800) {
            particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
          }
        }
        
        return Stack(
          children: [
            // Particle layer
            CustomPaint(
              painter: ParticlePainter(_particles),
              size: Size.infinite,
            ),
            // Content layer
            widget.child,
          ],
        );
      },
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    
    for (var particle in particles) {
      paint.color = Colors.white.withValues(alpha: particle.opacity);
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
