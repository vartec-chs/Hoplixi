import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'providers/recent_database_provider.dart';
import 'widgets/action_button.dart';
import 'widgets/action_button_compact.dart';
import 'widgets/recent_database_card.dart';

/// Модель данных для кнопки действия
class ActionItem {
  final IconData icon;
  final String label;
  final String? description;
  final bool isPrimary;
  final bool disabled;
  final String? routePath;
  final VoidCallback? onTap;

  const ActionItem({
    required this.icon,
    required this.label,
    this.description,
    this.isPrimary = false,
    this.disabled = false,
    this.routePath,
    this.onTap,
  });
}

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  double _offset = 0;

  // Анимации для шариков
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Инициализация анимаций шариков
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTitleBarLabel();
    });
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).updateColor(Colors.white);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }

  void _onScroll() {
    setState(() => _offset = _scrollController.offset);

    if (_scrollController.offset >= 160) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    } else {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentDbAsync = ref.watch(recentDatabaseProvider);

    // Определяем, есть ли недавняя БД
    final hasRecentDb = recentDbAsync.maybeWhen(
      data: (entry) => entry != null,
      orElse: () => false,
    );

    // Динамический offset: если есть карточка - наезжает на 88px, иначе начинается сразу после AppBar
    final contentTopOffset = hasRecentDb
        ? 220 + MediaQuery.of(context).padding.top - 88
        : 220 + MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // 1. AppBar-фон с градиентом и кружками
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220 + MediaQuery.of(context).padding.top,
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
                    // Title с анимацией
                    Positioned(
                      top: hasRecentDb
                          ? 60 + MediaQuery.of(context).padding.top
                          : 100 + MediaQuery.of(context).padding.top,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Hoplixi',
                              textStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                              speed: const Duration(milliseconds: 150),
                            ),
                            ScrambleAnimatedText(
                              'Добро пожаловать',
                              textStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                          ],
                          repeatForever: true,
                          pause: const Duration(milliseconds: 1000),
                          displayFullTextOnTap: true,
                          stopPauseOnTap: false,
                        ),
                      ),
                    ),
                    // Левый верхний круг
                    Positioned(
                      left: -40,
                      top: 20,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Левый нижний круг
                    Positioned(
                      left: 20,
                      bottom: -30,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.9,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Правый верхний круг
                    Positioned(
                      right: -50,
                      top: 40,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 1.1,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Правый средний круг
                    Positioned(
                      right: 30,
                      top: 120,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.8,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Правый нижний круг
                    Positioned(
                      right: -20,
                      bottom: 10,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 1.2,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Карточка БД (фиксированная) + скроллируемый контент ниже
          if (hasRecentDb)
            Positioned.fill(
              top: contentTopOffset,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: RecentDatabaseCard(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 500;
                        final items = _buildActionItems(context);

                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: isSmallScreen
                                ? _buildCompactGrid(items)
                                : _buildWideGrid(items),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 3. Центрированный экран без недавней БД
          if (!hasRecentDb)
            Positioned.fill(
              top: 220 + MediaQuery.of(context).padding.top + 16,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 500;
                  final items = _buildActionItems(context);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: isSmallScreen
                          ? _buildVerticalList(items)
                          : _buildWideGrid(items),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Список кнопок действий — легко расширять
  List<ActionItem> _buildActionItems(BuildContext context) {
    return [
      ActionItem(
        icon: LucideIcons.folderOpen,
        label: 'Открыть',
        description: 'Существующее хранилище',
        isPrimary: true,
        onTap: () => context.push(AppRoutesPaths.openStore),
      ),
      ActionItem(
        icon: LucideIcons.plus,
        label: 'Создать',
        description: 'Новое хранилище',
        onTap: () => context.push(AppRoutesPaths.createStore),
      ),
      ActionItem(
        icon: LucideIcons.settings,
        label: 'Настройки',
        description: 'Конфигурация',
        onTap: () => context.push(AppRoutesPaths.settings),
      ),
      ActionItem(
        icon: LucideIcons.fileText,
        label: 'Логи',
        description: 'Просмотр логов',
        onTap: () => context.push(AppRoutesPaths.logs),
      ),
    ];
  }

  /// Компактная сетка 2x2 для маленьких экранов
  Widget _buildCompactGrid(List<ActionItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: items
          .map(
            (item) => ActionButtonCompact(
              icon: item.icon,
              label: item.label,
              description: item.description,
              isPrimary: item.isPrimary,
              disabled: item.disabled,
              onTap: item.onTap,
            ),
          )
          .toList(),
    );
  }

  /// Сетка горизонтальных кнопок 2x2 для больших экранов
  Widget _buildWideGrid(List<ActionItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: items
          .map(
            (item) => ActionButton(
              icon: item.icon,
              label: item.label,
              description: item.description,
              isPrimary: item.isPrimary,
              disabled: item.disabled,
              onTap: item.onTap,
            ),
          )
          .toList(),
    );
  }

  /// Вертикальный список кнопок (одна колонка) для экрана без недавней БД
  Widget _buildVerticalList(List<ActionItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActionButton(
                icon: item.icon,
                label: item.label,
                description: item.description,
                isPrimary: item.isPrimary,
                disabled: item.disabled,
                onTap: item.onTap,
              ),
            ),
          )
          .toList(),
    );
  }
}
