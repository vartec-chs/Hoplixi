import 'package:hoplixi/main_store/models/dto/category_dto.dart';

/// Узел дерева категорий.
class CategoryTreeNode {
  CategoryTreeNode({required this.category, this.children = const []});

  final CategoryCardDto category;
  final List<CategoryTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
}
