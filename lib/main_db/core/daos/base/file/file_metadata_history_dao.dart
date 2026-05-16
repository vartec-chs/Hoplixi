import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

part 'file_metadata_history_dao.g.dart';

@DriftAccessor(tables: [FileMetadataHistory])
class FileMetadataHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileMetadataHistoryDaoMixin {
  FileMetadataHistoryDao(super.db);

  Future<void> insertFileMetadataHistory(
    FileMetadataHistoryCompanion companion,
  ) {
    return into(fileMetadataHistory).insert(companion);
  }

  Future<FileMetadataHistoryData?> getFileMetadataHistoryById(String id) {
    return (select(fileMetadataHistory)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<FileMetadataHistoryData>> getFileMetadataHistoryByHistoryId(
    String historyId,
  ) {
    return (select(fileMetadataHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .get();
  }

  Future<List<FileMetadataHistoryData>> getFileMetadataHistoryByOwner({
    required FileMetadataHistoryOwnerKind ownerKind,
    required String? ownerId,
  }) {
    return (select(fileMetadataHistory)
          ..where((tbl) {
            final kindMatch = tbl.ownerKind.equalsValue(ownerKind);
            final idMatch =
                ownerId == null ? tbl.ownerId.isNull() : tbl.ownerId.equals(ownerId);
            return kindMatch & idMatch;
          }))
        .get();
  }

  Future<int> deleteFileMetadataHistoryById(String id) {
    return (delete(fileMetadataHistory)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteFileMetadataHistoryByHistoryId(String historyId) {
    return (delete(fileMetadataHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<FileMetadataHistoryData>> getFileHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(fileMetadataHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, FileHistoryCardDataDto>> getFileHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasFilePathExpr = fileMetadataHistory.filePath.isNotNull();
    final query = selectOnly(fileMetadataHistory)
      ..addColumns([
        fileMetadataHistory.historyId,
        fileMetadataHistory.fileName,
        fileMetadataHistory.fileExtension,
        fileMetadataHistory.mimeType,
        fileMetadataHistory.fileSize,
        fileMetadataHistory.sha256,
        fileMetadataHistory.availabilityStatus,
        fileMetadataHistory.integrityStatus,
        fileMetadataHistory.missingDetectedAt,
        fileMetadataHistory.deletedAt,
        fileMetadataHistory.lastIntegrityCheckAt,
        fileMetadataHistory.snapshotCreatedAt,
        hasFilePathExpr,
      ])
      ..where(fileMetadataHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(fileMetadataHistory.historyId)!: FileHistoryCardDataDto(
          fileName: row.read(fileMetadataHistory.fileName),
          fileExtension: row.read(fileMetadataHistory.fileExtension),
          mimeType: row.read(fileMetadataHistory.mimeType),
          fileSize: row.read(fileMetadataHistory.fileSize),
          sha256: row.read(fileMetadataHistory.sha256),
          availabilityStatus: row.readWithConverter<FileAvailabilityStatus?, String>(fileMetadataHistory.availabilityStatus),
          integrityStatus: row.readWithConverter<FileIntegrityStatus?, String>(fileMetadataHistory.integrityStatus),
          missingDetectedAt: row.read(fileMetadataHistory.missingDetectedAt),
          deletedAt: row.read(fileMetadataHistory.deletedAt),
          lastIntegrityCheckAt: row.read(fileMetadataHistory.lastIntegrityCheckAt),
          snapshotCreatedAt: row.read(fileMetadataHistory.snapshotCreatedAt),
          hasFilePath: row.read(hasFilePathExpr) ?? false,
        ),
    };
  }

  Future<String?> getFilePathByHistoryId(String historyId) async {
    final row = await (selectOnly(fileMetadataHistory)
          ..addColumns([fileMetadataHistory.filePath])
          ..where(fileMetadataHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(fileMetadataHistory.filePath);
  }

}
