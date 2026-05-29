import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class FileSnapshotHandler implements VaultSnapshotTypeHandler {
  FileSnapshotHandler({
    required this.fileHistoryDao,
    required this.fileMetadataHistoryDao,
  });

  final FileHistoryDao fileHistoryDao;
  final FileMetadataHistoryDao fileMetadataHistoryDao;

  @override
  VaultItemType get type => VaultItemType.file;

  @override
  AsyncDBResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return tryCatchAsync(
      () async {
        if (view is! FileViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for File snapshot',
            entity: 'file',
          );
        }

        String? metadataHistoryId;
        if (view.metadata != null) {
          final m = view.metadata!;
          metadataHistoryId = const Uuid().v4();
          await fileMetadataHistoryDao.insertFileMetadataHistory(
            FileMetadataHistoryCompanion.insert(
              id: Value(metadataHistoryId),
              historyId: Value(historyId),
              ownerKind: const Value(
                FileMetadataHistoryOwnerKind.fileItemHistory,
              ),
              ownerId: Value(historyId),
              metadataId: Value(m.id),
              fileName: m.fileName,
              fileExtension: Value(m.fileExtension),
              filePath: Value(includeSecrets ? m.filePath : null),
              mimeType: m.mimeType,
              fileSize: m.fileSize,
              sha256: Value(m.sha256),
              availabilityStatus: Value(m.availabilityStatus),
              integrityStatus: Value(m.integrityStatus),
              missingDetectedAt: Value(m.missingDetectedAt),
              deletedAt: Value(m.deletedAt),
              lastIntegrityCheckAt: Value(m.lastIntegrityCheckAt),
            ),
          );
        }

        await fileHistoryDao.insertFileHistory(
          FileHistoryCompanion.insert(
            historyId: historyId,
            metadataHistoryId: Value(metadataHistoryId),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
