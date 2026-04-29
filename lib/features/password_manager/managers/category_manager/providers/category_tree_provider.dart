import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/models/dto/category_tree_node.dart';
import 'package:hoplixi/main_db/providers/dao_providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/category_tree_state.dart';

const int _kCategoryRootPageSize = 20;

final categoryTreeProvider =
    AsyncNotifierProvider.autoDispose<CategoryTreeNotifier, CategoryTreeState>(
      CategoryTreeNotifier.new,
    );

class CategoryTreeNotifier extends AsyncNotifier<CategoryTreeState> {
  @override
  Future<CategoryTreeState> build() async {
    ref.listen(managerRefreshTriggerProvider, (previous, next) {
      if (next.resourceType == ManagerResourceType.category ||
          next.resourceType == null) {
        refresh();
      }
    });

    return _loadInitial();
  }

  Future<CategoryTreeState> _loadInitial() async {
    final dao = await ref.read(categoryDaoProvider.future);
    final roots = await dao.getRootCategoryNodesPaginated(
      limit: _kCategoryRootPageSize,
      offset: 0,
    );

    return CategoryTreeState(
      roots: roots,
      rootOffset: roots.length,
      hasMoreRoots: roots.length >= _kCategoryRootPageSize,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitial);
  }

  Future<void> loadMoreRoots() async {
    final current = state.value;
    if (current == null ||
        current.isLoadingMoreRoots ||
        !current.hasMoreRoots) {
      return;
    }

    state = AsyncValue.data(current.copyWith(isLoadingMoreRoots: true));

    try {
      final dao = await ref.read(categoryDaoProvider.future);
      final roots = await dao.getRootCategoryNodesPaginated(
        limit: _kCategoryRootPageSize,
        offset: current.rootOffset,
      );

      final updated = state.value ?? current;
      state = AsyncValue.data(
        updated.copyWith(
          roots: [...updated.roots, ...roots],
          rootOffset: updated.rootOffset + roots.length,
          hasMoreRoots: roots.length >= _kCategoryRootPageSize,
          isLoadingMoreRoots: false,
        ),
      );
    } catch (_) {
      final fallback = state.value ?? current;
      state = AsyncValue.data(fallback.copyWith(isLoadingMoreRoots: false));
    }
  }

  Future<void> toggleNode(String categoryId) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final node = _findNode(current.roots, categoryId);
    if (node == null || !node.hasChildren || node.isLoadingChildren) {
      return;
    }

    if (node.isExpanded) {
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
      final dao = await ref.read(categoryDaoProvider.future);
      final children = await dao.getSubcategoryNodes(categoryId);
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
    } catch (_) {
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
