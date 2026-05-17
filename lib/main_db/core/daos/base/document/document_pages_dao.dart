import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_pages_tables.dart';

part 'document_pages_dao.g.dart';

@DriftAccessor(tables: [DocumentPages])
class DocumentPagesDao extends DatabaseAccessor<MainStore>
    with _$DocumentPagesDaoMixin {
  DocumentPagesDao(super.db);

  Future<DocumentPagesData?> getPageById(String pageId) {
    return (select(
      documentPages,
    )..where((t) => t.id.equals(pageId))).getSingleOrNull();
  }

  Future<List<DocumentPagesData>> getPagesByDocumentId(String documentId) {
    return (select(
      documentPages,
    )..where((t) => t.documentId.equals(documentId))).get();
  }

  Future<void> insertDocumentPage(DocumentPagesCompanion companion) {
    return into(documentPages).insert(companion);
  }

  Future<String> createDocumentPage({
    required String documentId,
    String? id,
  }) async {
    final pageId = id ?? const Uuid().v4();
    await into(documentPages).insert(
      DocumentPagesCompanion.insert(
        id: Value(pageId),
        documentId: documentId,
      ),
    );
    return pageId;
  }

  Future<int> updateCurrentVersionPage({
    required String pageId,
    required String? versionPageId,
  }) {
    return (update(documentPages)..where((t) => t.id.equals(pageId))).write(
      DocumentPagesCompanion(currentVersionPageId: Value(versionPageId)),
    );
  }

  Future<void> updateCurrentVersionPagesBatch(
    Map<String, String?> pageIdToVersionPageId,
  ) async {
    await batch((batch) {
      for (final entry in pageIdToVersionPageId.entries) {
        batch.update(
          documentPages,
          DocumentPagesCompanion(currentVersionPageId: Value(entry.value)),
          where: (t) => t.id.equals(entry.key),
        );
      }
    });
  }

  Future<int> deletePagesByDocumentId(String documentId) {
    return (delete(
      documentPages,
    )..where((t) => t.documentId.equals(documentId))).go();
  }
}
