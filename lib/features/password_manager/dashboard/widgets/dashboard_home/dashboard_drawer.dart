import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/drawer_filter_provider.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Drawer с фильтрацией по категориям и тегам (для мобильных устройств)
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key, required this.entityType});

  final EntityType entityType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: DashboardDrawerContent(entityType: entityType),
    );
  }
}

/// Контент панели фильтрации (может использоваться как в Drawer, так и как постоянная панель)
class DashboardDrawerContent extends ConsumerStatefulWidget {
  const DashboardDrawerContent({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<DashboardDrawerContent> createState() =>
      _DashboardDrawerContentState();
}

class _DashboardDrawerContentState
    extends ConsumerState<DashboardDrawerContent> {
  @override
  void didUpdateWidget(DashboardDrawerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если entityType изменился, сбрасываем выбранные фильтры
    if (oldWidget.entityType != widget.entityType) {
      ref.read(drawerFilterProvider(oldWidget.entityType).notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerStateAsync = ref.watch(drawerFilterProvider(widget.entityType));

    return SafeArea(
      child: drawerStateAsync.when(
        data: (drawerState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Фильтры', style: theme.textTheme.titleLarge),
                  if (drawerState.selectedCategoryIds.isNotEmpty ||
                      drawerState.selectedTagIds.isNotEmpty)
                    SmoothButton(
                      onPressed: () {
                        ref
                            .read(
                              drawerFilterProvider(widget.entityType).notifier,
                            )
                            .clearAll();
                      },
                      label: 'Очистить все',
                      size: .small,
                      type: .text,
                      variant: .error,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Контент с прокруткой
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Блок категорий
                  _CategorySection(
                    entityType: widget.entityType,
                    categories: drawerState.categories,
                    selectedIds: drawerState.selectedCategoryIds,
                    searchQuery: drawerState.categorySearchQuery,
                    isLoading: drawerState.isCategoriesLoading,
                    hasMore: drawerState.hasMoreCategories,
                  ),

                  const SizedBox(height: 12.0),
                  const Divider(height: 1),
                  const SizedBox(height: 12.0),

                  // Блок тегов
                  _TagSection(
                    entityType: widget.entityType,
                    tags: drawerState.tags,
                    selectedIds: drawerState.selectedTagIds,
                    searchQuery: drawerState.tagSearchQuery,
                    isLoading: drawerState.isTagsLoading,
                    hasMore: drawerState.hasMoreTags,
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки фильтров',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Секция категорий
class _CategorySection extends ConsumerStatefulWidget {
  const _CategorySection({
    required this.entityType,
    required this.categories,
    required this.selectedIds,
    required this.searchQuery,
    required this.isLoading,
    required this.hasMore,
  });

  final EntityType entityType;
  final List<CategoryCardDto> categories;
  final List<String> selectedIds;
  final String searchQuery;
  final bool isLoading;
  final bool hasMore;

  @override
  ConsumerState<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<_CategorySection> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(drawerFilterProvider(widget.entityType).notifier)
          .loadMoreCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(drawerFilterProvider(widget.entityType).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Категории', style: theme.textTheme.titleMedium),
            if (widget.selectedIds.isNotEmpty)
              SmoothButton(
                onPressed: () => notifier.clearCategories(),
                label: 'Очистить (${widget.selectedIds.length})',
                size: .small,
                type: .text,
              ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Поиск
        SizedBox(
          height: 40.0,
          child: TextField(
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск категорий...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => notifier.searchCategories(value),
          ),
        ),
        const SizedBox(height: 8.0),

        // Список категорий
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: widget.categories.length + (widget.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.categories.length) {
                return widget.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final category = widget.categories[index];
              final isSelected = widget.selectedIds.contains(category.id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => notifier.toggleCategory(category.id),
                title: Text(category.name),
                subtitle: category.itemsCount > 0
                    ? Text('${category.itemsCount} элементов')
                    : null,
                secondary: category.color != null
                    ? Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _parseCategoryColor(category.color, context),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                dense: true,

                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Секция тегов
class _TagSection extends ConsumerStatefulWidget {
  const _TagSection({
    required this.entityType,
    required this.tags,
    required this.selectedIds,
    required this.searchQuery,
    required this.isLoading,
    required this.hasMore,
  });

  final EntityType entityType;
  final List<TagCardDto> tags;
  final List<String> selectedIds;
  final String searchQuery;
  final bool isLoading;
  final bool hasMore;

  @override
  ConsumerState<_TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends ConsumerState<_TagSection> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(drawerFilterProvider(widget.entityType).notifier).loadMoreTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(drawerFilterProvider(widget.entityType).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Теги', style: theme.textTheme.titleMedium),
            if (widget.selectedIds.isNotEmpty)
              SmoothButton(
                onPressed: () => notifier.clearTags(),
                label: 'Очистить (${widget.selectedIds.length})',
                size: .small,
                type: .text,
              ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Поиск
        SizedBox(
          height: 40.0,
          child: TextField(
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск тегов...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => notifier.searchTags(value),
          ),
        ),
        const SizedBox(height: 8.0),

        // Список тегов
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: widget.tags.length + (widget.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.tags.length) {
                return widget.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final tag = widget.tags[index];
              final isSelected = widget.selectedIds.contains(tag.id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => notifier.toggleTag(tag.id),
                title: Text(tag.name),
                subtitle: tag.itemsCount > 0
                    ? Text('${tag.itemsCount} элементов')
                    : null,
                secondary: tag.color != null
                    ? Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _parseCategoryColor(tag.color, context),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Парсит цвет категории из строки в Color
Color _parseCategoryColor(String? colorString, BuildContext context) {
  final colorValue = int.tryParse(colorString ?? 'FFFFFF', radix: 16);
  final color = colorValue != null
      ? Color(0xFF000000 | colorValue)
      : Theme.of(context).colorScheme.primary;
  return color;
}
