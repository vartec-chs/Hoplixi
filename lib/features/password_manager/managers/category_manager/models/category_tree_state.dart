import 'category_tree_node_ui.dart';

class CategoryTreeState {
  const CategoryTreeState({
    this.roots = const [],
    this.isLoadingMoreRoots = false,
    this.hasMoreRoots = false,
    this.rootOffset = 0,
  });

  final List<CategoryTreeNodeUi> roots;
  final bool isLoadingMoreRoots;
  final bool hasMoreRoots;
  final int rootOffset;

  CategoryTreeState copyWith({
    List<CategoryTreeNodeUi>? roots,
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
