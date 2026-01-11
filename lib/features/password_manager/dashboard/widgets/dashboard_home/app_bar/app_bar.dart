import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/store_settings/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../../../models/entity_type.dart';
import '../../../providers/filter_providers/base_filter_provider.dart';
import '../entity_type_dropdown.dart';
import 'app_bar_widgets.dart';

/// Полноценный SliverAppBar для дашборда с фильтрацией и поиском
/// Включает drawer кнопку, выбор типа сущности, кнопку фильтров, поиск и вкладки
class DashboardSliverAppBar extends ConsumerStatefulWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  final EntityType? entityType;

  /// Высота расширенного состояния
  final double expandedHeight;

  /// Высота свернутого состояния
  final double collapsedHeight;

  /// Должен ли AppBar быть закрепленным при прокрутке
  final bool pinned;

  /// Должен ли AppBar плавать при прокрутке
  final bool floating;

  /// Должен ли AppBar быстро появляться при прокрутке вверх
  final bool snap;

  /// Показывать ли selector типа сущности
  final bool showEntityTypeSelector;

  /// Дополнительные actions в AppBar
  final List<Widget>? additionalActions;

  /// Callback при применении фильтров
  final VoidCallback? onFilterApplied;

  const DashboardSliverAppBar({
    super.key,
    required this.entityType,
    this.onMenuPressed,
    this.expandedHeight = 160.0,
    this.collapsedHeight = 60.0,

    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.showEntityTypeSelector = true,
    this.additionalActions,
    this.onFilterApplied,
  });

  @override
  ConsumerState<DashboardSliverAppBar> createState() =>
      _DashboardSliverAppBarState();
}

class _DashboardSliverAppBarState extends ConsumerState<DashboardSliverAppBar> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  late EntityType currentType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Инициализируем currentType из параметров виджета
    currentType = widget.entityType ?? EntityType.password;

    logDebug('DashboardSliverAppBar: Инициализация');
  }

  @override
  void didUpdateWidget(covariant DashboardSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем currentType если изменился entityType
    final newType = widget.entityType ?? EntityType.password;
    if (newType != currentType) {
      setState(() {
        currentType = newType;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Обновляем поисковый запрос в базовом фильтре с дебаунсом
    ref.read(baseFilterProvider.notifier).updateQuery(query);
    logDebug(
      'DashboardSliverAppBar: Обновлен поисковый запрос',
      data: {'query': query},
    );
  }

  void _openFilterModal() {
    logInfo('DashboardSliverAppBar: Открытие модального окна фильтров');

    FilterModal.show(
      context: context,
      entityType: currentType,
      onFilterApplied: () {
        logInfo('DashboardSliverAppBar: Фильтры применены');
        widget.onFilterApplied?.call();
      },
    );
  }

  void _openStoreSettingsModal() {
    logInfo(
      'DashboardSliverAppBar: Открытие модального окна настроек хранилища',
    );

    showStoreSettingsModal(context, ref);
  }

  String _getSearchHint(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return 'Поиск паролей по названию, URL, пользователю...';
      case EntityType.note:
        return 'Поиск заметок по заголовку, содержимому...';
      case EntityType.otp:
        return 'Поиск OTP по издателю, аккаунту...';
      case EntityType.bankCard:
        return 'Поиск карт по названию, номеру...';
      case EntityType.file:
        return 'Поиск файлов по имени...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseFilter = ref.watch(baseFilterProvider);
    final currentEntityType = currentType;

    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      collapsedHeight: widget.collapsedHeight,
      pinned: widget.pinned,
      floating: widget.floating,
      snap: widget.snap,
      elevation: 0,

      // Кнопка открытия drawer слева
      leading: widget.onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
              tooltip: 'Открыть меню',
            )
          : null,
      // Actions справа: выбор типа сущности и кнопка фильтров
      actions: [
        if (widget.showEntityTypeSelector) ...[
          // Компактный селектор типа сущности
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: EntityTypeCompactDropdown(
              onEntityTypeChanged: (entityType) {
                logInfo(
                  'DashboardSliverAppBar: Изменен тип сущности',
                  data: {'type': entityType.label},
                );
              },
            ),
          ),
        ],
        // Кнопка открытия модального окна фильтров
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              // Индикатор активных фильтров
              if (baseFilter.hasActiveConstraints)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openFilterModal,
          tooltip: 'Открыть фильтры',
        ),

        // Кнопка настроек хранилища
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _openStoreSettingsModal,
          tooltip: 'Настройки хранилища',
        ),

        // Дополнительные actions
        if (widget.additionalActions != null) ...widget.additionalActions!,

        const SizedBox(width: 8),
      ],

      // Заголовок в свернутом состоянии
      title: Text(
        currentEntityType.label,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Расширенный контент
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 58),

                // Нижняя часть с поиском и вкладками
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      // vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        // Поле поиска
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: 50,
                            child: PrimaryTextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              hintText: _getSearchHint(currentEntityType),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              decoration:
                                  primaryInputDecoration(
                                    context,
                                    hintText: _getSearchHint(currentEntityType),
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ),

                        // Вкладки фильтров
                        FilterTabs(
                          height: 40,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          borderRadius: 16,
                          onTabChanged: (tab) {
                            logInfo(
                              'DashboardSliverAppBar: Изменена вкладка',
                              data: {'tab': tab.label},
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
      ),
    );
  }
}

/// Компактная версия DashboardSliverAppBar для использования в различных экранах
class CompactDashboardSliverAppBar extends ConsumerWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Заголовок
  final String title;

  /// Дополнительные actions
  final List<Widget>? actions;

  /// Показывать ли кнопку фильтров
  final bool showFilterButton;

  /// Callback при открытии фильтров
  final VoidCallback? onFilterPressed;

  const CompactDashboardSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.title = 'Hoplixi',
    this.actions,
    this.showFilterButton = false,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseFilter = ref.watch(baseFilterProvider);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,

      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
        tooltip: 'Открыть меню',
      ),

      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      actions: [
        if (showFilterButton) ...[
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (baseFilter.hasActiveConstraints)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onFilterPressed,
            tooltip: 'Фильтры',
          ),
        ],
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}
