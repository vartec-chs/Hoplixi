import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/system/categories/category_revisions.dart';

part 'category_revisions_dao.g.dart';

@DriftAccessor(tables: [CategoryRevisions])
class CategoryRevisionsDao extends DatabaseAccessor<VaultDB>
    with _$CategoryRevisionsDaoMixin {
  CategoryRevisionsDao(super.db);

  Future<int> insertCategoryRevision(CategoryRevisionsCompanion companion) {
    return into(categoryRevisions).insert(companion);
  }

  Future<CategoryRevisionData?> getCategoryRevisionById(String id) {
    return (select(categoryRevisions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CategoryRevisionData>> getCategoryRevisionsByOriginalCategoryId(
    String categoryOriginalId,
  ) {
    return (select(categoryRevisions)
          ..where((t) => t.categoryOriginalId.equals(categoryOriginalId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.snapshotCreatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<int> deleteCategoryRevisionById(String id) {
    return (delete(categoryRevisions)..where((t) => t.id.equals(id))).go();
  }
}
