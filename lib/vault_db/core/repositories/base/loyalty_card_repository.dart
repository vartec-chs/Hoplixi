import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/loyalty_card_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';

class LoyaltyCardRepository {
  final VaultDB db;

  LoyaltyCardRepository(this.db);

  AsyncDBResult<String> create(CreateLoyaltyCardDto dto) {
    return tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db.vaultItemsDao.insertVaultItem(
          VaultItemsCompanion.insert(
            id: Value(itemId),
            type: VaultItemType.loyaltyCard,
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

        await db.loyaltyCardItemsDao.insertLoyaltyCard(
          LoyaltyCardItemsCompanion.insert(
            itemId: itemId,
            programName: dto.loyaltyCard.programName,
            cardNumber: Value(dto.loyaltyCard.cardNumber),
            barcodeValue: Value(dto.loyaltyCard.barcodeValue),
            password: Value(dto.loyaltyCard.password),
            barcodeType: Value(dto.loyaltyCard.barcodeType),
            barcodeTypeOther: Value(dto.loyaltyCard.barcodeTypeOther),
            issuer: Value(dto.loyaltyCard.issuer),
            website: Value(dto.loyaltyCard.website),
            phone: Value(dto.loyaltyCard.phone),
            email: Value(dto.loyaltyCard.email),
            validFrom: Value(dto.loyaltyCard.validFrom),
            validTo: Value(dto.loyaltyCard.validTo),
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
              message: 'Ошибка при создании карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> update(PatchLoyaltyCardDto dto) {
    return tryCatchAsync(
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

        await db.loyaltyCardItemsDao.updateLoyaltyCardByItemId(
          itemId,
          LoyaltyCardItemsCompanion(
            programName: dto.loyaltyCard.programName.toRequiredValue(),
            cardNumber: dto.loyaltyCard.cardNumber.toNullableValue(),
            barcodeValue: dto.loyaltyCard.barcodeValue.toNullableValue(),
            password: dto.loyaltyCard.password.toNullableValue(),
            barcodeType: dto.loyaltyCard.barcodeType.toNullableValue(),
            barcodeTypeOther: dto.loyaltyCard.barcodeTypeOther
                .toNullableValue(),
            issuer: dto.loyaltyCard.issuer.toNullableValue(),
            website: dto.loyaltyCard.website.toNullableValue(),
            phone: dto.loyaltyCard.phone.toNullableValue(),
            email: dto.loyaltyCard.email.toNullableValue(),
            validFrom: dto.loyaltyCard.validFrom.toNullableValue(),
            validTo: dto.loyaltyCard.validTo.toNullableValue(),
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
              message: 'Ошибка при обновлении карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<LoyaltyCardViewDto>> getViewById(String itemId) {
    return tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.loyaltyCardItems,
                  db.loyaltyCardItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(
                db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard),
              );

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final loyaltyCard = row.readTable(db.loyaltyCardItems);

        return Some(
          LoyaltyCardViewDto(
            item: item.toVaultItemViewDto(),
            loyaltyCard: loyaltyCard.toLoyaltyCardDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<LoyaltyCardCardDto>> getCardById(String itemId) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<List<LoyaltyCardCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка карт лояльности',
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
              message: 'Ошибка при удалении карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    final hasCardNumberExpr = db.loyaltyCardItems.cardNumber.isNotNull();
    final hasBarcodeValueExpr = db.loyaltyCardItems.barcodeValue.isNotNull();
    final hasPasswordExpr = db.loyaltyCardItems.password.isNotNull();

    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.loyaltyCardItems,
        db.loyaltyCardItems.itemId.equalsExp(db.vaultItems.id),
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
      db.loyaltyCardItems.programName,
      db.loyaltyCardItems.barcodeType,
      db.loyaltyCardItems.barcodeTypeOther,
      db.loyaltyCardItems.issuer,
      db.loyaltyCardItems.website,
      db.loyaltyCardItems.phone,
      db.loyaltyCardItems.email,
      db.loyaltyCardItems.validFrom,
      db.loyaltyCardItems.validTo,
      hasCardNumberExpr,
      hasBarcodeValueExpr,
      hasPasswordExpr,
    ]);
  }

  LoyaltyCardCardDto _mapRowToCardDto(TypedResult row) {
    final hasCardNumberExpr = db.loyaltyCardItems.cardNumber.isNotNull();
    final hasBarcodeValueExpr = db.loyaltyCardItems.barcodeValue.isNotNull();
    final hasPasswordExpr = db.loyaltyCardItems.password.isNotNull();

    return LoyaltyCardCardDto(
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
      loyaltyCard: LoyaltyCardCardDataDto(
        programName: row.read(db.loyaltyCardItems.programName)!,
        barcodeType: row.readWithConverter<LoyaltyBarcodeType?, String>(
          db.loyaltyCardItems.barcodeType,
        ),
        barcodeTypeOther: row.read(db.loyaltyCardItems.barcodeTypeOther),
        issuer: row.read(db.loyaltyCardItems.issuer),
        website: row.read(db.loyaltyCardItems.website),
        phone: row.read(db.loyaltyCardItems.phone),
        email: row.read(db.loyaltyCardItems.email),
        validFrom: row.read(db.loyaltyCardItems.validFrom),
        validTo: row.read(db.loyaltyCardItems.validTo),
        hasCardNumber: row.read(hasCardNumberExpr) ?? false,
        hasBarcodeValue: row.read(hasBarcodeValueExpr) ?? false,
        hasPassword: row.read(hasPasswordExpr) ?? false,
      ),
    );
  }
}
