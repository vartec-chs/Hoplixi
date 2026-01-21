import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Страница настройки биометрии
class BiometricPage extends ConsumerStatefulWidget {
  const BiometricPage({super.key});

  @override
  ConsumerState<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends ConsumerState<BiometricPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final setupState = ref.watch(setupProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100),

            // Иконка отпечатка с анимацией
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: setupState.biometricEnabled
                            ? [Colors.green.shade400, Colors.teal.shade600]
                            : [
                                colorScheme.surfaceContainerHighest,
                                colorScheme.surfaceContainerHigh,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: setupState.biometricEnabled
                              ? Colors.teal.withOpacity(0.3)
                              : colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 72,
                      color: setupState.biometricEnabled
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Заголовок
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Биометрическая защита',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      setupState.biometricAvailable
                          ? 'Используйте отпечаток пальца или Face ID\n'
                                'для быстрого и безопасного доступа'
                          : 'Биометрическая аутентификация\n'
                                'недоступна на этом устройстве',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Карточка с информацией и переключателем
            if (setupState.biometricAvailable) ...[
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBiometricCard(context, setupState),
                ),
              ),
            ] else ...[
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildUnavailableCard(context),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricCard(BuildContext context, SetupState setupState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Преимущества
          _buildFeatureRow(
            context,
            Icons.flash_on_rounded,
            'Быстрый доступ',
            'Разблокировка за секунду',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            context,
            Icons.security_rounded,
            'Высокая безопасность',
            'Уникальные биометрические данные',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            context,
            Icons.visibility_off_rounded,
            'Конфиденциальность',
            'Данные не покидают устройство',
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Кнопки
          Row(
            children: [
              Expanded(
                child: SmoothButton(
                  label: 'Пропустить',
                  onPressed: () {
                    ref.read(setupProvider.notifier).setBiometric(false);
                  },
                  type: SmoothButtonType.outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SmoothButton(
                  label: setupState.biometricEnabled
                      ? 'Включено ✓'
                      : 'Включить',
                  onPressed: () {
                    if (!setupState.biometricEnabled) {
                      ref.read(setupProvider.notifier).setBiometric(true);
                    }
                  },
                  type: SmoothButtonType.filled,
                  variant: setupState.biometricEnabled
                      ? SmoothButtonVariant.success
                      : SmoothButtonVariant.normal,
                  icon: Icon(
                    setupState.biometricEnabled
                        ? Icons.check_circle
                        : Icons.fingerprint,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Биометрия недоступна',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Вы можете настроить биометрическую\n'
            'аутентификацию позже в настройках',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
