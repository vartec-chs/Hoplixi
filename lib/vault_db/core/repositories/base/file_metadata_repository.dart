import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/file_mapper.dart';
import '../../scheme/tables/file/file_metadata.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

class FileMetadataRepository {
  final VaultDB db;

  FileMetadataRepository(this.db);

  AsyncDBResult<String> createMetadata(FileMetadataDataDto dto) {
    return tryCatchAsync(
      () async {
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
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании метаданных файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> updateMetadata(PatchFileMetadataDto dto) {
    return tryCatchAsync(
      () async {
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
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении метаданных файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<FileMetadataViewDto>> getMetadataById(
    String metadataId,
  ) {
    return tryCatchAsync(
      () async {
        final data = await db.fileMetadataDao.getFileMetadataById(metadataId);
        return Optional.fromNullable(data?.toFileMetadataViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении метаданных файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> markMissing({
    required String metadataId,
    required DateTime detectedAt,
  }) {
    return tryCatchAsync(
      () async {
        await db.fileMetadataDao.updateAvailabilityStatus(
          id: metadataId,
          availabilityStatus: FileAvailabilityStatus.missing,
          missingDetectedAt: detectedAt,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при пометке файла как отсутствующего',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> markDeleted({
    required String metadataId,
    required DateTime deletedAt,
  }) {
    return tryCatchAsync(
      () async {
        await db.fileMetadataDao.updateAvailabilityStatus(
          id: metadataId,
          availabilityStatus: FileAvailabilityStatus.deleted,
          deletedAt: deletedAt,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при пометке файла как удаленного',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> markAvailable({required String metadataId}) {
    return tryCatchAsync(
      () async {
        await db.fileMetadataDao.updateAvailabilityStatus(
          id: metadataId,
          availabilityStatus: FileAvailabilityStatus.available,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при пометке файла как доступного',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> updateIntegrityStatus({
    required String metadataId,
    required FileIntegrityStatus status,
    required DateTime checkedAt,
  }) {
    return tryCatchAsync(
      () async {
        await db.fileMetadataDao.updateIntegrityStatus(
          id: metadataId,
          integrityStatus: status,
          lastIntegrityCheckAt: checkedAt,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении статуса целостности файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> updateSha256({
    required String metadataId,
    required String? sha256,
    required DateTime checkedAt,
  }) {
    return tryCatchAsync(
      () async {
        await db.fileMetadataDao.updateSha256(
          id: metadataId,
          sha256: sha256,
          lastIntegrityCheckAt: checkedAt,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении SHA256 файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
