import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Индикатор страниц для мастера настройки
class SetupPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final ValueChanged<int>? onDotClicked;

  const SetupPageIndicator({
    super.key,
    required this.controller,
    required this.count,
    this.onDotClicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 8,
        activeDotColor: colorScheme.primary,
        dotColor: colorScheme.surfaceContainerHighest,
        paintStyle: PaintingStyle.fill,
      ),
      onDotClicked: onDotClicked,
    );
  }
}

/// Альтернативный индикатор с эффектом "worm"
class SetupWormIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final ValueChanged<int>? onDotClicked;

  const SetupWormIndicator({
    super.key,
    required this.controller,
    required this.count,
    this.onDotClicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: WormEffect(
        dotHeight: 10,
        dotWidth: 10,
        spacing: 12,
        activeDotColor: colorScheme.primary,
        dotColor: colorScheme.surfaceContainerHighest,
        type: WormType.thin,
      ),
      onDotClicked: onDotClicked,
    );
  }
}

/// Индикатор с эффектом "jumping dot"
class SetupJumpingIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final ValueChanged<int>? onDotClicked;

  const SetupJumpingIndicator({
    super.key,
    required this.controller,
    required this.count,
    this.onDotClicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: JumpingDotEffect(
        dotHeight: 10,
        dotWidth: 10,
        spacing: 12,
        jumpScale: 1.5,
        verticalOffset: 10,
        activeDotColor: colorScheme.primary,
        dotColor: colorScheme.surfaceContainerHighest,
      ),
      onDotClicked: onDotClicked,
    );
  }
}
