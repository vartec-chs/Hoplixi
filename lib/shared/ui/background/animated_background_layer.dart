import 'package:flutter/material.dart';

import 'app_background_intensity.dart';
import 'blob_layer.dart';
import 'noise_layer.dart';
import 'particles_layer.dart';
import 'symbols_layer.dart';
// import 'gradient_layer.dart';

class AnimatedBackgroundLayer extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool showParticles;
  final bool showSymbols;
  final AppBackgroundIntensity intensity;

  const AnimatedBackgroundLayer({
    super.key,
    required this.child,
    required this.enabled,
    required this.showParticles,
    required this.showSymbols,
    required this.intensity,
  });

  @override
  State<AnimatedBackgroundLayer> createState() =>
      _AnimatedBackgroundLayerState();
}

class _AnimatedBackgroundLayerState extends State<AnimatedBackgroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // const Positioned.fill(child: RepaintBoundary(child: GradientLayer())),
        Positioned.fill(
          child: RepaintBoundary(child: BlobLayer(animation: _controller)),
        ),
        const Positioned.fill(
          child: RepaintBoundary(child: NoiseLayer(opacity: 0.03)),
        ),
        if (widget.showSymbols)
          Positioned.fill(
            child: RepaintBoundary(
              child: SymbolsLayer(
                animation: _controller,
                intensity: widget.intensity,
              ),
            ),
          ),
        if (widget.showParticles)
          Positioned.fill(
            child: RepaintBoundary(
              child: ParticlesLayer(
                animation: _controller,
                intensity: widget.intensity,
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}
