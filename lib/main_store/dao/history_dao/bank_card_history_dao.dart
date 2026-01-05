import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/bank_cards_history.dart';

part 'bank_card_history_dao.g.dart';

@DriftAccessor(tables: [BankCardsHistory])
class BankCardHistoryDao extends DatabaseAccessor<MainStore>
    with _$BankCardHistoryDaoMixin {
  BankCardHistoryDao(super.db);

  /// Получить всю историю карт
  Future<List<BankCardsHistoryData>> getAllBankCardHistory() {
    return select(bankCardsHistory).get();
  }

  /// Получить запись истории по ID
  Future<BankCardsHistoryData?> getBankCardHistoryById(String id) {
    return (select(
      bankCardsHistory,
    )..where((bch) => bch.id.equals(id))).getSingleOrNull();
  }

  /// Получить историю карт в виде карточек
  Future<List<BankCardHistoryCardDto>> getAllBankCardHistoryCards() {
    return (select(bankCardsHistory)
          ..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)]))
        .map(
          (bch) => BankCardHistoryCardDto(
            id: bch.id,
            originalCardId: bch.originalCardId,
            action: bch.action.value,
            name: bch.name,
            cardholderName: bch.cardholderName,
            cardType: bch.cardType?.value,
            cardNetwork: bch.cardNetwork?.value,
            actionAt: bch.actionAt,
          ),
        )
        .get();
  }

  /// Смотреть всю историю карт с автообновлением
  Stream<List<BankCardsHistoryData>> watchAllBankCardHistory() {
    return (select(
      bankCardsHistory,
    )..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)])).watch();
  }

  /// Смотреть историю карт карточки с автообновлением
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryCards() {
    return (select(
      bankCardsHistory,
    )..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)])).watch().map(
      (history) => history
          .map(
            (bch) => BankCardHistoryCardDto(
              id: bch.id,
              originalCardId: bch.originalCardId,
              action: bch.action.value,
              name: bch.name,
              cardholderName: bch.cardholderName,
              cardType: bch.cardType?.value,
              cardNetwork: bch.cardNetwork?.value,
              actionAt: bch.actionAt,
            ),
          )
          .toList(),
    );
  }

  /// Получить историю для конкретной карты
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryByOriginalId(
    String originalCardId,
  ) {
    return (select(bankCardsHistory)
          ..where((bch) => bch.originalCardId.equals(originalCardId))
          ..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (bch) => BankCardHistoryCardDto(
                  id: bch.id,
                  originalCardId: bch.originalCardId,
                  action: bch.action.value,
                  name: bch.name,
                  cardholderName: bch.cardholderName,
                  cardType: bch.cardType?.value,
                  cardNetwork: bch.cardNetwork?.value,
                  actionAt: bch.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Получить историю по действию
  Stream<List<BankCardHistoryCardDto>> watchBankCardHistoryByAction(
    String action,
  ) {
    return (select(bankCardsHistory)
          ..where((bch) => bch.action.equals(action))
          ..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (bch) => BankCardHistoryCardDto(
                  id: bch.id,
                  originalCardId: bch.originalCardId,
                  action: bch.action.value,
                  name: bch.name,
                  cardholderName: bch.cardholderName,
                  cardType: bch.cardType?.value,
                  cardNetwork: bch.cardNetwork?.value,
                  actionAt: bch.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Создать запись истории
  Future<String> createBankCardHistory(CreateBankCardHistoryDto dto) {
    final companion = BankCardsHistoryCompanion.insert(
      originalCardId: dto.originalCardId,
      action: ActionInHistoryX.fromString(dto.action),
      name: dto.name,
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
      description: Value(dto.description),
      notes: Value(dto.notes),
      categoryId: Value(dto.categoryId),
      categoryName: Value(dto.categoryName),
      usedCount: Value(dto.usedCount),
      isFavorite: Value(dto.isFavorite),
      isArchived: Value(dto.isArchived),
      isPinned: Value(dto.isPinned),
      isDeleted: Value(dto.isDeleted),
      originalCreatedAt: Value(dto.originalCreatedAt),
      originalModifiedAt: Value(dto.originalModifiedAt),
      originalLastUsedAt: Value(dto.originalLastAccessedAt),
    );
    return into(bankCardsHistory).insert(companion).then((id) {
      return (select(bankCardsHistory)
            ..where((bch) => bch.id.equals(id.toString())))
          .map((bch) => bch.id)
          .getSingle();
    });
  }

  /// Удалить историю для карты
  Future<int> deleteBankCardHistoryByOriginalId(String originalCardId) {
    return (delete(
      bankCardsHistory,
    )..where((bch) => bch.originalCardId.equals(originalCardId))).go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldBankCardHistory(Duration olderThan) {
    final cutoffDate = DateTime.now().subtract(olderThan);
    return (delete(
      bankCardsHistory,
    )..where((bch) => bch.actionAt.isSmallerThanValue(cutoffDate))).go();
  }

  // ============================================
  // Методы для пагинации и поиска
  // ============================================

  /// Получить историю по ID оригинальной карты с пагинацией и поиском
  Future<List<BankCardHistoryCardDto>> getBankCardHistoryCardsByOriginalId(
    String originalCardId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    var query = select(bankCardsHistory)
      ..where((bch) => bch.originalCardId.equals(originalCardId))
      ..orderBy([(bch) => OrderingTerm.desc(bch.actionAt)])
      ..limit(limit, offset: offset);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          (bch) =>
              bch.name.like(search) |
              bch.cardholderName.like(search) |
              bch.bankName.like(search),
        );
    }

    final results = await query.get();
    return results
        .map(
          (bch) => BankCardHistoryCardDto(
            id: bch.id,
            originalCardId: bch.originalCardId,
            action: bch.action.value,
            name: bch.name,
            cardholderName: bch.cardholderName,
            cardType: bch.cardType?.value,
            cardNetwork: bch.cardNetwork?.value,
            actionAt: bch.actionAt,
          ),
        )
        .toList();
  }

  /// Подсчитать количество записей истории для карты
  Future<int> countBankCardHistoryByOriginalId(
    String originalCardId,
    String? searchQuery,
  ) async {
    var query = selectOnly(bankCardsHistory)
      ..addColumns([bankCardsHistory.id.count()])
      ..where(bankCardsHistory.originalCardId.equals(originalCardId));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          bankCardsHistory.name.like(search) |
              bankCardsHistory.cardholderName.like(search) |
              bankCardsHistory.bankName.like(search),
        );
    }

    final result = await query
        .map((row) => row.read(bankCardsHistory.id.count()))
        .getSingle();
    return result ?? 0;
  }

  /// Удалить запись истории по ID
  Future<int> deleteBankCardHistoryById(String historyId) {
    return (delete(
      bankCardsHistory,
    )..where((bch) => bch.id.equals(historyId))).go();
  }
}
