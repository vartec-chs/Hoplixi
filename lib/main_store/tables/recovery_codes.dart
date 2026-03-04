import 'package:drift/drift.dart';

import 'recovery_codes_items.dart';

@DataClassName('RecoveryCodeData')
class RecoveryCodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemId => text().references(
    RecoveryCodesItems,
    #itemId,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get code => text()();

  BoolColumn get used => boolean().withDefault(const Constant(false))();

  DateTimeColumn get usedAt => dateTime().nullable()();

  IntColumn get position => integer().nullable()();

  @override
  String get tableName => 'recovery_codes';
}
