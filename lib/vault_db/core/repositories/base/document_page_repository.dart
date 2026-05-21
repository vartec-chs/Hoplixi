import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';

class DocumentPageRepository {
  final VaultDB db;

  DocumentPageRepository(this.db);

  AsyncDbResult<String> createPage(String documentId) {
    return ResultUtils.tryCatchAsync(
      () => db.documentPagesDao.createDocumentPage(documentId: documentId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании страницы документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<DocumentPagesData>> getPageById(String id) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.documentPagesDao.getPageById(id);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении страницы документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<DocumentPagesData>> getPagesByDocumentId(
    String documentId,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.documentPagesDao.getPagesByDocumentId(documentId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении страниц документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateCurrentVersionPagesBatch(
    Map<String, String> pageIdToVersionPageId,
  ) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentPagesDao.updateCurrentVersionPagesBatch(
          pageIdToVersionPageId,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при массовом обновлении страниц документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePage(String id) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentPagesDao.deletePageById(id);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении страницы документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePagesByDocumentId(String documentId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.documentPagesDao.deletePagesByDocumentId(documentId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении страниц документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}

