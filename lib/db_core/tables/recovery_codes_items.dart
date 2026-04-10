import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('RecoveryCodesItemsData')
class RecoveryCodesItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Кэш: общее кол-во кодов. Обновляется триггерами при изменении recovery_codes.
  IntColumn get codesCount => integer().withDefault(const Constant(0))();

  /// Кэш: кол-во использованных кодов. Обновляется триггерами.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get generatedAt => dateTime().nullable()();

  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  TextColumn get displayHint => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'recovery_codes_items';
}
