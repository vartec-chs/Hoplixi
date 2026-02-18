import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';

import '../../../models/filter_tab.dart';
import '../../../providers/filter_tab_provider.dart';

/// Виджет для отображения вкладок фильтров
/// Управляет состоянием активной вкладки через провайдер
/// Адаптируется под текущий тип сущности
class FilterTabs extends ConsumerStatefulWidget {
  /// Callback при изменении активной вкладки
  final ValueChanged<FilterTab>? onTabChanged;

  /// Высота TabBar
  final double height;

  /// Отступы для лейблов
  final EdgeInsets labelPadding;

  /// Радиус скругления
  final double borderRadius;

  const FilterTabs({
    super.key,
    this.onTabChanged,
    this.height = 40,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    this.borderRadius = 12,
  });

  @override
  ConsumerState<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends ConsumerState<FilterTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<FilterTab> _currentTabs = [];

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер с минимальной длиной
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
  }

  void _updateTabController() {
    final pathParams = GoRouterState.of(context).pathParameters;
    final entityId = pathParams['entity'];
    final currentType =
        EntityType.fromId(entityId ?? '') ?? EntityType.password;
    final newTabs = FilterTab.getAvailableTabsForEntity(currentType);
    final currentTab = ref.read(filterTabProvider);

    // Если вкладки изменились, обновляем контроллер
    if (!_areTabsEqual(_currentTabs, newTabs)) {
      _currentTabs = newTabs;

      // Создаем новый TabController
      final oldController = _tabController;
      _tabController = TabController(length: _currentTabs.length, vsync: this);

      // Устанавливаем индекс активной вкладки
      final currentTabIndex = _currentTabs.indexOf(currentTab);
      if (currentTabIndex != -1) {
        _tabController.index = currentTabIndex;
      } else {
        // Если текущая вкладка недоступна, выбираем первую
        _tabController.index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(filterTabProvider.notifier).changeTab(_currentTabs.first);
        });
      }

      // Добавляем слушатель для отслеживания изменений
      _tabController.addListener(_onTabChanged);

      // Освобождаем старый контроллер
      oldController.removeListener(_onTabChanged);
      oldController.dispose();

      logDebug(
        'FilterTabs: Обновлены вкладки',
        data: {
          'entityType': currentType.id,
          'tabsCount': _currentTabs.length,
          'currentTabIndex': _tabController.index,
        },
      );
    }
  }

  bool _areTabsEqual(List<FilterTab> tabs1, List<FilterTab> tabs2) {
    if (tabs1.length != tabs2.length) return false;
    for (int i = 0; i < tabs1.length; i++) {
      if (tabs1[i] != tabs2[i]) return false;
    }
    return true;
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging &&
        _tabController.index >= 0 &&
        _tabController.index < _currentTabs.length) {
      final selectedTab = _currentTabs[_tabController.index];

      logDebug(
        'FilterTabs: Изменена вкладка',
        data: {'tabIndex': _tabController.index, 'tabLabel': selectedTab.label},
      );

      // Обновляем провайдер
      ref.read(filterTabProvider.notifier).changeTab(selectedTab);

      // Вызываем callback
      widget.onTabChanged?.call(selectedTab);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUse = MediaQuery.of(context).size.width <= 600;
    final isScrollable = isUse && _currentTabs.length > 3;
    final tabAlignment = isUse ? TabAlignment.center : TabAlignment.fill;
    final currentTab = ref.watch(filterTabProvider);

    // Слушаем изменения типа сущности

    // Слушаем изменения активной вкладки извне
    ref.listen<FilterTab>(filterTabProvider, (previous, next) {
      if (previous != next) {
        final newIndex = _currentTabs.indexOf(next);
        if (newIndex != -1 && _tabController.index != newIndex) {
          _tabController.animateTo(newIndex);
        }
      }
    });

    if (_currentTabs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Определяем цвет индикатора в зависимости от текущей вкладки
    final indicatorColor = theme.colorScheme.surfaceContainerLow;

    final labelColor = theme.colorScheme.onSecondary;

    final fillColor = AppColors.getInputFieldBackgroundColor(context);

    return Container(
      height: widget.height + 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: fillColor,
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isScrollable,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _AnimatedTabIndicator(
          color: indicatorColor,
          borderRadius: widget.borderRadius,
        ),
        labelColor: labelColor,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.7,
        ),
        splashFactory: InkRipple.splashFactory,
        dividerColor: Colors.transparent,

        physics: const BouncingScrollPhysics(),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        overlayColor: WidgetStateProperty.all(
          theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),

        indicatorPadding: const EdgeInsets.all(2),
        unselectedLabelStyle: theme.textTheme.bodyMedium,
        tabAlignment: tabAlignment,
        labelPadding: widget.labelPadding,
        splashBorderRadius: BorderRadius.circular(widget.borderRadius),
        tabs: _currentTabs.map((tab) {
          return Tab(
            icon: Icon(tab.icon, size: 16),
            text: tab.label,
            height: widget.height,
          );
        }).toList(),
      ),
    );
  }
}

/// Анимированный индикатор для TabBar с плавным переходом цвета
class _AnimatedTabIndicator extends Decoration {
  final Color color;
  final double borderRadius;

  const _AnimatedTabIndicator({
    required this.color,
    required this.borderRadius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _AnimatedTabIndicatorPainter(
      color: color,
      borderRadius: borderRadius,
      onChanged: onChanged,
    );
  }
}

class _AnimatedTabIndicatorPainter extends BoxPainter {
  final Color color;
  final double borderRadius;

  _AnimatedTabIndicatorPainter({
    required this.color,
    required this.borderRadius,
    VoidCallback? onChanged,
  }) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.drawRRect(rrect, paint);
  }
}
