import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_pages_tables.dart';

part 'document_version_pages_dao.g.dart';

@DriftAccessor(tables: [DocumentVersionPages])
class DocumentVersionPagesDao extends DatabaseAccessor<MainStore>
    with _$DocumentVersionPagesDaoMixin {
  DocumentVersionPagesDao(super.db);

  Future<void> insertVersionPage(DocumentVersionPagesCompanion companion) {
    return into(documentVersionPages).insert(companion);
  }

  Future<void> insertVersionPagesBatch(
    List<DocumentVersionPagesCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(documentVersionPages, companions);
    });
  }

  Future<List<DocumentVersionPagesData>> getPagesByVersionId(String versionId) {
    return (select(documentVersionPages)
          ..where((t) => t.versionId.equals(versionId))
          ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]))
        .get();
  }

  Future<List<DocumentVersionPagesData>> getPagesByPageId(String pageId) {
    return (select(documentVersionPages)..where((t) => t.pageId.equals(pageId)))
        .get();
  }

  Future<DocumentVersionPagesData?> getVersionPage({
    required String versionId,
    required String pageId,
  }) {
    return (select(documentVersionPages)..where(
          (t) => t.versionId.equals(versionId) & t.pageId.equals(pageId),
        ))
        .getSingleOrNull();
  }

  Future<DocumentVersionPagesData?> getPrimaryPageByVersionId(
    String versionId,
  ) {
    return (select(documentVersionPages)..where(
          (t) => t.versionId.equals(versionId) & t.isPrimary.equals(true),
        ))
        .getSingleOrNull();
  }

  Future<int> deletePagesByVersionId(String versionId) {
    return (delete(
      documentVersionPages,
    )..where((t) => t.versionId.equals(versionId))).go();
  }
}
