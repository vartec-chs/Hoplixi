import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';

class DocumentVersionRepository {
  final VaultDB db;

  DocumentVersionRepository(this.db);

  AsyncDbResult<Unit> createVersion(DocumentVersionsCompanion companion) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentVersionsDao.insertDocumentVersion(companion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<DocumentVersionsData>> getVersionById(
    String versionId,
  ) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.documentVersionsDao.getVersionById(versionId);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<DocumentVersionsData>> getVersionsByDocumentId(
    String documentId, {
    int? limit,
    int? offset,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.documentVersionsDao.getVersionsByDocumentId(
        documentId,
        limit: limit,
        offset: offset,
      ),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка версий документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<int>> getMaxVersionNumber(String documentId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.documentVersionsDao.getMaxVersionNumber(
          documentId,
        );
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении максимального номера версии',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteVersion(String versionId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentVersionsDao.deleteVersionById(versionId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  // Version Pages
  AsyncDbResult<Unit> createVersionPage(
    DocumentVersionPagesCompanion companion,
  ) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentVersionPagesDao.insertVersionPage(companion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании страницы версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<DocumentVersionPagesData>> getPagesByVersionId(
    String versionId,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.documentVersionPagesDao.getPagesByVersionId(versionId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении страниц версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePagesByVersionId(String versionId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentVersionPagesDao.deletePagesByVersionId(versionId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении страниц версии документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
