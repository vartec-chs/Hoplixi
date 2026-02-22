import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('RecoveryCodesHistoryData')
class RecoveryCodesHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get codesBlob => text()();

  IntColumn get codesCount => integer().nullable()();

  IntColumn get usedCount => integer().nullable()();

  TextColumn get perCodeStatus => text().nullable()();

  DateTimeColumn get generatedAt => dateTime().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  TextColumn get displayHint => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'recovery_codes_history';
}
