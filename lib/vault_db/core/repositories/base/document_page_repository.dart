import 'package:hoplixi/vault_db/core/vault_db.dart';

class DocumentPageRepository {
  final VaultDB db;

  DocumentPageRepository(this.db);

  Future<String> createPage(String documentId) {
    return db.documentPagesDao.createDocumentPage(documentId: documentId);
  }

  Future<DocumentPagesData?> getPageById(String id) {
    return db.documentPagesDao.getPageById(id);
  }

  Future<List<DocumentPagesData>> getPagesByDocumentId(String documentId) {
    return db.documentPagesDao.getPagesByDocumentId(documentId);
  }

  Future<void> updateCurrentVersionPagesBatch(
    Map<String, String> pageIdToVersionPageId,
  ) {
    return db.documentPagesDao.updateCurrentVersionPagesBatch(
      pageIdToVersionPageId,
    );
  }

  Future<void> deletePage(String id) {
    return db.documentPagesDao.deletePageById(id);
  }

  Future<void> deletePagesByDocumentId(String documentId) {
    return db.documentPagesDao.deletePagesByDocumentId(documentId);
  }
}
