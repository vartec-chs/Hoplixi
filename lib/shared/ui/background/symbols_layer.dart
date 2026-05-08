import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_background_intensity.dart';

class SymbolsLayer extends StatelessWidget {
  final Animation<double> animation;
  final AppBackgroundIntensity intensity;

  const SymbolsLayer({
    super.key,
    required this.animation,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final random = math.Random(1337); // fixed seed

    int count;
    switch (intensity) {
      case AppBackgroundIntensity.low:
        count = size.width > 600 ? 4 : 2;
        break;
      case AppBackgroundIntensity.normal:
        count = size.width > 600 ? 8 : 4;
        break;
      case AppBackgroundIntensity.high:
        count = size.width > 600 ? 16 : 8;
        break;
    }

    final icons = [
      LucideIcons.keyRound,
      LucideIcons.shieldCheck,
      LucideIcons.lockKeyhole,
      LucideIcons.fingerprintPattern,
      LucideIcons.database,
      LucideIcons.cloud,
      LucideIcons.scanLine,
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08);

    final symbols = List.generate(count, (index) {
      return _SymbolData(
        icon: icons[random.nextInt(icons.length)],
        initialX: random.nextDouble(),
        initialY: random.nextDouble(),
        radiusX: random.nextDouble() * 0.05 + 0.01,
        radiusY: random.nextDouble() * 0.05 + 0.01,
        size: random.nextDouble() * 40 + 40,
        seed: random.nextDouble() * math.pi * 2,
        rotationSpeed: random.nextDouble() * 2 - 1,
      );
    });

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        return Stack(
          children: symbols.map((s) {
            final x = (s.initialX + math.cos(t + s.seed) * s.radiusX) % 1.0;
            final y = (s.initialY + math.sin(t + s.seed) * s.radiusY) % 1.0;
            final realX = x < 0 ? x + 1.0 : x;
            final realY = y < 0 ? y + 1.0 : y;

            return Positioned(
              left: realX * size.width - s.size / 2,
              top: realY * size.height - s.size / 2,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: t * s.rotationSpeed + s.seed,
                  child: Icon(s.icon, size: s.size, color: color),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SymbolData {
  final IconData icon;
  final double initialX;
  final double initialY;
  final double radiusX;
  final double radiusY;
  final double size;
  final double seed;
  final double rotationSpeed;

  const _SymbolData({
    required this.icon,
    required this.initialX,
    required this.initialY,
    required this.radiusX,
    required this.radiusY,
    required this.size,
    required this.seed,
    required this.rotationSpeed,
  });
}
