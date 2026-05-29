import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/category_tree_node_ui.dart';
import '../models/category_tree_state.dart';

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
    final repos = await ref.read(vaultRepositories.future);
    final result = await repos.category.getCategoryTree();
    final dtos = result.getOrThrow();
    
    final roots = dtos.map(CategoryTreeNodeUi.fromDto).toList();

    return CategoryTreeState(
      roots: roots,
      rootOffset: roots.length,
      hasMoreRoots: false, // В новой архитектуре грузим всё сразу
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitial);
  }

  Future<void> loadMoreRoots() async {
    // В новой архитектуре грузим всё сразу
  }

  Future<void> toggleNode(String categoryId) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        roots: _updateNode(
          current.roots,
          categoryId,
          (target) => target.copyWith(isExpanded: !target.isExpanded),
        ),
      ),
    );
  }

  List<CategoryTreeNodeUi> _updateNode(
    List<CategoryTreeNodeUi> nodes,
    String categoryId,
    CategoryTreeNodeUi Function(CategoryTreeNodeUi target) update,
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
