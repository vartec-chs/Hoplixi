import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/filter_providers.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/models/drawer_category_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

const int _kCategoryPageSize = 20;
const Duration _kCategorySearchDebounce = Duration(milliseconds: 300);

final drawerCategoryFilterProvider = AsyncNotifierProvider.autoDispose
    .family<
      DrawerCategoryFilterNotifier,
      DrawerCategoryFilterState,
      EntityType
    >(DrawerCategoryFilterNotifier.new);

class DrawerCategoryFilterNotifier
    extends AsyncNotifier<DrawerCategoryFilterState> {
  static const String _logTag = 'DrawerCategoryFilterNotifier';
  Timer? _searchDebounce;
  List<CategoryCardDto> _allCategories = const [];
  List<DrawerCategoryTreeNode> _allRoots = const [];

  DrawerCategoryFilterNotifier(EntityType _);

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
    await _refreshCache();
    final roots = _sliceRoots(offset: 0);

    return DrawerCategoryFilterState(
      roots: roots,
      offset: roots.length,
      hasMore: roots.length < _allRoots.length,
    );
  }

  Future<void> _refreshCache() async {
    final repositories = await ref.read(vaultRepositories.future);
    final categories = (await repositories.category.getAllCategories())
        .getOrThrow()
      ..sort((a, b) => a.name.compareTo(b.name));

    _allCategories = categories;
    _allRoots = _buildTree(categories);
  }

  List<DrawerCategoryTreeNode> _sliceRoots({required int offset}) {
    final end = (offset + _kCategoryPageSize).clamp(0, _allRoots.length);
    if (offset >= end) return const [];
    return _allRoots.sublist(offset, end);
  }

  List<CategoryCardDto> _searchCategories(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return _allCategories
        .where((category) => category.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  List<DrawerCategoryTreeNode> _buildTree(List<CategoryCardDto> categories) {
    final childrenByParent = <String?, List<CategoryCardDto>>{};
    for (final category in categories) {
      childrenByParent.putIfAbsent(category.parentId, () => []).add(category);
    }

    DrawerCategoryTreeNode buildNode(CategoryCardDto category) {
      final children = childrenByParent[category.id] ?? const [];
      return DrawerCategoryTreeNode(
        category: category,
        children: children.map(buildNode).toList(growable: false),
      );
    }

    final roots = childrenByParent[null] ?? const [];
    return roots.map(buildNode).toList(growable: false);
  }

  void _reload() {
    state.whenData((current) async {
      if (current.isSearching) {
        await _loadSearch(reset: true, query: current.searchQuery);
      } else {
        await _loadRoots(reset: true);
      }
    });
  }

  void reload() => _reload();

  Future<void> _loadRoots({required bool reset}) async {
    final current = state.value;
    if (current == null) return;
    if (!reset && (current.isLoadingMore || !current.hasMore)) return;
    if (reset && current.isLoading) return;

    state = AsyncValue.data(
      current.copyWith(
        isLoading: reset,
        isLoadingMore: !reset,
        searchQuery: '',
        searchResults: reset ? const [] : current.searchResults,
      ),
    );

    try {
      if (reset) await _refreshCache();

      final offset = reset ? 0 : current.offset;
      final roots = _sliceRoots(offset: offset);
      final updated = state.value ?? current;

      state = AsyncValue.data(
        updated.copyWith(
          roots: reset ? roots : [...updated.roots, ...roots],
          offset: offset + roots.length,
          hasMore: offset + roots.length < _allRoots.length,
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
    if (current == null) return;
    if (!reset && (current.isLoadingMore || !current.hasMore)) return;
    if (reset && current.isLoading) return;

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
      if (reset) await _refreshCache();

      final matches = _searchCategories(trimmed);
      final offset = reset ? 0 : current.offset;
      final end = (offset + _kCategoryPageSize).clamp(0, matches.length);
      final categories = offset >= end
          ? const <CategoryCardDto>[]
          : matches.sublist(offset, end);
      final updated = state.value ?? current;

      state = AsyncValue.data(
        updated.copyWith(
          searchResults: reset
              ? categories
              : [...updated.searchResults, ...categories],
          offset: offset + categories.length,
          hasMore: offset + categories.length < matches.length,
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
    if (current == null) return;

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
    if (current == null || current.isSearching) return;

    state = AsyncValue.data(
      current.copyWith(
        roots: _updateNode(
          current.roots,
          categoryId,
          (target) => target.copyWith(isExpanded: expanded),
        ),
      ),
    );
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

  List<DrawerCategoryTreeNode> _updateNode(
    List<DrawerCategoryTreeNode> nodes,
    String categoryId,
    DrawerCategoryTreeNode Function(DrawerCategoryTreeNode target) update,
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
