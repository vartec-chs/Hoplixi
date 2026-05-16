import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/loyalty_card/loyalty_card_history.dart';

part 'loyalty_card_history_dao.g.dart';

@DriftAccessor(tables: [LoyaltyCardHistory])
class LoyaltyCardHistoryDao extends DatabaseAccessor<MainStore>
    with _$LoyaltyCardHistoryDaoMixin {
  LoyaltyCardHistoryDao(super.db);

  Future<void> insertLoyaltyCardHistory(
    LoyaltyCardHistoryCompanion companion,
  ) {
    return into(loyaltyCardHistory).insert(companion);
  }

  Future<LoyaltyCardHistoryData?> getLoyaltyCardHistoryByHistoryId(
    String historyId,
  ) {
    return (select(loyaltyCardHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsLoyaltyCardHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(loyaltyCardHistory)
          ..addColumns([loyaltyCardHistory.historyId])
          ..where(loyaltyCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteLoyaltyCardHistoryByHistoryId(String historyId) {
    return (delete(loyaltyCardHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
