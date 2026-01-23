import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import 'providers/tag_filter_provider.dart';
import 'providers/tag_pagination_provider.dart';

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
                padding: const EdgeInsets.all(12.0),
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
                    return _buildTagCard(
                      context,
                      ref,
                      state.items[index],
                      () => ref.read(tagListProvider.notifier).refresh(),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'tagsManagerFab',
        onPressed: () {
          final result = context.push<bool>(
            AppRoutesPaths.tagsAdd(widget.entity),
          );
          if (result != null) {
            result.then((added) {
              if (added == true) {
                ref.read(tagListProvider.notifier).refresh();
              }
            });
          }
        },
        child: const Icon(Icons.add),
      ),
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

  Widget _buildTagCard(
    BuildContext context,
    WidgetRef ref,
    TagCardDto tag,
    VoidCallback onRefresh,
  ) {
    final colorValue = int.tryParse(tag.color ?? 'FFFFFF', radix: 16);
    final color = colorValue != null
        ? Color(0xFF000000 | colorValue)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(child: Icon(Icons.label, color: color)),
        ),
        title: Text(tag.name),
        subtitle: Text('Тип: ${tag.type} • Элементов: ${tag.itemsCount}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              final result = context.push<bool>(
                AppRoutesPaths.tagsEdit(widget.entity, tag.id),
              );
              if (result != null) {
                result.then((edited) {
                  if (edited == true) {
                    onRefresh();
                  }
                });
              }
            } else if (value == 'delete') {
              await _handleDeleteTag(context, ref, tag);
            }
          },
        ),
        onTap: () {
          final result = context.push<bool>(
            AppRoutesPaths.tagsEdit(widget.entity, tag.id),
          );

          if (result != null) {
            result.then((edited) {
              if (edited == true) {
                onRefresh();
              }
            });
          }
        },
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final tagDao = await ref.read(tagDaoProvider.future);
        await tagDao.deleteTag(tag.id);

        // Уведомляем об удалении тега
        ref.read(tagFilterProvider.notifier).notifyTagDeleted(tagId: tag.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Тег "${tag.name}" успешно удален')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
