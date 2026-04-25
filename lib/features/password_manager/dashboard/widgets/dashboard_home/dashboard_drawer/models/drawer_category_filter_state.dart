import 'package:hoplixi/db_core/old/models/dto/category_dto.dart';
import 'package:hoplixi/db_core/old/models/dto/category_tree_node.dart';

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

  final List<CategoryTreeNode> roots;
  final List<CategoryCardDto> searchResults;
  final List<String> selectedIds;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String searchQuery;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  DrawerCategoryFilterState copyWith({
    List<CategoryTreeNode>? roots,
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
