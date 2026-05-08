import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedMeshGradient extends StatefulWidget {
  const AnimatedMeshGradient({super.key});

  @override
  State<AnimatedMeshGradient> createState() => _AnimatedMeshGradientState();
}

class _AnimatedMeshGradientState extends State<AnimatedMeshGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(
            progress: _controller.value,
            colors: [
              colorScheme.primary.withOpacity(0.15),
              colorScheme.secondary.withOpacity(0.1),
              colorScheme.tertiary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _MeshPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Background base
    canvas.drawRect(rect, Paint()..color = colors[3]);

    final double t = progress * 2 * pi;

    void drawBlob(Offset center, double radius, Color color) {
      final Paint paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
      canvas.drawCircle(center, radius, paint);
    }

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Blob 1
    drawBlob(
      Offset(
        centerX + cos(t) * size.width * 0.3,
        centerY + sin(t) * size.height * 0.2,
      ),
      size.width * 0.5,
      colors[0],
    );

    // Blob 2
    drawBlob(
      Offset(
        centerX + sin(t * 0.7) * size.width * 0.4,
        centerY + cos(t * 0.8) * size.height * 0.3,
      ),
      size.width * 0.6,
      colors[1],
    );

    // Blob 3
    drawBlob(
      Offset(
        centerX + cos(t * 0.5 + 1) * size.width * 0.2,
        centerY + sin(t * 1.2 + 2) * size.height * 0.4,
      ),
      size.width * 0.4,
      colors[2],
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
