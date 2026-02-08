import 'package:hoplixi/core/theme/clippers/fancy_theme_switcher_clippers.dart';

import 'theme_provider.dart';
import 'theme.dart';
import 'clippers/wave_theme_switcher_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;

/// Современный виджет для переключения темы приложения
class ThemeSwitcher extends ConsumerWidget {
  /// Размер виджета
  final double size;

  /// Показывать ли текст режима
  final bool showModeText;

  /// Стиль анимации
  final ThemeSwitcherStyle style;

  const ThemeSwitcher({
    super.key,
    this.size = 40.0,
    this.showModeText = false,
    this.style = ThemeSwitcherStyle.toggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final themeMode = theme.value ?? ThemeMode.system;

    switch (style) {
      case ThemeSwitcherStyle.toggle:
        return _buildToggleSwitch(context, themeMode, themeNotifier);
      case ThemeSwitcherStyle.dropdown:
        return _buildDropdown(context, themeMode, themeNotifier);
      case ThemeSwitcherStyle.segmented:
        return _buildSegmentedControl(context, themeMode, themeNotifier);
      case ThemeSwitcherStyle.animated:
        return _buildAnimatedSwitch(context, themeMode, themeNotifier);
    }
  }

  /// Простой переключатель с анимацией
  Widget _buildToggleSwitch(
    BuildContext context,
    ThemeMode themeMode,
    ThemeProvider themeNotifier,
  ) {
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return animated_theme.ThemeSwitcher.switcher(
      clipper: const PolygonThemeSwitcherClipper(),
      builder: (context, switcher) {
        return GestureDetector(
          onTap: () async {
            // Определяем новую тему перед изменением
            final newIsDark = !isDark;
            final newTheme = newIsDark
                ? AppTheme.dark(context)
                : AppTheme.light(context);

            // Обновляем тему через switcher с параметром isReversed
            // isReversed = true: тёмная -> светлая (обратная анимация)
            // isReversed = false: светлая -> тёмная (прямая анимация)
            switcher.changeTheme(
              theme: newTheme,
              isReversed:
                  isDark, // true при переходе из темной, false из светлой
            );

            // Затем обновляем состояние приложения
            if (newIsDark) {
              await themeNotifier.setDarkTheme();
            } else {
              await themeNotifier.setLightTheme();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: size * 1.8,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              color: isDark ? Colors.blue.shade600 : Colors.grey.shade300,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isDark ? size * 0.85 : 4,
                  top: 4,
                  child: Container(
                    width: size - 8,
                    height: size - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark ? Icons.nights_stay : Icons.wb_sunny,
                      size: size * 0.4,
                      color: isDark ? Colors.blue.shade600 : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Выпадающий список для выбора темы
  Widget _buildDropdown(
    BuildContext context,
    ThemeMode themeMode,
    ThemeProvider themeNotifier,
  ) {
    return PopupMenuButton<ThemeMode>(
      icon: Icon(_getThemeIcon(themeMode, context), size: size * 0.6),
      onSelected: (ThemeMode mode) {
        switch (mode) {
          case ThemeMode.light:
            themeNotifier.setLightTheme();
            break;
          case ThemeMode.dark:
            themeNotifier.setDarkTheme();
            break;
          case ThemeMode.system:
            themeNotifier.setSystemTheme();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange),
              SizedBox(width: 8),
              Text('Светлая'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.nights_stay, color: Colors.blue),
              SizedBox(width: 8),
              Text('Темная'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.settings_brightness, color: Colors.grey),
              SizedBox(width: 8),
              Text('Системная'),
            ],
          ),
        ),
      ],
    );
  }

  /// Сегментированный контрол
  Widget _buildSegmentedControl(
    BuildContext context,
    ThemeMode themeMode,
    ThemeProvider themeNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton(
            context,
            Icons.wb_sunny,
            themeMode == ThemeMode.light,
            ThemeMode.light,
            () => themeNotifier.setLightTheme(),
            themeNotifier,
          ),
          _buildSegmentButton(
            context,
            Icons.settings_brightness,
            themeMode == ThemeMode.system,
            ThemeMode.system,
            () => themeNotifier.setSystemTheme(),
            themeNotifier,
          ),
          _buildSegmentButton(
            context,
            Icons.nights_stay,
            themeMode == ThemeMode.dark,
            ThemeMode.dark,
            () => themeNotifier.setDarkTheme(),
            themeNotifier,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    IconData icon,
    bool isSelected,
    ThemeMode themeMode,
    VoidCallback onTap,
    ThemeProvider themeNotifier,
  ) {
    return animated_theme.ThemeSwitcher.switcher(
      clipper: const WaveThemeSwitcherClipper(
        waveCount: 6,
        amplitude: 25.0,
        spiralEffect: false,
        starEffect: true,
      ),
      builder: (context, switcher) {
        return GestureDetector(
          onTap: () async {
            // Определяем новую тему на основе выбранного режима
            final newTheme = themeMode == ThemeMode.light
                ? AppTheme.light(context)
                : themeMode == ThemeMode.dark
                ? AppTheme.dark(context)
                : MediaQuery.of(context).platformBrightness == Brightness.dark
                ? AppTheme.dark(context)
                : AppTheme.light(context);

            // Определяем направление анимации
            // isReversed = true: если переходим из темной темы
            // isReversed = false: если переходим из светлой темы
            final isReversed = themeMode != ThemeMode.light;

            // Обновляем тему через switcher с параметром isReversed
            switcher.changeTheme(theme: newTheme, isReversed: isReversed);

            // Обновляем состояние
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(size * 0.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: size * 0.5,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        );
      },
    );
  }

  /// Анимированный переключатель с плавными переходами
  Widget _buildAnimatedSwitch(
    BuildContext context,
    ThemeMode themeMode,
    ThemeProvider themeNotifier,
  ) {
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return animated_theme.ThemeSwitcher.switcher(
      clipper: const WaveThemeSwitcherClipper(
        waveCount: 8,
        amplitude: 50.0,
        spiralEffect: true,
        starEffect: true,
      ),
      builder: (context, switcher) {
        return GestureDetector(
          onTap: () async {
            // Определяем новую тему перед изменением
            final newIsDark = !isDark;
            final newTheme = newIsDark
                ? AppTheme.dark(context)
                : AppTheme.light(context);

            // Обновляем тему через switcher с параметром isReversed
            // isReversed = true: тёмная -> светлая (обратная анимация)
            // isReversed = false: светлая -> тёмная (прямая анимация)
            switcher.changeTheme(
              theme: newTheme,
              isReversed:
                  isDark, // true при переходе из темной, false из светлой
            );

            // Затем обновляем состояние приложения
            if (newIsDark) {
              await themeNotifier.setDarkTheme();
            } else {
              await themeNotifier.setLightTheme();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: size * 1.5,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.indigo.shade800, Colors.purple.shade600]
                    : [Colors.orange.shade300, Colors.yellow.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.purple : Colors.orange).withOpacity(
                    0.3,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Звезды для темной темы
                if (isDark) ..._buildStars(),

                // Солнце/луна
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  left: isDark ? size * 0.55 : 4,
                  top: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: size - 8,
                    height: size - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey.shade200 : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark ? Icons.nights_stay : Icons.wb_sunny,
                      size: size * 0.4,
                      color: isDark
                          ? Colors.indigo.shade300
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Создает звезды для темной темы
  List<Widget> _buildStars() {
    return [
      Positioned(
        left: size * 0.15,
        top: size * 0.2,
        child: Icon(
          Icons.star,
          size: size * 0.1,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      Positioned(
        left: size * 0.25,
        top: size * 0.6,
        child: Icon(
          Icons.star,
          size: size * 0.08,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
      Positioned(
        left: size * 0.1,
        top: size * 0.7,
        child: Icon(
          Icons.star,
          size: size * 0.06,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    ];
  }

  IconData _getThemeIcon(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nights_stay;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

/// Стили виджета переключения темы
enum ThemeSwitcherStyle {
  /// Простой переключатель
  toggle,

  /// Выпадающий список
  dropdown,

  /// Сегментированный контрол
  segmented,

  /// Анимированный переключатель
  animated,
}

/// Компактный виджет для AppBar
class AppBarThemeSwitcher extends ConsumerWidget {
  const AppBarThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ThemeSwitcher(size: 32, style: ThemeSwitcherStyle.toggle);
  }
}

/// Виджет с текстом для настроек
class SettingsThemeSwitcher extends ConsumerWidget {
  const SettingsThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final themeMode = theme.value ?? ThemeMode.system;

    return ListTile(
      leading: Icon(_getThemeIcon(themeMode, context)),
      title: const Text('Тема'),
      subtitle: Text(_getThemeText(themeMode)),
      trailing: const ThemeSwitcher(size: 40, style: ThemeSwitcherStyle.segmented),
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nights_stay;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Светлая тема';
      case ThemeMode.dark:
        return 'Темная тема';
      case ThemeMode.system:
        return 'Системная тема';
    }
  }
}
