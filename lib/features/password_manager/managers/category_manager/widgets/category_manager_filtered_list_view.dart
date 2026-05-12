import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_pagination_provider.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_db/core/old/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

import 'category_card.dart';
import 'category_tree_placeholder.dart';

class CategoryManagerFilteredListView extends ConsumerWidget {
  const CategoryManagerFilteredListView({
    super.key,
    required this.entity,
    required this.onRefresh,
  });

  final EntityType entity;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return categoriesAsync.when(
      data: (state) {
        if (state.items.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: CategoryTreePlaceholder(
              icon: Icons.search_off_rounded,
              title: 'Ничего не найдено',
              description:
                  'Попробуйте изменить поисковый запрос или ослабить фильтры.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              for (final category in state.items) ...[
                CategoryCard(
                  category: category,
                  onTap: () => _openEdit(context, category.id),
                  onEdit: () => _openEdit(context, category.id),
                  onDelete: () => _handleDelete(context, ref, category),
                ),
                const SizedBox(height: 12),
              ],
              if (state.isLoading && state.items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
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
      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: CategoryTreePlaceholder(
          icon: Icons.error_outline,
          title: 'Ошибка загрузки категорий',
          description: 'Не удалось загрузить результаты поиска.',
          action: ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Повторить'),
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, String categoryId) {
    context
        .push<bool>(AppRoutesPaths.categoryEditWithId(entity, categoryId))
        .then((updated) {
          if (updated == true) {
            onRefresh();
          }
        });
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryCardDto category,
  ) async {
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final dao = await ref.read(categoryDaoProvider.future);
      await dao.deleteCategory(category.id);

      ref.read(managerRefreshTriggerProvider.notifier).triggerCategoryRefresh();

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
