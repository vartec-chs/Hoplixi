import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/dto/file_dto.dart';
import '../../models/dto/vault_item_base_dto.dart';
import '../../models/mappers/file_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/file/file_metadata.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class FileRepository {
  final VaultDB db;

  FileRepository(this.db);

  AsyncDbResult<String> create(CreateFileDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        String? metadataId = dto.file.metadataId;

        if (dto.metadata != null) {
          metadataId = const Uuid().v4();

          await db.fileMetadataDao.insertFileMetadata(
            FileMetadataCompanion.insert(
              id: Value(metadataId),
              fileName: dto.metadata!.fileName,
              fileExtension: Value(dto.metadata!.fileExtension),
              filePath: Value(dto.metadata!.filePath),
              mimeType: dto.metadata!.mimeType,
              fileSize: dto.metadata!.fileSize,
              sha256: Value(dto.metadata!.sha256),
              availabilityStatus: Value(dto.metadata!.availabilityStatus),
              integrityStatus: Value(dto.metadata!.integrityStatus),
              missingDetectedAt: Value(dto.metadata!.missingDetectedAt),
              deletedAt: Value(dto.metadata!.deletedAt),
              lastIntegrityCheckAt: Value(dto.metadata!.lastIntegrityCheckAt),
            ),
          );
        }

        await db
            .into(db.vaultItems)
            .insert(
              VaultItemsCompanion.insert(
                id: Value(itemId),
                type: VaultItemType.file,
                name: dto.item.name,
                description: Value(dto.item.description),
                categoryId: Value(dto.item.categoryId),
                iconRefId: Value(dto.item.iconRefId),
                isFavorite: Value(dto.item.isFavorite),
                isPinned: Value(dto.item.isPinned),
                createdAt: Value(now),
                modifiedAt: Value(now),
              ),
            );

        await db.fileItemsDao.insertFileItem(
          FileItemsCompanion.insert(
            itemId: itemId,
            metadataId: Value(metadataId),
          ),
        );

        
        if (dto.tagIds.isNotEmpty) {
          for (final tagId in dto.tagIds) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchFileDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = dto.item.itemId;

        final itemUpdated =
            await (db.update(
              db.vaultItems,
            )..where((tbl) => tbl.id.equals(itemId))).write(
              VaultItemsCompanion(
                name: dto.item.name.toRequiredValue(),
                description: dto.item.description.toNullableValue(),
                categoryId: dto.item.categoryId.toNullableValue(),
                iconRefId: dto.item.iconRefId.toNullableValue(),
                isFavorite: dto.item.isFavorite.toRequiredValue(),
                isPinned: dto.item.isPinned.toRequiredValue(),
                modifiedAt: Value(now),
              ),
            );

        if (itemUpdated == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }

        await db.fileItemsDao.updateFileItemByItemId(
          itemId,
          FileItemsCompanion(metadataId: dto.file.metadataId.toNullableValue()),
        );

        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          await db.itemTagsDao.removeAllTagsFromItem(itemId);
          for (final tagId in tagsUpdate.value ?? []) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }

        final metadataDto = dto.metadata;
        if (metadataDto != null) {
          final metadataIdUpdate = dto.file.metadataId;
          String? targetMetadataId;
          if (metadataIdUpdate is FieldUpdateSet<String>) {
            targetMetadataId = metadataIdUpdate.value;
          }

          if (targetMetadataId == null) {
            throw DBCoreError.validation(
              code: 'metadata_id_required',
              message: 'Cannot update metadata because metadataId is null',
            );
          }

          await db.fileMetadataDao.updateFileMetadataById(
            targetMetadataId,
            FileMetadataCompanion(
              fileName: metadataDto.fileName.toRequiredValue(),
              fileExtension: metadataDto.fileExtension.toNullableValue(),
              filePath: metadataDto.filePath.toNullableValue(),
              mimeType: metadataDto.mimeType.toRequiredValue(),
              fileSize: metadataDto.fileSize.toRequiredValue(),
              sha256: metadataDto.sha256.toNullableValue(),
              availabilityStatus: metadataDto.availabilityStatus
                  .toRequiredValue(),
              integrityStatus: metadataDto.integrityStatus.toRequiredValue(),
              missingDetectedAt: metadataDto.missingDetectedAt
                  .toNullableValue(),
              deletedAt: metadataDto.deletedAt.toNullableValue(),
              lastIntegrityCheckAt: metadataDto.lastIntegrityCheckAt
                  .toNullableValue(),
            ),
          );
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<FileViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.fileItems,
                  db.fileItems.itemId.equalsExp(db.vaultItems.id),
                ),
                leftOuterJoin(
                  db.fileMetadata,
                  db.fileMetadata.id.equalsExp(db.fileItems.metadataId),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.file));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final fileItem = row.readTable(db.fileItems);
        final metadata = row.readTableOrNull(db.fileMetadata);

        return Some(
          FileViewDto(
            item: item.toVaultItemViewDto(),
            file: fileItem.toFileDataDto(),
            metadata: metadata?.toFileMetadataViewDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<FileCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.file));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FileCardDto>> getCards({int limit = 50, int offset = 0}) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.file))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка файлов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePermanently(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        // Note: file_items will be deleted by cascade.
        // metadata is NOT deleted automatically as it might be shared.
        final rows = await (db.delete(
          db.vaultItems,
        )..where((tbl) => tbl.id.equals(itemId))).go();
        if (rows == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении файла',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(db.fileItems, db.fileItems.itemId.equalsExp(db.vaultItems.id)),
      leftOuterJoin(
        db.fileMetadata,
        db.fileMetadata.id.equalsExp(db.fileItems.metadataId),
      ),
    ])..addColumns([
      db.vaultItems.id,
      db.vaultItems.type,
      db.vaultItems.name,
      db.vaultItems.description,
      db.vaultItems.categoryId,
      db.vaultItems.iconRefId,
      db.vaultItems.isFavorite,
      db.vaultItems.isArchived,
      db.vaultItems.isPinned,
      db.vaultItems.isDeleted,
      db.vaultItems.createdAt,
      db.vaultItems.modifiedAt,
      db.vaultItems.lastUsedAt,
      db.vaultItems.archivedAt,
      db.vaultItems.deletedAt,
      db.vaultItems.recentScore,

      db.fileItems.metadataId,
      db.fileMetadata.fileName,
      db.fileMetadata.fileExtension,
      db.fileMetadata.mimeType,
      db.fileMetadata.fileSize,
      db.fileMetadata.availabilityStatus,
      db.fileMetadata.integrityStatus,
      db.fileMetadata.missingDetectedAt,
      db.fileMetadata.deletedAt,
      db.fileMetadata.lastIntegrityCheckAt,
      db.fileMetadata.sha256,
    ]);
  }

  FileCardDto _mapRowToCardDto(TypedResult row) {
    return FileCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter<VaultItemType, String>(db.vaultItems.type)!,
        name: row.read(db.vaultItems.name)!,
        description: row.read(db.vaultItems.description),
        categoryId: row.read(db.vaultItems.categoryId),
        iconRefId: row.read(db.vaultItems.iconRefId),
        isFavorite: row.read(db.vaultItems.isFavorite)!,
        isArchived: row.read(db.vaultItems.isArchived)!,
        isPinned: row.read(db.vaultItems.isPinned)!,
        isDeleted: row.read(db.vaultItems.isDeleted)!,
        createdAt: row.read(db.vaultItems.createdAt)!,
        modifiedAt: row.read(db.vaultItems.modifiedAt)!,
        lastUsedAt: row.read(db.vaultItems.lastUsedAt),
        archivedAt: row.read(db.vaultItems.archivedAt),
        deletedAt: row.read(db.vaultItems.deletedAt),
        recentScore: row.read(db.vaultItems.recentScore),
      ),
      file: FileCardDataDto(
        metadataId: row.read(db.fileItems.metadataId),
        fileName: row.read(db.fileMetadata.fileName),
        fileExtension: row.read(db.fileMetadata.fileExtension),
        mimeType: row.read(db.fileMetadata.mimeType),
        fileSize: row.read(db.fileMetadata.fileSize),
        availabilityStatus: row
            .readWithConverter<FileAvailabilityStatus?, String>(
              db.fileMetadata.availabilityStatus,
            ),
        integrityStatus: row.readWithConverter<FileIntegrityStatus?, String>(
          db.fileMetadata.integrityStatus,
        ),
        missingDetectedAt: row.read(db.fileMetadata.missingDetectedAt),
        deletedAt: row.read(db.fileMetadata.deletedAt),
        lastIntegrityCheckAt: row.read(db.fileMetadata.lastIntegrityCheckAt),
        hasMetadata: row.read(db.fileItems.metadataId) != null,
        hasSha256: row.read(db.fileMetadata.sha256) != null,
      ),
    );
  }
}
