import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

part 'bank_card_history_dao.g.dart';

@DriftAccessor(tables: [BankCardHistory])
class BankCardHistoryDao extends DatabaseAccessor<MainStore>
    with _$BankCardHistoryDaoMixin {
  BankCardHistoryDao(super.db);

  Future<void> insertBankCardHistory(BankCardHistoryCompanion companion) {
    return into(bankCardHistory).insert(companion);
  }

  Future<BankCardHistoryData?> getBankCardHistoryByHistoryId(String historyId) {
    return (select(bankCardHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsBankCardHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(bankCardHistory)
          ..addColumns([bankCardHistory.historyId])
          ..where(bankCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteBankCardHistoryByHistoryId(String historyId) {
    return (delete(bankCardHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<BankCardHistoryData>> getBankCardHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(bankCardHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, BankCardHistoryCardDataDto>> getBankCardHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasCardNumberExpr = bankCardHistory.cardNumber.isNotNull();
    final hasCvvExpr = bankCardHistory.cvv.isNotNull();
    final hasAccountNumberExpr = bankCardHistory.accountNumber.isNotNull();
    final hasRoutingNumberExpr = bankCardHistory.routingNumber.isNotNull();
    final query = selectOnly(bankCardHistory)
      ..addColumns([
        bankCardHistory.historyId,
        bankCardHistory.cardholderName,
        bankCardHistory.cardType,
        bankCardHistory.cardNetwork,
        bankCardHistory.expiryMonth,
        bankCardHistory.expiryYear,
        bankCardHistory.bankName,
        hasCardNumberExpr,
        hasCvvExpr,
        hasAccountNumberExpr,
        hasRoutingNumberExpr,
      ])
      ..where(bankCardHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(bankCardHistory.historyId)!: BankCardHistoryCardDataDto(
          cardholderName: row.read(bankCardHistory.cardholderName),
          cardType: row.readWithConverter<CardType?, String>(bankCardHistory.cardType),
          cardNetwork: row.readWithConverter<CardNetwork?, String>(bankCardHistory.cardNetwork),
          expiryMonth: row.read(bankCardHistory.expiryMonth),
          expiryYear: row.read(bankCardHistory.expiryYear),
          bankName: row.read(bankCardHistory.bankName),
          hasCardNumber: row.read(hasCardNumberExpr) ?? false,
          hasCvv: row.read(hasCvvExpr) ?? false,
          hasAccountNumber: row.read(hasAccountNumberExpr) ?? false,
          hasRoutingNumber: row.read(hasRoutingNumberExpr) ?? false,
        ),
    };
  }

  Future<String?> getCardNumberByHistoryId(String historyId) async {
    final row = await (selectOnly(bankCardHistory)
          ..addColumns([bankCardHistory.cardNumber])
          ..where(bankCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(bankCardHistory.cardNumber);
  }

  Future<String?> getCvvByHistoryId(String historyId) async {
    final row = await (selectOnly(bankCardHistory)
          ..addColumns([bankCardHistory.cvv])
          ..where(bankCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(bankCardHistory.cvv);
  }

  Future<String?> getAccountNumberByHistoryId(String historyId) async {
    final row = await (selectOnly(bankCardHistory)
          ..addColumns([bankCardHistory.accountNumber])
          ..where(bankCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(bankCardHistory.accountNumber);
  }

  Future<String?> getRoutingNumberByHistoryId(String historyId) async {
    final row = await (selectOnly(bankCardHistory)
          ..addColumns([bankCardHistory.routingNumber])
          ..where(bankCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(bankCardHistory.routingNumber);
  }

}
