import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/recovery_codes_dto.dart';
import '../models/mappers/recovery_codes_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class RecoveryCodesRepository {
  final MainStore db;

  RecoveryCodesRepository(this.db);

  Future<String> create(CreateRecoveryCodesDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
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

      await db.into(db.recoveryCodesItems).insert(
            RecoveryCodesItemsCompanion.insert(
              itemId: itemId,
              generatedAt: Value(dto.recoveryCodes.generatedAt),
              oneTime: Value(dto.recoveryCodes.oneTime),
            ),
          );

      if (dto.recoveryCodes.codes.isNotEmpty) {
        for (final code in dto.recoveryCodes.codes) {
          await db.into(db.recoveryCodes).insert(
                RecoveryCodesCompanion.insert(
                  itemId: itemId,
                  code: code.code,
                  used: Value(code.used),
                  usedAt: Value(code.usedAt),
                  position: Value(code.position),
                ),
              );
        }
      }

      return itemId;
    });
  }

  Future<void> update(UpdateRecoveryCodesDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
          .write(
        VaultItemsCompanion(
          name: Value(dto.item.name),
          description: Value(dto.item.description),
          categoryId: Value(dto.item.categoryId),
          iconRefId: Value(dto.item.iconRefId),
          isFavorite: Value(dto.item.isFavorite),
          isPinned: Value(dto.item.isPinned),
          modifiedAt: Value(now),
        ),
      );

      await (db.update(db.recoveryCodesItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        RecoveryCodesItemsCompanion(
          generatedAt: Value(dto.recoveryCodes.generatedAt),
          oneTime: Value(dto.recoveryCodes.oneTime),
        ),
      );

      // Updating codes is complex (delete all and re-insert or diff).
      // Given the requirement, we assume codes can be replaced.
      await (db.delete(db.recoveryCodes)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .go();

      if (dto.recoveryCodes.codes.isNotEmpty) {
        for (final code in dto.recoveryCodes.codes) {
          await db.into(db.recoveryCodes).insert(
                RecoveryCodesCompanion.insert(
                  itemId: itemId,
                  code: code.code,
                  used: Value(code.used),
                  usedAt: Value(code.usedAt),
                  position: Value(code.position),
                ),
              );
        }
      }
    });
  }

  Future<RecoveryCodesViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.recoveryCodesItems,
        db.recoveryCodesItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final recoveryCodesItem = row.readTable(db.recoveryCodesItems);

    final codesRows = await (db.select(db.recoveryCodes)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();

    final codes = codesRows
        .map((r) => RecoveryCodeDto(
              code: r.code,
              used: r.used,
              usedAt: r.usedAt,
              position: r.position,
            ))
        .toList();

    return RecoveryCodesViewDto(
      item: item.toVaultItemViewDto(),
      recoveryCodes: recoveryCodesItem.toRecoveryCodesDataDto().copyWith(
            codes: codes,
          ),
    );
  }

  Future<RecoveryCodesCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<RecoveryCodesCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.recoveryCodes))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapRowToCardDto).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.recoveryCodesItems,
        db.recoveryCodesItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..addColumns([
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
      ),
    );
  }
}
