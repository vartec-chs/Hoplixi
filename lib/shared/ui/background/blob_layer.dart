import 'dart:math' as math;

import 'package:flutter/material.dart';

class BlobLayer extends StatelessWidget {
  final Animation<double> animation;

  const BlobLayer({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final color1 = isDark
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.primary.withValues(alpha: 0.08);
    final color2 = isDark
        ? colorScheme.tertiary.withValues(alpha: 0.12)
        : colorScheme.tertiary.withValues(alpha: 0.08);
    final color3 = isDark
        ? colorScheme.secondary.withValues(alpha: 0.1)
        : colorScheme.secondary.withValues(alpha: 0.05);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        return Stack(
          children: [
            _buildBlob(
              color: color1,
              size: size.width * 0.8,
              x: size.width * 0.1 + math.cos(t) * size.width * 0.1,
              y: size.height * 0.1 + math.sin(t) * size.height * 0.1,
            ),
            _buildBlob(
              color: color2,
              size: size.width * 0.9,
              x: size.width * 0.5 + math.sin(t + math.pi) * size.width * 0.1,
              y: size.height * 0.6 + math.cos(t + math.pi) * size.height * 0.1,
            ),
            _buildBlob(
              color: color3,
              size: size.width * 0.7,
              x:
                  size.width * 0.3 +
                  math.cos(t + math.pi / 2) * size.width * 0.15,
              y:
                  size.height * 0.4 +
                  math.sin(t + math.pi / 2) * size.height * 0.15,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlob({
    required Color color,
    required double size,
    required double x,
    required double y,
  }) {
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
