import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_picker_provider.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_filters.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_item.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Модальное окно выбора категории
class CategoryPickerModal {
  /// Показать модальное окно выбора категории (одиночный выбор)
  static Future<void> show({
    required BuildContext context,
    required Function(String categoryId, String categoryName)
    onCategorySelected,
    String? currentCategoryId,
    List<String>? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,

      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onCategorySelected,
          currentCategoryId,
          filterByType,
        ),
      ],
    );
  }

  /// Показать модальное окно выбора категорий (множественный выбор для фильтра)
  static Future<void> showMultiple({
    required BuildContext context,
    required Function(List<String> categoryIds, List<String> categoryNames)
    onCategoriesSelected,
    List<String>? currentCategoryIds,
    List<String>? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildMultiplePickerPage(
          context,
          onCategoriesSelected,
          currentCategoryIds ?? [],
          filterByType,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage _buildPickerPage(
    BuildContext context,
    Function(String categoryId, String categoryName) onCategorySelected,
    String? currentCategoryId,
    List<String>? filterByType,
  ) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      forceMaxHeight: true,
      resizeToAvoidBottomInset: false,

      topBarTitle: const Text('Выберите категорию'),
      isTopBarLayerAlwaysVisible: true,

      mainContentSliversBuilder: (context) => [
        // Фильтры (поле поиска всегда видно, типы только если не заданы извне)
        SliverToBoxAdapter(
          child: CategoryPickerFilters(hideTypeFilter: filterByType != null),
        ),

        // Список категорий
        _CategoryListView(
          currentCategoryId: currentCategoryId,
          onCategorySelected: onCategorySelected,
          filterByType: filterByType,
        ),
      ],
    );
  }

  /// Построить страницу с множественным выбором категорий
  static SliverWoltModalSheetPage _buildMultiplePickerPage(
    BuildContext context,
    Function(List<String> categoryIds, List<String> categoryNames)
    onCategoriesSelected,
    List<String> currentCategoryIds,
    List<String>? filterByType,
  ) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      forceMaxHeight: true,
      topBarTitle: const Text('Выберите категории'),
      isTopBarLayerAlwaysVisible: true,
      mainContentSliversBuilder: (context) => [
        // Фильтры (только поле поиска для множественного выбора)
        SliverToBoxAdapter(
          child: const CategoryPickerFilters(hideTypeFilter: true),
        ),
        // Контент с состоянием
        _MultipleCategoryPickerContent(
          onCategoriesSelected: onCategoriesSelected,
          initialCategoryIds: currentCategoryIds,
          filterByType: filterByType,
        ),
      ],
    );
  }
}

/// Список категорий с анимацией (одиночный выбор)
class _CategoryListView extends ConsumerStatefulWidget {
  const _CategoryListView({
    required this.currentCategoryId,
    required this.onCategorySelected,
    this.filterByType,
  });

  final String? currentCategoryId;
  final Function(String categoryId, String categoryName) onCategorySelected;
  final List<String>? filterByType;
  @override
  ConsumerState<_CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<_CategoryListView> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  List<dynamic> _items = [];
  bool _showLoadingIndicator = false;

  /// Кэшированный список типов для провайдера
  late final List<CategoryType?> _cachedTypes;

  @override
  void initState() {
    super.initState();
    // Преобразуем типы один раз при инициализации
    _cachedTypes =
        widget.filterByType != null && widget.filterByType!.isNotEmpty
        ? widget.filterByType!
              .map((type) => CategoryTypeX.fromString(type))
              .toList()
        : <CategoryType?>[];
  }

