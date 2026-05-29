import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../models/tag_manager_filter.dart';
import '../providers/tag_filter_provider.dart';

class TagsManagerAppBar extends ConsumerStatefulWidget {
  const TagsManagerAppBar({super.key});

  @override
  ConsumerState<TagsManagerAppBar> createState() => _TagsManagerAppBarState();
}

class _TagsManagerAppBarState extends ConsumerState<TagsManagerAppBar> {
  late final TextEditingController _searchController;
  late final ProviderSubscription<TagManagerFilter> _filterSubscription;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(tagFilterProvider);
    _isSearchActive = filter.query.isNotEmpty;
    _searchController = TextEditingController(text: filter.query);
    _filterSubscription = ref.listenManual(tagFilterProvider, (previous, next) {
      if (_searchController.text != next.query) {
        _searchController.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
      if (!_isSearchActive && next.query.isNotEmpty && mounted) {
        setState(() => _isSearchActive = true);
      }
    });
  }

  @override
  void dispose() {
    _filterSubscription.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(tagFilterProvider);
    final filterCount = _countActiveFilters(filter);
    final hasSearchText = _searchController.text.isNotEmpty;
    final currentSortField = ref.watch(
      tagFilterProvider.select((state) => state.sortField),
    );

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      title: _isSearchActive
          ? SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: primaryInputDecoration(
                  context,
                  hintText: 'Поиск тегов...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: hasSearchText
                      ? IconButton(
                          tooltip: 'Очистить поиск',
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(tagFilterProvider.notifier)
                                .updateQuery('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 44,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  ref.read(tagFilterProvider.notifier).updateQuery(value);
                  setState(() {});
                },
              ),
            )
          : const Text('Теги'),
      actions: [
        IconButton(
          tooltip: _isSearchActive ? 'Закрыть поиск' : 'Поиск',
          onPressed: () {
            setState(() {
              if (_isSearchActive) {
                _searchController.clear();
                ref.read(tagFilterProvider.notifier).updateQuery('');
              }
              _isSearchActive = !_isSearchActive;
            });
          },
          icon: Icon(_isSearchActive ? Icons.close : Icons.search),
        ),
        PopupMenuButton<TagManagerSortField>(
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
            _sortItem(
              context: context,
              currentSortField: currentSortField,
              value: TagManagerSortField.name,
              label: 'По названию',
            ),
            _sortItem(
              context: context,
              currentSortField: currentSortField,
              value: TagManagerSortField.createdAt,
              label: 'По дате создания',
            ),
            _sortItem(
              context: context,
              currentSortField: currentSortField,
              value: TagManagerSortField.modifiedAt,
              label: 'По дате изменения',
            ),
          ],
        ),
        IconButton(
          tooltip: 'Фильтры',
          onPressed: () => _showFilterSheet(context, filter),
          icon: Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            child: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<TagManagerSortField> _sortItem({
    required BuildContext context,
    required TagManagerSortField currentSortField,
    required TagManagerSortField value,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (currentSortField == value) const Icon(Icons.check, size: 20),
          if (currentSortField == value) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  int _countActiveFilters(TagManagerFilter filter) {
    var count = 0;
    if (filter.color != null) {
      count++;
    }
    return count;
  }

  Future<void> _showFilterSheet(BuildContext context, TagManagerFilter filter) async {
    final colorController = TextEditingController(
      text: filter.color != null ? filter.color!.toRadixString(16).toUpperCase() : '',
    );

    try {
      await WoltModalSheet.show<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        pageListBuilder: (modalSheetContext) => [
          WoltModalSheetPage(
            hasTopBarLayer: true,
            isTopBarLayerAlwaysVisible: true,
            surfaceTintColor: Colors.transparent,
            topBarTitle: Text(
              'Фильтрация тегов',
              style: Theme.of(modalSheetContext).textTheme.titleMedium,
            ),
            leadingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalSheetContext).pop(),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        TextField(
                          controller: colorController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Цвет',
                            hintText: 'HEX, например FFA726',
                            prefixIcon: const Icon(Icons.palette_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SmoothButton(
                                onPressed: () {
                                  colorController.clear();
                                  setModalState(() {});
                                },
                                label: 'Сбросить',
                                type: SmoothButtonType.text,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SmoothButton(
                                onPressed: () async {
                                  final colorText = colorController.text.trim();
                                  int? color;
                                  if (colorText.isNotEmpty) {
                                    try {
                                      color = int.parse(colorText, radix: 16);
                                    } catch (_) {}
                                  }

                                  await ref
                                      .read(tagFilterProvider.notifier)
                                      .updateFilter(
                                        filter.copyWith(
                                          color: color,
                                        ),
                                      );
                                  if (modalSheetContext.mounted) {
                                    Navigator.of(modalSheetContext).pop();
                                  }
                                },
                                label: 'Применить',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } finally {
      colorController.dispose();
    }
  }
}
