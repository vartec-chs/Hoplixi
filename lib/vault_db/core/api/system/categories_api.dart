import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/category_repository.dart';

/// Public API boundary for category queries and commands.
class CategoriesApi {
  const CategoriesApi({required this._repository});

  final CategoryRepository _repository;

  AsyncDBResult<String> create(CreateCategoryDto dto) {
    return _repository.createCategory(dto);
  }

  AsyncDBResult<Unit> update(PatchCategoryDto dto) {
    return _repository.updateCategory(dto);
  }

  AsyncDBResult<Unit> delete(String categoryId) {
    return _repository.deleteCategory(categoryId);
  }

  AsyncDBResult<Optional<CategoryViewDto>> get(String categoryId) {
    return _repository.getCategory(categoryId);
  }

  AsyncDBResult<List<CategoryCardDto>> list() {
    return _repository.getAllCategories();
  }

  AsyncDBResult<List<CategoryTreeNodeDto>> tree() {
    return _repository.getCategoryTree();
  }

  AsyncDBResult<bool> exists(String categoryId) {
    return _repository.existsCategory(categoryId);
  }
}
