import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/bank_card/bank_card_items.dart';

part 'bank_card_items_dao.g.dart';

@DriftAccessor(tables: [BankCardItems])
class BankCardItemsDao extends DatabaseAccessor<MainStore>
    with _$BankCardItemsDaoMixin {
  BankCardItemsDao(super.db);

  Future<void> insertBankCard(BankCardItemsCompanion companion) {
    return into(bankCardItems).insert(companion);
  }

  Future<int> updateBankCardByItemId(
    String itemId,
    BankCardItemsCompanion companion,
  ) {
    return (update(bankCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<BankCardItemsData?> getBankCardByItemId(String itemId) {
    return (select(bankCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsBankCardByItemId(String itemId) async {
    final row = await (selectOnly(bankCardItems)
          ..addColumns([bankCardItems.itemId])
          ..where(bankCardItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteBankCardByItemId(String itemId) {
    return (delete(bankCardItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<String?> getCardNumberByItemId(String itemId) async {
    final row = await (selectOnly(bankCardItems)
          ..addColumns([bankCardItems.cardNumber])
          ..where(bankCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(bankCardItems.cardNumber);
  }

  Future<String?> getCvvByItemId(String itemId) async {
    final row = await (selectOnly(bankCardItems)
          ..addColumns([bankCardItems.cvv])
          ..where(bankCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(bankCardItems.cvv);
  }

  Future<String?> getAccountNumberByItemId(String itemId) async {
    final row = await (selectOnly(bankCardItems)
          ..addColumns([bankCardItems.accountNumber])
          ..where(bankCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(bankCardItems.accountNumber);
  }

  Future<String?> getRoutingNumberByItemId(String itemId) async {
    final row = await (selectOnly(bankCardItems)
          ..addColumns([bankCardItems.routingNumber])
          ..where(bankCardItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(bankCardItems.routingNumber);
  }
}
