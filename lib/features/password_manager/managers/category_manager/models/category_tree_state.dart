import 'package:hoplixi/db_core/models/dto/category_tree_node.dart';

class CategoryTreeState {
  const CategoryTreeState({
    this.roots = const [],
    this.isLoadingMoreRoots = false,
    this.hasMoreRoots = false,
    this.rootOffset = 0,
  });

  final List<CategoryTreeNode> roots;
  final bool isLoadingMoreRoots;
  final bool hasMoreRoots;
  final int rootOffset;

  CategoryTreeState copyWith({
    List<CategoryTreeNode>? roots,
    bool? isLoadingMoreRoots,
    bool? hasMoreRoots,
    int? rootOffset,
  }) {
    return CategoryTreeState(
      roots: roots ?? this.roots,
      isLoadingMoreRoots: isLoadingMoreRoots ?? this.isLoadingMoreRoots,
      hasMoreRoots: hasMoreRoots ?? this.hasMoreRoots,
      rootOffset: rootOffset ?? this.rootOffset,
    );
  }
}
