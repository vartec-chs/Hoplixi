import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

import 'providers/tag_pagination_provider.dart';
import 'widgets/tag_card.dart';
import 'widgets/tags_manager_app_bar.dart';

class TagsManagerScreen extends ConsumerStatefulWidget {
  final EntityType entity;

  const TagsManagerScreen({super.key, required this.entity});

  @override
  ConsumerState<TagsManagerScreen> createState() => _TagsManagerScreenState();
}

class _TagsManagerScreenState extends ConsumerState<TagsManagerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(tagListProvider.notifier).loadMore();
    }
  }

  void _refresh() {
    ref.read(tagListProvider.notifier).refresh();
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  @override
  Widget build(BuildContext context) {
    final tagState = ref.watch(tagListProvider);
    final paginationState = tagState.value;
    final showBottomLoader =
        paginationState?.isLoading == true &&
        (paginationState?.items.isNotEmpty ?? false);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const TagsManagerAppBar(),
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
                    final tag = state.items[index];
                    return TagCard(
                      tag: tag,
                      onTap: () => _openEdit(tag.id),
                      onEdit: () => _openEdit(tag.id),
                      onDelete: () => _handleDeleteTag(context, ref, tag),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: state.items.length,
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
                      onPressed: _refresh,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showBottomLoader)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isMobileLayout(context)
          ? FloatingActionButton(
              heroTag: 'tagsManagerFab',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                final result = context.push<bool>(
                  AppRoutesPaths.tagsAdd(widget.entity),
                );
                result.then((added) {
                  if (added == true) {
                    _refresh();
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _openEdit(String tagId) {
    context.push<bool>(AppRoutesPaths.tagsEdit(widget.entity, tagId)).then((
      edited,
    ) {
      if (edited == true) {
        _refresh();
      }
    });
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

        ref.read(managerRefreshTriggerProvider.notifier).triggerTagRefresh();
        _refresh();

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
