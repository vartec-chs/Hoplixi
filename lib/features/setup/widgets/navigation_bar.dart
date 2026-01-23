import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Навигационная панель для мастера настройки
class SetupNavigationBar extends StatelessWidget {
  final bool canGoBack;
  final bool isLastPage;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;
  final Widget? indicator;

  const SetupNavigationBar({
    super.key,
    this.canGoBack = false,
    this.isLastPage = false,
    this.isLoading = false,
    this.onBack,
    this.onNext,
    this.onComplete,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      color: colorScheme.surface,

      child: Row(
        children: [
          // Кнопка назад
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: canGoBack ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: canGoBack ? 1.0 : 0.8,
              child: IconButton.filled(
                onPressed: canGoBack ? onBack : null,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),

          const Spacer(),

          // Индикатор страниц
          if (indicator != null) indicator!,

          const Spacer(),

          // Кнопка вперёд / завершить
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: isLastPage
                ? SmoothButton(
                    key: const ValueKey('complete'),
                    label: 'Завершить',
                    onPressed: isLoading ? null : onComplete,
                    type: SmoothButtonType.filled,
                    variant: SmoothButtonVariant.success,
                    loading: isLoading,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                  )
                : SmoothButton(
                    key: const ValueKey('next'),
                    label: 'Далее',
                    onPressed: isLoading ? null : onNext,
                    type: SmoothButtonType.filled,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    iconPosition: SmoothButtonIconPosition.end,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Минималистичная навигационная панель
class SetupMinimalNavigationBar extends StatelessWidget {
  final bool canGoBack;
  final bool isLastPage;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;

  const SetupMinimalNavigationBar({
    super.key,
    this.canGoBack = false,
    this.isLastPage = false,
    this.isLoading = false,
    this.onBack,
    this.onNext,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Кнопка назад
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canGoBack ? 1.0 : 0.0,
              child: TextButton.icon(
                onPressed: canGoBack ? onBack : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Назад'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Кнопка вперёд / завершить
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLastPage
                  ? FilledButton.icon(
                      key: const ValueKey('complete'),
                      onPressed: isLoading ? null : onComplete,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Завершить'),
                    )
                  : TextButton.icon(
                      key: const ValueKey('next'),
                      onPressed: isLoading ? null : onNext,
                      icon: const Text('Далее'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 18),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
