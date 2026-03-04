import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('RecoveryCodesHistoryData')
class RecoveryCodesHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Снимок общего кол-ва кодов на момент события.
  IntColumn get codesCount => integer().nullable()();

  /// Снимок кол-ва использованных кодов.
  IntColumn get usedCount => integer().nullable()();

  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  TextColumn get displayHint => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'recovery_codes_history';
}
