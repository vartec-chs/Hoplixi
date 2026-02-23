import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('RecoveryCodesItemsData')
class RecoveryCodesItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get codesBlob => text()();

  IntColumn get codesCount => integer().nullable()();

  IntColumn get usedCount => integer().nullable()();

  TextColumn get perCodeStatus => text().nullable()();

  DateTimeColumn get generatedAt => dateTime().nullable()();

  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  TextColumn get displayHint => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'recovery_codes_items';
}
