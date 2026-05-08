import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/background/app_animated_background.dart';
import 'package:hoplixi/shared/ui/button.dart';

class BackgroundShowcaseScreen extends StatelessWidget {
  const BackgroundShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Animated Background',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This screen demonstrates the AppAnimatedBackground with its layers: Mesh Gradient, Noise, Floating Symbols, and Particles.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SmoothButton.primary(
                  label: 'Action in Background',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
