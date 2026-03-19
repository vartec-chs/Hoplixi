import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import 'category_manager_filter_bar.dart';

class CategoryManagerAppBar extends ConsumerStatefulWidget {
  const CategoryManagerAppBar({super.key});

  @override
  ConsumerState<CategoryManagerAppBar> createState() =>
      _CategoryManagerAppBarState();
}

class _CategoryManagerAppBarState extends ConsumerState<CategoryManagerAppBar> {
  late final TextEditingController _searchController;
  late final ProviderSubscription<CategoriesFilter> _filterSubscription;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(categoryFilterProvider);
    _isSearchActive = filter.query.isNotEmpty;
    _searchController = TextEditingController(text: filter.query);
    _filterSubscription = ref.listenManual(categoryFilterProvider, (
      previous,
      next,
    ) {
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
    final filter = ref.watch(categoryFilterProvider);
    final filterCount = countCategoryManagerFilters(filter);
    final hasSearchText = _searchController.text.isNotEmpty;

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
                  hintText: 'Поиск категорий...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: hasSearchText
                      ? IconButton(
                          tooltip: 'Очистить поиск',
                          onPressed: () {
                            _searchController.clear();
                            ref.read(categoryFilterProvider.notifier).updateQuery('');
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
                  ref.read(categoryFilterProvider.notifier).updateQuery(value);
                  setState(() {});
                },
              ),
            )
          : const Text('Категории'),
      actions: [
        IconButton(
          tooltip: _isSearchActive ? 'Закрыть поиск' : 'Поиск',
          onPressed: () {
            setState(() {
              if (_isSearchActive) {
                _searchController.clear();
                ref.read(categoryFilterProvider.notifier).updateQuery('');
              }
              _isSearchActive = !_isSearchActive;
            });
          },
          icon: Icon(_isSearchActive ? Icons.close : Icons.search),
        ),
        IconButton(
          tooltip: 'Фильтры',
          onPressed: () => showCategoryManagerFilterSheet(context, ref, filter),
          icon: Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            child: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}
