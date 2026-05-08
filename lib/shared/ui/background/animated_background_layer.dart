import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  late final Ticker _ticker;
  late final _InfiniteAnimation _animation = _InfiniteAnimation();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      // 60 seconds per "cycle" for a calmer feel, and it never resets
      _animation.update(elapsed.inMicroseconds / 60000000.0);
    });
    if (widget.enabled) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: BlobLayer(animation: _animation)),
        ),
        const Positioned.fill(
          child: RepaintBoundary(child: NoiseLayer(opacity: 0.03)),
        ),
        if (widget.showSymbols)
          Positioned.fill(
            child: RepaintBoundary(
              child: SymbolsLayer(
                animation: _animation,
                intensity: widget.intensity,
              ),
            ),
          ),
        if (widget.showParticles)
          Positioned.fill(
            child: RepaintBoundary(
              child: ParticlesLayer(
                animation: _animation,
                intensity: widget.intensity,
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _InfiniteAnimation extends Animation<double>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  double _value = 0.0;

  void update(double newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  double get value => _value;

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}
}
