import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_tree_provider.dart';

import 'category_tree_placeholder.dart';
import 'category_tree_section.dart';

class CategoryTreeView extends ConsumerWidget {
  const CategoryTreeView({
    super.key,
    required this.entity,
    required this.onRefresh,
  });

  final EntityType entity;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);

    return treeAsync.when(
      data: (treeState) {
        if (treeState.roots.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: CategoryTreePlaceholder(
              icon: Icons.folder_off_outlined,
              title: 'Категории не найдены',
              description:
                  'Создайте первую категорию, чтобы собрать структуру дерева.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              for (var index = 0; index < treeState.roots.length; index++)
                CategoryTreeSection(
                  node: treeState.roots[index],
                  entity: entity,
                  depth: 0,
                  isLast: index == treeState.roots.length - 1,
                  onRefresh: onRefresh,
                ),
              if (treeState.isLoadingMoreRoots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ]),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: CategoryTreePlaceholder(
          icon: Icons.error_outline,
          title: 'Ошибка загрузки категорий',
          description: 'Не удалось построить дерево категорий.',
          action: ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Повторить'),
          ),
        ),
      ),
    );
  }
}
