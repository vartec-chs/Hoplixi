import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/system/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<MainStore> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<int> insertCategory(CategoriesCompanion companion) {
    return into(categories).insert(companion);
  }

  Future<int> updateCategoryById(String id, CategoriesCompanion companion) {
    return (update(categories)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<CategoriesData?> getCategoryById(String id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoriesData>> getAllCategories() {
    return select(categories).get();
  }

  Future<List<CategoriesData>> getRootCategories() {
    return (select(categories)..where((t) => t.parentId.isNull())).get();
  }

  Future<List<CategoriesData>> getChildren(String parentId) {
    return (select(categories)..where((t) => t.parentId.equals(parentId))).get();
  }

  Future<bool> existsCategory(String id) async {
    final query = selectOnly(categories)..addColumns([categories.id])..where(categories.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> deleteCategoryById(String id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  Future<List<CategoriesData>> getCategoriesByType(CategoryType type) {
    return (select(categories)..where((t) => t.type.equals(type.name))).get();
  }

  Future<List<CategoriesData>> getChildrenOrdered(String? parentId) {
    final query = select(categories);
    if (parentId == null) {
      query.where((t) => t.parentId.isNull());
    } else {
      query.where((t) => t.parentId.equals(parentId));
    }
    // В таблице categories нет поля sortOrder в Drift файле, 
    // но инструкция просила getChildrenOrdered если есть sortOrder.
    // Сортируем по имени по умолчанию.
    query.orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.get();
  }
}
