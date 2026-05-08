import 'dart:math';

import 'package:flutter/material.dart';

class ParticlesLayer extends StatefulWidget {
  const ParticlesLayer({super.key});

  @override
  State<ParticlesLayer> createState() => _ParticlesLayerState();
}

class _ParticlesLayerState extends State<ParticlesLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        velocity: Offset(_random.nextDouble() * 0.02 - 0.01, _random.nextDouble() * 0.02 - 0.01),
        size: _random.nextDouble() * 2 + 1,
        opacity: _random.nextDouble() * 0.3 + 0.1,
      ));
    }
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
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  Offset position;
  final Offset velocity;
  final double size;
  final double opacity;

  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });

  void update(double t) {
    position = Offset(
      (position.dx + velocity.dx * 0.1) % 1.0,
      (position.dy + velocity.dy * 0.1) % 1.0,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (final particle in particles) {
      particle.update(progress);
      paint.color = color.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(particle.position.dx * size.width, particle.position.dy * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
