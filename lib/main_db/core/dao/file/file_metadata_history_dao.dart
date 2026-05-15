import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/file/file_metadata_history.dart';

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
}
