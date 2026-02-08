import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../providers/category_filter_provider.dart';
import '../providers/category_pagination_provider.dart';
import '../widgets/category_card.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализация или загрузка данных, если необходимо
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentSortField = ref.watch(
      categoryFilterProvider.select((filter) => filter.sortField),
    );
    final categoryState = ref.watch(categoryListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            title: const Text('Категории'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final searchQuery = ref.read(categoryFilterProvider).query;
                  showSearchDialog(
                    context,
                    initialValue: searchQuery,
                    onSearch: (value) {
                      ref
                          .read(categoryFilterProvider.notifier)
                          .updateQuery(value);
                    },
                  );
                },
                tooltip: 'Поиск',
              ),
              PopupMenuButton<CategoriesSortField>(
                icon: const Icon(Icons.sort),
                tooltip: 'Сортировка',
                onSelected: (sortField) async {
                  if (sortField != currentSortField) {
                    await ref
                        .read(categoryFilterProvider.notifier)
                        .updateSortField(sortField);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: CategoriesSortField.name,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.name)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.name)
                          const SizedBox(width: 8),
                        const Text('По названию'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.type,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.type)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.type)
                          const SizedBox(width: 8),
                        const Text('По типу'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.createdAt,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.createdAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.createdAt)
                          const SizedBox(width: 8),
                        const Text('По дате создания'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.modifiedAt,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.modifiedAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.modifiedAt)
                          const SizedBox(width: 8),
                        const Text('По дате изменения'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // SliverToBoxAdapter(child: CategoryPickerField(isFilter: true)),
          categoryState.when(
            data: (state) {
              if (state.items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Категории не найдены')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    // Адаптивное количество колонок в зависимости от ширины
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width < 400
                        ? 1
                        : width < 600
                        ? 2
                        : width < 900
                        ? 3
                        : 4;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == state.items.length && state.hasMore) {
                            // Загружаем следующую страницу при достижении конца
                            Future.microtask(
                              () => ref
                                  .read(categoryListProvider.notifier)
                                  .loadMore(),
                            );
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (index >= state.items.length) {
                            return null;
                          }
                          final category = state.items[index];
                          return CategoryCard(
                            category: category,
                            onTap: () {
                              context
                                  .push<bool>(
                                    AppRoutesPaths.categoryEditWithId(
                                      widget.entity,
                                      category.id,
                                    ),
                                  )
                                  .then((updated) {
                                    if (updated == true) {
                                      ref
                                          .read(categoryListProvider.notifier)
                                          .refresh();
                                    }
                                  });
                            },
                            onEdit: () async {
                              final result = await context.push<bool>(
                                AppRoutesPaths.categoryEditWithId(
                                  widget.entity,
                                  category.id,
                                ),
                              );
                              if (result == true) {
                                ref
                                    .read(categoryListProvider.notifier)
                                    .refresh();
                              }
                            },
                            onDelete: () => _handleDeleteCategory(
                              context,
                              category,
                              () => ref
                                  .read(categoryListProvider.notifier)
                                  .refresh(),
                            ),
                          );
                        },
                        childCount: state.hasMore
                            ? state.items.length + 1
                            : state.items.length,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ошибка загрузки категорий'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(categoryListProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isMobileLayout(context)
          ? FloatingActionButton(
              heroTag: 'categoryManagerFab',
              onPressed: () {
                final result = context.push<bool>(
                  AppRoutesPaths.categoryAdd(widget.entity),
                );

                result.then((created) {
                  if (created == true) {
                    ref.read(categoryListProvider.notifier).refresh();
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  static void showSearchDialog(
    BuildContext context, {
    required String initialValue,
    required Function(String) onSearch,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск категорий'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Введите название...',
          ),
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context),
            label: 'Отмена',
            variant: .error,
            type: .text,
          ),
          SmoothButton(
            onPressed: () {
              onSearch(controller.text);
              Navigator.pop(context);
            },
            label: 'Поиск',
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteCategory(
    BuildContext context,
    CategoryCardDto category,
    VoidCallback onRefresh,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          'Вы уверены, что хотите удалить категорию "${category.name}"?',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Отмена',
            variant: .normal,
            type: .text,
          ),
          SmoothButton(
            onPressed: () => Navigator.pop(context, true),
            variant: .error,
            label: 'Удалить',
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final categoryDao = await ref.read(categoryDaoProvider.future);
        await categoryDao.deleteCategory(category.id);

        // Уведомляем об удалении категории
        ref
            .read(managerRefreshTriggerProvider.notifier)
            .triggerCategoryRefresh();

        if (context.mounted) {
          Toaster.success(
            title: 'Категория удалена',
            description: 'Категория "${category.name}" успешно удалена.',
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          Toaster.error(
            title: 'Ошибка удаления',
            description:
                'Не удалось удалить категорию "${category.name}". Попробуйте еще раз.',
          );
        }
      }
    }
  }
}
