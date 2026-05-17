import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/file_history_payload.dart';
import 'vault_history_restore_handler.dart';

class FileHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  FileHistoryRestoreHandler({
    required this.fileItemsDao,
    required this.fileMetadataDao,
  });

  final FileItemsDao fileItemsDao;
  final FileMetadataDao fileMetadataDao;

  @override
  VaultItemType get type => VaultItemType.file;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! FileHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for File restore',
          entity: 'file',
        ),
      );
    }

    String? metadataId = payload.metadataId;
    if (payload.metadataHistoryId != null) {
      if (payload.fileName == null ||
          payload.mimeType == null ||
          payload.fileSize == null) {
        return const Failure(
          DBCoreError.conflict(
            code: 'history.restore.missing_metadata',
            message: 'Нельзя восстановить файл: отсутствуют метаданные',
            entity: 'file',
          ),
        );
      }

      metadataId ??= const Uuid().v4();
      await fileMetadataDao.upsertFileMetadata(
        FileMetadataCompanion(
          id: Value(metadataId),
          fileName: Value(payload.fileName!),
          fileExtension: Value(payload.fileExtension),
          filePath: Value(payload.filePath),
          mimeType: Value(payload.mimeType!),
          fileSize: Value(payload.fileSize!),
          sha256: Value(payload.sha256),
          availabilityStatus: Value(
            payload.availabilityStatus ?? FileAvailabilityStatus.available,
          ),
          integrityStatus: Value(
            payload.integrityStatus ?? FileIntegrityStatus.unknown,
          ),
          missingDetectedAt: Value(payload.missingDetectedAt),
          deletedAt: Value(payload.deletedAt),
          lastIntegrityCheckAt: Value(payload.lastIntegrityCheckAt),
        ),
      );
    }

    await fileItemsDao.upsertFileItem(
      FileItemsCompanion(
        itemId: Value(base.itemId),
        metadataId: Value(metadataId),
      ),
    );

    return const Success(unit);
  }
}
