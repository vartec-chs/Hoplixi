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

  Future<DocumentVersionsData?> getVersionById(String versionId) {
    return (select(
      documentVersions,
    )..where((t) => t.id.equals(versionId))).getSingleOrNull();
  }

  Future<List<DocumentVersionsData>> getVersionsByDocumentId(
    String documentId, {
    int? limit,
    int? offset,
  }) {
    final query = select(documentVersions)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm(expression: t.versionNumber)]);
      
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    return query.get();
  }

  Future<int?> getMaxVersionNumber(String documentId) async {
    final query = selectOnly(documentVersions)
      ..addColumns([documentVersions.versionNumber.max()])
      ..where(documentVersions.documentId.equals(documentId));
    final result = await query
        .map((row) => row.read(documentVersions.versionNumber.max()))
        .getSingleOrNull();
    return result;
  }

  Future<bool> existsVersionForDocument({
    required String documentId,
    required String versionId,
  }) async {
    final query = selectOnly(documentVersions)
      ..where(documentVersions.id.equals(versionId) & documentVersions.documentId.equals(documentId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> deleteVersionById(String versionId) {
    return (delete(documentVersions)..where((t) => t.id.equals(versionId))).go();
  }
}
