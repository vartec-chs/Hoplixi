import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/models/drawer_category_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/providers/drawer_category_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/old/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/category_tree_node.dart';
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

    final selectedIds = categoryStateAsync.whenOrNull(
      data: (state) => state.selectedIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          theme,
          notifier,
          selectedIds: selectedIds ?? const [],
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: categoryStateAsync.when(
              data: (state) => KeyedSubtree(
                key: const ValueKey('data'),
                child: _buildBody(state, theme, notifier),
              ),
              loading: () => const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => const Center(
                key: ValueKey('error'),
                child: Text('Ошибка загрузки категорий'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DrawerCategoryFilterNotifier notifier, {
    required List<String> selectedIds,
  }) {
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
                  if (selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: notifier.clearSelection,
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    iconSize: 20,
                    icon: const Icon(Icons.refresh, size: 20),
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
      ],
    );
  }

  Widget _buildBody(
    DrawerCategoryFilterState state,
    ThemeData theme,
    DrawerCategoryFilterNotifier notifier,
  ) {
    final searchTree = state.isSearching
        ? _buildTree(state.searchResults)
        : null;
    final hasVisibleContent = state.isSearching
        ? state.searchResults.isNotEmpty
        : state.roots.isNotEmpty;

    if (!hasVisibleContent && !state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Категории не найдены',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          if (state.isSearching) ...[
            for (final root in searchTree!)
              _CategoryTreeTile(
                entry: root,
                selectedIds: state.selectedIds,
                onToggle: notifier.toggle,
                depth: 0,
              ),
          ] else ...[
            for (var index = 0; index < state.roots.length; index++)
              _LazyCategoryTreeTile(
                node: state.roots[index],
                selectedIds: state.selectedIds,
                onToggle: notifier.toggle,
                onExpandChanged: notifier.toggleExpand,
                depth: 0,
              ),
          ],
          if (state.isLoadingMore || (state.isLoading && hasVisibleContent))
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      checkColor: checkColor,
      controlAffinity: ListTileControlAffinity.leading,
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

class _LazyCategoryTreeTile extends StatelessWidget {
  const _LazyCategoryTreeTile({
    required this.node,
    required this.selectedIds,
    required this.onToggle,
    required this.onExpandChanged,
    required this.depth,
  });

  final CategoryTreeNode node;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final void Function(String categoryId, bool expanded) onExpandChanged;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = node.category;
    final isSelected = selectedIds.contains(category.id);
    final color = ColorsHelper.parseColor(
      category.color,
      theme.colorScheme.primary,
    );
    final checkColor = ColorsHelper.onColorFor(color);
    final indent = depth * 16.0;

    if (node.hasChildren) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onExpandChanged(category.id, !node.isExpanded),
              onLongPress: () => onToggle(category.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Checkbox(
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${category.itemsCount} эл.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: node.isLoadingChildren
                          ? const SizedBox(
                              key: ValueKey('loader'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : AnimatedRotation(
                              key: ValueKey('arrow-${node.isExpanded}'),
                              turns: node.isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isSelected
                                    ? color
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0, -0.04),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: !node.isExpanded
                      ? const SizedBox.shrink(key: ValueKey('collapsed'))
                      : node.isLoadingChildren
                      ? const Padding(
                          key: ValueKey('loading'),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Column(
                          key: ValueKey(
                            'children-${category.id}-${node.children.length}',
                          ),
                          children: [
                            for (
                              var index = 0;
                              index < node.children.length;
                              index++
                            )
                              TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  '${category.id}-child-${node.children[index].category.id}',
                                ),
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 160 + (index * 35),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 8),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _LazyCategoryTreeTile(
                                  node: node.children[index],
                                  selectedIds: selectedIds,
                                  onToggle: onToggle,
                                  onExpandChanged: onExpandChanged,
                                  depth: depth + 1,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CheckboxListTile(
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      checkColor: checkColor,
      controlAffinity: ListTileControlAffinity.leading,
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
