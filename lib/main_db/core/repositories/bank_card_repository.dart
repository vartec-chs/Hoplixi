import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/bank_card/bank_card_items.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/bank_card_dto.dart';
import '../models/mappers/bank_card_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class BankCardRepository {
  final MainStore db;

  BankCardRepository(this.db);

  Future<String> create(CreateBankCardDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.bankCard,
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

      await db.into(db.bankCardItems).insert(
            BankCardItemsCompanion.insert(
              itemId: itemId,
              cardholderName: Value(dto.bankCard.cardholderName),
              cardNumber: dto.bankCard.cardNumber,
              cardType: Value(dto.bankCard.cardType),
              cardTypeOther: Value(dto.bankCard.cardTypeOther),
              cardNetwork: Value(dto.bankCard.cardNetwork),
              cardNetworkOther: Value(dto.bankCard.cardNetworkOther),
              expiryMonth: Value(dto.bankCard.expiryMonth),
              expiryYear: Value(dto.bankCard.expiryYear),
              cvv: Value(dto.bankCard.cvv),
              bankName: Value(dto.bankCard.bankName),
              accountNumber: Value(dto.bankCard.accountNumber),
              routingNumber: Value(dto.bankCard.routingNumber),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateBankCardDto dto) {
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

      await (db.update(db.bankCardItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        BankCardItemsCompanion(
          cardholderName: Value(dto.bankCard.cardholderName),
          cardNumber: Value(dto.bankCard.cardNumber),
          cardType: Value(dto.bankCard.cardType),
          cardTypeOther: Value(dto.bankCard.cardTypeOther),
          cardNetwork: Value(dto.bankCard.cardNetwork),
          cardNetworkOther: Value(dto.bankCard.cardNetworkOther),
          expiryMonth: Value(dto.bankCard.expiryMonth),
          expiryYear: Value(dto.bankCard.expiryYear),
          cvv: Value(dto.bankCard.cvv),
          bankName: Value(dto.bankCard.bankName),
          accountNumber: Value(dto.bankCard.accountNumber),
          routingNumber: Value(dto.bankCard.routingNumber),
        ),
      );
    });
  }

  Future<BankCardViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.bankCardItems,
        db.bankCardItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.bankCard));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final bankCard = row.readTable(db.bankCardItems);

    return BankCardViewDto(
      item: item.toVaultItemViewDto(),
      bankCard: bankCard.toBankCardDataDto(),
    );
  }

  Future<BankCardCardDto?> getCardById(String itemId) async {
    final expr = _BankCardCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.bankCard));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<BankCardCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _BankCardCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.bankCard))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _BankCardCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.bankCardItems,
        db.bankCardItems.itemId.equalsExp(db.vaultItems.id),
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

        db.bankCardItems.cardholderName,
        db.bankCardItems.cardType,
        db.bankCardItems.cardNetwork,
        db.bankCardItems.expiryMonth,
        db.bankCardItems.expiryYear,
        db.bankCardItems.bankName,
        expr.hasCardNumber,
        expr.hasCvv,
      ]);
  }

  BankCardCardDto _mapRowToCardDto(
    TypedResult row,
    _BankCardCardExpressions expr,
  ) {
    return BankCardCardDto(
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
      bankCard: BankCardCardDataDto(
        cardholderName: row.read(db.bankCardItems.cardholderName),
        cardType: row.readWithConverter<CardType?, String>(
          db.bankCardItems.cardType,
        ),
        cardNetwork: row.readWithConverter<CardNetwork?, String>(
          db.bankCardItems.cardNetwork,
        ),
        expiryMonth: row.read(db.bankCardItems.expiryMonth),
        expiryYear: row.read(db.bankCardItems.expiryYear),
        bankName: row.read(db.bankCardItems.bankName),
        hasCvv: row.read(expr.hasCvv) ?? false,
        hasCardNumber: row.read(expr.hasCardNumber) ?? false,
      ),
    );
  }
}

class _BankCardCardExpressions {
  _BankCardCardExpressions(this.db)
      : hasCardNumber = db.bankCardItems.cardNumber.isNotNull(),
        hasCvv = db.bankCardItems.cvv.isNotNull();

  final MainStore db;
  final Expression<bool> hasCardNumber;
  final Expression<bool> hasCvv;
}