  void _updateItems(List<dynamic> newItems) {
    if (!mounted) return;

    final oldLength = _items.length;
    final newLength = newItems.length;

    // Если список пустой, просто заменяем
    if (oldLength == 0) {
      setState(() {
        _items = List.from(newItems);
        _showLoadingIndicator = false;
      });
      // Анимируем добавление всех элементов
      for (int i = 0; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + i * 20),
        );
      }
      return;
    }

    // Удаляем лишние элементы
    if (newLength < oldLength) {
      for (int i = oldLength - 1; i >= newLength; i--) {
        final item = _items[i];
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(item, animation, false),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Добавляем новые элементы
    if (newLength > oldLength) {
      for (int i = oldLength; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + (i - oldLength) * 20),
        );
      }
    }

    setState(() {
      _items = List.from(newItems);
      _showLoadingIndicator = false;
    });
  }

  Widget _buildAnimatedItem(
    dynamic category,
    Animation<double> animation,
    bool isSelected,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: CategoryPickerItem(
          category: category,
          isSelected: isSelected,
          onTap: () {
            widget.onCategorySelected(category.id, category.name);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Используем кэшированные типы
    final categoriesState = ref.watch(categoryPickerListProvider(_cachedTypes));

    return categoriesState.when(
      data: (state) {
        // Обновляем список при получении новых данных
        if (state.items.length != _items.length ||
            (state.items.isNotEmpty &&
                _items.isNotEmpty &&
                state.items.first.id != _items.first.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateItems(state.items);
          });
        }

        if (state.items.isEmpty && !state.isLoading) {
          logDebug(
            'No categories found to display',
            tag: '_CategoryListViewState',
          );
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Категории не найдены',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverAnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            if (index >= _items.length) {
              return const SizedBox.shrink();
            }

            final category = _items[index];
            final isSelected = category.id == widget.currentCategoryId;

            return _buildAnimatedItem(category, animation, isSelected);
          },
        );
      },
      loading: () {
        return SliverFillRemaining(
          child: Center(
            child: _showLoadingIndicator
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
          ),
        );
      },
      error: (error, stack) {
        setState(() => _showLoadingIndicator = false);
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки категорий',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Контент модального окна с состоянием выбранных категорий (множественный выбор)
class _MultipleCategoryPickerContent extends ConsumerStatefulWidget {
  const _MultipleCategoryPickerContent({
    required this.onCategoriesSelected,
    required this.initialCategoryIds,
    this.filterByType,
  });

  final Function(List<String> categoryIds, List<String> categoryNames)
  onCategoriesSelected;
  final List<String> initialCategoryIds;
  final List<String>? filterByType;

  @override
  ConsumerState<_MultipleCategoryPickerContent> createState() =>
      _MultipleCategoryPickerContentState();
}

class _MultipleCategoryPickerContentState
    extends ConsumerState<_MultipleCategoryPickerContent> {
  late List<String> _selectedCategoryIds;
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  List<dynamic> _items = [];

  /// Кэшированный список типов для провайдера
  late final List<CategoryType?> _cachedTypes;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List<String>.from(widget.initialCategoryIds);
    // Преобразуем типы один раз при инициализации
    _cachedTypes =
        widget.filterByType != null && widget.filterByType!.isNotEmpty
        ? widget.filterByType!
              .map((type) => CategoryTypeX.fromString(type))
              .toList()
        : <CategoryType?>[];
  }

  void _updateItems(List<dynamic> newItems) {
    if (!mounted) return;

    final oldLength = _items.length;
    final newLength = newItems.length;

    // Если список пустой, просто заменяем
    if (oldLength == 0) {
      setState(() {
        _items = List.from(newItems);
      });
      // Анимируем добавление всех элементов
      for (int i = 0; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + i * 20),
        );
      }
      return;
    }

    // Удаляем лишние элементы
    if (newLength < oldLength) {
      for (int i = oldLength - 1; i >= newLength; i--) {
        final item = _items[i];
        final isSelected = _selectedCategoryIds.contains(item.id);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedItem(item, animation, isSelected),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Добавляем новые элементы
    if (newLength > oldLength) {
      for (int i = oldLength; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + (i - oldLength) * 20),
        );
      }
    }

    setState(() {
      _items = List.from(newItems);
    });
  }

  Widget _buildAnimatedItem(
    dynamic category,
    Animation<double> animation,
    bool isSelected,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: CategoryPickerItem(
          category: category,
          isSelected: isSelected,
          onTap: () => _toggleCategory(category.id, category.name, _items),
        ),
      ),
    );
  }

  void _toggleCategory(
    String categoryId,
    String categoryName,
    List<dynamic> allCategories,
  ) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        // Убираем категорию из выбранных
        _selectedCategoryIds.remove(categoryId);
      } else {
        // Добавляем категорию
        _selectedCategoryIds.add(categoryId);
      }
    });

    // Собираем имена для выбранных категорий
    final selectedCategoryNames = <String>[];
    for (final categoryId in _selectedCategoryIds) {
      try {
        final selectedCategory = allCategories.firstWhere(
          (c) => c.id == categoryId,
        );
        selectedCategoryNames.add(selectedCategory.name as String);
      } catch (e) {
        // Категория не найдена в списке, пропускаем
        continue;
      }
    }

    widget.onCategoriesSelected(_selectedCategoryIds, selectedCategoryNames);
  }

  @override
  Widget build(BuildContext context) {
    // Используем кэшированные типы
    final categoriesState = ref.watch(categoryPickerListProvider(_cachedTypes));

    return categoriesState.when(
      data: (state) {
        // Обновляем список при получении новых данных
        if (state.items.length != _items.length ||
            (state.items.isNotEmpty &&
                _items.isNotEmpty &&
                state.items.first.id != _items.first.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateItems(state.items);
          });
        }

        if (state.items.isEmpty && !state.isLoading) {
          return SliverMainAxisGroup(
            slivers: [
              if (widget.filterByType == null)
                SliverToBoxAdapter(
                  child: CategoryPickerFilters(
                    selectedCount: _selectedCategoryIds.length,
                  ),
                ),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Категории не найдены',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            if (widget.filterByType == null)
              SliverToBoxAdapter(
                child: CategoryPickerFilters(
                  selectedCount: _selectedCategoryIds.length,
                ),
              ),
            SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                if (index >= _items.length) {
                  return const SizedBox.shrink();
                }

                final category = _items[index];
                final isSelected = _selectedCategoryIds.contains(category.id);

                return _buildAnimatedItem(category, animation, isSelected);
              },
            ),
            if (state.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(
                                    categoryPickerListProvider(
                                      _cachedTypes,
                                    ).notifier,
                                  )
                                  .loadMore();
                            },
                            child: const Text('Загрузить еще'),
                          ),
                        ),
                ),
              ),
          ],
        );
      },
      loading: () => SliverMainAxisGroup(
        slivers: [
          if (widget.filterByType == null)
            SliverToBoxAdapter(
              child: CategoryPickerFilters(
                selectedCount: _selectedCategoryIds.length,
              ),
            ),
          SliverFillRemaining(
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, stack) => SliverMainAxisGroup(
        slivers: [
          if (widget.filterByType == null)
            SliverToBoxAdapter(
              child: CategoryPickerFilters(
                selectedCount: _selectedCategoryIds.length,
              ),
            ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки категорий',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
