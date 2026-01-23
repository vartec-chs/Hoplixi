import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/providers/tag_picker_provider.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_filters.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_item.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Модальное окно выбора тегов
class TagPickerModal {
  /// Показать модальное окно выбора тегов (множественный выбор)
  static Future<void> show({
    required BuildContext context,
    required Function(List<String> tagIds, List<String> tagNames)
    onTagsSelected,
    List<String>? currentTagIds,
    int? maxTagPicks,
    List<TagType?>? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onTagsSelected: onTagsSelected,
          currentTagIds: currentTagIds ?? [],
          maxTagPicks: maxTagPicks,
          isSingleMode: false,
          filterByType: filterByType,
        ),
      ],
    );
  }

  /// Показать модальное окно выбора тега (одиночный выбор)
  static Future<void> showSingle({
    required BuildContext context,
    required Function(String? tagId, String? tagName) onTagSelected,
    String? currentTagId,
    List<TagType?>? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onTagSelected: onTagSelected,
          currentTagIds: currentTagId != null ? [currentTagId] : [],
          maxTagPicks: 1,
          isSingleMode: true,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage _buildPickerPage(
    BuildContext context, {
    Function(List<String> tagIds, List<String> tagNames)? onTagsSelected,
    Function(String? tagId, String? tagName)? onTagSelected,
    required List<String> currentTagIds,
    int? maxTagPicks,
    required bool isSingleMode,
    List<TagType?>? filterByType,
  }) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      forceMaxHeight: true,
      topBarTitle: Text(
        isSingleMode
            ? 'Выберите тег'
            : (maxTagPicks != null && maxTagPicks > 0
                  ? 'Выберите теги (макс. $maxTagPicks)'
                  : 'Выберите теги'),
      ),
      isTopBarLayerAlwaysVisible: true,
      mainContentSliversBuilder: (context) => [
        // Контент с состоянием
        _TagPickerContent(
          onTagsSelected: onTagsSelected,
          onTagSelected: onTagSelected,
          initialTagIds: currentTagIds,
          maxTagPicks: maxTagPicks,
          isSingleMode: isSingleMode,
          filterByType: filterByType,
        ),
      ],
    );
  }
}

/// Контент модального окна с состоянием выбранных тегов
class _TagPickerContent extends ConsumerStatefulWidget {
  const _TagPickerContent({
    this.onTagsSelected,
    this.onTagSelected,
    required this.initialTagIds,
    this.maxTagPicks,
    required this.isSingleMode,
    this.filterByType,
  });

  final Function(List<String> tagIds, List<String> tagNames)? onTagsSelected;
  final Function(String? tagId, String? tagName)? onTagSelected;
  final List<String> initialTagIds;
  final int? maxTagPicks;
  final bool isSingleMode;
  final List<TagType?>? filterByType;

  @override
  ConsumerState<_TagPickerContent> createState() => _TagPickerContentState();
}

class _TagPickerContentState extends ConsumerState<_TagPickerContent> {
  late List<String> _selectedTagIds;
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  List<dynamic> _items = [];

  /// Кэшированный список типов для провайдера
  late final List<TagType?> _cachedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List<String>.from(widget.initialTagIds);
    // Преобразуем тип из String в List<TagType?>
    _cachedTypes = widget.filterByType != null
        ? widget.filterByType!
        : <TagType?>[];
  }

  void _updateItems(List<dynamic> newItems) {
    if (!mounted) return;

    final oldLength = _items.length;
    final newLength = newItems.length;

    // Если список пустой, просто заменяем
    if (oldLength == 0) {
      setState(() {
        _items = List.from(newItems);
      });
      // Анимируем добавление всех элементов
      for (int i = 0; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + i * 20),
        );
      }
      return;
    }

    // Удаляем лишние элементы
    if (newLength < oldLength) {
      for (int i = oldLength - 1; i >= newLength; i--) {
        final item = _items[i];
        final isSelected = _selectedTagIds.contains(item.id);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedItem(item, animation, isSelected),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Добавляем новые элементы
    if (newLength > oldLength) {
      for (int i = oldLength; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + (i - oldLength) * 20),
        );
      }
    }

    setState(() {
      _items = List.from(newItems);
    });
  }

  Widget _buildAnimatedItem(
    dynamic tag,
    Animation<double> animation,
    bool isSelected,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: TagPickerItem(
          tag: tag,
          isSelected: isSelected,
          onTap: () => _toggleTag(tag.id, tag.name, _items),
        ),
      ),
    );
  }

  void _toggleTag(String tagId, String tagName, List<dynamic> allTags) {
    if (widget.isSingleMode) {
      // Режим одиночного выбора
      setState(() {
        if (_selectedTagIds.contains(tagId)) {
          // Снимаем выбор
          _selectedTagIds.clear();
          widget.onTagSelected?.call(null, null);
        } else {
          // Выбираем новый тег
          _selectedTagIds = [tagId];
          widget.onTagSelected?.call(tagId, tagName);
        }
      });
    } else {
      // Режим множественного выбора
      setState(() {
        if (_selectedTagIds.contains(tagId)) {
          // Убираем тег из выбранных
          _selectedTagIds.remove(tagId);
        } else {
          // Проверяем лимит
          if (widget.maxTagPicks != null &&
              _selectedTagIds.length >= widget.maxTagPicks!) {
            Toaster.warning(
              title: 'Теги',
              description: 'Можно выбрать максимум ${widget.maxTagPicks} тегов',
            );
            return;
          }
          _selectedTagIds.add(tagId);
        }
      });

      // Собираем имена для выбранных тегов
      final selectedTagNames = <String>[];
      for (final tagId in _selectedTagIds) {
        try {
          final selectedTag = allTags.firstWhere((t) => t.id == tagId);
          selectedTagNames.add(selectedTag.name as String);
        } catch (e) {
          // Тег не найден в списке, пропускаем
          continue;
        }
      }

      widget.onTagsSelected?.call(_selectedTagIds, selectedTagNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagPickerListProvider(_cachedTypes));

    return tagsState.when(
      data: (state) {
        // Обновляем список при получении новых данных
        if (state.items.length != _items.length ||
            (state.items.isNotEmpty &&
                _items.isNotEmpty &&
                state.items.first.id != _items.first.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateItems(state.items);
          });
        }

        if (state.items.isEmpty && !state.isLoading) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: TagPickerFilters(
                  filterByType: widget.filterByType,
                  selectedCount: _selectedTagIds.length,
                  maxCount: widget.maxTagPicks,
                ),
              ),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Теги не найдены',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: TagPickerFilters(
                filterByType: widget.filterByType,
                selectedCount: _selectedTagIds.length,
                maxCount: widget.maxTagPicks,
              ),
            ),
            SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                if (index >= _items.length) {
                  return const SizedBox.shrink();
                }

                final tag = _items[index];
                final isSelected = _selectedTagIds.contains(tag.id);

                return _buildAnimatedItem(tag, animation, isSelected);
              },
            ),
            if (state.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(
                                    tagPickerListProvider(
                                      _cachedTypes,
                                    ).notifier,
                                  )
                                  .loadMore();
                            },
                            child: const Text('Загрузить еще'),
                          ),
                        ),
                ),
              ),
          ],
        );
      },
      loading: () => SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: TagPickerFilters(
              filterByType: widget.filterByType,
              selectedCount: _selectedTagIds.length,
              maxCount: widget.maxTagPicks,
            ),
          ),
          SliverFillRemaining(
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, stack) => SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: TagPickerFilters(
              filterByType: widget.filterByType,
              selectedCount: _selectedTagIds.length,
              maxCount: widget.maxTagPicks,
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки тегов',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
