import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_category_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/providers/drawer_category_filter_provider.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../colors.dart';

class CategorySection extends ConsumerStatefulWidget {
  const CategorySection({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
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
          .read(drawerCategoryFilterProvider(widget.entityType).notifier)
          .loadMore();
    }
  }

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
    final categoryStateAsync = ref.watch(
      drawerCategoryFilterProvider(widget.entityType),
    );
    final notifier = ref.read(
      drawerCategoryFilterProvider(widget.entityType).notifier,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: categoryStateAsync.when(
        data: (state) => Container(
          key: ValueKey('data-${state.categories.length}'),
          child: _buildData(state, theme, notifier),
        ),
        loading: () => const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          key: const ValueKey('error'),
          child: Text(
            'Ошибка загрузки категорий',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildData(
    DrawerCategoryFilterState state,
    ThemeData theme,
    DrawerCategoryFilterNotifier notifier,
  ) {
    final tree = _buildTree(state.categories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Категории', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  if (state.selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: notifier.clearSelection,
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: notifier.reload,
                    tooltip: 'Обновить категории',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),

        SizedBox(
          height: 40.0,
          child: TextField(
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск категорий...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: notifier.search,
          ),
        ),
        const SizedBox(height: 8.0),

        Expanded(
          child: state.categories.isEmpty && !state.isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Категории не найдены',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      for (final root in tree)
                        _CategoryTreeTile(
                          entry: root,
                          selectedIds: state.selectedIds,
                          onToggle: notifier.toggle,
                          depth: 0,
                        ),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Модель узла дерева
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTreeEntry {
  _CategoryTreeEntry({required this.category});

  final CategoryCardDto category;
  final List<_CategoryTreeEntry> children = [];

  bool get hasChildren => children.isNotEmpty;
}

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
    final color = ColorsHelper.parseColor(
      category.color,
      theme.colorScheme.primary,
    );
    final checkColor = ColorsHelper.onColorFor(color);
    final indent = depth * 16.0;

    if (entry.hasChildren) {
      return Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.only(left: indent, right: 8),
          childrenPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          minTileHeight: 0,
          leading: Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            value: isSelected,
            onChanged: (_) => onToggle(category.id),
            checkColor: checkColor,
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

    return CheckboxListTile(
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      checkColor: checkColor,
      controlAffinity: .leading,
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
}
