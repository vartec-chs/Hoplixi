import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_versions.dart';

part 'document_versions_dao.g.dart';

@DriftAccessor(tables: [DocumentVersions])
class DocumentVersionsDao extends DatabaseAccessor<MainStore>
    with _$DocumentVersionsDaoMixin {
  DocumentVersionsDao(super.db);

  Future<void> insertDocumentVersion(DocumentVersionsCompanion companion) {
    return into(documentVersions).insert(companion);
  }

  Future<int> updateDocumentVersionById(
    String id,
    DocumentVersionsCompanion companion,
  ) {
    return (update(documentVersions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<DocumentVersionsData?> getDocumentVersionById(String id) {
    return (select(documentVersions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DocumentVersionsData>> getVersionsByDocumentId(String documentId) {
    return (select(documentVersions)
          ..where((t) => t.documentId.equals(documentId))
          ..orderBy([(t) => OrderingTerm(expression: t.versionNumber)]))
        .get();
  }

  Future<DocumentVersionsData?> getLatestVersionByDocumentId(String documentId) {
    return (select(documentVersions)
          ..where((t) => t.documentId.equals(documentId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.versionNumber, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DocumentVersionsData?> getVersionByDocumentIdAndNumber({
    required String documentId,
    required int versionNumber,
  }) {
    return (select(documentVersions)
          ..where((t) =>
              t.documentId.equals(documentId) &
              t.versionNumber.equals(versionNumber)))
        .getSingleOrNull();
  }

  Future<int> getNextVersionNumber(String documentId) async {
    final query = selectOnly(documentVersions)
      ..addColumns([documentVersions.versionNumber.max()])
      ..where(documentVersions.documentId.equals(documentId));
    final result = await query.map((row) => row.read(documentVersions.versionNumber.max())).getSingle();
    return (result ?? 0) + 1;
  }

  Future<int> deleteDocumentVersionById(String id) {
    return (delete(documentVersions)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteVersionsByDocumentId(String documentId) {
    return (delete(documentVersions)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }
}
