import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';

import 'animated_background_layer.dart';
import 'app_background_intensity.dart';

class AppAnimatedBackground extends ConsumerWidget {
  const AppAnimatedBackground({
    super.key,
    required this.child,
    this.enabled = true,
    this.showParticles = true,
    this.showSymbols = true,
    this.intensity = AppBackgroundIntensity.normal,
  });

  final Widget child;
  final bool enabled;
  final bool showParticles;
  final bool showSymbols;
  final AppBackgroundIntensity intensity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnimatedEnabled =
        ref.watch(animatedBackgroundEnabledProvider).value ?? true;

    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceContainerLowest;
    final isEnabled = enabled && isAnimatedEnabled;

    return Container(
      // duration: const Duration(milliseconds: 500),
      // curve: Curves.easeInOut,
      color: backgroundColor,
      child: isEnabled
          ? AnimatedBackgroundLayer(
              enabled: true,
              showParticles: showParticles,
              showSymbols: showSymbols,
              intensity: intensity,
              child: child,
            )
          : child,
    );
  }
}
