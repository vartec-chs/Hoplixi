import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_category_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/db_core/models/dto/category_tree_node.dart';
import 'package:hoplixi/db_core/models/enums/entity_types.dart';
import 'package:hoplixi/db_core/models/filter/index.dart';
import 'package:hoplixi/db_core/provider/dao_providers.dart';

const int _kCategoryPageSize = 20;
const Duration _kCategorySearchDebounce = Duration(milliseconds: 300);

final drawerCategoryFilterProvider =
    AsyncNotifierProvider.family<
      DrawerCategoryFilterNotifier,
      DrawerCategoryFilterState,
      EntityType
    >(DrawerCategoryFilterNotifier.new);

class DrawerCategoryFilterNotifier
    extends AsyncNotifier<DrawerCategoryFilterState> {
  static const String _logTag = 'DrawerCategoryFilterNotifier';
  Timer? _searchDebounce;

  DrawerCategoryFilterNotifier(this._entityType);

  final EntityType _entityType;

  List<CategoryType> get _allowedTypes => [
    _entityType.toCategoryType(),
    CategoryType.mixed,
  ];

  @override
  Future<DrawerCategoryFilterState> build() async {
    ref.onDispose(() => _searchDebounce?.cancel());

    ref.listen<ManagerRefreshState>(managerRefreshTriggerProvider, (
      previous,
      next,
    ) {
      if (next.resourceType == ManagerResourceType.category) {
        logDebug(
          '$_logTag categories changed, reloading drawer state',
          tag: _logTag,
        );
        _reload();
      }
    });

    return _loadBrowseInitial();
  }

  Future<DrawerCategoryFilterState> _loadBrowseInitial() async {
    final categoryDao = await ref.read(categoryDaoProvider.future);
    final roots = await categoryDao.getFilteredRootCategoryNodesPaginated(
      types: _allowedTypes,
      limit: _kCategoryPageSize,
      offset: 0,
    );

    return DrawerCategoryFilterState(
      roots: roots,
      offset: roots.length,
      hasMore: roots.length >= _kCategoryPageSize,
    );
  }

  void _reload() {
    state.whenData((current) {
      if (current.isSearching) {
        _loadSearch(reset: true, query: current.searchQuery);
      } else {
        _loadRoots(reset: true);
      }
    });
  }

  void reload() => _reload();

  Future<void> _loadRoots({required bool reset}) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (!reset && (current.isLoadingMore || !current.hasMore)) {
      return;
    }
    if (reset && current.isLoading) {
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        isLoading: reset,
        isLoadingMore: !reset,
        searchQuery: '',
        searchResults: reset ? const [] : current.searchResults,
      ),
    );

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final offset = reset ? 0 : current.offset;
      final roots = await categoryDao.getFilteredRootCategoryNodesPaginated(
        types: _allowedTypes,
        limit: _kCategoryPageSize,
        offset: offset,
      );

      final updated = state.value ?? current;
      state = AsyncValue.data(
        updated.copyWith(
          roots: reset ? roots : [...updated.roots, ...roots],
          offset: offset + roots.length,
          hasMore: roots.length >= _kCategoryPageSize,
          isLoading: false,
          isLoadingMore: false,
          searchQuery: '',
          searchResults: const [],
        ),
      );
    } catch (e, st) {
      logError(
        '$_logTag failed to load root categories',
        error: e,
        stackTrace: st,
      );
      final fallback = state.value ?? current;
      state = AsyncValue.data(
        fallback.copyWith(isLoading: false, isLoadingMore: false),
      );
    }
  }

  Future<void> _loadSearch({required bool reset, required String query}) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (!reset && (current.isLoadingMore || !current.hasMore)) {
      return;
    }
    if (reset && current.isLoading) {
      return;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await _loadRoots(reset: true);
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        isLoading: reset,
        isLoadingMore: !reset,
        searchQuery: trimmed,
        searchResults: reset ? const [] : current.searchResults,
      ),
    );

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final offset = reset ? 0 : current.offset;
      final filter = CategoriesFilter.create(
        query: trimmed,
        types: _allowedTypes,
        limit: _kCategoryPageSize,
        offset: offset,
      );
      final categories = await categoryDao.getCategoryCardsFiltered(filter);
      final updated = state.value ?? current;

      state = AsyncValue.data(
        updated.copyWith(
          searchResults: reset
              ? categories
              : [...updated.searchResults, ...categories],
          offset: offset + categories.length,
          hasMore: categories.length >= _kCategoryPageSize,
          isLoading: false,
          isLoadingMore: false,
          searchQuery: trimmed,
        ),
      );
    } catch (e, st) {
      logError(
        '$_logTag failed to search categories',
        error: e,
        stackTrace: st,
      );
      final fallback = state.value ?? current;
      state = AsyncValue.data(
        fallback.copyWith(isLoading: false, isLoadingMore: false),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) {
      return;
    }

    if (current.isSearching) {
      await _loadSearch(reset: false, query: current.searchQuery);
    } else {
      await _loadRoots(reset: false);
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kCategorySearchDebounce, () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        await _loadRoots(reset: true);
      } else {
        await _loadSearch(reset: true, query: trimmed);
      }
    });
  }

  Future<void> toggleExpand(String categoryId, bool expanded) async {
    final current = state.value;
    if (current == null || current.isSearching) {
      return;
    }

    final node = _findNode(current.roots, categoryId);
    if (node == null || !node.hasChildren || node.isLoadingChildren) {
      return;
    }

    if (!expanded) {
      state = AsyncValue.data(
        current.copyWith(
          roots: _updateNode(
            current.roots,
            categoryId,
            (target) => target.copyWith(isExpanded: false),
          ),
        ),
      );
      return;
    }

    if (node.isChildrenLoaded) {
      state = AsyncValue.data(
        current.copyWith(
          roots: _updateNode(
            current.roots,
            categoryId,
            (target) => target.copyWith(isExpanded: true),
          ),
        ),
      );
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        roots: _updateNode(
          current.roots,
          categoryId,
          (target) =>
              target.copyWith(isExpanded: true, isLoadingChildren: true),
        ),
      ),
    );

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final children = await categoryDao.getFilteredSubcategoryNodes(
        parentId: categoryId,
        types: _allowedTypes,
      );
      final updated = state.value ?? current;

      state = AsyncValue.data(
        updated.copyWith(
          roots: _updateNode(
            updated.roots,
            categoryId,
            (target) => target.copyWith(
              children: children,
              isExpanded: true,
              isChildrenLoaded: true,
              isLoadingChildren: false,
            ),
          ),
        ),
      );
    } catch (e, st) {
      logError('$_logTag failed to load children', error: e, stackTrace: st);
      final fallback = state.value ?? current;
      state = AsyncValue.data(
        fallback.copyWith(
          roots: _updateNode(
            fallback.roots,
            categoryId,
            (target) =>
                target.copyWith(isExpanded: false, isLoadingChildren: false),
          ),
        ),
      );
    }
  }

  void toggle(String id) {
    state.whenData((s) {
      final selected = s.selectedIds;
      final updated = selected.contains(id)
          ? selected.where((e) => e != id).toList()
          : [...selected, id];
      state = AsyncValue.data(s.copyWith(selectedIds: updated));
      _applyToBase();
    });
  }

  void clearSelection() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(selectedIds: []));
      _applyToBase();
    });
  }

  void _applyToBase() {
    state.whenData((s) {
      ref.read(baseFilterProvider.notifier).setCategoryIds(s.selectedIds);
    });
  }

  CategoryTreeNode? _findNode(List<CategoryTreeNode> nodes, String categoryId) {
    for (final node in nodes) {
      if (node.category.id == categoryId) {
        return node;
      }

      final nested = _findNode(node.children, categoryId);
      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  List<CategoryTreeNode> _updateNode(
    List<CategoryTreeNode> nodes,
    String categoryId,
    CategoryTreeNode Function(CategoryTreeNode target) update,
  ) {
    return [
      for (final node in nodes)
        if (node.category.id == categoryId)
          update(node)
        else
          node.copyWith(
            children: _updateNode(node.children, categoryId, update),
          ),
    ];
  }
}
