import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/loyalty_card/loyalty_card_items.dart';

part 'loyalty_card_items_dao.g.dart';

@DriftAccessor(tables: [LoyaltyCardItems])
class LoyaltyCardItemsDao extends DatabaseAccessor<MainStore>
    with _$LoyaltyCardItemsDaoMixin {
  LoyaltyCardItemsDao(super.db);

  Future<void> insertLoyaltyCard(
    LoyaltyCardItemsCompanion companion,
  ) {
    return into(loyaltyCardItems).insert(companion);
  }

  Future<int> updateLoyaltyCardByItemId(
    String itemId,
    LoyaltyCardItemsCompanion companion,
  ) {
    return (update(loyaltyCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<LoyaltyCardItemsData?> getLoyaltyCardByItemId(String itemId) {
    return (select(loyaltyCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsLoyaltyCardByItemId(String itemId) async {
    final row = await (selectOnly(loyaltyCardItems)
          ..addColumns([loyaltyCardItems.itemId])
          ..where(loyaltyCardItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteLoyaltyCardByItemId(String itemId) {
    return (delete(loyaltyCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<String?> getCardNumberByItemId(String itemId) async {
    final row = await (selectOnly(loyaltyCardItems)
          ..addColumns([loyaltyCardItems.cardNumber])
          ..where(loyaltyCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardItems.cardNumber);
  }

  Future<String?> getBarcodeValueByItemId(String itemId) async {
    final row = await (selectOnly(loyaltyCardItems)
          ..addColumns([loyaltyCardItems.barcodeValue])
          ..where(loyaltyCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardItems.barcodeValue);
  }

  Future<String?> getLoyaltyPasswordByItemId(String itemId) async {
    final row = await (selectOnly(loyaltyCardItems)
          ..addColumns([loyaltyCardItems.password])
          ..where(loyaltyCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(loyaltyCardItems.password);
  }
}
