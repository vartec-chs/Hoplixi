import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/note_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class NoteRepository {
  final VaultDB db;

  NoteRepository(this.db);

  AsyncDBResult<String> create(CreateNoteDto dto) {
    return tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db
            .into(db.vaultItems)
            .insert(
              VaultItemsCompanion.insert(
                id: Value(itemId),
                type: VaultItemType.note,
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
            .into(db.noteItems)
            .insert(
              NoteItemsCompanion.insert(
                itemId: itemId,
                deltaJson: dto.note.deltaJson,
                content: dto.note.content,
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
              message: 'Ошибка при создании заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> update(PatchNoteDto dto) {
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
          db.noteItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          NoteItemsCompanion(
            deltaJson: dto.note.deltaJson.toRequiredValue(),
            content: dto.note.content.toRequiredValue(),
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
              message: 'Ошибка при обновлении заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<NoteViewDto>> getViewById(String itemId) {
    return tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.noteItems,
                  db.noteItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.note));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final note = row.readTable(db.noteItems);

        return Some(
          NoteViewDto(
            item: item.toVaultItemViewDto(),
            note: note.toNoteDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<NoteCardDto>> getCardById(String itemId) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.note));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<List<NoteCardDto>> getCards({int limit = 50, int offset = 0}) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.note))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка заметок',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> deletePermanently(String itemId) {
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
              message: 'Ошибка при удалении заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(db.noteItems, db.noteItems.itemId.equalsExp(db.vaultItems.id)),
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
      db.noteItems.content,
    ]);
  }

  NoteCardDto _mapRowToCardDto(TypedResult row) {
    return NoteCardDto(
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
      data: NoteCardDataDto(content: row.read(db.noteItems.content)!),
    );
  }
}
