import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('LoyaltyCardHistoryData')
class LoyaltyCardHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get programName => text().withLength(min: 1, max: 255)();

  TextColumn get cardNumber => text().withLength(min: 0, max: 255).nullable()();

  TextColumn get holderName => text().nullable()();

  TextColumn get barcodeValue => text().nullable()();

  TextColumn get barcodeType => text().nullable()();
  TextColumn get password => text().nullable()();
  TextColumn get pointsBalance => text().nullable()();

  TextColumn get tier => text().nullable()();

  DateTimeColumn get expiryDate => dateTime().nullable()();

  TextColumn get website => text().nullable()();

  TextColumn get phoneNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'loyalty_card_history';
}
