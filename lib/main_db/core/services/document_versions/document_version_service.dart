import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../daos/base/document/document_items_dao.dart';
import '../../daos/base/document/document_pages_dao.dart';
import '../../daos/base/document/document_version_pages_dao.dart';
import '../../daos/base/document/document_versions_dao.dart';
import '../../daos/base/vault_items/vault_items_dao.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/dto/document_version_dto.dart';
import 'document_version_hash_service.dart';
import 'document_version_policy_service.dart';

class DocumentVersionService {
  DocumentVersionService({
    required this.db,
    required this.hashService,
    required this.policyService,
  }) : documentItemsDao = db.documentItemsDao,
       documentPagesDao = db.documentPagesDao,
       documentVersionsDao = db.documentVersionsDao,
       documentVersionPagesDao = db.documentVersionPagesDao,
       vaultItemsDao = db.vaultItemsDao;

  final MainStore db;
  final DocumentItemsDao documentItemsDao;
  final DocumentPagesDao documentPagesDao;
  final DocumentVersionsDao documentVersionsDao;
  final DocumentVersionPagesDao documentVersionPagesDao;
  final VaultItemsDao vaultItemsDao;
  final DocumentVersionHashService hashService;
  final DocumentVersionPolicyService policyService;

  Future<DbResult<DocumentVersionViewDto>> createVersion(
    CreateDocumentVersionDto dto,
  ) async {
    final validationResult = policyService.validateCreateVersion(dto);
    if (validationResult.isError()) {
      return Failure(validationResult.exceptionOrNull()!);
    }

    try {
      return await db.transaction(() async {
        final vaultItem = await vaultItemsDao.getVaultItemById(dto.documentId);
        if (vaultItem == null || vaultItem.type.name != 'document') {
          return const Failure(
            DBCoreError.notFound(
              entity: 'vault_items',
              id: '', // Used dto.documentId but not accessible in const, so we will use non-const
            ),
          );
        }

        final maxVersion =
            await documentVersionsDao.getMaxVersionNumber(dto.documentId) ?? 0;
        final nextVersionNumber = maxVersion + 1;

        final aggregateHash =
            dto.aggregateSha256Hash ??
            hashService.aggregatePageHashes(dto.pages);

        final versionId = const Uuid().v4();

        await documentVersionsDao.insertDocumentVersion(
          DocumentVersionsCompanion.insert(
            id: Value(versionId),
            documentId: dto.documentId,
            historyId: Value(dto.historyId),
            versionNumber: nextVersionNumber,
            documentType: Value(dto.documentType),
            documentTypeOther: Value(dto.documentTypeOther),
            aggregateSha256Hash: Value(aggregateHash),
            pageCount: Value(dto.pages.length),
          ),
        );

        bool hasPrimary = dto.pages.any((p) => p.isPrimary);
        int minPageNumber = dto.pages
            .map((p) => p.pageNumber)
            .reduce((a, b) => a < b ? a : b);

        final createdVersionPages = <DocumentVersionPagesData>[];

        for (final pageDto in dto.pages) {
          String pageId;
          if (pageDto.pageId != null) {
            final page = await documentPagesDao.getPageById(pageDto.pageId!);
            if (page == null || page.documentId != dto.documentId) {
              return Failure(
                DBCoreError.notFound(
                  entity: 'document_pages',
                  id: pageDto.pageId!,
                  message: 'Page not found or belongs to a different document.',
                ),
              );
            }
            pageId = page.id;
          } else {
            pageId = await documentPagesDao.createDocumentPage(
              documentId: dto.documentId,
            );
          }

          final isPrimary = !hasPrimary && pageDto.pageNumber == minPageNumber
              ? true
              : pageDto.isPrimary;

          final versionPageId = const Uuid().v4();
          final companion = DocumentVersionPagesCompanion.insert(
            id: Value(versionPageId),
            versionId: versionId,
            pageId: pageId,
            metadataHistoryId: Value(pageDto.metadataHistoryId),
            pageNumber: pageDto.pageNumber,
            pageSha256Hash: Value(pageDto.pageSha256Hash),
            isPrimary: Value(isPrimary),
          );

          await documentVersionPagesDao.insertVersionPage(companion);

          createdVersionPages.add(
            DocumentVersionPagesData(
              id: versionPageId,
              versionId: versionId,
              pageId: pageId,
              metadataHistoryId: pageDto.metadataHistoryId,
              pageNumber: pageDto.pageNumber,
              pageSha256Hash: pageDto.pageSha256Hash,
              isPrimary: isPrimary,
              createdAt:
                  DateTime.now(), // Will be overridden by getVersionDetail
            ),
          );
        }

        if (dto.activate) {
          await documentItemsDao.upsertDocumentItem(
            itemId: dto.documentId,
            currentVersionId: versionId,
          );

          final pageIdToVersionPageId = {
            for (final vp in createdVersionPages) vp.pageId: vp.id,
          };

          await documentPagesDao.updateCurrentVersionPagesBatch(
            pageIdToVersionPageId,
          );
        }

        return getVersionDetail(
          versionId: versionId,
        ).then((res) => Success(res.getOrNull()!));
      });
    } catch (e, st) {
      if (e is DBCoreError) return Failure(e);
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  Future<DbResult<Unit>> activateVersion({
    required String documentId,
    required String versionId,
  }) async {
    try {
      return await db.transaction(() async {
        final version = await documentVersionsDao.getVersionById(versionId);
        if (version == null || version.documentId != documentId) {
          return Failure(
            DBCoreError.notFound(
              entity: 'document_versions',
              id: versionId,
              message: 'Version not found or belongs to a different document',
            ),
          );
        }

        final versionPages = await documentVersionPagesDao.getPagesByVersionId(
          versionId,
        );

        await documentItemsDao.upsertDocumentItem(
          itemId: documentId,
          currentVersionId: versionId,
        );

        final pageIdToVersionPageId = {
          for (final vp in versionPages) vp.pageId: vp.id,
        };

        await documentPagesDao.updateCurrentVersionPagesBatch(
          pageIdToVersionPageId,
        );

        return const Success(unit);
      });
    } catch (e, st) {
      if (e is DBCoreError) return Failure(e);
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  Future<DbResult<List<DocumentVersionCardDto>>> getVersions({
    required String documentId,
    int? limit,
    int? offset,
  }) async {
    try {
      final versions = await documentVersionsDao.getVersionsByDocumentId(
        documentId,
        limit: limit,
        offset: offset,
      );

      final currentItem = await documentItemsDao.getDocumentItemByItemId(
        documentId,
      );
      final currentVersionId = currentItem?.currentVersionId;

      final result = versions
          .map(
            (v) => DocumentVersionCardDto(
              id: v.id,
              documentId: v.documentId,
              historyId: v.historyId,
              versionNumber: v.versionNumber,
              documentType: v.documentType,
              documentTypeOther: v.documentTypeOther,
              aggregateSha256Hash: v.aggregateSha256Hash,
              pageCount: v.pageCount,
              createdAt: v.createdAt,
              modifiedAt: v.modifiedAt,
              isCurrent: v.id == currentVersionId,
            ),
          )
          .toList();

      return Success(result);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  Future<DbResult<DocumentVersionViewDto>> getVersionDetail({
    required String versionId,
  }) async {
    try {
      final version = await documentVersionsDao.getVersionById(versionId);
      if (version == null) {
        return Failure(
          DBCoreError.notFound(entity: 'document_versions', id: versionId),
        );
      }

      final pages = await documentVersionPagesDao.getPagesByVersionId(
        versionId,
      );
      final documentItem = await documentItemsDao.getDocumentItemByItemId(
        version.documentId,
      );

      final isCurrent = documentItem?.currentVersionId == version.id;

      final pageDtos = pages
          .map(
            (p) => DocumentVersionPageViewDto(
              id: p.id,
              versionId: p.versionId,
              pageId: p.pageId,
              metadataHistoryId: p.metadataHistoryId,
              pageNumber: p.pageNumber,
              pageSha256Hash: p.pageSha256Hash,
              isPrimary: p.isPrimary,
              createdAt: p.createdAt,
            ),
          )
          .toList();

      return Success(
        DocumentVersionViewDto(
          id: version.id,
          documentId: version.documentId,
          historyId: version.historyId,
          versionNumber: version.versionNumber,
          documentType: version.documentType,
          documentTypeOther: version.documentTypeOther,
          aggregateSha256Hash: version.aggregateSha256Hash,
          pageCount: version.pageCount,
          createdAt: version.createdAt,
          modifiedAt: version.modifiedAt,
          pages: pageDtos,
          isCurrent: isCurrent,
        ),
      );
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  Future<DbResult<DocumentVersionViewDto>> getCurrentVersion({
    required String documentId,
  }) async {
    try {
      final documentItem = await documentItemsDao.getDocumentItemByItemId(
        documentId,
      );
      final currentVersionId = documentItem?.currentVersionId;
      if (currentVersionId == null) {
        return Failure(
          DBCoreError.notFound(entity: 'document_items', id: documentId),
        );
      }

      return getVersionDetail(versionId: currentVersionId);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  Future<DbResult<Unit>> deleteVersion({
    required String documentId,
    required String versionId,
  }) async {
    try {
      return await db.transaction(() async {
        final documentItem = await documentItemsDao.getDocumentItemByItemId(
          documentId,
        );
        if (documentItem?.currentVersionId == versionId) {
          return const Failure(
            DBCoreError.conflict(
              code: 'document.version.delete_current_forbidden',
              message: 'Cannot delete the currently active version',
            ),
          );
        }

        final rowsDeleted = await documentVersionsDao.deleteVersionById(
          versionId,
        );
        if (rowsDeleted == 0) {
          return Failure(
            DBCoreError.notFound(entity: 'document_versions', id: versionId),
          );
        }

        return const Success(unit);
      });
    } catch (e, st) {
      if (e is DBCoreError) return Failure(e);
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }
}
