import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/category_tree_node.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';

/// Провайдер дерева категорий
final categoryTreeProvider =
    AsyncNotifierProvider.autoDispose<
      CategoryTreeNotifier,
      List<CategoryTreeNode>
    >(() => CategoryTreeNotifier());

class CategoryTreeNotifier extends AsyncNotifier<List<CategoryTreeNode>> {
  @override
  Future<List<CategoryTreeNode>> build() async {
    ref.listen(managerRefreshTriggerProvider, (previous, next) {
      if (next.resourceType == ManagerResourceType.category ||
          next.resourceType == null) {
        refresh();
      }
    });
    return _load();
  }

  Future<List<CategoryTreeNode>> _load() async {
    final dao = await ref.read(categoryDaoProvider.future);
    return dao.getCategoryTree();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}
