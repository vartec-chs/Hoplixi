import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/document_dto.dart';
import '../models/mappers/document_mapper.dart';

class DocumentVersionRepository {
  final MainStore db;

  DocumentVersionRepository(this.db);

  Future<String> createVersion(CreateDocumentVersionDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final versionId = const Uuid().v4();

      // 1. Определяем номер версии
      final nextNumber = await db.documentVersionsDao.getNextVersionNumber(dto.documentId);

      // 2. Вставляем версию
      await db.documentVersionsDao.insertDocumentVersion(
        DocumentVersionsCompanion.insert(
          id: Value(versionId),
          documentId: dto.documentId,
          historyId: Value(dto.version.historyId),
          versionNumber: nextNumber,
          documentType: Value(dto.version.documentType),
          documentTypeOther: Value(dto.version.documentTypeOther),
          aggregateSha256Hash: Value(dto.version.aggregateSha256Hash),
          pageCount: Value(dto.pages.length),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      // 3. Вставляем страницы версии
      for (final pageDto in dto.pages) {
        await db.documentVersionPagesDao.insertDocumentVersionPage(
          DocumentVersionPagesCompanion.insert(
            versionId: versionId,
            metadataHistoryId: Value(pageDto.metadataHistoryId),
            pageNumber: pageDto.pageNumber,
            pageSha256Hash: Value(pageDto.pageSha256Hash),
            isPrimary: Value(pageDto.isPrimary),
            createdAt: Value(now),
          ),
        );
      }

      // 4. Обновляем текущую версию в document_items, если нужно
      if (dto.setAsCurrent) {
        await db.documentItemsDao.setCurrentVersionId(
          itemId: dto.documentId,
          currentVersionId: versionId,
        );
      }

      // 5. Обновляем modifiedAt в vault_items
      await (db.update(db.vaultItems)..where((t) => t.id.equals(dto.documentId)))
          .write(VaultItemsCompanion(modifiedAt: Value(now)));

      return versionId;
    });
  }

  Future<DocumentVersionViewDto?> getVersionById(String versionId) async {
    final data = await db.documentVersionsDao.getDocumentVersionById(versionId);
    return data?.toDocumentVersionViewDto();
  }

  Future<List<DocumentVersionCardDto>> getVersionsByDocumentId(
      String documentId) async {
    final list = await db.documentVersionsDao.getVersionsByDocumentId(documentId);
    return list.map((e) => e.toDocumentVersionCardDto()).toList();
  }

  Future<DocumentVersionViewDto?> getCurrentVersionByDocumentId(
      String documentId) async {
    final item = await db.documentItemsDao.getDocumentItemByItemId(documentId);
    if (item?.currentVersionId == null) return null;
    return getVersionById(item!.currentVersionId!);
  }

  Future<void> setCurrentVersion({
    required String documentId,
    required String versionId,
  }) async {
    await db.transaction(() async {
      await db.documentItemsDao.setCurrentVersionId(
        itemId: documentId,
        currentVersionId: versionId,
      );
      await (db.update(db.vaultItems)..where((t) => t.id.equals(documentId)))
          .write(VaultItemsCompanion(modifiedAt: Value(DateTime.now())));
    });
  }

  Future<void> deleteVersion(String versionId) async {
    await db.documentVersionsDao.deleteDocumentVersionById(versionId);
  }
}
