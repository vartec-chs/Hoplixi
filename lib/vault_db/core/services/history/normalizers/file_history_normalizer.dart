import 'package:hoplixi/vault_db/core/repositories/base/file_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/file_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class FileHistoryNormalizer implements VaultHistoryTypeNormalizer {
  FileHistoryNormalizer({
    required this.fileHistoryDao,
    required this.fileMetadataHistoryDao,
    required this.fileRepository,
  });

  final FileHistoryDao fileHistoryDao;
  final FileMetadataHistoryDao fileMetadataHistoryDao;
  final FileRepository fileRepository;

  @override
  VaultItemType get type => VaultItemType.file;

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final historyList = await fileHistoryDao.getFileHistoryByHistoryIds([
          historyId,
        ]);
        if (historyList.isEmpty) return const None();

        final history = historyList.first;
        if (history.metadataHistoryId == null) {
          return const Some(FileHistoryPayload(metadataHistoryId: null));
        }

        final metaHistory = await fileMetadataHistoryDao
            .getFileMetadataHistoryById(history.metadataHistoryId!);
        if (metaHistory == null) {
          return Some(
            FileHistoryPayload(metadataHistoryId: history.metadataHistoryId),
          );
        }

        return Some(
          FileHistoryPayload(
            metadataId: metaHistory.metadataId,
            metadataHistoryId: history.metadataHistoryId,
            fileName: metaHistory.fileName,
            fileExtension: metaHistory.fileExtension,
            filePath: metaHistory.filePath,
            mimeType: metaHistory.mimeType,
            fileSize: metaHistory.fileSize,
            sha256: metaHistory.sha256,
            availabilityStatus: metaHistory.availabilityStatus,
            integrityStatus: metaHistory.integrityStatus,
            missingDetectedAt: metaHistory.missingDetectedAt,
            deletedAt: metaHistory.deletedAt,
            lastIntegrityCheckAt: metaHistory.lastIntegrityCheckAt,
            snapshotCreatedAt: metaHistory.snapshotCreatedAt,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final viewOpt = (await fileRepository.getViewById(itemId)).getOrThrow();
        return viewOpt.fold((view) {
          final metadata = view.metadata;
          return Some(
            FileHistoryPayload(
              metadataId: metadata?.id,
              fileName: metadata?.fileName,
              fileExtension: metadata?.fileExtension,
              filePath: metadata?.filePath,
              mimeType: metadata?.mimeType,
              fileSize: metadata?.fileSize,
              sha256: metadata?.sha256,
              availabilityStatus: metadata?.availabilityStatus,
              integrityStatus: metadata?.integrityStatus,
              missingDetectedAt: metadata?.missingDetectedAt,
              deletedAt: metadata?.deletedAt,
              lastIntegrityCheckAt: metadata?.lastIntegrityCheckAt,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
