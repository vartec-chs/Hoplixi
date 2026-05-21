import 'package:hoplixi/vault_db/core/vault_db.dart';

class DocumentVersionRepository {
  final VaultDB db;

  DocumentVersionRepository(this.db);

  Future<void> createVersion(DocumentVersionsCompanion companion) {
    return db.documentVersionsDao.insertDocumentVersion(companion);
  }

  Future<DocumentVersionsData?> getVersionById(String versionId) {
    return db.documentVersionsDao.getVersionById(versionId);
  }

  Future<List<DocumentVersionsData>> getVersionsByDocumentId(
    String documentId, {
    int? limit,
    int? offset,
  }) {
    return db.documentVersionsDao.getVersionsByDocumentId(
      documentId,
      limit: limit,
      offset: offset,
    );
  }

  Future<int?> getMaxVersionNumber(String documentId) {
    return db.documentVersionsDao.getMaxVersionNumber(documentId);
  }

  Future<void> deleteVersion(String versionId) {
    return db.documentVersionsDao.deleteVersionById(versionId);
  }

  // Version Pages
  Future<void> createVersionPage(DocumentVersionPagesCompanion companion) {
    return db.documentVersionPagesDao.insertVersionPage(companion);
  }

  Future<List<DocumentVersionPagesData>> getPagesByVersionId(String versionId) {
    return db.documentVersionPagesDao.getPagesByVersionId(versionId);
  }

  Future<void> deletePagesByVersionId(String versionId) {
    return db.documentVersionPagesDao.deletePagesByVersionId(versionId);
  }
}
