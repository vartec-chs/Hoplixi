import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class HomeHeaderBackground extends StatelessWidget {
  const HomeHeaderBackground({
    super.key,
    required this.height,
    required this.hasRecentDatabase,
    required this.isAppActive,
    required this.pulseAnimation,
  });

  final double height;
  final bool hasRecentDatabase;
  final bool isAppActive;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.primary, colorScheme.primaryContainer],
            ),
          ),
          child: Stack(
            children: [
              _AnimatedTitle(
                top: (hasRecentDatabase ? 60 : 100) + topPadding,
                isAppActive: isAppActive,
              ),
              _PulseCircle(
                animation: pulseAnimation,
                left: -40,
                top: 20,
                size: 120,
                opacity: 0.1,
              ),
              _PulseCircle(
                animation: pulseAnimation,
                left: 20,
                bottom: -30,
                size: 80,
                opacity: 0.08,
                scaleFactor: 0.9,
              ),
              _PulseCircle(
                animation: pulseAnimation,
                right: -50,
                top: 40,
                size: 140,
                opacity: 0.12,
                scaleFactor: 1.1,
              ),
              _PulseCircle(
                animation: pulseAnimation,
                right: 30,
                top: 120,
                size: 60,
                opacity: 0.1,
                scaleFactor: 0.8,
              ),
              _PulseCircle(
                animation: pulseAnimation,
                right: -20,
                bottom: 10,
                size: 90,
                opacity: 0.07,
                scaleFactor: 1.2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({required this.top, required this.isAppActive});

  final double top;
  final bool isAppActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: colorScheme.onPrimary,
    );

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: isAppActive
              ? AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Hoplixi',
                      textStyle: textStyle,
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1000),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: false,
                )
              : Text('Hoplixi', style: textStyle),
        ),
      ),
    );
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({
    required this.animation,
    required this.size,
    required this.opacity,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.scaleFactor = 1,
  });

  final Animation<double> animation;
  final double size;
  final double opacity;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value * scaleFactor,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity),
              ),
            ),
          );
        },
      ),
    );
  }
}
