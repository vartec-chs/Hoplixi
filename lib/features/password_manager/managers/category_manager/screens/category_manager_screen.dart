import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_tree_node.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

import '../providers/category_tree_provider.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key, required this.entity});

  final EntityType entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            title: const Text('Категории'),
          ),
          treeAsync.when(
            data: (tree) {
              if (tree.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Категории не найдены')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CategoryTreeSection(
                      node: tree[index],
                      entity: entity,
                      depth: 0,
                      onRefresh: () =>
                          ref.read(categoryTreeProvider.notifier).refresh(),
                    ),
                    childCount: tree.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ошибка загрузки категорий'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(categoryTreeProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categoryManagerFab',
        onPressed: () {
          context.push<bool>(AppRoutesPaths.categoryAdd(entity)).then((
            created,
          ) {
            if (created == true) {
              ref.read(categoryTreeProvider.notifier).refresh();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Секция узла дерева (корневого уровня)
// ---------------------------------------------------------------------------

class _CategoryTreeSection extends ConsumerWidget {
  const _CategoryTreeSection({
    required this.node,
    required this.entity,
    required this.depth,
    required this.onRefresh,
  });

  final CategoryTreeNode node;
  final EntityType entity;
  final int depth;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final category = node.category;
    final color = _parseColor(category.color, colorScheme.primary);

    if (node.hasChildren) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 16.0, bottom: 4),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: _CategoryColorDot(color: color),
              title: Text(
                category.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${category.itemsCount} эл. • ${node.children.length} подкатегорий',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: _CategoryActions(
                category: category,
                entity: entity,
                onRefresh: onRefresh,
              ),
              children: [
                ...node.children.map(
                  (child) => _CategoryTreeSection(
                    node: child,
                    entity: entity,
                    depth: depth + 1,
                    onRefresh: onRefresh,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Листовая категория
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, bottom: 4),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: _CategoryColorDot(color: color),
          title: Text(
            category.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${category.itemsCount} элементов',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => context
              .push<bool>(
                AppRoutesPaths.categoryEditWithId(entity, category.id),
              )
              .then((updated) {
                if (updated == true) onRefresh();
              }),
          trailing: _CategoryActions(
            category: category,
            entity: entity,
            onRefresh: onRefresh,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : fallback;
  }
}

// ---------------------------------------------------------------------------
// Цветной кружок категории
// ---------------------------------------------------------------------------

class _CategoryColorDot extends StatelessWidget {
  const _CategoryColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      shape: BoxShape.circle,
      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
    ),
    child: Center(child: Icon(Icons.folder_outlined, color: color, size: 18)),
  );
}

// ---------------------------------------------------------------------------
// Меню действий над категорией
// ---------------------------------------------------------------------------

class _CategoryActions extends ConsumerWidget {
  const _CategoryActions({
    required this.category,
    required this.entity,
    required this.onRefresh,
  });

  final CategoryCardDto category;
  final EntityType entity;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Редактировать'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              const SizedBox(width: 12),
              Text('Удалить', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          context
              .push<bool>(
                AppRoutesPaths.categoryEditWithId(entity, category.id),
              )
              .then((updated) {
                if (updated == true) onRefresh();
              });
        } else if (value == 'delete') {
          _handleDelete(context, ref);
        }
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Вы уверены, что хотите удалить «${category.name}»?'),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.pop(context, true),
            variant: SmoothButtonVariant.error,
            label: 'Удалить',
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final dao = await ref.read(categoryDaoProvider.future);
        await dao.deleteCategory(category.id);

        ref
            .read(managerRefreshTriggerProvider.notifier)
            .triggerCategoryRefresh();

        if (context.mounted) {
          Toaster.success(
            title: 'Категория удалена',
            description: '«${category.name}» успешно удалена.',
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          Toaster.error(
            title: 'Ошибка удаления',
            description: 'Не удалось удалить «${category.name}».',
          );
        }
      }
    }
  }
}
