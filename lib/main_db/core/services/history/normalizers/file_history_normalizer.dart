import 'package:hoplixi/main_db/core/repositories/base/file_repository.dart';

import '../../../daos/daos.dart';
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
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final historyList = await fileHistoryDao.getFileHistoryByHistoryIds([historyId]);
    if (historyList.isEmpty) return null;

    final history = historyList.first;
    if (history.metadataHistoryId == null) {
      return FileHistoryPayload(
        metadataHistoryId: null,
      );
    }

    final metaHistory = await fileMetadataHistoryDao.getFileMetadataHistoryById(history.metadataHistoryId!);
    if (metaHistory == null) {
      return FileHistoryPayload(
        metadataHistoryId: history.metadataHistoryId,
      );
    }

    return FileHistoryPayload(
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
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await fileRepository.getViewById(itemId);
    if (view == null) return null;

    final metadata = view.metadata;

    return FileHistoryPayload(
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
    );
  }
}
