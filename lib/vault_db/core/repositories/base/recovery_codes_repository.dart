import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/recovery_codes_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class RecoveryCodesRepository {
  final VaultDB db;

  RecoveryCodesRepository(this.db);

  AsyncDbResult<String> create(CreateRecoveryCodesDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db.vaultItemsDao.insertVaultItem(
          VaultItemsCompanion.insert(
            id: Value(itemId),
            type: VaultItemType.recoveryCodes,
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

        await db.recoveryCodesItemsDao.insertRecoveryCodesItem(
          RecoveryCodesItemsCompanion.insert(
            itemId: itemId,
            generatedAt: Value(dto.recoveryCodes.generatedAt),
            oneTime: Value(dto.recoveryCodes.oneTime),
            codesCount: const Value(0),
            usedCount: const Value(0),
          ),
        );

        if (dto.codes.isNotEmpty) {
          await db.recoveryCodesDao.insertRecoveryCodesBatch(
            dto.codes.map((codeDto) {
              return RecoveryCodesCompanion.insert(
                itemId: itemId,
                code: codeDto.code,
                used: Value(codeDto.used),
                usedAt: Value(codeDto.usedAt),
                position: Value(codeDto.position),
              );
            }).toList(),
          );
        }

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchRecoveryCodesDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = dto.item.itemId;

        final itemUpdated = await db.vaultItemsDao.updateVaultItemById(
          itemId,
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

        await db.recoveryCodesItemsDao.updateRecoveryCodesItemByItemId(
          itemId,
          RecoveryCodesItemsCompanion(
            generatedAt: dto.recoveryCodes.generatedAt.toNullableValue(),
            oneTime: dto.recoveryCodes.oneTime.toRequiredValue(),
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
              message: 'Ошибка при обновлении кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<RecoveryCodesViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.recoveryCodesItems,
                  db.recoveryCodesItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(
                db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes),
              );

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final recoveryCodesItem = row.readTable(db.recoveryCodesItems);

        final codesData = await db.recoveryCodesDao.getRecoveryCodesByItemId(
          itemId,
        );

        return Some(
          RecoveryCodesViewDto(
            item: item.toVaultItemViewDto(),
            recoveryCodes: recoveryCodesItem.toRecoveryCodesDataDto(),
            codes: codesData.map((c) => c.toRecoveryCodeValueDto()).toList(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<RecoveryCodesCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<RecoveryCodesCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePermanently(String itemId) {
    return ResultUtils.tryCatchAsync(
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
              message: 'Ошибка при удалении кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  // --- Методы управления кодами ---

  AsyncDbResult<int> addCode({
    required String itemId,
    required RecoveryCodeValueDto code,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final id = await db.recoveryCodesDao.insertRecoveryCode(
          RecoveryCodesCompanion.insert(
            itemId: itemId,
            code: code.code,
            used: Value(code.used),
            usedAt: Value(code.usedAt),
            position: Value(code.position),
          ),
        );
        await _updateModifiedAt(itemId);
        return id;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при добавлении кода восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> addCodes({
    required String itemId,
    required List<RecoveryCodeValueDto> codes,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        await db.recoveryCodesDao.insertRecoveryCodesBatch(
          codes
              .map(
                (c) => RecoveryCodesCompanion.insert(
                  itemId: itemId,
                  code: c.code,
                  used: Value(c.used),
                  usedAt: Value(c.usedAt),
                  position: Value(c.position),
                ),
              )
              .toList(),
        );
        await _updateModifiedAt(itemId);
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при массовом добавлении кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> markCodeUsed({
    required int codeId,
    required DateTime usedAt,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final code = await db.recoveryCodesDao.getRecoveryCodeById(codeId);
        if (code == null) {
          throw DBCoreError.notFound(entity: 'recovery_codes', id: '$codeId');
        }

        final count = await db.recoveryCodesDao.markCodeUsed(
          id: codeId,
          usedAt: usedAt,
        );
        await _updateModifiedAt(code.itemId);
        return count;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при пометке кода восстановления как использованного',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> markCodeUnused({required int codeId}) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final code = await db.recoveryCodesDao.getRecoveryCodeById(codeId);
        if (code == null) {
          throw DBCoreError.notFound(entity: 'recovery_codes', id: '$codeId');
        }

        final count = await db.recoveryCodesDao.markCodeUnused(id: codeId);
        await _updateModifiedAt(code.itemId);
        return count;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при пометке кода восстановления как неиспользованного',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> deleteCode(int codeId) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final code = await db.recoveryCodesDao.getRecoveryCodeById(codeId);
        if (code == null) {
          throw DBCoreError.notFound(entity: 'recovery_codes', id: '$codeId');
        }

        final count = await db.recoveryCodesDao.deleteRecoveryCodeById(codeId);
        await _updateModifiedAt(code.itemId);
        return count;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении кода восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> replaceCodes({
    required String itemId,
    required List<RecoveryCodeValueDto> codes,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        await db.recoveryCodesDao.deleteRecoveryCodesByItemId(itemId);
        if (codes.isNotEmpty) {
          await db.recoveryCodesDao.insertRecoveryCodesBatch(
            codes
                .map(
                  (c) => RecoveryCodesCompanion.insert(
                    itemId: itemId,
                    code: c.code,
                    used: Value(c.used),
                    usedAt: Value(c.usedAt),
                    position: Value(c.position),
                  ),
                )
                .toList(),
          );
        }
        await _updateModifiedAt(itemId);
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при замене кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  Future<void> _updateModifiedAt(String itemId) async {
    await db.vaultItemsDao.touchModifiedAt(itemId, DateTime.now());
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.recoveryCodesItems,
        db.recoveryCodesItems.itemId.equalsExp(db.vaultItems.id),
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
      db.recoveryCodesItems.codesCount,
      db.recoveryCodesItems.usedCount,
      db.recoveryCodesItems.generatedAt,
      db.recoveryCodesItems.oneTime,
    ]);
  }

  RecoveryCodesCardDto _mapRowToCardDto(TypedResult row) {
    return RecoveryCodesCardDto(
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
      recoveryCodes: RecoveryCodesCardDataDto(
        codesCount: row.read(db.recoveryCodesItems.codesCount)!,
        usedCount: row.read(db.recoveryCodesItems.usedCount)!,
        generatedAt: row.read(db.recoveryCodesItems.generatedAt),
        oneTime: row.read(db.recoveryCodesItems.oneTime)!,
        hasCodes: (row.read(db.recoveryCodesItems.codesCount) ?? 0) > 0,
      ),
    );
  }
}
