import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/mappers/file_mapper.dart';
import '../../tables/file/file_metadata.dart';

class FileMetadataRepository {
  final MainStore db;

  FileMetadataRepository(this.db);

  Future<String> createMetadata(FileMetadataDataDto dto) async {
    final id = const Uuid().v4();
    await db.fileMetadataDao.insertFileMetadata(
      FileMetadataCompanion.insert(
        id: Value(id),
        fileName: dto.fileName,
        fileExtension: Value(dto.fileExtension),
        filePath: Value(dto.filePath),
        mimeType: dto.mimeType,
        fileSize: dto.fileSize,
        sha256: Value(dto.sha256),
        availabilityStatus: Value(dto.availabilityStatus),
        integrityStatus: Value(dto.integrityStatus),
        missingDetectedAt: Value(dto.missingDetectedAt),
        deletedAt: Value(dto.deletedAt),
        lastIntegrityCheckAt: Value(dto.lastIntegrityCheckAt),
      ),
    );
    return id;
  }

  Future<void> updateMetadata(PatchFileMetadataDto dto) async {
    await db.fileMetadataDao.updateFileMetadataById(
      dto.id,
      FileMetadataCompanion(
        fileName: dto.fileName.toRequiredValue(),
        fileExtension: dto.fileExtension.toNullableValue(),
        filePath: dto.filePath.toNullableValue(),
        mimeType: dto.mimeType.toRequiredValue(),
        fileSize: dto.fileSize.toRequiredValue(),
        sha256: dto.sha256.toNullableValue(),
        availabilityStatus: dto.availabilityStatus.toRequiredValue(),
        integrityStatus: dto.integrityStatus.toRequiredValue(),
        missingDetectedAt: dto.missingDetectedAt.toNullableValue(),
        deletedAt: dto.deletedAt.toNullableValue(),
        lastIntegrityCheckAt: dto.lastIntegrityCheckAt.toNullableValue(),
      ),
    );
  }

  Future<FileMetadataViewDto?> getMetadataById(String metadataId) async {
    final data = await db.fileMetadataDao.getFileMetadataById(metadataId);
    return data?.toFileMetadataViewDto();
  }

  Future<void> markMissing({
    required String metadataId,
    required DateTime detectedAt,
  }) async {
    await db.fileMetadataDao.updateAvailabilityStatus(
      id: metadataId,
      availabilityStatus: FileAvailabilityStatus.missing,
      missingDetectedAt: detectedAt,
    );
  }

  Future<void> markDeleted({
    required String metadataId,
    required DateTime deletedAt,
  }) async {
    await db.fileMetadataDao.updateAvailabilityStatus(
      id: metadataId,
      availabilityStatus: FileAvailabilityStatus.deleted,
      deletedAt: deletedAt,
    );
  }

  Future<void> markAvailable({required String metadataId}) async {
    await db.fileMetadataDao.updateAvailabilityStatus(
      id: metadataId,
      availabilityStatus: FileAvailabilityStatus.available,
    );
  }

  Future<void> updateIntegrityStatus({
    required String metadataId,
    required FileIntegrityStatus status,
    required DateTime checkedAt,
  }) async {
    await db.fileMetadataDao.updateIntegrityStatus(
      id: metadataId,
      integrityStatus: status,
      lastIntegrityCheckAt: checkedAt,
    );
  }

  Future<void> updateSha256({
    required String metadataId,
    required String? sha256,
    required DateTime checkedAt,
  }) async {
    await db.fileMetadataDao.updateSha256(
      id: metadataId,
      sha256: sha256,
      lastIntegrityCheckAt: checkedAt,
    );
  }
}
