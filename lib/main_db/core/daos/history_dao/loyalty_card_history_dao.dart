import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/loyalty_card_history_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/main_db/core/tables/loyalty_card/loyalty_card_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_item_history.dart';

part 'loyalty_card_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, LoyaltyCardHistory])
class LoyaltyCardHistoryDao extends DatabaseAccessor<MainStore>
    with _$LoyaltyCardHistoryDaoMixin {
  LoyaltyCardHistoryDao(super.db);

  Future<List<LoyaltyCardHistoryCardDto>>
  getAllLoyaltyCardHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              loyaltyCardHistory,
              loyaltyCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.loyaltyCard))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return (await query.get()).map(_mapToCard).toList();
  }

  Stream<List<LoyaltyCardHistoryCardDto>> watchLoyaltyCardHistoryByOriginalId(
    String originalLoyaltyCardId,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              loyaltyCardHistory,
              loyaltyCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(originalLoyaltyCardId) &
                vaultItemHistory.type.equalsValue(VaultItemType.loyaltyCard),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  Future<List<LoyaltyCardHistoryCardDto>>
  getLoyaltyCardHistoryCardsByOriginalId(
    String originalLoyaltyCardId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        loyaltyCardHistory,
        loyaltyCardHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(originalLoyaltyCardId) &
        vaultItemHistory.type.equalsValue(VaultItemType.loyaltyCard);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              loyaltyCardHistory.programName.like(q) |
              loyaltyCardHistory.cardNumber.like(q) |
              loyaltyCardHistory.tier.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    return (await query.get()).map(_mapToCard).toList();
  }

  Future<int> countLoyaltyCardHistoryByOriginalId(
    String originalLoyaltyCardId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          loyaltyCardHistory,
          loyaltyCardHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(originalLoyaltyCardId) &
            vaultItemHistory.type.equalsValue(VaultItemType.loyaltyCard),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            loyaltyCardHistory.programName.like(q) |
            loyaltyCardHistory.cardNumber.like(q) |
            loyaltyCardHistory.tier.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<String> createLoyaltyCardHistory(
    CreateLoyaltyCardHistoryDto dto,
  ) async {
    return db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalLoyaltyCardId,
        type: VaultItemType.loyaltyCard,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.name,
        description: Value(dto.description),
        categoryId: Value(dto.categoryId),
        categoryName: Value(dto.categoryName),
        usedCount: Value(dto.usedCount),
        isFavorite: Value(dto.isFavorite),
        isArchived: Value(dto.isArchived),
        isPinned: Value(dto.isPinned),
        isDeleted: Value(dto.isDeleted),
        lastUsedAt: Value(dto.originalLastAccessedAt),
        originalCreatedAt: Value(dto.originalCreatedAt),
        originalModifiedAt: Value(dto.originalModifiedAt),
      );

      await into(vaultItemHistory).insert(companion);
      final historyId = companion.id.value;

      await into(loyaltyCardHistory).insert(
        LoyaltyCardHistoryCompanion.insert(
          historyId: historyId,
          programName: dto.programName,
          cardNumber: Value(dto.cardNumber),
          holderName: Value(dto.holderName),
          barcodeValue: Value(dto.barcodeValue),
          barcodeType: Value(dto.barcodeType),
          password: Value(dto.password),
          pointsBalance: Value(dto.pointsBalance),
          tier: Value(dto.tier),
          expiryDate: Value(dto.expiryDate),
          website: Value(dto.website),
          phoneNumber: Value(dto.phoneNumber),
        ),
      );

      return historyId;
    });
  }

  Future<int> deleteLoyaltyCardHistoryByOriginalId(
    String originalLoyaltyCardId,
  ) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(originalLoyaltyCardId) &
              h.type.equalsValue(VaultItemType.loyaltyCard),
        ))
        .go();
  }

  Future<int> deleteLoyaltyCardHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  LoyaltyCardHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final loyalty = row.readTable(loyaltyCardHistory);

    return LoyaltyCardHistoryCardDto(
      id: history.id,
      originalLoyaltyCardId: history.itemId,
      action: history.action.value,
      name: history.name,
      programName: loyalty.programName,
      cardNumber: loyalty.cardNumber,
      tier: loyalty.tier,
      actionAt: history.actionAt,
    );
  }
}
