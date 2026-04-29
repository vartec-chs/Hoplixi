import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_db/core/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/category_tree_node.dart';
import 'package:hoplixi/main_db/providers/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

import '../providers/category_tree_provider.dart';

class CategoryTreeSection extends ConsumerWidget {
  const CategoryTreeSection({
    super.key,
    required this.node,
    required this.entity,
    required this.depth,
    required this.isLast,
    required this.onRefresh,
  });

  final CategoryTreeNode node;
  final EntityType entity;
  final int depth;
  final bool isLast;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = _resolveIconColor(theme, node.category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryNodeFrame(
          depth: depth,
          isLast: isLast,
          child: _CategoryTreeRow(
            category: node.category,
            depth: depth,
            iconColor: iconColor,
            hasChildren: node.hasChildren,
            isExpanded: node.isExpanded,
            isLoadingChildren: node.isLoadingChildren,
            trailingText: _buildMetaText(node),
            onTap: () {
              if (node.hasChildren) {
                ref
                    .read(categoryTreeProvider.notifier)
                    .toggleNode(node.category.id);
                return;
              }

              context
                  .push<bool>(
                    AppRoutesPaths.categoryEditWithId(entity, node.category.id),
                  )
                  .then((updated) {
                    if (updated == true) {
                      onRefresh();
                    }
                  });
            },
            actions: _CategoryActions(
              category: node.category,
              entity: entity,
              onRefresh: onRefresh,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: node.isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < node.children.length; index++)
                        CategoryTreeSection(
                          node: node.children[index],
                          entity: entity,
                          depth: depth + 1,
                          isLast: index == node.children.length - 1,
                          onRefresh: onRefresh,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Color _resolveIconColor(ThemeData theme, String? hex) {
    final fallback = theme.colorScheme.onSurfaceVariant;
    if (hex == null || hex.isEmpty) {
      return fallback;
    }

    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : fallback;
  }

  String? _buildMetaText(CategoryTreeNode node) {
    final itemsCount = node.category.itemsCount;
    if (node.isLoadingChildren) {
      return 'загрузка...';
    }
    if (itemsCount > 0) {
      return '$itemsCount';
    }
    return null;
  }
}

class _CategoryNodeFrame extends StatelessWidget {
  const _CategoryNodeFrame({
    required this.depth,
    required this.isLast,
    required this.child,
  });

  final int depth;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.outlineVariant.withOpacity(0.9);

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (depth > 0) ...[
            Positioned(
              left: 10,
              top: -10,
              bottom: isLast ? 20 : 0,
              child: Container(width: 1, color: lineColor),
            ),
            Positioned(
              left: 10,
              top: 19,
              child: Container(width: 22, height: 1, color: lineColor),
            ),
          ],
          Padding(
            padding: EdgeInsets.only(left: depth > 0 ? 22 : 0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CategoryTreeRow extends StatelessWidget {
  const _CategoryTreeRow({
    required this.category,
    required this.depth,
    required this.iconColor,
    required this.hasChildren,
    required this.isExpanded,
    required this.isLoadingChildren,
    required this.onTap,
    required this.actions,
    this.trailingText,
  });

  final CategoryCardDto category;
  final int depth;
  final Color iconColor;
  final bool hasChildren;
  final bool isExpanded;
  final bool isLoadingChildren;
  final VoidCallback onTap;
  final Widget actions;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = hasChildren && isExpanded
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.45)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (hasChildren)
                  SizedBox(
                    width: 18,
                    child: isLoadingChildren
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  )
                else
                  const SizedBox(width: 18),
                Icon(
                  hasChildren
                      ? (isExpanded
                            ? Icons.folder_open_outlined
                            : Icons.folder_outlined)
                      : Icons.description_outlined,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: depth == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_horiz,
        color: colorScheme.onSurfaceVariant.withOpacity(0.76),
        size: 18,
      ),
      splashRadius: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 36),
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
                if (updated == true) {
                  onRefresh();
                }
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
      } catch (_) {
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
