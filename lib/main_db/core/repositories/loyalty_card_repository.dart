import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/loyalty_card_dto.dart';
import '../models/mappers/loyalty_card_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class LoyaltyCardRepository {
  final MainStore db;

  LoyaltyCardRepository(this.db);

  Future<String> create(CreateLoyaltyCardDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
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

      await db.into(db.loyaltyCardItems).insert(
            LoyaltyCardItemsCompanion.insert(
              itemId: itemId,
              programName: dto.loyaltyCard.programName,
              cardNumber: dto.loyaltyCard.cardNumber,
              memberSince: Value(dto.loyaltyCard.memberSince),
              expiryDate: Value(dto.loyaltyCard.expiryDate),
              points: Value(dto.loyaltyCard.points),
              tier: Value(dto.loyaltyCard.tier),
              notes: Value(dto.loyaltyCard.notes),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateLoyaltyCardDto dto) {
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

      await (db.update(db.loyaltyCardItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        LoyaltyCardItemsCompanion(
          programName: Value(dto.loyaltyCard.programName),
          cardNumber: Value(dto.loyaltyCard.cardNumber),
          memberSince: Value(dto.loyaltyCard.memberSince),
          expiryDate: Value(dto.loyaltyCard.expiryDate),
          points: Value(dto.loyaltyCard.points),
          tier: Value(dto.loyaltyCard.tier),
          notes: Value(dto.loyaltyCard.notes),
        ),
      );
    });
  }

  Future<LoyaltyCardViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.loyaltyCardItems,
        db.loyaltyCardItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final loyaltyCard = row.readTable(db.loyaltyCardItems);

    return LoyaltyCardViewDto(
      item: item.toVaultItemViewDto(),
      loyaltyCard: loyaltyCard.toLoyaltyCardDataDto(),
    );
  }

  Future<LoyaltyCardCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<LoyaltyCardCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.loyaltyCard))
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
        db.loyaltyCardItems,
        db.loyaltyCardItems.itemId.equalsExp(db.vaultItems.id),
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

        db.loyaltyCardItems.programName,
        db.loyaltyCardItems.cardNumber,
        db.loyaltyCardItems.expiryDate,
        db.loyaltyCardItems.points,
        db.loyaltyCardItems.tier,
      ]);
  }

  LoyaltyCardCardDto _mapRowToCardDto(TypedResult row) {
    return LoyaltyCardCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.read(db.vaultItems.type)!,
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
        cardNumber: row.read(db.loyaltyCardItems.cardNumber)!,
        expiryDate: row.read(db.loyaltyCardItems.expiryDate),
        points: row.read(db.loyaltyCardItems.points),
        tier: row.read(db.loyaltyCardItems.tier),
      ),
    );
  }
}
