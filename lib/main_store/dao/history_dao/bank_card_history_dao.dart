import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/bank_card_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'bank_card_history_dao.g.dart';

/// DAO для управления историей банковских карт.
///
/// Table-Per-Type: общие поля в [VaultItemHistory],
/// type-specific — в [BankCardHistory].
@DriftAccessor(tables: [VaultItemHistory, BankCardHistory])
class BankCardHistoryDao extends DatabaseAccessor<MainStore>
    with _$BankCardHistoryDaoMixin {
  BankCardHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории карт
  Future<List<BankCardHistoryCardDto>> getAllBankCardHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              bankCardHistory,
              bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.bankCard))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Смотреть всю историю карт
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              bankCardHistory,
              bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.bankCard))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю для конкретной карты
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryByOriginalId(
    String originalCardId,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              bankCardHistory,
              bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(originalCardId) &
                vaultItemHistory.type.equalsValue(VaultItemType.bankCard),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю по действию
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryByAction(
    String action,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              bankCardHistory,
              bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.bankCard),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить карточки с пагинацией и поиском
  Future<List<BankCardHistoryCardDto>> getBankCardHistoryCardsByOriginalId(
    String originalCardId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        bankCardHistory,
        bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(originalCardId) &
        vaultItemHistory.type.equalsValue(VaultItemType.bankCard);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              bankCardHistory.cardholderName.like(q) |
              bankCardHistory.bankName.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей
  Future<int> countBankCardHistoryByOriginalId(
    String originalCardId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          bankCardHistory,
          bankCardHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(originalCardId) &
            vaultItemHistory.type.equalsValue(VaultItemType.bankCard),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            bankCardHistory.cardholderName.like(q) |
            bankCardHistory.bankName.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории банковской карты
  Future<String> createBankCardHistory(CreateBankCardHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalCardId,
        type: VaultItemType.bankCard,
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

      await into(bankCardHistory).insert(
        BankCardHistoryCompanion.insert(
          historyId: historyId,
          cardholderName: dto.cardholderName,
          cardNumber: Value(dto.cardNumber),
          cardType: dto.cardType != null
              ? Value(CardTypeX.fromString(dto.cardType!))
              : const Value.absent(),
          cardNetwork: dto.cardNetwork != null
              ? Value(CardNetworkX.fromString(dto.cardNetwork!))
              : const Value.absent(),
          expiryMonth: Value(dto.expiryMonth),
          expiryYear: Value(dto.expiryYear),
          cvv: Value(dto.cvv),
          bankName: Value(dto.bankName),
          accountNumber: Value(dto.accountNumber),
          routingNumber: Value(dto.routingNumber),
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретной карты
  Future<int> deleteBankCardHistoryByOriginalId(String originalCardId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(originalCardId) &
              h.type.equalsValue(VaultItemType.bankCard),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldBankCardHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.bankCard),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deleteBankCardHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  BankCardHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final bc = row.readTable(bankCardHistory);

    return BankCardHistoryCardDto(
      id: h.id,
      originalCardId: h.itemId,
      action: h.action.value,
      name: h.name,
      cardholderName: bc.cardholderName,
      cardType: bc.cardType?.value,
      cardNetwork: bc.cardNetwork?.value,
      actionAt: h.actionAt,
    );
  }
}
