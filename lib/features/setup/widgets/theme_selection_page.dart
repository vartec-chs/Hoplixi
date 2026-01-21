import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';

/// Страница выбора темы приложения
class ThemeSelectionPage extends ConsumerStatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  ConsumerState<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends ConsumerState<ThemeSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Заголовок
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Выберите тему',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Настройте внешний вид приложения под себя',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Карточки выбора темы
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildThemeOptions(context, setupState),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(BuildContext context, SetupState setupState) {
    return animated_theme.ThemeSwitcher.switcher(
      builder: (context, switcher) {
        return _buildThemeList(context, setupState, switcher);
      },
    );
  }

  Widget _buildThemeList(
    BuildContext context,
    SetupState setupState,
    dynamic switcher,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final themes = [
      (
        ThemeMode.light,
        'Светлая',
        Icons.wb_sunny_rounded,
        Colors.orange,
        'Яркий и чистый интерфейс',
      ),
      (
        ThemeMode.dark,
        'Тёмная',
        Icons.nights_stay_rounded,
        Colors.indigo,
        'Комфорт для глаз',
      ),
      (
        ThemeMode.system,
        'Системная',
        Icons.settings_brightness_rounded,
        Colors.teal,
        'Следует за системой',
      ),
    ];

    return Column(
      children: themes.map((themeOption) {
        final isSelected = setupState.selectedTheme == themeOption.$1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final selectedTheme = themeOption.$1;

                  // Определяем новую тему
                  final newTheme = selectedTheme == ThemeMode.light
                      ? AppTheme.light(context)
                      : selectedTheme == ThemeMode.dark
                      ? AppTheme.dark(context)
                      : MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                      ? AppTheme.dark(context)
                      : AppTheme.light(context);

                  // Определяем направление анимации
                  final currentIsDark =
                      setupState.selectedTheme == ThemeMode.dark ||
                      (setupState.selectedTheme == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);
                  final isReversed =
                      currentIsDark && selectedTheme != ThemeMode.dark;

                  // Анимируем переход темы
                  switcher.changeTheme(theme: newTheme, isReversed: isReversed);

                  // Обновляем состояние setup
                  ref.read(setupProvider.notifier).setTheme(selectedTheme);

                  // Обновляем глобальную тему
                  final themeNotifier = ref.read(themeProvider.notifier);
                  switch (selectedTheme) {
                    case ThemeMode.light:
                      await themeNotifier.setLightTheme();
                      break;
                    case ThemeMode.dark:
                      await themeNotifier.setDarkTheme();
                      break;
                    case ThemeMode.system:
                      await themeNotifier.setSystemTheme();
                      break;
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Иконка темы
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              themeOption.$4.withOpacity(0.8),
                              themeOption.$4,
                            ],
                          ),
                        ),
                        child: Icon(
                          themeOption.$3,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Текст
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              themeOption.$2,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              themeOption.$5,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                          .withOpacity(0.7)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Чекбокс
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
