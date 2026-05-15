import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/dto/file_dto.dart';
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

  Future<void> updateMetadata({
    required String metadataId,
    required FileMetadataDataDto dto,
  }) async {
    await db.fileMetadataDao.updateFileMetadataById(
      metadataId,
      FileMetadataCompanion(
        fileName: Value(dto.fileName),
        fileExtension: Value(dto.fileExtension),
        filePath: Value(dto.filePath),
        mimeType: Value(dto.mimeType),
        fileSize: Value(dto.fileSize),
        sha256: Value(dto.sha256),
        availabilityStatus: Value(dto.availabilityStatus),
        integrityStatus: Value(dto.integrityStatus),
        missingDetectedAt: Value(dto.missingDetectedAt),
        deletedAt: Value(dto.deletedAt),
        lastIntegrityCheckAt: Value(dto.lastIntegrityCheckAt),
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

  Future<void> markAvailable({
    required String metadataId,
  }) async {
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
