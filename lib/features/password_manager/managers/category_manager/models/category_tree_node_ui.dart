import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';

class CategoryTreeNodeUi {
  const CategoryTreeNodeUi({
    required this.category,
    this.children = const [],
    this.isExpanded = false,
    this.isLoadingChildren = false,
    this.isChildrenLoaded = false,
  });

  final CategoryCardDto category;
  final List<CategoryTreeNodeUi> children;
  final bool isExpanded;
  final bool isLoadingChildren;
  final bool isChildrenLoaded;

  bool get hasChildren => children.isNotEmpty;

  CategoryTreeNodeUi copyWith({
    CategoryCardDto? category,
    List<CategoryTreeNodeUi>? children,
    bool? isExpanded,
    bool? isLoadingChildren,
    bool? isChildrenLoaded,
  }) {
    return CategoryTreeNodeUi(
      category: category ?? this.category,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
      isChildrenLoaded: isChildrenLoaded ?? this.isChildrenLoaded,
    );
  }

  factory CategoryTreeNodeUi.fromDto(CategoryTreeNodeDto dto) {
    return CategoryTreeNodeUi(
      category: dto.category,
      children: dto.children.map(CategoryTreeNodeUi.fromDto).toList(),
      isChildrenLoaded: true,
    );
  }
}
