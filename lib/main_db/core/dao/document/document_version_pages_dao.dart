import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/document/document_version_pages.dart';

part 'document_version_pages_dao.g.dart';

@DriftAccessor(tables: [DocumentVersionPages])
class DocumentVersionPagesDao extends DatabaseAccessor<MainStore>
    with _$DocumentVersionPagesDaoMixin {
  DocumentVersionPagesDao(super.db);

  Future<void> insertDocumentVersionPage(
      DocumentVersionPagesCompanion companion) {
    return into(documentVersionPages).insert(companion);
  }

  // Version pages are mostly immutable, but we keep the method for specific fields if needed.
  // Note: document_version_pages has a preventUpdate trigger in Drift file.
  Future<int> updateDocumentVersionPageById(
    String id,
    DocumentVersionPagesCompanion companion,
  ) {
    return (update(documentVersionPages)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<DocumentVersionPagesData?> getDocumentVersionPageById(String id) {
    return (select(documentVersionPages)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DocumentVersionPagesData>> getPagesByVersionId(String versionId) {
    return (select(documentVersionPages)
          ..where((t) => t.versionId.equals(versionId))
          ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]))
        .get();
  }

  Future<DocumentVersionPagesData?> getPrimaryPageByVersionId(String versionId) {
    return (select(documentVersionPages)
          ..where((t) => t.versionId.equals(versionId) & t.isPrimary.equals(true)))
        .getSingleOrNull();
  }

  Future<int> deleteDocumentVersionPageById(String id) {
    return (delete(documentVersionPages)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deletePagesByVersionId(String versionId) {
    return (delete(documentVersionPages)
          ..where((t) => t.versionId.equals(versionId)))
        .go();
  }
}
