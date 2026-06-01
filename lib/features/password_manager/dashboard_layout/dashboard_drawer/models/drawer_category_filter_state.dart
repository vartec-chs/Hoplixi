import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';

class DrawerCategoryTreeNode {
  const DrawerCategoryTreeNode({
    required this.category,
    this.children = const [],
    this.isExpanded = false,
    this.isChildrenLoaded = true,
    this.isLoadingChildren = false,
  });

  final CategoryCardDto category;
  final List<DrawerCategoryTreeNode> children;
  final bool isExpanded;
  final bool isChildrenLoaded;
  final bool isLoadingChildren;

  bool get hasChildren => children.isNotEmpty;

  DrawerCategoryTreeNode copyWith({
    CategoryCardDto? category,
    List<DrawerCategoryTreeNode>? children,
    bool? isExpanded,
    bool? isChildrenLoaded,
    bool? isLoadingChildren,
  }) {
    return DrawerCategoryTreeNode(
      category: category ?? this.category,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isChildrenLoaded: isChildrenLoaded ?? this.isChildrenLoaded,
      isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
    );
  }
}

class DrawerCategoryFilterState {
  const DrawerCategoryFilterState({
    this.roots = const [],
    this.searchResults = const [],
    this.selectedIds = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.offset = 0,
    this.searchQuery = '',
  });

  final List<DrawerCategoryTreeNode> roots;
  final List<CategoryCardDto> searchResults;
  final List<String> selectedIds;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String searchQuery;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  DrawerCategoryFilterState copyWith({
    List<DrawerCategoryTreeNode>? roots,
    List<CategoryCardDto>? searchResults,
    List<String>? selectedIds,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? searchQuery,
  }) {
    return DrawerCategoryFilterState(
      roots: roots ?? this.roots,
      searchResults: searchResults ?? this.searchResults,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
