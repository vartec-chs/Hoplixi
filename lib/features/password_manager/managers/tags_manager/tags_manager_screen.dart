import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import 'providers/tag_filter_provider.dart';
import 'providers/tag_pagination_provider.dart';
import 'widgets/tag_card.dart';

class TagsManagerScreen extends ConsumerStatefulWidget {
  final EntityType entity;

  const TagsManagerScreen({super.key, required this.entity});

  @override
  ConsumerState<TagsManagerScreen> createState() => _TagsManagerScreenState();
}

class _TagsManagerScreenState extends ConsumerState<TagsManagerScreen> {
  @override
  void initState() {
    super.initState();
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentSortField = ref.watch(
      tagFilterProvider.select((filter) => filter.sortField),
    );
    final tagState = ref.watch(tagListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            title: const Text('Теги'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final searchQuery = ref.read(tagFilterProvider).query;
                  _showSearchDialog(
                    context,
                    initialValue: searchQuery,
                    onSearch: (value) {
                      ref.read(tagFilterProvider.notifier).updateQuery(value);
                    },
                  );
                },
                tooltip: 'Поиск',
              ),
              PopupMenuButton<TagsSortField>(
                icon: const Icon(Icons.sort),
                tooltip: 'Сортировка',
                onSelected: (sortField) async {
                  if (sortField != currentSortField) {
                    await ref
                        .read(tagFilterProvider.notifier)
                        .updateSortField(sortField);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TagsSortField.name,
                    child: Row(
                      children: [
                        if (currentSortField == TagsSortField.name)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == TagsSortField.name)
                          const SizedBox(width: 8),
                        const Text('По названию'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TagsSortField.type,
                    child: Row(
                      children: [
                        if (currentSortField == TagsSortField.type)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == TagsSortField.type)
                          const SizedBox(width: 8),
                        const Text('По типу'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TagsSortField.createdAt,
                    child: Row(
                      children: [
                        if (currentSortField == TagsSortField.createdAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == TagsSortField.createdAt)
                          const SizedBox(width: 8),
                        const Text('По дате создания'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TagsSortField.modifiedAt,
                    child: Row(
                      children: [
                        if (currentSortField == TagsSortField.modifiedAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == TagsSortField.modifiedAt)
                          const SizedBox(width: 8),
                        const Text('По дате изменения'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // SliverToBoxAdapter(child: TagPickerField()),
          tagState.when(
            data: (state) {
              if (state.items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Теги не найдены')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    if (index == state.items.length && state.hasMore) {
                      // Загружаем следующую страницу при достижении конца
                      Future.microtask(
                        () => ref.read(tagListProvider.notifier).loadMore(),
                      );
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (index >= state.items.length) {
                      return null;
                    }
                    final tag = state.items[index];
                    return TagCard(
                      tag: tag,
                      onTap: () {
                        context
                            .push<bool>(
                              AppRoutesPaths.tagsEdit(widget.entity, tag.id),
                            )
                            .then((edited) {
                              if (edited == true) {
                                ref.read(tagListProvider.notifier).refresh();
                              }
                            });
                      },
                      onEdit: () {
                        context
                            .push<bool>(
                              AppRoutesPaths.tagsEdit(widget.entity, tag.id),
                            )
                            .then((edited) {
                              if (edited == true) {
                                ref.read(tagListProvider.notifier).refresh();
                              }
                            });
                      },
                      onDelete: () => _handleDeleteTag(context, ref, tag),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: state.hasMore
                      ? state.items.length + 1
                      : state.items.length,
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
                    const Text('Ошибка загрузки тегов'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(tagListProvider.notifier).refresh(),
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
              heroTag: 'tagsManagerFab',
              onPressed: () {
                final result = context.push<bool>(
                  AppRoutesPaths.tagsAdd(widget.entity),
                );
                result.then((added) {
                  if (added == true) {
                    ref.read(tagListProvider.notifier).refresh();
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  static void _showSearchDialog(
    BuildContext context, {
    required String initialValue,
    required Function(String) onSearch,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск тегов'),
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
            label: 'Найти',
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteTag(
    BuildContext context,
    WidgetRef ref,
    TagCardDto tag,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тег?'),
        content: Text('Вы уверены, что хотите удалить тег "${tag.name}"?'),
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
        final tagDao = await ref.read(tagDaoProvider.future);
        await tagDao.deleteTag(tag.id);

        // Уведомляем об удалении тега
        ref.read(managerRefreshTriggerProvider.notifier).triggerTagRefresh();
        ref.read(tagListProvider.notifier).refresh();

        if (context.mounted) {
          Toaster.success(
            title: 'Тег удален',
            description: 'Тег "${tag.name}" успешно удален.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          Toaster.error(
            title: 'Ошибка удаления',
            description:
                'Не удалось удалить тег "${tag.name}". Попробуйте еще раз.',
          );
        }
      }
    }
  }
}
