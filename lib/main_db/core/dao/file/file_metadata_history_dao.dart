import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/file/file_metadata_history.dart';

part 'file_metadata_history_dao.g.dart';

@DriftAccessor(tables: [FileMetadataHistory])
class FileMetadataHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileMetadataHistoryDaoMixin {
  FileMetadataHistoryDao(super.db);

  Future<void> insertFileMetadataHistory(
      FileMetadataHistoryCompanion companion) {
    return into(fileMetadataHistory).insert(companion);
  }

  Future<FileMetadataHistoryData?> getFileMetadataHistoryById(String id) {
    return (select(fileMetadataHistory)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<FileMetadataHistoryData>> getByHistoryId(String historyId) {
    return (select(fileMetadataHistory)
          ..where((t) => t.historyId.equals(historyId)))
        .get();
  }

  Future<List<FileMetadataHistoryData>> getByOwner({
    required FileMetadataHistoryOwnerKind ownerKind,
    required String? ownerId,
  }) {
    return (select(fileMetadataHistory)
          ..where((t) {
            final kindMatch = t.ownerKind.equals(ownerKind.name);
            final idMatch = ownerId == null ? t.ownerId.isNull() : t.ownerId.equals(ownerId);
            return kindMatch & idMatch;
          }))
        .get();
  }

  Future<int> deleteFileMetadataHistoryById(String id) {
    return (delete(fileMetadataHistory)..where((t) => t.id.equals(id))).go();
  }
}
