import 'package:hoplixi/main_db/core/old/models/dto/category_dto.dart';

/// Узел дерева категорий.
class CategoryTreeNode {
  CategoryTreeNode({
    required this.category,
    this.children = const [],
    bool? hasChildren,
    this.isExpanded = false,
    this.isChildrenLoaded = false,
    this.isLoadingChildren = false,
  }) : _hasChildren = hasChildren ?? children.isNotEmpty;

  final CategoryCardDto category;
  final List<CategoryTreeNode> children;
  final bool _hasChildren;
  final bool isExpanded;
  final bool isChildrenLoaded;
  final bool isLoadingChildren;

  bool get hasChildren => _hasChildren;

  CategoryTreeNode copyWith({
    CategoryCardDto? category,
    List<CategoryTreeNode>? children,
    bool? hasChildren,
    bool? isExpanded,
    bool? isChildrenLoaded,
    bool? isLoadingChildren,
  }) {
    return CategoryTreeNode(
      category: category ?? this.category,
      children: children ?? this.children,
      hasChildren: hasChildren ?? _hasChildren,
      isExpanded: isExpanded ?? this.isExpanded,
      isChildrenLoaded: isChildrenLoaded ?? this.isChildrenLoaded,
      isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
    );
  }
}

