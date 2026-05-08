import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';

import 'animated_mesh_gradient.dart';
import 'floating_symbols_layer.dart';
import 'noise_overlay.dart';
import 'particles_layer.dart';

class AppAnimatedBackground extends ConsumerWidget {
  final Widget child;

  const AppAnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnimatedEnabled =
        ref.watch(animatedBackgroundEnabledProvider).value ?? true;

    if (!isAnimatedEnabled) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: child,
      );
    }

    return Stack(
      children: [
        // Layer 1: Animated Mesh Gradient (Slow, subtle colors)
        const Positioned.fill(child: AnimatedMeshGradient()),

        // Layer 2: Noise Overlay (Premium tactile feel)
        const Positioned.fill(child: NoiseOverlay(opacity: 0.03)),

        // Layer 3: Floating Symbols (Security themed icons)
        const Positioned.fill(child: FloatingSymbolsLayer()),

        // Layer 4: Particles (Glow effects)
        const Positioned.fill(child: ParticlesLayer()),

        // Layer 5: Main Content
        child,
      ],
    );
  }
}
