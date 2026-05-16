import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

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


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<LoyaltyCardHistoryData>> getLoyaltyCardHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(loyaltyCardHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, LoyaltyCardHistoryCardDataDto>> getLoyaltyCardHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasCardNumberExpr = loyaltyCardHistory.cardNumber.isNotNull();
    final hasBarcodeValueExpr = loyaltyCardHistory.barcodeValue.isNotNull();
    final hasPasswordExpr = loyaltyCardHistory.password.isNotNull();
    final query = selectOnly(loyaltyCardHistory)
      ..addColumns([
        loyaltyCardHistory.historyId,
        loyaltyCardHistory.programName,
        loyaltyCardHistory.barcodeType,
        loyaltyCardHistory.issuer,
        loyaltyCardHistory.website,
        loyaltyCardHistory.phone,
        loyaltyCardHistory.email,
        loyaltyCardHistory.validFrom,
        loyaltyCardHistory.validTo,
        hasCardNumberExpr,
        hasBarcodeValueExpr,
        hasPasswordExpr,
      ])
      ..where(loyaltyCardHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(loyaltyCardHistory.historyId)!: LoyaltyCardHistoryCardDataDto(
          programName: row.read(loyaltyCardHistory.programName),
          barcodeType: row.readWithConverter<LoyaltyBarcodeType?, String>(loyaltyCardHistory.barcodeType),
          issuer: row.read(loyaltyCardHistory.issuer),
          website: row.read(loyaltyCardHistory.website),
          phone: row.read(loyaltyCardHistory.phone),
          email: row.read(loyaltyCardHistory.email),
          validFrom: row.read(loyaltyCardHistory.validFrom),
          validTo: row.read(loyaltyCardHistory.validTo),
          hasCardNumber: row.read(hasCardNumberExpr) ?? false,
          hasBarcodeValue: row.read(hasBarcodeValueExpr) ?? false,
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
    };
  }

  Future<String?> getCardNumberByHistoryId(String historyId) async {
    final row = await (selectOnly(loyaltyCardHistory)
          ..addColumns([loyaltyCardHistory.cardNumber])
          ..where(loyaltyCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardHistory.cardNumber);
  }

  Future<String?> getBarcodeValueByHistoryId(String historyId) async {
    final row = await (selectOnly(loyaltyCardHistory)
          ..addColumns([loyaltyCardHistory.barcodeValue])
          ..where(loyaltyCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardHistory.barcodeValue);
  }

  Future<String?> getPasswordByHistoryId(String historyId) async {
    final row = await (selectOnly(loyaltyCardHistory)
          ..addColumns([loyaltyCardHistory.password])
          ..where(loyaltyCardHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardHistory.password);
  }

}
