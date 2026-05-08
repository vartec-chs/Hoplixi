import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FloatingSymbolsLayer extends StatefulWidget {
  const FloatingSymbolsLayer({super.key});

  @override
  State<FloatingSymbolsLayer> createState() => _FloatingSymbolsLayerState();
}

class _FloatingSymbolsLayerState extends State<FloatingSymbolsLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SymbolData> _symbols = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _generateSymbols();
  }

  void _generateSymbols() {
    final icons = [
      LucideIcons.lock,
      LucideIcons.key,
      LucideIcons.shield,
      LucideIcons.fingerprintPattern,
      LucideIcons.scanFace,
      LucideIcons.hardDrive,
      LucideIcons.database,
      LucideIcons.vault,
    ];

    for (int i = 0; i < 15; i++) {
      _symbols.add(
        _SymbolData(
          icon: icons[_random.nextInt(icons.length)],
          initialOffset: Offset(_random.nextDouble(), _random.nextDouble()),
          speed: _random.nextDouble() * 0.05 + 0.02,
          size: _random.nextDouble() * 20 + 20,
          opacity: _random.nextDouble() * 0.05 + 0.02,
          rotationSpeed: _random.nextDouble() * 2 - 1,
        ),
      );
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
        return Stack(
          children: _symbols.map((symbol) {
            final double t = _controller.value;
            final double x = (symbol.initialOffset.dx + t * symbol.speed) % 1.0;
            final double y =
                (symbol.initialOffset.dy +
                    sin(t * pi * 2 * symbol.speed * 10) * 0.02) %
                1.0;

            return Positioned(
              left: x * MediaQuery.of(context).size.width,
              top: y * MediaQuery.of(context).size.height,
              child: Transform.rotate(
                angle: t * pi * 2 * symbol.rotationSpeed,
                child: Icon(
                  symbol.icon,
                  size: symbol.size,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(symbol.opacity),
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
  final Offset initialOffset;
  final double speed;
  final double size;
  final double opacity;
  final double rotationSpeed;

  _SymbolData({
    required this.icon,
    required this.initialOffset,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.rotationSpeed,
  });
}
