import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/dto/document_dto.dart';
import '../../models/mappers/document_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';

class DocumentRepository {
  final VaultDB db;

  DocumentRepository(this.db);

  AsyncDbResult<String> create(CreateDocumentDto dto) {
    return tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db
            .into(db.vaultItems)
            .insert(
              VaultItemsCompanion.insert(
                id: Value(itemId),
                type: VaultItemType.document,
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

        await db
            .into(db.documentItems)
            .insert(
              DocumentItemsCompanion.insert(
                itemId: itemId,
                currentVersionId: Value(dto.document.currentVersionId),
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
              message: 'Ошибка при создании документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchDocumentDto dto) {
    return tryCatchAsync(
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

        await (db.update(
          db.documentItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          DocumentItemsCompanion(
            currentVersionId: dto.document.currentVersionId.toNullableValue(),
          ),
        );

        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          await db.itemTagsDao.removeAllTagsFromItem(itemId);
          for (final tagId in tagsUpdate.value ?? []) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<DocumentViewDto>> getViewById(String itemId) {
    return tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.documentItems,
                  db.documentItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.document));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final document = row.readTable(db.documentItems);

        return Some(
          DocumentViewDto(
            item: item.toVaultItemViewDto(),
            document: document.toDocumentDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<DocumentCardDto>> getCardById(String itemId) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.document));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<DocumentCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.document))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка документов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePermanently(String itemId) {
    return tryCatchAsync(
      () async {
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
              message: 'Ошибка при удалении документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.documentItems,
        db.documentItems.itemId.equalsExp(db.vaultItems.id),
      ),
      leftOuterJoin(
        db.documentVersions,
        db.documentVersions.id.equalsExp(db.documentItems.currentVersionId),
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

      db.documentItems.currentVersionId,
      db.documentVersions.versionNumber,
      db.documentVersions.documentType,
      db.documentVersions.documentTypeOther,
      db.documentVersions.pageCount,
      db.documentVersions.createdAt,
      db.documentVersions.modifiedAt,
    ]);
  }

  DocumentCardDto _mapRowToCardDto(TypedResult row) {
    final currentVersionId = row.read(db.documentItems.currentVersionId);

    return DocumentCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter<VaultItemType?, String>(
          db.vaultItems.type,
        )!,
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
      document: DocumentCurrentVersionCardDataDto(
        currentVersionId: currentVersionId,
        currentVersionNumber: row.read(db.documentVersions.versionNumber),
        documentType: row.readWithConverter<DocumentType?, String>(
          db.documentVersions.documentType,
        ),
        documentTypeOther: row.read(db.documentVersions.documentTypeOther),
        pageCount: row.read(db.documentVersions.pageCount),
        versionCreatedAt: row.read(db.documentVersions.createdAt),
        versionModifiedAt: row.read(db.documentVersions.modifiedAt),
        hasCurrentVersion: currentVersionId != null,
      ),
    );
  }
}
