import 'package:flutter/material.dart';

class GradientLayer extends StatelessWidget {
  const GradientLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surface.withValues(alpha: 1.0),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  colorScheme.surface.withValues(alpha: 1.0),
                ]
              : [
                  colorScheme.surface.withValues(alpha: 1.0),
                  colorScheme.surfaceContainer.withValues(alpha: 0.5),
                  colorScheme.surface.withValues(alpha: 1.0),
                ],
        ),
      ),
    );
  }
}
