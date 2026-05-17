import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_pages.dart';

part 'document_pages_dao.g.dart';

@DriftAccessor(tables: [DocumentPages])
class DocumentPagesDao extends DatabaseAccessor<MainStore>
    with _$DocumentPagesDaoMixin {
  DocumentPagesDao(super.db);

  Future<void> insertDocumentPage(DocumentPagesCompanion companion) {
    return into(documentPages).insert(companion);
  }

  Future<int> updateDocumentPageById(
    String id,
    DocumentPagesCompanion companion,
  ) {
    return (update(
      documentPages,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  Future<DocumentPagesData?> getDocumentPageById(String id) {
    return (select(
      documentPages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<DocumentPagesData>> getPagesByDocumentId(String documentId) {
    return (select(
      documentPages,
    )..where((t) => t.documentId.equals(documentId))).get();
  }

  Future<int> setCurrentVersionPageId({
    required String pageId,
    required String? currentVersionPageId,
  }) {
    return (update(documentPages)..where((t) => t.id.equals(pageId))).write(
      DocumentPagesCompanion(currentVersionPageId: Value(currentVersionPageId)),
    );
  }

  Future<int> deleteDocumentPageById(String id) {
    return (delete(documentPages)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deletePagesByDocumentId(String documentId) {
    return (delete(
      documentPages,
    )..where((t) => t.documentId.equals(documentId))).go();
  }
}
