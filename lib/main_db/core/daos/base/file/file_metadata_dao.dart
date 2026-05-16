import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/file/file_metadata.dart';

part 'file_metadata_dao.g.dart';

@DriftAccessor(tables: [FileMetadata])
class FileMetadataDao extends DatabaseAccessor<MainStore>
    with _$FileMetadataDaoMixin {
  FileMetadataDao(super.db);

  Future<void> insertFileMetadata(FileMetadataCompanion companion) {
    return into(fileMetadata).insert(companion);
  }

  Future<int> updateFileMetadataById(
    String id,
    FileMetadataCompanion companion,
  ) {
    return (update(fileMetadata)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<FileMetadataData?> getFileMetadataById(String id) {
    return (select(fileMetadata)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> existsFileMetadata(String id) async {
    final query = selectOnly(fileMetadata)..where(fileMetadata.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> deleteFileMetadataById(String id) {
    return (delete(fileMetadata)..where((t) => t.id.equals(id))).go();
  }

  Future<List<FileMetadataData>> getByAvailabilityStatus(
    FileAvailabilityStatus status,
  ) {
    return (select(fileMetadata)
          ..where((t) => t.availabilityStatus.equals(status.name)))
        .get();
  }

  Future<List<FileMetadataData>> getByIntegrityStatus(
    FileIntegrityStatus status,
  ) {
    return (select(fileMetadata)
          ..where((t) => t.integrityStatus.equals(status.name)))
        .get();
  }

  Future<int> updateAvailabilityStatus({
    required String id,
    required FileAvailabilityStatus availabilityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
  }) {
    return (update(fileMetadata)..where((t) => t.id.equals(id))).write(
      FileMetadataCompanion(
        availabilityStatus: Value(availabilityStatus),
        missingDetectedAt: Value(missingDetectedAt),
        deletedAt: Value(deletedAt),
      ),
    );
  }

  Future<int> updateIntegrityStatus({
    required String id,
    required FileIntegrityStatus integrityStatus,
    required DateTime lastIntegrityCheckAt,
  }) {
    return (update(fileMetadata)..where((t) => t.id.equals(id))).write(
      FileMetadataCompanion(
        integrityStatus: Value(integrityStatus),
        lastIntegrityCheckAt: Value(lastIntegrityCheckAt),
      ),
    );
  }

  Future<int> updateSha256({
    required String id,
    required String? sha256,
    required DateTime lastIntegrityCheckAt,
  }) {
    return (update(fileMetadata)..where((t) => t.id.equals(id))).write(
      FileMetadataCompanion(
        sha256: Value(sha256),
        lastIntegrityCheckAt: Value(lastIntegrityCheckAt),
      ),
    );
  }

  Future<String?> getFilePathByMetadataId(String metadataId) async {
    final row = await (selectOnly(fileMetadata)
          ..addColumns([fileMetadata.filePath])
          ..where(fileMetadata.id.equals(metadataId)))
        .getSingleOrNull();
    return row?.read(fileMetadata.filePath);
  }
}
