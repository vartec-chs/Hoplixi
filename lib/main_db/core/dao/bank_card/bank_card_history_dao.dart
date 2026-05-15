import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/bank_card/bank_card_history.dart';

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
}
