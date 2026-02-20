import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/utils/color_parser.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/drawer_filter_provider.dart';
import 'package:hoplixi/features/settings/providers/settings_provider.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/close_database_button.dart';

/// Drawer с фильтрацией по категориям и тегам (для мобильных устройств)
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key, required this.entityType});

  final EntityType entityType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(child: DashboardDrawerContent(entityType: entityType)),
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
  BackupScope _parseBackupScope(String? raw) {
    switch (raw) {
      case 'databaseOnly':
        return BackupScope.databaseOnly;
      case 'encryptedFilesOnly':
        return BackupScope.encryptedFilesOnly;
      case 'full':
      default:
        return BackupScope.full;
    }
  }

  Future<void> _createBackupNow() async {
    final settings = ref.read(settingsProvider);
    final backupPath = settings[AppKeys.backupPath.key] as String?;
    final scopeRaw = settings[AppKeys.backupScope.key] as String?;
    final backupMaxPerStore =
        settings[AppKeys.backupMaxPerStore.key] as int? ?? 10;
    final scope = _parseBackupScope(scopeRaw);

    final result = await ref
        .read(mainStoreProvider.notifier)
        .createBackup(
          scope: scope,
          outputDirPath: backupPath,
          periodic: false,
          maxBackupsPerStore: backupMaxPerStore,
        );

    if (!mounted) return;

    if (result == null) {
      Toaster.error(
        title: 'Бэкап не создан',
        description: 'Проверьте, что хранилище открыто',
      );
      return;
    }

    Toaster.success(title: 'Бэкап создан', description: result.backupPath);
  }

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
    final drawerNotifier = ref.read(
      drawerFilterProvider(widget.entityType).notifier,
    );
    final isStoreOpen = ref
        .watch(mainStoreProvider)
        .maybeWhen(data: (state) => state.isOpen, orElse: () => false);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: drawerStateAsync.when(
          data: (drawerState) => Column(
            key: ValueKey(widget.entityType),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Фильтры',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (drawerState.selectedCategoryIds.isNotEmpty ||
                          drawerState.selectedTagIds.isNotEmpty)
                        SmoothButton(
                          onPressed: drawerNotifier.clearAll,
                          label: 'Очистить все',
                          size: .small,
                          type: .text,
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Контент с прокруткой
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
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

                    const SizedBox(height: 8.0),
                    const Divider(height: 1),
                    const SizedBox(height: 8.0),

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
              if (isMobile) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: CloseDatabaseButton(
                          type: CloseDatabaseButtonType.smooth,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SmoothButton(
                          label: 'Бэкап',
                          size: SmoothButtonSize.small,
                          icon: const Icon(Icons.backup),
                          onPressed: isStoreOpen ? _createBackupNow : null,
                          type: SmoothButtonType.filled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          loading: () => Column(
            key: const ValueKey('loading'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок (для предотвращения скачка)
              SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Фильтры', style: theme.textTheme.titleMedium),
                ),
              ),
              const Divider(height: 1),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (error, stack) => Center(
            key: const ValueKey('error'),
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

  /// Строим дерево из плоского списка категорий
  List<_CategoryTreeEntry> _buildTree(List<CategoryCardDto> cats) {
    final map = <String, _CategoryTreeEntry>{};
    final roots = <_CategoryTreeEntry>[];

    for (final c in cats) {
      map[c.id] = _CategoryTreeEntry(category: c);
    }
    for (final c in cats) {
      final entry = map[c.id]!;
      if (c.parentId != null && map.containsKey(c.parentId)) {
        map[c.parentId]!.children.add(entry);
      } else {
        roots.add(entry);
      }
    }
    return roots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(drawerFilterProvider(widget.entityType).notifier);
    final tree = _buildTree(widget.categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Категории', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  if (widget.selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: () => notifier.clearCategories(),
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => notifier.reloadCategories(),
                    tooltip: 'Обновить категории',
                  ),
                ],
              ),
            ],
          ),
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

        // Дерево категорий
        Container(
          constraints: const BoxConstraints(maxHeight: 350),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                for (final root in tree)
                  _CategoryTreeTile(
                    entry: root,
                    selectedIds: widget.selectedIds,
                    onToggle: (id) => notifier.toggleCategory(id),
                    depth: 0,
                  ),
                if (widget.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (widget.categories.isEmpty && !widget.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Категории не найдены',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Модель узла дерева для драйвера
class _CategoryTreeEntry {
  _CategoryTreeEntry({required this.category});

  final CategoryCardDto category;
  final List<_CategoryTreeEntry> children = [];

  bool get hasChildren => children.isNotEmpty;
}

/// Виджет одного узла дерева в drawer
class _CategoryTreeTile extends StatelessWidget {
  const _CategoryTreeTile({
    required this.entry,
    required this.selectedIds,
    required this.onToggle,
    required this.depth,
  });

  final _CategoryTreeEntry entry;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = entry.category;
    final isSelected = selectedIds.contains(category.id);
    final color = _parseColor(category.color, theme.colorScheme.primary);
    final indent = depth * 16.0;

    if (entry.hasChildren) {
      // Выбор всего поддерева — показываем ExpansionTile с checkbox
      return Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.only(left: indent, right: 8),
          leading: Checkbox(
            value: isSelected,
            onChanged: (_) => onToggle(category.id),
            fillColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? color : null,
            ),
          ),
          title: Text(
            category.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${category.itemsCount} эл.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: entry.children
              .map(
                (child) => _CategoryTreeTile(
                  entry: child,
                  selectedIds: selectedIds,
                  onToggle: onToggle,
                  depth: depth + 1,
                ),
              )
              .toList(),
        ),
      );
    }

    // Листовой узел
    return CheckboxListTile(
      contentPadding: EdgeInsets.only(left: indent, right: 8),
      value: isSelected,
      onChanged: (_) => onToggle(category.id),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? color : null,
      ),
      title: Text(
        category.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: category.itemsCount > 0
          ? Text('${category.itemsCount} элементов')
          : null,
      dense: true,
    );
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : fallback;
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
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Теги', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  if (widget.selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: () => notifier.clearTags(),
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => notifier.reloadTags(),
                    tooltip: 'Обновить теги',
                  ),
                ],
              ),
            ],
          ),
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
                    ? Icon(
                        Icons.tag,
                        size: 18,
                        color: parseColor(tag.color, context),
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
