import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_background_intensity.dart';

class ParticlesLayer extends StatelessWidget {
  final Animation<double> animation;
  final AppBackgroundIntensity intensity;

  const ParticlesLayer({
    super.key,
    required this.animation,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlesPainter(
            progress: animation.value,
            intensity: intensity,
            color: Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final AppBackgroundIntensity intensity;
  final Color color;
  final bool isDark;

  static List<_Particle>? _cachedParticles;
  static Size? _cachedSize;
  static AppBackgroundIntensity? _cachedIntensity;

  _ParticlesPainter({
    required this.progress,
    required this.intensity,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedParticles == null ||
        _cachedSize != size ||
        _cachedIntensity != intensity) {
      _generateParticles(size);
      _cachedSize = size;
      _cachedIntensity = intensity;
    }

    final paint = Paint();
    final t = progress * 2 * math.pi;

    for (final p in _cachedParticles!) {
      final dx = (p.initialX + math.cos(t + p.seed) * p.radiusX) % size.width;
      final dy = (p.initialY + math.sin(t + p.seed) * p.radiusY) % size.height;

      final realDx = dx < 0 ? dx + size.width : dx;
      final realDy = dy < 0 ? dy + size.height : dy;

      final alpha =
          (p.baseAlpha * (0.5 + 0.5 * math.sin(t * p.twinkleSpeed + p.seed)))
              .clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: isDark ? alpha : alpha * 0.6);
      canvas.drawCircle(Offset(realDx, realDy), p.size, paint);
    }
  }

  void _generateParticles(Size size) {
    final random = math.Random(42); // fixed seed
    int count;
    switch (intensity) {
      case AppBackgroundIntensity.low:
        count = size.width > 600 ? 30 : 15;
        break;
      case AppBackgroundIntensity.normal:
        count = size.width > 600 ? 60 : 30;
        break;
      case AppBackgroundIntensity.high:
        count = size.width > 600 ? 120 : 60;
        break;
    }

    _cachedParticles = List.generate(count, (index) {
      return _Particle(
        initialX: random.nextDouble() * size.width,
        initialY: random.nextDouble() * size.height,
        radiusX: random.nextDouble() * 50 + 10,
        radiusY: random.nextDouble() * 50 + 10,
        size: random.nextDouble() * 1.5 + 0.5,
        baseAlpha: random.nextDouble() * 0.4 + 0.1,
        seed: random.nextDouble() * math.pi * 2,
        twinkleSpeed: random.nextDouble() * 10 + 5,
      );
    });
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.color != color ||
        oldDelegate.intensity != intensity;
  }
}

class _Particle {
  final double initialX;
  final double initialY;
  final double radiusX;
  final double radiusY;
  final double size;
  final double baseAlpha;
  final double seed;
  final double twinkleSpeed;

  const _Particle({
    required this.initialX,
    required this.initialY,
    required this.radiusX,
    required this.radiusY,
    required this.size,
    required this.baseAlpha,
    required this.seed,
    required this.twinkleSpeed,
  });
}
